-- Emergency stop: unlike 'stop', Dumby drops everything (no inventory
-- dump, no more exploring) and rushes straight home.
return {
    name = "rescue",
    description = "EMERGENCY: abandon everything and rush home now.",
    execute = function(ctx)
        ctx.send({ cmd = "rescue" })
        ctx.log.Warn("RESCUE signal sent, waiting for confirmation...")
    end,
}
