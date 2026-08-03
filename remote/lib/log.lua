local THEME = require("lib.theme")

local Log = {}

function Log.New(ui)
    local self = {}

    local function emit(level, msg)
        ui.log("[" .. level:upper() .. "] " .. msg, THEME.logColors[level])
    end

    function self.Info(msg) emit("info", msg) end
    function self.Ok(msg) emit("ok", msg) end
    function self.Warn(msg) emit("warn", msg) end
    function self.Crit(msg) emit("crit", msg) end

    return self
end

return Log