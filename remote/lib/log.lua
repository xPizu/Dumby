-- Severity-tagged console output. Falls back to plain tags on non-color
-- terminals (basic Computer, no Advanced Computer / Monitor).
local Log = {}

local TAGS = {
    ok = "[OK]",
    warn = "[WARN]",
    crit = "[CRIT]",
    info = "[i]",
}

local COLORS = {
    ok = colors.green,
    warn = colors.yellow,
    crit = colors.red,
    info = colors.white,
}

local function write(level, msg)
    local isColor = term.isColor and term.isColor()
    if isColor then term.setTextColor(COLORS[level]) end
    print(TAGS[level] .. " " .. msg)
    if isColor then term.setTextColor(colors.white) end
end

function Log.Info(msg) write("info", msg) end
function Log.Ok(msg) write("ok", msg) end
function Log.Warn(msg) write("warn", msg) end
function Log.Crit(msg) write("crit", msg) end

return Log
