local UI = require("lib.ui")

return {
    name = "clear",
    description = "Clear the screen.",
    execute = function(ctx)
        UI.Clear()
        UI.PrintHeader(ctx.commandList)
    end,
}
