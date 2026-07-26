-- Obsidian Engine showcase

local args = { ... }
local auto = false
local smoke = false
for _, value in ipairs(args) do
    if value == "--auto" then auto = true end
    if value == "--smoke" then
        auto = true
        smoke = true
    end
end

local Engine = require("../Obsidian/src")
local scene = Engine.scene.new()
local buffer = Engine.buffer
local tween = Engine.tween
local particles = Engine.particles

scene.name = "Obsidian Showcase"
Engine.setFPS(30)
Engine.showDebug(false)

local C = {
    white = "0",
    orange = "1",
    magenta = "2",
    lightBlue = "3",
    yellow = "4",
    lime = "5",
    pink = "6",
    gray = "7",
    lightGray = "8",
    cyan = "9",
    purple = "a",
    blue = "b",
    brown = "c",
    green = "d",
    red = "e",
    black = "f",
}

local A = {
    bright = Engine.rgb("#8fe9c4"),
    accent = Engine.rgb("#5fd7a4"),
    mid = Engine.rgb("#3cc48c"),
    deep = Engine.rgb("#17805a"),
    dark = Engine.rgb("#0f5540"),
}

local SPRITES = {}
for name, file in pairs({
    hero = "assets/hero.obs",
    creatures = "assets/creatures.obs",
    actors = "assets/actors.obs",
}) do
    local sprite, err = Engine.loader.loadSprite(file)
    if not sprite then
        error("showcase: cannot load " .. file .. ": " .. tostring(err), 0)
    end
    SPRITES[name] = sprite
end

local pages = {
    { name = "OBSIDIAN", duration = 4.5 },
    { name = "SPRITES", duration = 6.0 },
    { name = "PIXELS", duration = 6.0 },
    { name = "ECS", duration = 6.0 },
    { name = "PHYSICS", duration = 6.0 },
    { name = "PARTICLES", duration = 6.0 },
    { name = "PATHFINDING", duration = 6.0 },
    { name = "TWEENING", duration = 5.5 },
    { name = "CREATE", duration = 4.0 },
}

local finaleHold = 4.0

if smoke then
    for _, page in ipairs(pages) do page.duration = 0.45 end
    finaleHold = 0
end

local totalDuration = 0
for _, page in ipairs(pages) do
    totalDuration = totalDuration + page.duration
end

local W, H = 51, 19
local elapsed = 0
local paused = false
local actorIds = {}
local ballIds = {}
local emitterIds = {}
local lastPageIndex = 0
local stirTimer = 0

local BOWL = { left = 13, right = 38, top = 5, floor = 15 }
local BALL_COUNT = 14
local path = {}
local obstacles = {}
local tweenRows = {}
local pageIndex = 1
local pageTime = 0

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function text(x, y, value, fg, bg)
    if y < 1 or y > H or x > W then return end
    value = tostring(value)
    if x < 1 then
        value = value:sub(2 - x)
        x = 1
    end
    if x + #value - 1 > W then
        value = value:sub(1, W - x + 1)
    end
    if #value > 0 then
        buffer:drawText(x, y, value, fg or C.white, bg or C.black)
    end
end

local function center(y, value, fg, bg)
    text(math.floor((W - #value) / 2) + 1, y, value, fg, bg)
end

local function fill(x, y, width, height, bg, char, fg)
    width = math.min(width, W - x + 1)
    height = math.min(height, H - y + 1)
    if width > 0 and height > 0 then
        buffer:drawRect(x, y, width, height, char or " ", fg or bg, bg)
    end
end

local function panel(x, y, width, height, title, accent)
    fill(x, y, width, height, C.black)
    text(x, y, string.rep("-", width), C.gray)
    text(x + 1, y, " " .. title .. " ", accent or A.accent)
    text(x, y + height - 1, string.rep("-", width), C.gray)
end

local function tag(x, y, label, color)
    text(x, y, " " .. label .. " ", C.black, color)
end

local function progressDots(active)
    local x = math.floor((W - (#pages * 3 - 1)) / 2) + 1
    for i = 1, #pages do
        text(x + (i - 1) * 3, H, i == active and "##" or "--",
            i == active and A.accent or C.gray)
    end
end

local function header(section, detail)
    buffer:clearSubpixels()
    fill(1, 1, W, H, C.black)
    text(2, 1, "OBSIDIAN", C.white)
    text(11, 1, "ENGINE", A.accent)
    text(W - #section, 1, section, A.bright)
    text(2, 2, string.rep("-", math.max(1, W - 2)), C.gray)
    if detail then text(2, 3, detail, C.lightGray) end
end

local function makeSprite(rows, paint, background)
    local width = 0
    for _, row in ipairs(rows) do width = math.max(width, #row) end

    local chars, fg, bg = {}, {}, {}
    for y, row in ipairs(rows) do
        row = row .. string.rep(" ", width - #row)
        chars[y] = row
        fg[y], bg[y] = {}, {}
        for x = 1, width do
            local ch = row:sub(x, x)
            if ch == " " then
                fg[y][x], bg[y][x] = " ", " "
            else
                fg[y][x] = paint and paint(ch, x, y, width, #rows) or C.white
                bg[y][x] = background or C.black
            end
        end
    end

    return {
        width = width,
        height = #rows,
        frameCount = 1,
        [1] = { chars, fg, bg },
    }
end

local function makeDot(ch, fg, bg)
    return makeSprite({ ch }, function() return fg or C.white end, bg or C.black)
end

local function blitSprite(spr, x, y, frameIndex)
    local frame = spr[frameIndex or 1]
    if frame then
        buffer:drawSprite(frame, math.floor(x), math.floor(y), 0, 0)
    end
end

local function animFrame(spr, t, fps)
    return (math.floor(t * (fps or 6)) % spr.frameCount) + 1
end

-- ---------------------------------------------------------------------------
-- Sprites
-- ---------------------------------------------------------------------------

local function shardPaint(_, _, y, _, height)
    local ramp = { A.bright, A.accent, A.mid, A.deep, A.dark }
    local step = math.floor((y - 1) / math.max(1, height) * #ramp) + 1
    return ramp[math.min(#ramp, step)]
end

local SHARD = makeSprite({
    "   /\\   ",
    "  /  \\  ",
    " /    \\ ",
    "<      >",
    " \\    / ",
    "  \\  /  ",
    "   \\/   ",
}, shardPaint)

local SHARD_SMALL = makeSprite({
    " /\\ ",
    "<  >",
    " \\/ ",
}, shardPaint)

local WALKER = makeSprite({ "<>" }, function() return C.black end, A.accent)
local GOAL = makeSprite({ "[]" }, function() return C.black end, A.bright)
local NOZZLE = makeSprite({ "\\^/" }, function(ch)
    return ch == "^" and A.bright or A.deep
end)
local TWEEN_TOKEN = makeSprite({ "[]" }, function() return A.bright end)

local GREEN_RAMP = {}
local RAMP_STEPS = 16
do
    local from = { 0x0f, 0x55, 0x40 }
    local to = { 0x8f, 0xe9, 0xc4 }
    for i = 1, RAMP_STEPS do
        local k = (i - 1) / (RAMP_STEPS - 1)
        GREEN_RAMP[i] = Engine.rgb(("#%02x%02x%02x"):format(
            math.floor(from[1] + (to[1] - from[1]) * k + 0.5),
            math.floor(from[2] + (to[2] - from[2]) * k + 0.5),
            math.floor(from[3] + (to[3] - from[3]) * k + 0.5)))
    end
end

local function currentPage(time)
    local cursor = 0
    for index, page in ipairs(pages) do
        if time < cursor + page.duration then
            return index, time - cursor
        end
        cursor = cursor + page.duration
    end
    return #pages, time - (cursor - pages[#pages].duration)
end

local function spawnActors()
    for i = 1, 12 do
        local id = scene:spawn()
        local x = 4 + ((i * 11) % math.max(10, W - 8))
        local y = 6 + ((i * 7) % math.max(4, H - 10))
        scene:attach(id, "pos", Engine.math.vec2(x, y))
        scene:attach(id, "velocity", Engine.math.vec2(
            ((i % 5) - 2) * 1.35,
            ((i % 3) - 1) * 0.75
        ))
        scene:attach(id, "showcaseActor", {
            frame = ((i - 1) % SPRITES.actors.frameCount) + 1,
        })
        actorIds[#actorIds + 1] = id
    end
end

local function buildBowl()
    local height = BOWL.floor - BOWL.top + 1
    local width = BOWL.right - BOWL.left + 1
    scene:addStatic(nil, BOWL.left, BOWL.top,
        { collider = { x = 0, y = 0, w = 1, h = height } })
    scene:addStatic(nil, BOWL.right, BOWL.top,
        { collider = { x = 0, y = 0, w = 1, h = height } })
    scene:addStatic(nil, BOWL.left, BOWL.floor,
        { collider = { x = 0, y = 0, w = width, h = 1 } })
end

local function resetBalls()
    for index, id in ipairs(ballIds) do
        local pos = scene:get(id, "pos")
        local vel = scene:get(id, "vel")
        if pos and vel then
            local span = BOWL.right - BOWL.left - 2
            pos:set(BOWL.left + 2 + ((index * 5) % span),
                BOWL.top + 1 + (index % 3))
            vel:set(((index % 5) - 2) * 3, 0)
        end
    end
end

local function spawnBalls()
    for index = 1, BALL_COUNT do
        local id = scene:spawn()
        scene:attach(id, "pos", Engine.math.vec2(0, 0))
        scene:attach(id, "vel", Engine.math.vec2(0, 0))
        scene:attach(id, "body", Engine.physics.createBody({
            bounciness = 0.55,
            friction = 0.02,
        }))
        scene:attach(id, "collider", { x = 0, y = 0, w = 1, h = 1 })
        scene:attach(id, "ballTint", GREEN_RAMP[
            math.floor((index - 1) / BALL_COUNT * RAMP_STEPS) + 1])
        ballIds[#ballIds + 1] = id
    end
    resetBalls()
end

local function spawnEmitters()
    local sprite = makeDot(".", C.white, C.black)
    local configs = {
        {
            x = math.floor(W * 0.25), y = H - 3,
            spawnRate = 42, angle = -90, spread = 42,
            speedMin = 2, speedMax = 7, lifeMin = 0.8, lifeMax = 1.6,
            colors = { A.dark, A.deep, A.mid, A.accent },
            chars = { ".", "*", "+" }, gravityScale = -0.15, drag = 0.3,
        },
        {
            x = math.floor(W * 0.5), y = math.floor(H * 0.55),
            spawnRate = 34, angle = 0, spread = 360,
            speedMin = 3, speedMax = 10, lifeMin = 0.6, lifeMax = 1.5,
            colors = { A.deep, A.accent, A.bright, C.white },
            chars = { "*", "+", "." }, gravityScale = 0.08, drag = 0.12,
        },
        {
            x = math.floor(W * 0.76), y = H - 3,
            spawnRate = 38, angle = -90, spread = 24,
            speedMin = 3, speedMax = 8, lifeMin = 0.7, lifeMax = 1.4,
            colors = { A.mid, A.accent, A.bright, C.white },
            chars = { ".", ":", "*" }, gravityScale = 0.3, drag = 0.08,
        },
    }

    for _, config in ipairs(configs) do
        config.sprite = sprite
        config.active = false
        local id = scene:spawn()
        scene:attach(id, "pos", Engine.math.vec2(config.x, config.y))
        scene:attach(id, "emitter", particles.createEmitter(config))
        emitterIds[#emitterIds + 1] = id
    end
end

local function buildPath()
    local gridW = math.min(21, math.floor((W - 5) / 2))
    local gridH = math.min(10, H - 8)

    local function block(x, y)
        obstacles[x .. ":" .. y] = true
    end

    for x = 0, gridW + 1 do
        block(x, 0)
        block(x, gridH + 1)
    end
    for y = 0, gridH + 1 do
        block(0, y)
        block(gridW + 1, y)
    end
    for y = 1, gridH - 2 do
        if y ~= 3 then block(6, y) end
    end
    for y = 3, gridH do
        if y ~= gridH - 1 then block(13, y) end
    end
    for x = 7, 12 do
        if x ~= 10 then block(x, 6) end
    end

    local gridScene = {}
    function gridScene:isAreaBlocked(x, y)
        return obstacles[math.floor(x) .. ":" .. math.floor(y)] == true
    end

    path = Engine.pathfinding.findPath(
        gridScene,
        Engine.math.vec2(2, 2),
        Engine.math.vec2(gridW - 1, gridH - 1),
        { w = 1, h = 1 },
        nil,
        nil,
        false,
        4000
    ) or {}
end

local function buildTweens()
    local definitions = {
        { "linear", tween.easing.linear, A.bright },
        { "cubicOut", tween.easing.cubicOut, A.accent },
        { "elasticOut", tween.easing.elasticOut, A.mid },
        { "bounceOut", tween.easing.bounceOut, A.deep },
    }
    for index, definition in ipairs(definitions) do
        local target = { x = 0 }
        tweenRows[index] = {
            name = definition[1],
            target = target,
            color = definition[3],
        }
        tween.to(target, 1.8, { x = 1 }, {
            easing = definition[2],
            pingpong = true,
            delay = (index - 1) * 0.12,
        })
    end
end

local function drawIntro(t)
    header("SHOWCASE", "A fast 2D game engine for CC:Tweaked")

    local startY = math.max(5, math.floor((H - SHARD.height) / 2))
    local shardX = math.floor((W - SHARD.width) / 2) + 1
    blitSprite(SHARD, shardX, startY)

    -- A halo that breathes around the shard, drawn from the same ramp.
    local pulse = 0.5 + math.sin(t * 3) * 0.5
    local halo = pulse > 0.55 and A.accent or A.deep
    local haloY = startY + SHARD.height
    center(haloY, string.rep("=", SHARD.width + 2), halo)

    local titleY = math.min(H - 4, haloY + 2)
    center(titleY, "OBSIDIAN ENGINE", C.white)
    center(titleY + 1, "BUILD WORLDS. MOVE FAST.", A.accent)
    progressDots(1)
end

local function drawSprites(t)
    header("01 / SPRITES", "Multi-frame .obs assets with per-cell RGB colour")

    local hero = SPRITES.hero
    local creatures = SPRITES.creatures
    local actors = SPRITES.actors

    local laneY = 5
    local travel = math.max(1, W - hero.width - 4)
    local phase = (t * 0.30) % 2
    local walk = phase < 1 and phase or (2 - phase)
    blitSprite(hero, 3 + math.floor(walk * travel), laneY,
        animFrame(hero, t, 6))

    local heroLabel = ("%dx%d, %d frames")
        :format(hero.width, hero.height, hero.frameCount)
    text(2, laneY - 1, heroLabel, A.bright)

    local ruleY = laneY + hero.height
    text(2, ruleY, string.rep("-", W - 2), C.gray)

    local entries = {
        { sprite = actors, frame = 1 },
        { sprite = creatures, frame = animFrame(creatures, t, 2) },
    }

    local rowY = ruleY + 2
    local tallest = 0
    for _, entry in ipairs(entries) do
        tallest = math.max(tallest, entry.sprite.height)
    end

    local spacing = math.max(10, math.floor((W - 6) / #entries))
    local x = 3
    for _, entry in ipairs(entries) do
        local spr = entry.sprite
        blitSprite(spr, x, rowY, entry.frame)
        text(x, rowY + tallest, ("%dx%d"):format(spr.width, spr.height),
            A.bright)
        text(x + 5, rowY + tallest,
            spr.frameCount .. (spr.frameCount == 1 and " frame" or " frames"),
            C.lightGray)
        x = x + spacing
    end

    tag(2, H - 2, "loadSprite", A.deep)
    tag(15, H - 2, "PER-CELL RGB", A.mid)
    tag(math.max(30, W - 14), H - 2, "CACHED", A.accent)
    progressDots(2)
end

local function drawSubpixels(t)
    header("02 / PIXELS", "2x3 subpixels per cell, compiled into mosaic glyphs")

    local vw = W * 2
    local waveTop, waveBottom = 5, 12
    local rampTop, rampBottom = 14, 15

    if pageTime >= 0.25 then
        local top = (waveTop - 1) * 3 + 1
        local rows = (waveBottom - waveTop + 1) * 3
        local mid = top + rows / 2
        local amplitude = rows / 2 - 2

        for vx = 1, vw do
            local phase = (vx / vw) * math.pi * 4
            for wave = 0, 1 do
                local offset = wave * math.pi * 0.5
                local vy = mid + math.sin(phase + offset - t * 3) * amplitude
                local shade = GREEN_RAMP[math.max(1, math.min(RAMP_STEPS,
                    math.floor((vx / vw) * RAMP_STEPS) + 1))]
                buffer:drawSubpixel(vx, math.floor(vy), shade)
            end
        end

        local rampY = (rampTop - 1) * 3 + 1
        local rampH = (rampBottom - rampTop + 1) * 3
        for i = 1, RAMP_STEPS do
            local x1 = math.floor((i - 1) / RAMP_STEPS * vw) + 1
            local x2 = math.floor(i / RAMP_STEPS * vw)
            if x2 >= x1 then
                buffer:drawSubpixelRect(x1, rampY, x2 - x1 + 1, rampH,
                    GREEN_RAMP[i])
            end
        end
    end

    text(2, waveBottom + 1, ("%d x %d subpixels"):format(vw, H * 3), A.bright)

    tag(math.max(30, W - 15), H - 2, "MOSAIC GLYPHS", A.accent)
    progressDots(3)
end

local function drawECS(t)
    header("03 / ECS", "Composition over inheritance - thousands of possibilities")

    local viewX, viewY = 2, 5
    local sideW = W >= 62 and 19 or 15
    local viewW = W - sideW - 4
    local viewH = H - 7
    panel(viewX, viewY, viewW, viewH, "LIVE WORLD", A.accent)

    for gx = viewX + 2, viewX + viewW - 2, 6 do
        for gy = viewY + 2, viewY + viewH - 2, 3 do
            text(gx, gy, ".", C.gray)
        end
    end

    local spr = SPRITES.actors
    for _, id in ipairs(actorIds) do
        local pos = scene:get(id, "pos")
        local actor = scene:get(id, "showcaseActor")
        if pos and actor then
            local span = math.max(1, viewW - 2 - spr.width)
            local rows = math.max(1, viewH - 2 - spr.height + 1)
            local x = viewX + 1 + ((math.floor(pos.x) - 1) % span)
            local y = viewY + 1 + ((math.floor(pos.y) - 1) % rows)
            blitSprite(spr, x, y, actor.frame)
        end
    end

    local sideX = viewX + viewW + 2
    text(sideX, viewY, "WORLD", A.accent)
    text(sideX, viewY + 2, "entities", C.lightGray)
    text(sideX, viewY + 3, tostring(#actorIds), C.white)
    text(sideX, viewY + 5, "systems", C.lightGray)
    text(sideX, viewY + 6, "4 active", A.bright)
    if H >= 18 then
        text(sideX, viewY + 8, "pos", A.mid)
        text(sideX + 4, viewY + 8, "velocity", A.deep)
        text(sideX, viewY + 9, "sprite", A.bright)
    end
    progressDots(4)
end

local function drawPhysics(t)
    header("04 / PHYSICS", "Gravity, restitution and AABB collision response")

    local width = BOWL.right - BOWL.left + 1
    for y = BOWL.top, BOWL.floor - 1 do
        text(BOWL.left, y, "|", A.deep)
        text(BOWL.right, y, "|", A.deep)
    end
    text(BOWL.left, BOWL.floor, string.rep("=", width), A.mid)

    local resting = 0
    for _, id in ipairs(ballIds) do
        local pos = scene:get(id, "pos")
        local vel = scene:get(id, "vel")
        local tint = scene:get(id, "ballTint")
        if pos then
            text(math.floor(pos.x), math.floor(pos.y), "O", tint or A.accent)
            if vel and math.abs(vel.y) < 1.5 then resting = resting + 1 end
        end
    end

    local sideX = BOWL.right + 2
    if sideX <= W - 8 then
        text(sideX, BOWL.top, "BODIES", A.accent)
        text(sideX, BOWL.top + 2, tostring(#ballIds), C.white)
        text(sideX, BOWL.top + 4, "bounce", C.lightGray)
        text(sideX, BOWL.top + 5, "0.55", A.bright)
        text(sideX, BOWL.top + 7, "resting", C.lightGray)
        text(sideX, BOWL.top + 8, tostring(resting), A.mid)
    end

    text(2, BOWL.top, "AABB", A.accent)
    text(2, BOWL.top + 2, "walls are", C.lightGray)
    text(2, BOWL.top + 3, "static", A.bright)
    text(2, BOWL.top + 4, "colliders", A.bright)

    tag(2, H - 2, "applyImpulse", A.deep)
    tag(math.max(24, W - 20), H - 2, "SPATIAL GRID", A.accent)
    progressDots(5)
end

local function drawParticles(t)
    header("05 / VFX", "ECS-powered particles - emit, update, render, recycle")

    for y = 5, H - 3 do
        local shade = ((y + math.floor(t * 2)) % 4 == 0) and C.gray or C.black
        text(1, y, string.rep(".", W), shade)
    end

    local live = scene:select("isParticle")
    for _, id in ipairs(live) do
        local pos = scene:get(id, "pos")
        local color = scene:get(id, "colorOverride") or C.white
        local char = scene:get(id, "charOverride") or "."
        if pos then text(math.floor(pos.x), math.floor(pos.y), char, color) end
    end

    for _, id in ipairs(emitterIds) do
        local pos = scene:get(id, "pos")
        if pos then
            blitSprite(NOZZLE, math.floor(pos.x) - 1, math.floor(pos.y))
        end
    end

    tag(2, H - 2, "3 EMITTERS", A.deep)
    tag(16, H - 2, tostring(#live) .. " LIVE", A.mid)
    tag(math.max(28, W - 17), H - 2, "REAL-TIME VFX", A.accent)
    progressDots(6)
end

local function drawPathfinding(t)
    header("06 / AI", "A* pathfinding with collision-aware navigation")

    local gridW = math.min(21, math.floor((W - 5) / 2))
    local gridH = math.min(10, H - 8)
    local ox, oy = 2, 5
    local pathLookup = {}
    for _, node in ipairs(path) do
        pathLookup[node.x .. ":" .. node.y] = true
    end

    for y = 1, gridH do
        for x = 1, gridW do
            local key = x .. ":" .. y
            local value, color = "  ", C.black
            if obstacles[key] then
                value, color = "##", C.gray
            elseif pathLookup[key] then
                value, color = "..", A.deep
            elseif (x + y) % 2 == 0 then
                value, color = " .", C.gray
            end
            text(ox + (x - 1) * 2, oy + y - 1, value, color)
        end
    end

    if #path > 0 then
        local goal = path[#path]
        blitSprite(GOAL, ox + (goal.x - 1) * 2, oy + goal.y - 1)

        local speed = 4
        local index = (math.floor(t * speed) % #path) + 1
        local node = path[index]
        blitSprite(WALKER, ox + (node.x - 1) * 2, oy + node.y - 1)
    end

    local sideX = ox + gridW * 2 + 2
    if sideX <= W - 8 then
        text(sideX, oy, "NAVIGATION", A.accent)
        text(sideX, oy + 2, "A* search", C.white)
        text(sideX, oy + 3, "8-way grid", C.lightGray)
        text(sideX, oy + 5, "waypoints", C.lightGray)
        text(sideX, oy + 6, tostring(#path), A.bright)
        text(sideX, oy + 8, "collision", C.lightGray)
        text(sideX, oy + 9, "aware", A.mid)
    end
    progressDots(7)
end

local function drawTweens(t)
    header("07 / MOTION", "Tweening, easing and frame diagnostics")

    local labelW = 12
    local trackX = labelW + 3
    local trackW = math.max(12, W - trackX - 2)
    for index, row in ipairs(tweenRows) do
        local y = 5 + (index - 1) * 2
        text(2, y, row.name, C.lightGray)
        text(trackX, y, string.rep("-", trackW), C.gray)
        local span = math.max(1, trackW - TWEEN_TOKEN.width)
        local x = trackX + math.floor(clamp(row.target.x, 0, 1) * span)
        blitSprite(TWEEN_TOKEN, x, y)
    end

    local statsY = math.min(H - 4, 14)
    text(2, statsY, "FRAME PIPELINE", A.accent)
    local labels = { "update", "systems", "render", "present" }
    local colors = { A.bright, A.accent, A.mid, A.deep }
    local bx = 2
    for index, label in ipairs(labels) do
        local width = math.max(7, math.floor((W - 7) / #labels))
        fill(bx, statsY + 2, width, 2, C.black)
        text(bx, statsY + 2, label, colors[index])
        text(bx, statsY + 3, tostring(index + 1) .. " ms", C.white)
        bx = bx + width + 1
    end
    progressDots(8)
end

local function drawFinale(t)
    header("READY", "One engine. A complete toolbox for your next CC:Tweaked game.")

    local y = math.max(5, math.floor(H * 0.24))
    blitSprite(SHARD_SMALL,
        math.floor((W - SHARD_SMALL.width) / 2) + 1, y)

    y = y + SHARD_SMALL.height
    center(y, "OBSIDIAN", C.white)
    center(y + 1, "2D GAME ENGINE", A.accent)

    local tags = {
        { "ECS", A.bright },
        { "PHYSICS", A.accent },
        { "PARTICLES", A.mid },
        { "AI", A.deep },
    }
    local total = 0
    for _, item in ipairs(tags) do total = total + #item[1] + 3 end
    local x = math.floor((W - total) / 2) + 1
    for _, item in ipairs(tags) do
        tag(x, y + 4, item[1], item[2])
        x = x + #item[1] + 3
    end

    center(math.min(H - 3, y + 6), "github.com/Pyroxenium/Obsidian", C.lightGray)
    center(math.min(H - 2, y + 7), "START BUILDING", A.bright)
    progressDots(9)
end

scene.onLoad = function()
    W, H = buffer:getSize()
    math.randomseed(2501)
    particles.registerAll(scene)
    spawnActors()
    buildBowl()
    spawnBalls()
    spawnEmitters()

    Engine.physics.setGravity(0, 26)
    scene:addSystem({ "pos", "vel", "body", "collider" },
        Engine.physics.system(scene, 2))
    buildPath()
    buildTweens()
end

scene:addSystem({ "pos", "velocity", "showcaseActor" }, function(dt, ids, components)
    for _, id in ipairs(ids) do
        local pos = components.pos[id]
        local velocity = components.velocity[id]
        pos.x = pos.x + velocity.x * dt
        pos.y = pos.y + velocity.y * dt
        if pos.x < 2 or pos.x > W - 2 then velocity.x = -velocity.x end
        if pos.y < 4 or pos.y > H - 3 then velocity.y = -velocity.y end
    end
end)

scene.onUpdate = function(dt)
    if paused then return end
    elapsed = elapsed + dt
    pageIndex, pageTime = currentPage(elapsed)

    local particlesActive = pageIndex == 6
    for _, id in ipairs(emitterIds) do
        local emitter = scene:get(id, "emitter")
        if emitter then emitter.active = particlesActive end
    end

    if pageIndex == 5 then
        if lastPageIndex ~= 5 then
            resetBalls()
            stirTimer = 0
        end
        stirTimer = stirTimer + dt
        if stirTimer >= 2.2 then
            stirTimer = 0
            for index, id in ipairs(ballIds) do
                local vel = scene:get(id, "vel")
                if vel then
                    Engine.physics.applyImpulse(vel,
                        Engine.math.vec2(((index % 5) - 2) * 4, -20))
                end
            end
        end
    end
    lastPageIndex = pageIndex

    if auto and elapsed >= totalDuration + finaleHold then
        Engine.stop()
    end
end

scene.onDraw = function()
    pageIndex, pageTime = currentPage(elapsed)
    if pageIndex == 1 then
        drawIntro(pageTime)
    elseif pageIndex == 2 then
        drawSprites(pageTime)
    elseif pageIndex == 3 then
        drawSubpixels(pageTime)
    elseif pageIndex == 4 then
        drawECS(pageTime)
    elseif pageIndex == 5 then
        drawPhysics(pageTime)
    elseif pageIndex == 6 then
        drawParticles(pageTime)
    elseif pageIndex == 7 then
        drawPathfinding(pageTime)
    elseif pageIndex == 8 then
        drawTweens(pageTime)
    else
        drawFinale(pageTime)
    end

    if pageTime < 0.25 and pageIndex > 1 then
        local cover = math.floor(W * (1 - pageTime / 0.25))
        if cover > 0 then fill(W - cover + 1, 1, cover, H, C.black) end
    end
end

scene.onEvent = function(event)
    if event[1] ~= "key" then return end
    if event[2] == keys.q then
        Engine.stop()
    elseif event[2] == keys.space then
        paused = not paused
    elseif event[2] == keys.r then
        elapsed = 0
        paused = false
    end
end

Engine.setScene(scene)
Engine.start()
