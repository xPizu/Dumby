-- Dumby (Configuration File)
return {
    MinStartFuel = 10,
    FuelSafetyMargin = 15,
    ComfortableFuel = 200,
    CoalReserveKeep = 8,
    InventoryFullThreshold = 1,
    MaxCaveDepth = 16,
    GeoScanRadius = 8,
    MaxRadius = 40,
    LayerSpacing = 4,
    LayerCount = 3,
    RednetProtocol = "dumby",
    RednetTurtleHostname = "dumby-turtle",
    RednetRemoteHostname = "dumby-remote",
    HeartbeatInterval = 10,

    RednetChunkyProtocol = "dumby-chunky",
    RednetMiningHostname = "dumby-mining",
    RednetChunkyHostname = "dumby-chunky",
    ChunkyFollowBuffer = 3,
    RednetGeoProtocol = "dumby-geo",
    RednetGeoHostname = "dumby-geo",
    GeoScanInterval = 2,
    GeoBootOffset = { x = 0, y = 0, z = -2 },

    FuelItems = {
        ["minecraft:coal"] = true,
        ["minecraft:charcoal"] = true,
        ["minecraft:coal_block"] = true,
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