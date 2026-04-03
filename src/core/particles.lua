local mathUtils = require("core.math")
local physics = require("core.physics")
local logger = require("core.logger")
local loader = require("core.loader")

local particles = {}

function particles.createEmitter(config)
    return {
        active = config.active ~= false,
        spawnRate = config.spawnRate or 10,
        accumulator = 0,
        angle = config.angle or 0,
        spread = config.spread or 360,
        speedMin = config.speedMin or 5,
        speedMax = config.speedMax or 10,
        lifeMin = config.lifeMin or 1,
        lifeMax = config.lifeMax or 2,
        sprite = config.sprite,
        colors = config.colors,
        chars = config.chars,
        z = config.z or 1,
        bounce = config.bounce or false,
        gravityScale = config.gravityScale or 0,
        drag = config.drag or 0
    }
end

function particles.load(path)
    local config = loader.loadEmitter(path)
    if not config then return nil end
    return particles.createEmitter(config)
end

function particles.emitterSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            local emitter = components.emitter[id]
            local pos = components.pos[id]

            if emitter.active and pos then
                emitter.accumulator = emitter.accumulator + dt
                local waitTime = 1 / emitter.spawnRate

                while emitter.accumulator >= waitTime do
                    emitter.accumulator = emitter.accumulator - waitTime

                    local p = scene:createEntity()
                    local angle = math.rad(emitter.angle + (math.random() - 0.5) * emitter.spread)
                    local speed = emitter.speedMin + math.random() * (emitter.speedMax - emitter.speedMin)
                    local life = emitter.lifeMin + math.random() * (emitter.lifeMax - emitter.lifeMin)

                    scene:setComponent(p, "pos", mathUtils.vec2(pos.x, pos.y))
                    scene:setComponent(p, "velocity", mathUtils.vec2(math.cos(angle) * speed, math.sin(angle) * speed))
                    scene:setComponent(p, "lifetime", life)
                    scene:setComponent(p, "maxLifetime", life)
                    scene:setComponent(p, "isParticle", true)
                    scene:setComponent(p, "z", emitter.z)
                    if emitter.bounce then scene:setComponent(p, "particleBounce", true) end
                    if emitter.gravityScale ~= 0 then scene:setComponent(p, "particleGravity", emitter.gravityScale) end
                    if emitter.drag > 0 then scene:setComponent(p, "particleDrag", emitter.drag) end

                    if emitter.sprite then scene:setComponent(p, "sprite", emitter.sprite) end
                    if emitter.colors then scene:setComponent(p, "particleColors", emitter.colors) end
                    if emitter.chars then scene:setComponent(p, "particleChars", emitter.chars) end
                end
            end
        end
    end
end

function particles.motionSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            local pos = components.pos[id]
            local vel = components.velocity[id]
            local hasBounce = components.particleBounce and components.particleBounce[id]

            local drag = components.particleDrag and components.particleDrag[id]
            if drag then
                mathUtils.applyDamping(vel, drag, dt)
            end

            local gScale = components.particleGravity and components.particleGravity[id]
            if gScale then
                vel.y = vel.y + physics.GRAVITY_VECTOR.y * gScale * dt
            end

            if hasBounce then
                local oldX = pos.x
                pos.x = pos.x + vel.x * dt
                local hitX, _, slopeYX = scene:isAreaBlocked(pos.x, pos.y, 1, 1, id)
                if hitX and not slopeYX then
                    pos.x = oldX
                    vel.x = -vel.x * 0.5
                end

                local oldY = pos.y
                pos.y = pos.y + vel.y * dt
                local hitY, _, slopeY = scene:isAreaBlocked(pos.x, pos.y, 1, 1, id)
                if hitY then
                    if slopeY then pos.y = slopeY - 1 else pos.y = oldY end
                    vel.y = -vel.y * 0.5
                end
            else
                pos.x = pos.x + vel.x * dt
                pos.y = pos.y + vel.y * dt
            end
        end
    end
end

function particles.updateSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            local life = components.lifetime[id]
            local maxLife = components.maxLifetime[id]
            local colors = components.particleColors and components.particleColors[id]
            local chars = components.particleChars and components.particleChars[id]

            local progress = math.max(0, math.min(1, 1 - (life / (maxLife > 0 and maxLife or 1))))

            if colors then
                local idx = math.max(1, math.min(#colors, math.ceil(progress * #colors)))
                scene:setComponent(id, "colorOverride", colors[idx])
            end

            if chars then
                local idx = math.max(1, math.min(#chars, math.ceil(progress * #chars)))
                scene:setComponent(id, "charOverride", chars[idx])
            end
        end
    end
end

function particles.cleanupSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            components.lifetime[id] = components.lifetime[id] - dt
            if components.lifetime[id] <= 0 then
                scene:destroyEntity(id)
            end
        end
    end
end

function particles.registerAll(scene)
    scene:addSystem({"emitter", "pos"},                        particles.emitterSystem(scene))
    scene:addSystem({"pos", "velocity", "isParticle"},          particles.motionSystem(scene))
    scene:addSystem({"lifetime", "maxLifetime", "isParticle"}, particles.updateSystem(scene))
    scene:addSystem({"lifetime", "isParticle"},                 particles.cleanupSystem(scene))
end

return particles