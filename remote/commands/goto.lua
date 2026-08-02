-- Sends a target the turtle will walk to (digging as needed) BEFORE it
-- starts its spiral, so exploration is centered somewhere other than the
-- boot position. Only takes effect if sent before 'start'.
return {
    name = "goto",
    description = "goto <x> <y> <z> -- head there before exploring (must be sent before start).",
    execute = function(ctx, args)
        local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if not x or not y or not z then
            ctx.log.Warn("Usage: goto <x> <y> <z>")
            return
        end

        ctx.send({ cmd = "goto_target", x = x, y = y, z = z })
        ctx.log.Info("Goto target sent: (" .. x .. ", " .. y .. ", " .. z .. "), waiting for confirmation...")
    end,
}
