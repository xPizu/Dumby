local LOG = require("lib.log")
local UI = require("lib.ui")
local SOUND_MODULE = require("lib.sound")

local MODEM = peripheral.find("modem")
if not MODEM then error("No modem found on this computer.") end
rednet.open(peripheral.getName(MODEM))

local PROTOCOL = "dumby"
local REMOTE_HOSTNAME = "dumby-remote"
-- Must stay >= the turtle's heartbeat interval (10s), otherwise BootCheck's
-- single receive can land in the gap between two heartbeats and wrongly
-- report Dumby as offline even though it's up and broadcasting fine.
local BOOT_TIMEOUT = 15
local ALIVE_TIMEOUT = 15

rednet.host(PROTOCOL, REMOTE_HOSTNAME)

local SOUND = SOUND_MODULE.New(peripheral.find("speaker"))

-- No live rednet.lookup here: it's a blocking network round-trip and doing
-- it per-message caused missed heartbeats and dropped stop commands. We
-- trust the first sender we ever hear from on this protocol and lock onto
-- them -- fine for a 1-to-1 turtle/remote pairing.
local state = { turtleId = nil }

local function Send(message)
    if state.turtleId then
        rednet.send(state.turtleId, message, PROTOCOL)
    else
        rednet.broadcast(message, PROTOCOL)
    end
end

-- Commands: one file per command in commands/, each returning
-- { name, description, execute(ctx, args) }. Drop a new file in there and
-- it's picked up automatically, no wiring needed here.
local commands = {}
local commandList = {}
for _, file in ipairs(fs.list("commands")) do
    if file:match("%.lua$") then
        local cmd = dofile("commands/" .. file)
        commands[cmd.name] = cmd
        table.insert(commandList, cmd)
    end
end
table.sort(commandList, function(a, b) return a.name < b.name end)

local ctx = { send = Send, log = LOG, state = state, commandList = commandList, sound = SOUND }

UI.Clear()
UI.PrintHeader(commandList)
print("")

-- Boot Check: wait for Dumby's first heartbeat, or assume it's offline.
LOG.Info("Waiting for Dumby...")
local senderId, message = rednet.receive(PROTOCOL, BOOT_TIMEOUT)
if type(message) == "table" and message.cmd == "alive" then
    state.turtleId = senderId
    LOG.Ok("Dumby is online!")
    SOUND:PlayOnline()
else
    LOG.Warn("No signal received during " .. BOOT_TIMEOUT .. "s. Maybe Dumby is offline.")
    SOUND:PlayOffline()
end
print("")

-- Command Loop: read user input, dispatch to the matching command file.
local function CommandLoop()
    while true do
        io.write("> ")
        local input = read()

        local args = {}
        for word in input:gmatch("%S+") do table.insert(args, word) end
        local name = table.remove(args, 1)

        if name then
            local cmd = commands[name]
            if cmd then
                cmd.execute(ctx, args)
            else
                LOG.Warn("Unknown command '" .. name .. "'. Type 'help' for the list.")
            end
        end
    end
end

-- Listening Loop: handle unsolicited messages from Dumby (heartbeat,
-- returning home, status replies). If nothing arrives for ALIVE_TIMEOUT
-- seconds, assume Dumby is offline.
local function ListenLoop()
    while true do
        local senderId2, message2 = rednet.receive(PROTOCOL, ALIVE_TIMEOUT)

        if not state.turtleId and senderId2 then
            state.turtleId = senderId2
        end

        if message2 == nil then
            LOG.Warn("No signal from Dumby during " .. ALIVE_TIMEOUT .. "s")
            SOUND:PlayOffline()
        elseif senderId2 ~= state.turtleId or type(message2) ~= "table" then
            -- Ignore anyone but our own turtle
        elseif message2.cmd == "alive" then
            -- Skip
        elseif message2.cmd == "ack" then
            if message2.detail then
                LOG.Warn("Dumby confirmed '" .. message2.of .. "' (" .. message2.detail .. ")")
            else
                LOG.Ok("Dumby confirmed '" .. message2.of .. "'.")
                if message2.of == "rescue" then SOUND:PlayRescue() end
            end
        elseif message2.cmd == "returning_home" then
            if message2.reason == "Unpassable obstacle" then
                LOG.Crit("Dumby is STUCK (unpassable obstacle) and heading back home.")
                SOUND:PlayAlert()
            elseif message2.reason == "Insufficient fuel" then
                LOG.Warn("Dumby is low on fuel and heading back home.")
                SOUND:PlayLowFuel()
            elseif message2.reason == "Inventory full" then
                LOG.Warn("Dumby's inventory is full and heading back home.")
                SOUND:PlayLowFuel()
            else
                LOG.Info("Dumby is heading back home (" .. tostring(message2.reason) .. ").")
                SOUND:PlayReturn()
            end
        elseif message2.cmd == "status_report" then
            LOG.Ok(string.format(
                "pos(%d,%d,%d) fuel=%s ore=%d started=%s stop=%s",
                message2.x, message2.y, message2.z,
                tostring(message2.fuel), message2.ore,
                tostring(message2.started), tostring(message2.stopReason)
            ))
        end
    end
end

parallel.waitForAny(CommandLoop, ListenLoop)
