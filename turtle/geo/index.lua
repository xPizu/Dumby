-- Dumby Geo (Companion Scanner)
-- Runs on a separate turtle equipped with a Geo Scanner + wireless modem
-- (no pickaxe, no room for it: same 2-upgrade-slot limit that keeps the
-- mining turtle to pickaxe+modem). It follows the mining turtle through
-- tunnels it already carved (same move-broadcast channel as the Chunky
-- turtle), and periodically scans for ore, reporting hits back so the
-- mining turtle can path to them.

local CONFIG = require("config")
local NAVIGATOR = require("classes.navigator")
local FUEL_MANAGER = require("classes.managers.fuel")
local COMMUNICATOR = require("classes.communicator")

local function Log(msg) print("[Geo] " .. msg) end

local nav = NAVIGATOR:New()
local fuel = FUEL_MANAGER:New()
local link = COMMUNICATOR:New(CONFIG.RednetGeoProtocol, CONFIG.RednetGeoHostname, CONFIG.RednetMiningHostname)

if not link:IsAvailable() then
    error("No modem found on this Geo turtle.")
end

local scanner = nil
for _, name in ipairs(peripheral.getNames()) do
    local ptype = peripheral.getType(name)
    Log("Peripheral '" .. name .. "': " .. tostring(ptype))
    if ptype == "geoScanner" or ptype == "geo_scanner" then
        scanner = peripheral.wrap(name)
    end
end

if not scanner then
    error("No Geo Scanner found on this turtle (see peripheral list above).")
end

local FOLLOW_ACTIONS = {
    forward = function() return nav:Forward() end,
    up = function() return nav:Up() end,
    down = function() return nav:Down() end,
    left = function() nav:TurnLeft(); return true end,
    right = function() nav:TurnRight(); return true end,
}

local function ExecuteFollow(action)
    local move = FOLLOW_ACTIONS[action]
    if not move then return end

    fuel:AutoRefuel(0)

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

-- Same move-broadcast channel the Chunky turtle listens on -- both can
-- follow independently off the same feed.
local function FollowLoop()
    Log("Waiting for the mining turtle...")
    local peerId = nil
    local queue = {}

    while true do
        local senderId, message = rednet.receive(CONFIG.RednetChunkyProtocol)

        if not peerId then
            peerId = senderId
            Log("Following mining turtle #" .. senderId)
        end

        if senderId == peerId and FOLLOW_ACTIONS[message] then
            table.insert(queue, message)
            while #queue > CONFIG.ChunkyFollowBuffer do
                local ok, err = pcall(ExecuteFollow, table.remove(queue, 1))
                if not ok then Log("Move error: " .. tostring(err)) end
            end
        end
    end
end

-- Scans on an interval and reports any whitelisted ore, converted to this
-- turtle's own boot-relative coordinates -- the mining turtle applies
-- CONFIG.GeoBootOffset to translate them into its own frame.
local function ScanLoop()
    while true do
        sleep(CONFIG.GeoScanInterval)

        local ok, blocks = pcall(function() return scanner.scan(CONFIG.GeoScanRadius) end)
        if ok and blocks then
            for _, b in ipairs(blocks) do
                if CONFIG.OreWhitelist[b.name] then
                    link:Broadcast({
                        cmd = "ore_found",
                        x = nav.x + b.x,
                        y = nav.y + b.y,
                        z = nav.z + b.z,
                    })
                end
            end
        elseif not ok then
            Log("Scan error: " .. tostring(blocks))
        end
    end
end

local ok, err = pcall(parallel.waitForAny, FollowLoop, ScanLoop)
if not ok then
    Log("FATAL: " .. tostring(err))
    print("Program halted.")
end
