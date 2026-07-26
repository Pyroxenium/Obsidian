--- examples/particles_demo.lua
--- Simple particles demo for the Obsidian engine
--- Controls: A/D = move emitter, SPACE = toggle emitter, Q = quit

local Engine = require("../Obsidian/src")
local Particles = Engine.particles
local buf = Engine.buffer

local demo = Engine.scene.new()
demo.name = "Particles Demo"

local function makeSprite(ch, fg, bg)
    local frame = { { { ch } }, { { fg or "7" } }, { { bg or "0" } } }
    return { width = 1, height = 1, [1] = frame }
end
demo.onLoad = function()
    local W, H = buf:getSize()
    if os.epoch then math.randomseed(os.epoch("utc") % 100000) end

    -- Register particle systems (motion/update/cleanup)
    Particles.registerAll(demo)

    local palettes = {
        { "c", "6", "e" }, -- warm (yellow/orange/white)
        { "4", "c", "e" }, -- red -> yellow -> white
        { "9", "b", "f" }, -- blue -> cyan -> white
        { "a", "e", "f" }, -- green-ish -> white
    }

    local spawnX = math.floor(W / 2)
    local spawnY = math.max(3, H - 3)
    local particleSprite = makeSprite(".", "7", "f")
    local autoSpawn = true
    local spawnTimer = 0
    local nextSpawn = 0.4 + math.random() * 1.6

    local function spawnBurst(cx, cy)
        local count = math.random(24, 80)
        local colors = palettes[math.random(#palettes)]
        local chars = {"*", "."}

        for i = 1, count do
            local p = demo:spawn()
            local angle = math.random() * math.pi * 2
            local speed = 4 + math.random() * 10
            local vx = math.cos(angle) * speed
            local vy = math.sin(angle) * speed
            local life = 0.6 + math.random() * 1.6

            demo:attach(p, "pos", { x = cx, y = cy })
            demo:attach(p, "sprite", particleSprite)
            demo:attach(p, "velocity", { x = vx, y = vy })
            demo:attach(p, "lifetime", life)
            demo:attach(p, "maxLifetime", life)
            demo:attach(p, "isParticle", true)
            demo:attach(p, "z", 0)
            demo:attach(p, "particleGravity", 0.8)
            demo:attach(p, "particleDrag", 0.02)
            demo:attach(p, "particleChars", chars)
            demo:attach(p, "particleColors", colors)
        end
    end

    -- Rocket launcher: rockets ascend then burst at fuse expiry
    local function spawnRocket(cx, cy)
        local r = demo:spawn()
        local vx = math.random(-6, 6)
        local vy = -(20 + math.random() * 20)
        local fuse = 0.7 + math.random() * 1.6

        demo:attach(r, "pos", { x = cx, y = cy })
        demo:attach(r, "sprite", particleSprite)
        demo:attach(r, "velocity", { x = vx, y = vy })
        demo:attach(r, "isParticle", true)
        demo:attach(r, "particleGravity", 0.6)
        demo:attach(r, "particleDrag", 0.01)
        demo:attach(r, "rocketTimer", fuse)
        demo:attach(r, "particleColors", { "f" })
    end

    -- initial rocket (launch from bottom)
    spawnRocket(spawnX, spawnY)

    -- Small campfire emitter at bottom-left of spawn position
    local fireX = math.max(3, spawnX - 12)
    local fireConf = {
        spawnRate = 28,
        angle = -90,
        spread = 40,
        speedMin = 0.6,
        speedMax = 2.0,
        lifeMin = 0.6,
        lifeMax = 1.4,
        sprite = makeSprite(".", "e", "0"),
        colors = { "6", "c", "e" },
        chars = { "." },
        z = 0,
        bounce = false,
        gravityScale = -0.6,
        drag = 0.5,
    }
    local fireEmitter = Particles.createEmitter(fireConf)
    local fireEnt = demo:spawn()
    demo:attach(fireEnt, "pos", { x = fireX, y = spawnY })
    demo:attach(fireEnt, "emitter", fireEmitter)

    -- HUD / instructions
    demo.ui:text("fireworks_hud", 1, H, { text = "A/D move | SPACE toggle auto | Q quit", z = 500 })

    -- Input
    local hookA = Engine.input.onKey("a", function()
        spawnX = math.max(1, spawnX - 2)
    end, { repeatable = true, repeatDelay = 0.03, repeatInterval = 0.02 })

    local hookD = Engine.input.onKey("d", function()
        spawnX = math.min(W, spawnX + 2)
    end, { repeatable = true, repeatDelay = 0.03, repeatInterval = 0.02 })

    local hookSpace = Engine.input.onKey("space", function()
        autoSpawn = not autoSpawn
    end)

    local hookQ = Engine.input.onKey("q", function() error("quit") end)

    demo.event:once("unload", function()
        if hookA then Engine.input.offKey(hookA) end
        if hookD then Engine.input.offKey(hookD) end
        if hookSpace then Engine.input.offKey(hookSpace) end
        if hookQ then Engine.input.offKey(hookQ) end
    end)

    demo.onUpdate = function(dt)
        spawnTimer = spawnTimer + dt

        -- Update rockets: decrement fuse, spawn burst on expiry
        local rockets = demo:select("rocketTimer")
        for _, rid in ipairs(rockets) do
            local t = demo:get(rid, "rocketTimer")
            if t then
                t = t - dt
                if t <= 0 then
                    local pos = demo:get(rid, "pos")
                    if pos then spawnBurst(math.floor(pos.x), math.floor(pos.y)) end
                    demo:despawn(rid)
                else
                    demo:attach(rid, "rocketTimer", t)
                end
            end
        end

        if autoSpawn and spawnTimer >= nextSpawn then
            spawnTimer = 0
            nextSpawn = 0.3 + math.random() * 1.8
            local cx = spawnX + math.random(-10, 10)
            if math.random() < 0.6 then
                -- rocket launches from bottom of screen
                spawnRocket(cx, spawnY)
            else
                local cy = math.max(3, math.random(3, math.floor(H / 2)))
                spawnBurst(cx, cy)
            end
        end
    end
end

Engine.setScene(demo)
Engine.start()
