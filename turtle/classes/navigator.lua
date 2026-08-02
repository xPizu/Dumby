local Navigator = {
    DIRS = {
        { dx = 0,  dz = 1  },
        { dx = 1,  dz = 0  },
        { dx = 0,  dz = -1 },
        { dx = -1, dz = 0  },
    }
}
Navigator.__index = Navigator

function Navigator:New()
    local self = setmetatable({}, Navigator)
    self.x, self.y, self.z = 0, 0, 0
    self.facing = 1
    self.OnMove = nil
    return self
end

-- Lets a follower turtle (e.g. the chunk-loading Chunky Turtle) replay the
-- exact same movement sequence over rednet, one primitive at a time.
function Navigator:notify(action)
    if self.OnMove then self.OnMove(action) end
end

function Navigator:TurnRight()
    turtle.turnRight()
    self.facing = (self.facing % 4) + 1
    self:notify("right")
end

function Navigator:TurnLeft()
    turtle.turnLeft()
    self.facing = ((self.facing - 2) % 4) + 1
    self:notify("left")
end

function Navigator:FaceDirection(target)
    while self.facing ~= target do
        self:TurnRight()
    end
end

function Navigator:Forward()
    while turtle.detect() do
        if not turtle.dig() then break end
        sleep(0.4)
    end

    local attempts = 0
    while not turtle.forward() do
        attempts = attempts + 1
        if attempts > 6 then return false end
        turtle.attack()
        turtle.dig()
        sleep(0.3)
    end

    local d = Navigator.DIRS[self.facing]
    self.x, self.z = self.x + d.dx, self.z + d.dz
    self:notify("forward")
    return true
end

function Navigator:Back()
    self:TurnRight()
    self:TurnRight()

    local ok = self:Forward()
    self:TurnRight() 
    self:TurnRight()

    return ok
end

function Navigator:Up()
    while turtle.detectUp() do
        if not turtle.digUp() then break end
        sleep(0.4)
    end

    local attempts = 0
    while not turtle.up() do
        attempts = attempts + 1
        if attempts > 6 then return false end
        turtle.attackUp()
        turtle.digUp()
        sleep(0.3)
    end
    
    self.y = self.y + 1
    self:notify("up")
    return true
end

function Navigator:Down()
    while turtle.detectDown() do
        if not turtle.digDown() then break end
        sleep(0.4)
    end

    local attempts = 0
    while not turtle.down() do
        attempts = attempts + 1
        if attempts > 6 then return false end
        turtle.attackDown()
        turtle.digDown()
        sleep(0.3)
    end

    self.y = self.y - 1
    self:notify("down")
    return true
end

function Navigator:DistanceHome()
    return math.abs(self.x) + math.abs(self.y) + math.abs(self.z)
end

-- Straight-line move to any target (y first, then x, then z), digging through
-- whatever's in the way. Used both for returning home and for "goto" jumps
-- to a new exploration center.
function Navigator:GoTo(targetX, targetY, targetZ)
    while self.y > targetY do self:Down() end
    while self.y < targetY do self:Up() end

    local dx = targetX - self.x
    if dx ~= 0 then
        self:FaceDirection(dx > 0 and 4 or 2)
        for _ = 1, math.abs(dx) do self:Forward() end
    end

    local dz = targetZ - self.z
    if dz ~= 0 then
        self:FaceDirection(dz > 0 and 3 or 1)
        for _ = 1, math.abs(dz) do self:Forward() end
    end
end

function Navigator:GoHome()
    self:GoTo(0, 0, 0)
    self:FaceDirection(1)
end

return Navigator