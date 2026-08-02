return {
    name = "help",
    description = "List available commands.",
    execute = function(ctx)
        for _, cmd in ipairs(ctx.commandList) do
            ctx.log.Info(cmd.name .. " -- " .. cmd.description)
        end
    end,
}
