-- Dumby (Configuration File)
return {
    MinStartFuel = 10,
    FuelSafetyMargin = 15,
    ComfortableFuel = 200,
    CoalReserveKeep = 8,
    InventoryFullThreshold = 1,
    MaxVeinDepth = 16,
    MaxRadius = 40,
    RednetProtocol = "dumby",
    HeartbeatInterval = 10,

    FuelItems = {
        ["minecraft:coal"] = true,
        ["minecraft:charcoal"] = true,
    },

    OreWhitelist = {
        ["minecraft:coal_ore"] = true, ["minecraft:deepslate_coal_ore"] = true,
        ["minecraft:iron_ore"] = true, ["minecraft:deepslate_iron_ore"] = true,
        ["minecraft:copper_ore"] = true, ["minecraft:deepslate_copper_ore"] = true,
        ["minecraft:gold_ore"] = true, ["minecraft:deepslate_gold_ore"] = true,
        ["minecraft:nether_gold_ore"] = true,
        ["minecraft:redstone_ore"] = true, ["minecraft:deepslate_redstone_ore"] = true,
        ["minecraft:lapis_ore"] = true, ["minecraft:deepslate_lapis_ore"] = true,
        ["minecraft:diamond_ore"] = true, ["minecraft:deepslate_diamond_ore"] = true,
        ["minecraft:emerald_ore"] = true, ["minecraft:deepslate_emerald_ore"] = true,
        ["minecraft:nether_quartz_ore"] = true,
        ["minecraft:ancient_debris"] = true,
    },

    JunkBlacklist = {
        ["minecraft:cobblestone"] = true, ["minecraft:cobbled_deepslate"] = true,
        ["minecraft:stone"] = true, ["minecraft:deepslate"] = true,
        ["minecraft:dirt"] = true, ["minecraft:gravel"] = true, ["minecraft:sand"] = true,
        ["minecraft:andesite"] = true, ["minecraft:diorite"] = true, ["minecraft:granite"] = true,
        ["minecraft:tuff"] = true, ["minecraft:netherrack"] = true,
    },
}