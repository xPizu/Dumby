local CONFIG = require("config")
local FUEL_MANAGER = require("classes.managers.fuel")
local COMMUNICATOR = require("classes.communicator")

local FUEL = FUEL_MANAGER:New()
local LINK = COMMUNICATOR:New(CONFIG.RednetChunkyProtocol, CONFIG.RednetChunkyHostname, CONFIG.RednetMiningHostname)

if not LINK:IsAvailable() then
    error("No modem found on this Chunky turtle.")
end

local ACTIONS = {
    forward = turtle.forward,
    up = turtle.up,
    down = turtle.down,
    left = turtle.turnLeft,
    right = turtle.turnRight,
}

local function Execute(action)
    local move = ACTIONS[action]
    if not move then return end

    FUEL:AutoRefuel()

    local attempts = 0
    while not move() do
        attempts = attempts + 1
        if attempts > 6 then break end
        sleep(0.3)
    end
end

print("Dumby Chunky -- Follower")
print("Waiting for the mining turtle...")

local queue = {}
while true do
    local senderId, message = rednet.receive(CONFIG.RednetChunkyProtocol)
    if senderId == LINK:ResolvePeer() and ACTIONS[message] then
        table.insert(queue, message)

        while #queue > CONFIG.ChunkyFollowBuffer do
            Execute(table.remove(queue, 1))
        end
    end
end