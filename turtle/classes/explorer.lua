local CONFIG = require("config")

local Explorer = {}
Explorer.__index = Explorer

function Explorer:New(fuel, inventory)
    local self = setmetatable({}, Explorer)
    self.Fuel = fuel
    self.Inventory = inventory
    self.StopRequested = false
    self.Rescue = false
    self.StopReason = nil
    self.OreCount = 0
    return self
end

-- Rescue implies StopRequested (every existing safety check already respects
-- it) but also skips inventory housekeeping on the way home -- see Robot:ReturnHome.
function Explorer:TriggerRescue()
    self.StopRequested = true
    self.Rescue = true
    self.StopReason = "Rescue triggered"
end

function Explorer:CheckSafety(nav)
    if self.StopRequested then
        self.StopReason = self.StopReason or "Stop order received"
        return false
    end

    self.Inventory:DropJunk()
    if self.Inventory:IsFull() then
        self.StopReason = "Inventory full"
        return false
    end

    self.Fuel:AutoRefuel()
    local needed = nav:DistanceHome() + CONFIG.FuelSafetyMargin
    if self.Fuel:GetLevel() < needed then
        self.StopReason = "Insufficient fuel"
        return false
    end

    return true
end

-- Geo Scanner support: sees ore buried under solid rock within radius, not
-- just blocks touching the turtle's 6 faces -- this is what the blind
-- adjacent-check kept walking right past. Falls back to doing nothing if no
-- Geo Scanner is attached (the cave-follow logic below still works alone).
function Explorer:ScanForOre(nav)
    local geo = peripheral.find("geoScanner") or peripheral.find("geo_scanner")
    if not geo then return {} end

    local blocks = geo.scan(CONFIG.GeoScanRadius)
    if not blocks then return {} end

    local targets = {}
    for _, b in ipairs(blocks) do
        if CONFIG.OreWhitelist[b.name] then
            table.insert(targets, {
                x = nav.x + b.x,
                y = nav.y + b.y,
                z = nav.z + b.z,
                dist = math.abs(b.x) + math.abs(b.y) + math.abs(b.z),
            })
        end
    end

    table.sort(targets, function(a, b2) return a.dist < b2.dist end)
    return targets
end

-- Walks straight to each detected ore block (closest first), digging
-- through whatever's in the way -- Navigator already does that for free.
function Explorer:MineTargets(nav)
    for _, target in ipairs(self:ScanForOre(nav)) do
        if not self:CheckSafety(nav) then return end

        local beforeX, beforeY, beforeZ = nav.x, nav.y, nav.z
        nav:GoTo(target.x, target.y, target.z)
        if nav.x ~= beforeX or nav.y ~= beforeY or nav.z ~= beforeZ then
            self.OreCount = self.OreCount + 1
        end
    end
end

-- Ore reported by a companion Geo turtle (already converted to this
-- turtle's own coordinate frame -- see Robot's ore_found handler).
function Explorer:QueueRemoteOre(x, y, z)
    self.RemoteTargets = self.RemoteTargets or {}
    table.insert(self.RemoteTargets, { x = x, y = y, z = z })
end

function Explorer:DrainRemoteTargets(nav)
    if not self.RemoteTargets then return end

    while #self.RemoteTargets > 0 do
        if not self:CheckSafety(nav) then return end

        local target = table.remove(self.RemoteTargets, 1)
        local beforeX, beforeY, beforeZ = nav.x, nav.y, nav.z
        nav:GoTo(target.x, target.y, target.z)
        if nav.x ~= beforeX or nav.y ~= beforeY or nav.z ~= beforeZ then
            self.OreCount = self.OreCount + 1
        end
    end
end

-- Recurses into any open cavity (already air) or whitelisted ore, not just ore --
-- this is what lets the turtle actually follow natural caves instead of      --
-- stopping dead the moment a branch isn't a solid ore block.                 --
function Explorer:MineVeinAt(nav, dir, depth)
    if dir == "up" then
        local blocked = turtle.detectUp()
        if blocked then
            local ok, data = turtle.inspectUp()
            if not (ok and CONFIG.OreWhitelist[data.name]) then return end
        end

        if not nav:Up() then return end
        if blocked then self.OreCount = self.OreCount + 1 end
        self:ScanAndMine(nav, depth + 1)
        nav:Down()
    elseif dir == "down" then
        local blocked = turtle.detectDown()
        if blocked then
            local ok, data = turtle.inspectDown()
            if not (ok and CONFIG.OreWhitelist[data.name]) then return end
        end

        if not nav:Down() then return end
        if blocked then self.OreCount = self.OreCount + 1 end
        self:ScanAndMine(nav, depth + 1)
        nav:Up()
    else
        nav:FaceDirection(dir)
        local blocked = turtle.detect()
        if blocked then
            local ok, data = turtle.inspect()
            if not (ok and CONFIG.OreWhitelist[data.name]) then return end
        end

        if not nav:Forward() then return end
        if blocked then self.OreCount = self.OreCount + 1 end
        self:ScanAndMine(nav, depth + 1)
        nav:Back()
    end
end

function Explorer:ScanAndMine(nav, depth)
    depth = depth or 0
    if depth >= CONFIG.MaxCaveDepth then return end
    if not self:CheckSafety(nav) then return end

    local originalFacing = nav.facing
    self:MineVeinAt(nav, "up", depth)
    if not self.StopRequested then self:MineVeinAt(nav, "down", depth) end
    for f = 1, 4 do
        if self.StopRequested then break end
        self:MineVeinAt(nav, f, depth)
    end
    nav:FaceDirection(originalFacing)
end

-- Runs one square spiral pass at the turtle's current altitude.
-- Returns true once the pass completed the full radius, false on a terminal stop.
function Explorer:RunSpiralLayer(nav, maxRadius)
    local segLen, segCount = 1, 0

    while true do
        for _ = 1, segLen do
            if not self:CheckSafety(nav) then return false end
            if not nav:Forward() then
                self.StopReason = "Unpassable obstacle"
                return false
            end
            self:MineTargets(nav)
            self:DrainRemoteTargets(nav)
            self:ScanAndMine(nav)
        end

        nav:TurnRight()
        segCount = segCount + 1
        if segCount % 2 == 0 then
            segLen = segLen + 1
        end
        if segLen > maxRadius then
            return true
        end
    end
end

-- Repeats the spiral pass at CONFIG.LayerCount altitudes, CONFIG.LayerSpacing
-- blocks apart, so exploration covers more than a single Y-slice of the map.
function Explorer:RunSpiral(nav, maxRadius)
    for layer = 1, CONFIG.LayerCount do
        if not self:RunSpiralLayer(nav, maxRadius) then return end

        if layer < CONFIG.LayerCount then
            for _ = 1, CONFIG.LayerSpacing do
                if not self:CheckSafety(nav) then return end
                if not nav:Down() then
                    self.StopReason = "Unpassable obstacle"
                    return
                end
            end
        end
    end

    self.StopReason = "All layers explored"
end

return Explorer