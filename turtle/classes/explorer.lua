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

function Explorer:MineVeinAt(nav, dir, depth)
    if dir == "up" then
        if not turtle.detectUp() then return end
        local ok, data = turtle.inspectUp()
        if not (ok and CONFIG.OreWhitelist[data.name]) then return end

        if not nav:Up() then return end
        self.OreCount = self.OreCount + 1
        self:ScanAndMine(nav, depth + 1)
        nav:Down()
    elseif dir == "down" then
        if not turtle.detectDown() then return end
        local ok, data = turtle.inspectDown()
        if not (ok and CONFIG.OreWhitelist[data.name]) then return end

        if not nav:Down() then return end
        self.OreCount = self.OreCount + 1
        self:ScanAndMine(nav, depth + 1)
        nav:Up()
    else
        nav:faceDirection(dir)
        if not turtle.detect() then return end
        local ok, data = turtle.inspect()
        if not (ok and CONFIG.OreWhitelist[data.name]) then return end

        if not nav:Forward() then return end
        self.OreCount = self.OreCount + 1
        self:ScanAndMine(nav, depth + 1)
        nav:Back()
    end
end

function Explorer:ScanAndMine(nav, depth)
    depth = depth or 0
    if depth >= CONFIG.MaxVeinDepth then return end
    if not self:CheckSafety(nav) then return end

    local originalFacing = nav.facing
    self:MineVeinAt(nav, "up", depth)
    self:MineVeinAt(nav, "down", depth)
    for f = 1, 4 do
        self:MineVeinAt(nav, f, depth)
    end
    nav:faceDirection(originalFacing)
end

function Explorer:RunSpiral(nav, maxRadius)
    local segLen, segCount = 1, 0

    while true do
        for _ = 1, segLen do
            if not self:CheckSafety(nav) then return end
            if not nav:Forward() then
                self.StopReason = "Unpassable obstacle"
                return
            end
            self:ScanAndMine(nav)
        end

        nav:TurnRight()
        segCount = segCount + 1
        if segCount % 2 == 0 then
            segLen = segLen + 1
        end
        if segLen > maxRadius then
            self.StopReason = "Maximum radius reached"
            return
        end
    end
end

return Explorer