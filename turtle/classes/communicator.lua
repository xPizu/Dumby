local CONFIG = require("config")

local Communicator = {}
Communicator.__index = Communicator

function Communicator:New()
    local self = setmetatable({}, Communicator)
    self.modemSide = nil

    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" then
            self.modemSide = side
            break
        end
    end

    if self.modemSide then
        rednet.open(self.modemSide)
    end

    return self
end

function Communicator:IsAvailable()
    return self.modemSide ~= nil
end

function Communicator:Broadcast(message)
    if self:IsAvailable() then
        rednet.broadcast(message, CONFIG.rednetProtocol)
    end
end

function Communicator:Listen(handlers)
    while true do
        local _, message = rednet.receive(CONFIG.RednetProtocol)
        local handler = handlers[message]
        if handler then handler() end
    end
end

return Communicator