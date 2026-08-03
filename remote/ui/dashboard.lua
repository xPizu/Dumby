-- Builds the whole Basalt widget tree: a tab bar switching between
-- Control (button grid + typed-command input), Stats (live gauges) and
-- Log (scrolling severity-tagged output). Pure UI shell -- knows nothing
-- about rednet or commands, just calls back into startup.lua.
local basalt = require("basalt")
local THEME = require("lib.theme")

local Dashboard = {}

local LOG_LINES = 16
local BUTTON_W, BUTTON_H = 10, 3
local BUTTON_COLS = 4
local GAUGE_W = 30

function Dashboard.Build(commandList, callbacks)
    local w, h = term.getSize()

    local main = basalt.getMainFrame()
    main.background = colors.black

    main:addLabel({
        x = 1, y = 1, width = w, height = 1,
        text = ">> DUMBY REMOTE CONTROL <<",
        background = THEME.accent,
        foreground = colors.black,
    })

    local statusLabel = main:addLabel({
        x = 2, y = 2, width = w - 2, height = 1,
        text = "OFFLINE",
        foreground = THEME.offline,
    })

    local tabNames = { "CONTROL", "STATS", "LOG" }
    local frames = {}

    for i, name in ipairs(tabNames) do
        main:addButton({
            x = (i - 1) * 12 + 1, y = 4, width = 11, height = 1,
            text = name,
        }):onClick(function()
            for n, f in pairs(frames) do f.visible = (n == name) end
        end)
    end

    local bodyY = 6
    for _, name in ipairs(tabNames) do
        frames[name] = main:addFrame({
            x = 1, y = bodyY,
            width = w, height = h - bodyY + 1,
            visible = false,
        })
    end

    -- Control tab: button grid + a typed-command input for goto/sound
    for i, cmd in ipairs(commandList) do
        local col = (i - 1) % BUTTON_COLS
        local row = math.floor((i - 1) / BUTTON_COLS)
        frames.CONTROL:addButton({
            x = col * (BUTTON_W + 1) + 1,
            y = row * (BUTTON_H + 1) + 1,
            width = BUTTON_W, height = BUTTON_H,
            text = cmd.name:upper(),
            background = THEME.buttonColors[cmd.name] or colors.gray,
        }):onClick(function() callbacks.onButtonClick(cmd) end)
    end

    local inputY = math.ceil(#commandList / BUTTON_COLS) * (BUTTON_H + 1) + 2
    frames.CONTROL:addLabel({ x = 1, y = inputY, width = 30, height = 1, text = "Typed command (goto/sound):" })
    local input = frames.CONTROL:addInput({
        x = 1, y = inputY + 1, width = w - 2,
        placeholder = "e.g. goto 10 0 -5",
    })
    input:onEnter(function()
        local text = input.text
        input.text = ""
        if text ~= "" then callbacks.onSubmit(text) end
    end)

    -- Stats tab: fuel gauge + numeric readouts
    frames.STATS:addLabel({ x = 2, y = 2, width = 10, height = 1, text = "FUEL" })
    frames.STATS:addLabel({ x = 2, y = 3, width = GAUGE_W, height = 1, background = colors.gray })
    local fuelFill = frames.STATS:addLabel({ x = 2, y = 3, width = 1, height = 1, background = THEME.online })
    local fuelText = frames.STATS:addLabel({ x = 2, y = 4, width = GAUGE_W, height = 1, text = "-" })

    frames.STATS:addLabel({ x = 2, y = 6, width = 10, height = 1, text = "ORE FOUND" })
    local oreText = frames.STATS:addLabel({ x = 2, y = 7, width = GAUGE_W, height = 1, text = "-" })

    frames.STATS:addLabel({ x = 2, y = 9, width = 10, height = 1, text = "POSITION" })
    local posText = frames.STATS:addLabel({ x = 2, y = 10, width = GAUGE_W, height = 1, text = "-" })

    -- Log tab: fixed-size ring buffer of lines, oldest at top
    local logLabels = {}
    for i = 1, LOG_LINES do
        logLabels[i] = frames.LOG:addLabel({ x = 1, y = i, width = w, height = 1, text = "" })
    end
    local logBuffer = {}

    local function RenderLog()
        for i = 1, LOG_LINES do
            local entry = logBuffer[i]
            logLabels[i].text = entry and entry.text or ""
            logLabels[i].foreground = entry and entry.color or colors.white
        end
    end

    local function AppendLog(text, color)
        table.insert(logBuffer, { text = text, color = color or colors.white })
        while #logBuffer > LOG_LINES do table.remove(logBuffer, 1) end
        RenderLog()
    end

    local function ClearLog()
        logBuffer = {}
        RenderLog()
    end

    local function SetStatus(online, simulation)
        statusLabel.text = (online and "ONLINE" or "OFFLINE") .. (simulation and "  [SIM]" or "")
        statusLabel.foreground = simulation and THEME.simulation or (online and THEME.online or THEME.offline)
    end

    local function SetStats(fuel, ore, x, y, z)
        fuelText.text = "fuel: " .. tostring(fuel)
        oreText.text = "ore: " .. tostring(ore)
        posText.text = string.format("pos: (%d, %d, %d)", x or 0, y or 0, z or 0)

        local ratio = math.max(0, math.min(1, (tonumber(fuel) or 0) / 500))
        fuelFill.width = math.max(1, math.floor(GAUGE_W * ratio))
    end

    for n, f in pairs(frames) do f.visible = (n == "CONTROL") end

    return {
        log = AppendLog,
        clearLog = ClearLog,
        setStatus = SetStatus,
        setStats = SetStats,
    }
end

return Dashboard
