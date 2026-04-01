local Math = {}

local Vector2 = {}
Vector2.__index = Vector2

function Math.vec2(x, y)
    local v = { x = x or 0, y = y or 0 }
    setmetatable(v, Vector2)
    return v
end

function Vector2.__add(v1, v2) return Math.vec2(v1.x + v2.x, v1.y + v2.y) end
function Vector2.__sub(v1, v2) return Math.vec2(v1.x - v2.x, v1.y - v2.y) end
function Vector2.__eq(v1, v2)  return v1.x == v2.x and v1.y == v2.y end
function Vector2.__mul(v, s)
    if type(s) == "number" then return Math.vec2(v.x * s, v.y * s) end
    return Math.vec2(v.x * s.x, v.y * s.y) 
end
function Vector2.__div(v, s) return Math.vec2(v.x / s, v.y / s) end
function Vector2.__unm(v) return Math.vec2(-v.x, -v.y) end
function Vector2.__tostring(v) return string.format("Vec2(%.2f, %.2f)", v.x, v.y) end

function Vector2:dist(other)
    if not other or not other.x then return 9999 end
    return Math.dist(self.x, self.y, other.x, other.y)
end

function Vector2:len()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector2:normalize()
    local l = self:len()
    if l == 0 then return Math.vec2(0, 0) end
    return Math.vec2(self.x / l, self.y / l)
end

function Vector2:lerp(other, t)
    return Math.vec2(Math.lerp(self.x, other.x, t), Math.lerp(self.y, other.y, t))
end

function Vector2:dot(other)
    return self.x * other.x + self.y * other.y
end

function Vector2:unpack() return self.x, self.y end

function Vector2:set(x, y)
    if x ~= nil then self.x = x end
    if y ~= nil then self.y = y end
    return self
end

function Vector2:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    return self
end

function Vector2:mul(s)
    self.x = self.x * s
    self.y = self.y * s
    return self
end

function Math.lerp(a, b, t)
    return a + (b - a) * t
end

function Math.applyDamping(velocity, amount, dt)
    local factor = (1 - amount) ^ (dt * 20)
    velocity.x = velocity.x * factor
    velocity.y = velocity.y * factor
end

function Math.isVec2(v)
    return type(v) == "table" and getmetatable(v) == Vector2
end

function Math.clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function Math.dist(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

function Math.normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length == 0 then
        return 0, 0, 0
    end
    return x / length, y / length, length
end

function Math.round(val)
    return math.floor(val + 0.5)
end

function Math.sign(val)
    if val > 0 then return 1 elseif val < 0 then return -1 else return 0 end
end

function Math.angleBetween(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function Math.fromAngle(angle, length)
    length = length or 1
    return Math.vec2(math.cos(angle) * length, math.sin(angle) * length)
end

return Math