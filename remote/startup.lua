local LOG = require("lib.log")
local UI = require("lib.ui")
local SOUND_MODULE = require("lib.sound")

local MODEM = peripheral.find("modem")
if not MODEM then error("No modem found on this computer.") end
rednet.open(peripheral.getName(MODEM))

local PROTOCOL = "dumby"
local REMOTE_HOSTNAME = "dumby-remote"
local BOOT_TIMEOUT = 15
local ALIVE_TIMEOUT = 15

rednet.host(PROTOCOL, REMOTE_HOSTNAME)

local SOUND = SOUND_MODULE.New(peripheral.find("speaker"))
local state = { turtleId = nil, online = false }

local function Send(message)
    if state.turtleId then
        rednet.send(state.turtleId, message, PROTOCOL)
    else
        rednet.broadcast(message, PROTOCOL)
    end
end

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

local ctx = { send = Send, log = LOG, state = state, commandList = commandList, sound = SOUND, ui = UI }

UI.Clear()
UI.PrintHeader(commandList)
print("")

LOG.Info("Waiting for Dumby...")
local senderId, message = rednet.receive(PROTOCOL, BOOT_TIMEOUT)
if type(message) == "table" and message.cmd == "alive" then
    state.turtleId = senderId
    state.online = true
    LOG.Ok("Dumby is online!")
    SOUND:PlayOnline()
else
    LOG.Warn("No signal received during " .. BOOT_TIMEOUT .. "s. Maybe Dumby is offline.")
    SOUND:PlayOffline()
end
print("")

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

local RETURN_REASONS = {
    ["Unpassable obstacle"] = { level = "Crit", text = "STUCK (unpassable obstacle) and heading back home.", sound = "PlayAlert" },
    ["Insufficient fuel"] = { level = "Warn", text = "low on fuel and heading back home.", sound = "PlayLowFuel" },
    ["Inventory full"] = { level = "Warn", text = "inventory is full and heading back home.", sound = "PlayInventoryFull" },
}

local ACK_SOUNDS = {
    rescue = "PlayRescue",
    stop = "PlayReturn",
}

local MESSAGE_HANDLERS = {
    alive = function() end,

    ack = function(msg)
        if msg.detail then
            LOG.Warn("Dumby confirmed '" .. msg.of .. "' (" .. msg.detail .. ")")
            return
        end
        LOG.Ok("Dumby confirmed '" .. msg.of .. "'.")
        local sound = ACK_SOUNDS[msg.of]
        if sound then SOUND[sound](SOUND) end
    end,

    returning_home = function(msg)
        local info = RETURN_REASONS[msg.reason]
        if not info then
            LOG.Info("Dumby is heading back home (" .. tostring(msg.reason) .. ").")
            return
        end
        LOG[info.level]("Dumby is " .. info.text)
        SOUND[info.sound](SOUND)
    end,

    status_report = function(msg)
        LOG.Ok(string.format(
            "pos(%d,%d,%d) fuel=%s ore=%d started=%s stop=%s",
            msg.x, msg.y, msg.z,
            tostring(msg.fuel), msg.ore,
            tostring(msg.started), tostring(msg.stopReason)
        ))
    end,
}

local function ListenLoop()
    while true do
        local senderId2, message2 = rednet.receive(PROTOCOL, ALIVE_TIMEOUT)

        if not state.turtleId and senderId2 then
            state.turtleId = senderId2
        end

        if message2 == nil then
            if state.online then
                LOG.Warn("No signal from Dumby during " .. ALIVE_TIMEOUT .. "s")
                SOUND:PlayOffline()
                state.online = false
            end
        elseif senderId2 == state.turtleId and type(message2) == "table" then
            state.online = true
            local handler = MESSAGE_HANDLERS[message2.cmd]
            if handler then handler(message2) end
        end
    end
end

parallel.waitForAny(CommandLoop, ListenLoop)