return {
    name = "start",
    description = "Launch Dumby's exploration.",
    execute = function(ctx)
        ctx.send({ cmd = "start" })
        ctx.log.Info("Launch signal sent, waiting for confirmation...")
    end,
}
