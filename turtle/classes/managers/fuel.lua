local CONFIG = require("config")

local FuelManager = {}
FuelManager.__index = FuelManager

function FuelManager:New()
    return setmetatable({}, FuelManager)
end

function FuelManager:GetLevel()
    return turtle.getFuelLevel()
end

function FuelManager:AutoRefuel()
    if turtle.getFuelLevel() >= CONFIG.ComfortableFuel then return end

    local total = 0
    for slot = 1, 16 do
        local itemDetails = turtle.getItemDetail(slot)
        if itemDetails and CONFIG.FuelItems[itemDetails.name] then total = total + itemDetails.count end
    end

    local excess = total - CONFIG.CoalReserveKeep
    if excess <= 0 then return end

    for slot = 1, 16 do
        if excess <= 0 then break end
        local itemDetails = turtle.getItemDetail(slot)
        if itemDetails and CONFIG.FuelItems[itemDetails.name] then
            turtle.select(slot)
            local toUse = math.min(excess, itemDetails.count)
            turtle.refuel(toUse)
            excess = excess - toUse
        end
    end
    turtle.select(1)
end

return FuelManager