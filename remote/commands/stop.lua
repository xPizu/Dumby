return {
    name = "stop",
    description = "Ask Dumby to wrap up and return home.",
    execute = function(ctx)
        ctx.send({ cmd = "stop" })
        ctx.log.Info("Return signal sent, waiting for confirmation...")
    end,
}
