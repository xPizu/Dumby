local CONFIG = require("config")

local Explorer = {}
Explorer.__index = Explorer

function Explorer:New(fuel, inventory)
    local self = setmetatable({}, Explorer)
    self.Fuel = fuel
    self.Inventory = inventory
    self.StopRequested = false
    self.StopReason = nil
    self.OreCount = 0
    return self
end

function Explorer:CheckSafety(nav)
    if self.StopRequested then
        self.StopReason = "Stop order received"
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