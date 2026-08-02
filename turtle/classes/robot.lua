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
    self.Communicator = COMMUNICATOR:New(CONFIG.RednetProtocol, CONFIG.RednetTurtleHostname, CONFIG.RednetRemoteHostname)
    self.ChunkyLink = COMMUNICATOR:New(CONFIG.RednetChunkyProtocol, CONFIG.RednetMiningHostname, CONFIG.RednetChunkyHostname)
    self.Navigator.OnMove = function(action) self.ChunkyLink:Broadcast(action) end
    self.GeoLink = COMMUNICATOR:New(CONFIG.RednetGeoProtocol, CONFIG.RednetMiningHostname, CONFIG.RednetGeoHostname)
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
    local reason = self.Explorer.StopReason or "mission complete"
    self:Log("Return to base (" .. reason .. ")")
    self.Communicator:Broadcast({ cmd = "returning_home", reason = reason })
    self.Navigator:GoHome()
    if not self.Explorer.Rescue then
        self.Inventory:Dump()
    end
    self.Fuel:AutoRefuel()
    self:Log("Returned to base. Found minerals: " .. self.Explorer.OreCount .. " | Fuel remaining: " .. tostring(self.Fuel:GetLevel()))
end

function ROBOT:Ack(of, detail)
    self.Communicator:Broadcast({ cmd = "ack", of = of, detail = detail })
end

function ROBOT:SendStatus()
    self.Communicator:Broadcast({
        cmd = "status_report",
        x = self.Navigator.x,
        y = self.Navigator.y,
        z = self.Navigator.z,
        fuel = self.Fuel:GetLevel(),
        ore = self.Explorer.OreCount,
        started = self.Started,
        stopReason = self.Explorer.StopReason,
    })
end

-- Listens for ore reported by a companion Geo turtle and converts its
-- coordinates (in the Geo turtle's own frame) into ours via the configured
-- boot offset, then hands them to the Explorer to path to.
function ROBOT:GeoLinkLoop()
    if not self.GeoLink:IsAvailable() then
        while true do sleep(3600) end
    end

    local offset = CONFIG.GeoBootOffset
    self.GeoLink:Listen({
        ore_found = function(msg)
            self.Explorer:QueueRemoteOre(msg.x + offset.x, msg.y + offset.y, msg.z + offset.z)
        end,
    })
end

function ROBOT:HeartbeatLoop()
    if not self.Communicator:IsAvailable() then
        while true do sleep(3600) end
    end

    while true do
        self.Communicator:Broadcast({ cmd = "alive" })
        sleep(CONFIG.HeartbeatInterval)
    end
end

function ROBOT:Run()
    if not self:CheckStartupFuel() then return end

    self:Log("Wireless modem: " .. (self.Communicator:IsAvailable() and "OK" or "ABSENT (no remote control)"))
    self:Log("Waiting for start signal...")

    parallel.waitForAny(
        function()
            while true do
                while not self.Started do
                    sleep(0.5)
                end
                self:Log("Launching exploration mission...")

                local ok, err = pcall(function()
                    if self.PendingGoto then
                        local g = self.PendingGoto
                        self:Log("Heading to goto target (" .. g.x .. ", " .. g.y .. ", " .. g.z .. ")...")
                        self.Navigator:GoTo(g.x, g.y, g.z)
                        self.PendingGoto = nil
                    end
                    self.Explorer:RunSpiral(self.Navigator, CONFIG.MaxRadius)
                end)

                if not ok then
                    self:Log("CRASH during exploration: " .. tostring(err))
                    self.Explorer.StopReason = "Crash: " .. tostring(err)
                end

                self:ReturnHome()
                self:Log("Completed exploration mission. Minerals found: " .. self.Explorer.OreCount .. " | Fuel remaining: " .. tostring(self.Fuel:GetLevel()))

                self.Started = false
                self.Explorer.StopRequested = false
                self.Explorer.Rescue = false
                self.Explorer.StopReason = nil
                self.Explorer.OreCount = 0
                self.Navigator.x, self.Navigator.y, self.Navigator.z = 0, 0, 0

                self:Log("Waiting for start signal...")
            end
        end,
        function()
            if self.Communicator:IsAvailable() then
                self.Communicator:Listen({
                    start = function()
                        self:Log("Launch signal received.")
                        if self.Started then
                            self:Ack("start", "already started")
                            return
                        end
                        self.Started = true
                        self:Ack("start")
                    end,
                    stop = function()
                        self:Log("Stop signal received.")
                        self.Explorer.StopRequested = true
                        self:Ack("stop")
                    end,
                    rescue = function()
                        self:Log("RESCUE signal received! Abandoning mission, rushing home.")
                        self.Explorer:TriggerRescue()
                        self:Ack("rescue")
                    end,
                    status = function()
                        self:SendStatus()
                    end,
                    goto_target = function(msg)
                        if self.Started then
                            self:Log("Ignoring goto: mission already started.")
                            self:Ack("goto_target", "ignored, already started")
                            return
                        end
                        self.PendingGoto = { x = msg.x, y = msg.y, z = msg.z }
                        self:Log("Goto target set to (" .. msg.x .. ", " .. msg.y .. ", " .. msg.z .. ").")
                        self:Ack("goto_target")
                    end,
                })
            else
                self:Log("No wireless modem detected. Remote control is unavailable. The robot will run continuously, starting in 5 seconds.")
                sleep(5)
                while true do
                    self.Started = true
                    sleep(1)
                end
            end
        end,
        function() self:HeartbeatLoop() end,
        function() self:GeoLinkLoop() end
    )
end

return ROBOT