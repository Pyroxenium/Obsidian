local Physics = {}
local mathUtils = require("core.math")

Physics.GRAVITY_VECTOR = mathUtils.vec2(0, 50)

function Physics.resolveBounce(velocity, normal, bounciness)
    bounciness = bounciness or 1.0

    local dot = velocity:dot(normal)

    if dot < 0 then
        local response = normal * (-(1 + bounciness) * dot)
        velocity:add(response)
    end

    return velocity
end

function Physics.resolveCollision(body1, vel1, body2, vel2, normal)
    local m1 = body1.mass or 1.0
    local m2 = body2.mass or 1.0
    if m1 <= 0 and m2 <= 0 then return end

    local e = math.min(body1.bounciness or 0, body2.bounciness or 0)

    local relVel = vel1 - vel2
    local velAlongNormal = relVel:dot(normal)

    if velAlongNormal > 0 then return end

    local j = -(1 + e) * velAlongNormal
    local invM1 = m1 > 0 and (1 / m1) or 0
    local invM2 = m2 > 0 and (1 / m2) or 0
    j = j / (invM1 + invM2)

    local impulse = normal * j
    vel1:add(impulse * invM1)
    vel2:add(impulse * -invM2)
end

function Physics.applyImpulse(velocity, force, mass)
    local m = mass or 1.0
    if m <= 0 then return end

    if type(force) == "table" and force.x then
        velocity:add(force * (1 / m))
    else
        velocity.x = velocity.x + (force / m)
    end
end

function Physics.createBody(config)
    return {
        mass = config.mass or 1.0,
        bounciness = config.bounciness or 0.0,
        friction = config.friction or 0.15,
        gravityScale = config.gravityScale or 1.0,
        isKinematic = config.isKinematic or false,
        useGravity = config.useGravity or true
    }
end

return Physics