local CONFIG = require("config")
local NAVIGATOR = require("classes.navigator")
local FUEL_MANAGER = require("classes.managers.fuel")
local INVENTORY_MANAGER = require("classes.managers.inventory")
local COMMUNICATOR = require("classes.communicator")
local EXPLORER = require("classes.explorer")

local ROBOT = {}
ROBOT.__index = ROBOT

function ROBOT:New()
    local self = setmetatable({}, ROBOT)
    self.Navigator = NAVIGATOR:New()
    self.Fuel = FUEL_MANAGER:New()
    self.Inventory = INVENTORY_MANAGER:New()
    self.Communicator = COMMUNICATOR:New()
    self.Explorer = EXPLORER:New(self.Fuel, self.Inventory)
    self.Started = false
    return self
end

function ROBOT:Log(msg)
    print("[René] " .. msg)
end

function ROBOT:CheckStartupFuel()
    self.Fuel:AutoRefuel()
    if self.Fuel:GetLevel() < CONFIG.MinStartFuel then
        self:Log("Insufficent fuel to start (" .. tostring(self.Fuel:GetLevel())
            .. "). Add fuel to the inventory and restart.")
        return false
    end
    return true
end

function ROBOT:ReturnHome()
    self:Log("Return to base (" .. tostring(self.Explorer.stopReason or "mission complete") .. ")")
    self.Communicator:Broadcast("returning_home")
    self.Navigator:GoHome()
    self.Inventory:Dump()
    self.Fuel:AutoRefuel()
    self:Log("Returned to base. Found minerals: " .. self.Explorer.OreCount .. " | Fuel remaining: " .. tostring(self.Fuel:GetLevel()))
end

function ROBOT:HeartbeatLoop()
    if not self.Communicator:IsAvailable() then
        while true do sleep(3600) end
    end

    while true do
        self.Communicator:Broadcast("alive")
        sleep(CONFIG.HeartbeatInterval)
    end
end

function ROBOT:Run()
    if not self:CheckStartupFuel() then return end

    self:Log("Wireless modem: " .. (self.Communicator:IsAvailable() and "OK" or "ABSENT (no remote control)"))
    self:Log("Waiting for start signal...")

    parallel.waitForAny(
        function()
            while not self.Started do
                sleep(0.5)
            end
            self:Log("Launching exploration mission...")
            self.Explorer:RunSpiral(self.Navigator, CONFIG.MaxRadius)
            self:ReturnHome()
        end,
        function()
            if self.Communicator:IsAvailable() then
                self.Communicator:Listen({
                    start = function()
                        if not self.Started then
                            self.Started = true
                            self:Log("Launch signal received.")
                        end 
                    end,
                    stop = function()
                        self.Explorer.stopRequested = true 
                    end
                })
            else
                self:Log("No wireless modem detected. Remote control is unavailable. The robot will run the exploration mission in 5 seconds.")
                sleep(5)
                self.Started = true
                while true do sleep(3600) end
            end
        end,
        function() self:HeartbeatLoop() end
    )

    self:Log("Completed exploration mission. Minerals found: " .. self.Explorer.OreCount .. " | Fuel remaining: " .. tostring(self.Fuel:GetLevel()))
end

return ROBOT