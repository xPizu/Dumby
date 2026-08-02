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

function Communicator:Broadcast(message)
    if not self:IsAvailable() then return end

    if self.peerId then
        rednet.send(self.peerId, message, self.protocol)
    else
        rednet.broadcast(message, self.protocol)
    end
end

-- No live rednet.lookup on the hot path here: it's a blocking network
-- round-trip and doing it per-message caused missed heartbeats and dropped
-- stop commands. Instead we trust the first sender we ever hear from on this
-- protocol and lock onto them -- fine for a 1-to-1 turtle/remote pairing.
--
-- Messages are {cmd = "...", ...extra fields}; handlers are keyed by cmd and
-- receive the full message table.
function Communicator:Listen(handlers)
    while true do
        local senderId, message = rednet.receive(self.protocol)

        if not self.peerId then
            self.peerId = senderId
        end

        if senderId == self.peerId and type(message) == "table" then
            local handler = handlers[message.cmd]
            if handler then
                local ok, err = pcall(handler, message)
                if not ok then
                    print("[!] Handler error for '" .. tostring(message.cmd) .. "': " .. tostring(err))
                end
            end
        end
    end
end

return Communicator
