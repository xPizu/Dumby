local basalt = require("basalt")
local LOG_MODULE = require("lib.log")
local SOUND_MODULE = require("lib.sound")
local Dashboard = require("ui.dashboard")

local MODEM = peripheral.find("modem")
if not MODEM then error("No modem found on this computer.") end
rednet.open(peripheral.getName(MODEM))

local PROTOCOL = "dumby"
local REMOTE_HOSTNAME = "dumby-remote"
local ALIVE_TIMEOUT = 15

rednet.host(PROTOCOL, REMOTE_HOSTNAME)

local SOUND = SOUND_MODULE.New(peripheral.find("speaker"))
local state = { turtleId = nil, online = false, simulation = false, fuel = nil, ore = nil, x = nil, y = nil, z = nil }

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

local ctx = { send = Send, state = state, commandList = commandList, sound = SOUND }

local ui = Dashboard.Build(commandList, {
    onButtonClick = function(cmd) cmd.execute(ctx, {}) end,
    onSubmit = function(text)
        local args = {}
        for word in text:gmatch("%S+") do table.insert(args, word) end
        local name = table.remove(args, 1)
        local cmd = name and commands[name]
        if cmd then
            cmd.execute(ctx, args)
        else
            ctx.log.Warn("Unknown command '" .. tostring(name) .. "'.")
        end
    end,
})

ctx.log = LOG_MODULE.New(ui)
ctx.ui = ui

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
    alive = function(msg)
        state.simulation = msg.simulation or false
        ui.setStatus(state.online, state.simulation)
    end,

    ack = function(msg)
        if msg.detail then
            ctx.log.Warn("Dumby confirmed '" .. msg.of .. "' (" .. msg.detail .. ")")
            return
        end
        ctx.log.Ok("Dumby confirmed '" .. msg.of .. "'.")
        local sound = ACK_SOUNDS[msg.of]
        if sound then SOUND[sound](SOUND) end
    end,

    returning_home = function(msg)
        local info = RETURN_REASONS[msg.reason]
        if not info then
            ctx.log.Info("Dumby is heading back home (" .. tostring(msg.reason) .. ").")
            return
        end
        ctx.log[info.level]("Dumby is " .. info.text)
        SOUND[info.sound](SOUND)
    end,

    status_report = function(msg)
        state.fuel, state.ore = msg.fuel, msg.ore
        state.x, state.y, state.z = msg.x, msg.y, msg.z
        state.simulation = msg.simulation or false
        ui.setStats(msg.fuel, msg.ore, msg.x, msg.y, msg.z)
        ui.setStatus(state.online, state.simulation)
        ctx.log.Ok(string.format(
            "pos(%d,%d,%d) fuel=%s ore=%d started=%s stop=%s",
            msg.x, msg.y, msg.z,
            tostring(msg.fuel), msg.ore,
            tostring(msg.started), tostring(msg.stopReason)
        ))
    end,
}

local function SetOnline(online)
    if state.online == online then return end
    state.online = online
    ui.setStatus(state.online, state.simulation)
end

local function ListenLoop()
    ctx.log.Info("Waiting for Dumby...")
    while true do
        local senderId, message = rednet.receive(PROTOCOL, ALIVE_TIMEOUT)

        if not state.turtleId and senderId then
            state.turtleId = senderId
        end

        if message == nil then
            if state.online then
                ctx.log.Warn("No signal from Dumby during " .. ALIVE_TIMEOUT .. "s")
                SOUND:PlayOffline()
                SetOnline(false)
            end
        elseif senderId == state.turtleId and type(message) == "table" then
            SetOnline(true)
            local handler = MESSAGE_HANDLERS[message.cmd]
            if handler then handler(message) end
        end
    end
end

basalt.schedule(ListenLoop)
basalt.run()
