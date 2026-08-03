local SimTurtle = {}

local function log(msg)
    print("[SIM] " .. msg)
end

local ALWAYS_TRUE = { "forward", "back", "up", "down", "turnLeft", "turnRight", "dig", "digUp", "digDown" }
local ALWAYS_FALSE = { "detect", "detectUp", "detectDown", "attack", "attackUp", "attackDown" }
local INSPECTS = { "inspect", "inspectUp", "inspectDown" }

function SimTurtle.Install()
    log("Simulation mode active -- no real movement, digging, or fuel use.")

    for _, name in ipairs(ALWAYS_TRUE) do
        turtle[name] = function() log(name .. "()"); return true end
    end

    for _, name in ipairs(ALWAYS_FALSE) do
        turtle[name] = function() log(name .. "()"); return false end
    end

    for _, name in ipairs(INSPECTS) do
        turtle[name] = function() return false, "No block to inspect" end
    end

    local fakeFuel = 500
    turtle.getFuelLevel = function() return fakeFuel end
    turtle.refuel = function(count)
        fakeFuel = fakeFuel + (count or 1) * 80
        log("refuel() -> fuel now " .. fakeFuel)
        return true
    end

    turtle.getItemDetail = function() return nil end
    turtle.select = function() return true end
    turtle.drop = function() return true end
    turtle.dropUp = function() return true end
    turtle.dropDown = function() return true end
end

return SimTurtle