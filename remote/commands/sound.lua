local SOUNDS = {
    online = "PlayOnline",
    offline = "PlayOffline",
    returning = "PlayReturn",
    alert = "PlayAlert",
    lowfuel = "PlayLowFuel",
    rescue = "PlayRescue",
    inventoryfull = "PlayInventoryFull",
}

local NAMES = {}
for k in pairs(SOUNDS) do table.insert(NAMES, k) end
table.sort(NAMES)

return {
    name = "sound",
    description = "sound <" .. table.concat(NAMES, "|") .. "> -- test a sound.",
    execute = function(ctx, args)
        local name = args[1]
        local method = name and SOUNDS[name:lower()]
        if not method then
            ctx.log.Warn("Usage: sound <" .. table.concat(NAMES, "|") .. ">")
            return
        end

        ctx.log.Info("Playing '" .. name .. "'...")
        ctx.sound[method](ctx.sound)
    end,
}
