return {
    name = "status",
    description = "Ask Dumby for its current position, fuel and ore count.",
    execute = function(ctx)
        ctx.send({ cmd = "status" })
        ctx.log.Info("Status requested, waiting for reply...")
    end,
}
