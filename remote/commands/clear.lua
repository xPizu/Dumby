return {
    name = "clear",
    description = "Clear the screen.",
    execute = function(ctx)
        ctx.ui.Clear()
        ctx.ui.PrintHeader(ctx.commandList)
    end,
}
