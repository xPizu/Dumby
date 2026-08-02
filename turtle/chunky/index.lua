-- Dumby Chunky (Follower)
-- Runs on a separate turtle equipped with a Chunky Turtle upgrade + wireless
-- modem (no pickaxe needed: it only ever walks through tunnels the mining
-- turtle already carved). It replays the mining turtle's moves a few steps
-- behind so its chunk-loading radius keeps trailing the exploration.

local CONFIG = require("config")
local FUEL_MANAGER = require("classes.managers.fuel")
local COMMUNICATOR = require("classes.communicator")

local function Log(msg) print("[Chunky] " .. msg) end

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

-- Turning costs no fuel in CC:Tweaked, forward/up/down do. With no pickaxe
-- and no auto-refuel source, running dry looks exactly like "spins in place
-- but never advances" -- so we warn loudly instead of failing silently.
local outOfFuelWarned = false
local function CheckFuel()
    FUEL:AutoRefuel(0)
    local level = FUEL:GetLevel()
    if level == 0 then
        if not outOfFuelWarned then
            Log("OUT OF FUEL -- add coal/charcoal to the inventory. Turns still work, movement won't.")
            outOfFuelWarned = true
        end
    elseif outOfFuelWarned then
        Log("Fuel restored (" .. level .. "). Resuming movement.")
        outOfFuelWarned = false
    end
end

local function Execute(action)
    local move = ACTIONS[action]
    if not move then return end

    CheckFuel()

    local attempts = 0
    while not move() do
        attempts = attempts + 1
        if attempts > 6 then
            Log("Could not " .. action .. " after 6 attempts, giving up on this step.")
            return
        end
        sleep(0.3)
    end
end

Log("Waiting for the mining turtle...")

local queue = {}
while true do
    local senderId, message = rednet.receive(CONFIG.RednetChunkyProtocol)

    if not LINK.peerId then
        LINK.peerId = senderId
        Log("Paired with mining turtle #" .. senderId)
    end

    if senderId == LINK.peerId and ACTIONS[message] then
        table.insert(queue, message)

        while #queue > CONFIG.ChunkyFollowBuffer do
            Execute(table.remove(queue, 1))
        end
    end
end
