local CONFIG = require("config")

local InventoryManager = {}
InventoryManager.__index = InventoryManager

function InventoryManager:New()
    return setmetatable({}, InventoryManager)
end

function InventoryManager:DropJunk()
    for slot = 1, 16 do
        local itemDetails = turtle.getItemDetail(slot)
        if itemDetails and CONFIG.JunkBlacklist[itemDetails.name] then
            turtle.select(slot)
            turtle.drop()
        end
    end
    turtle.select(1)
end

function InventoryManager:GetFreeSlots()
    local free = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then free = free + 1 end
    end
    return free
end

function InventoryManager:IsFull()
    return self:GetFreeSlots() <= CONFIG.InventoryFullThreshold
end

function InventoryManager:Dump()
    for slot = 1, 16 do
        local itemDetails = turtle.getItemDetail(slot)
        if itemDetails and not CONFIG.FuelItems[itemDetails.name] then
            turtle.select(slot)
            turtle.drop()
        end
    end
    turtle.select(1)
end

return InventoryManager