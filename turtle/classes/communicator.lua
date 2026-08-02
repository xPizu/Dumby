local Communicator = {}
Communicator.__index = Communicator

-- protocol/selfHostname/peerHostname let a turtle open several independent
-- rednet links (e.g. one to the human remote, one to a follower turtle)
-- without them ever seeing each other's traffic.
function Communicator:New(protocol, selfHostname, peerHostname)
    local self = setmetatable({}, Communicator)
    self.modemSide = nil
    self.protocol = protocol
    self.peerHostname = peerHostname
    self.peerId = nil

    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" then
            self.modemSide = side
            break
        end
    end

    if self.modemSide then
        if not rednet.isOpen(self.modemSide) then
            rednet.open(self.modemSide)
        end
        rednet.host(self.protocol, selfHostname)
    end

    return self
end

function Communicator:IsAvailable()
    return self.modemSide ~= nil
end

function Communicator:ResolvePeer()
    if not self.peerId then
        self.peerId = rednet.lookup(self.protocol, self.peerHostname)
    end
    return self.peerId
end

function Communicator:Broadcast(message)
    if not self:IsAvailable() then return end

    local peerId = self:ResolvePeer()
    if peerId then
        rednet.send(peerId, message, self.protocol)
    else
        rednet.broadcast(message, self.protocol)
    end
end

function Communicator:Listen(handlers)
    while true do
        local senderId, message = rednet.receive(self.protocol)
        if senderId == self:ResolvePeer() then
            local handler = handlers[message]
            if handler then handler(message) end
        end
    end
end

return Communicator
