-- Obsidian Engine showcase
-- Run from the repository with: examples/showcase
-- Add --auto to stop after one complete loop (useful for recording).

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

local pages = {
    { name = "OBSIDIAN", duration = 4.5 },
    { name = "ECS", duration = 6.0 },
    { name = "PARTICLES", duration = 6.0 },
    { name = "PATHFINDING", duration = 6.0 },
    { name = "TWEENING", duration = 5.5 },
    { name = "CREATE", duration = 4.0 },
}

if smoke then
    for _, page in ipairs(pages) do page.duration = 0.45 end
end

local totalDuration = 0
for _, page in ipairs(pages) do
    totalDuration = totalDuration + page.duration
end

local W, H = 51, 19
local elapsed = 0
local paused = false
local actorIds = {}
local emitterIds = {}
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
    text(x + 1, y, " " .. title .. " ", accent or C.purple)
    text(x, y + height - 1, string.rep("-", width), C.gray)
end

local function tag(x, y, label, color)
    text(x, y, " " .. label .. " ", C.black, color)
end

local function progressDots(active)
    local x = math.floor((W - (#pages * 3 - 1)) / 2) + 1
    for i = 1, #pages do
        text(x + (i - 1) * 3, H, i == active and "##" or "--",
            i == active and C.magenta or C.gray)
    end
end

local function header(section, detail)
    fill(1, 1, W, H, C.black)
    text(2, 1, "OBSIDIAN", C.white)
    text(11, 1, "ENGINE", C.purple)
    text(W - #section, 1, section, C.cyan)
    text(2, 2, string.rep("-", math.max(1, W - 2)), C.gray)
    if detail then text(2, 3, detail, C.lightGray) end
end

local function makeSprite(ch, fg, bg)
    local frame = { { { ch } }, { { fg or C.white } }, { { bg or C.black } } }
    return { width = 1, height = 1, [1] = frame }
end

local function currentPage(time)
    local cursor = 0
    for index, page in ipairs(pages) do
        if time < cursor + page.duration then
            return index, time - cursor
        end
        cursor = cursor + page.duration
    end
    return #pages, pages[#pages].duration
end

local function spawnActors()
    local colors = { C.cyan, C.magenta, C.purple, C.lightBlue, C.pink, C.lime }
    for i = 1, 28 do
        local id = scene:spawn()
        local x = 4 + ((i * 11) % math.max(10, W - 8))
        local y = 6 + ((i * 7) % math.max(4, H - 10))
        scene:attach(id, "pos", Engine.math.vec2(x, y))
        scene:attach(id, "velocity", Engine.math.vec2(
            ((i % 5) - 2) * 1.35,
            ((i % 3) - 1) * 0.75
        ))
        scene:attach(id, "showcaseActor", {
            color = colors[((i - 1) % #colors) + 1],
            char = (i % 5 == 0) and "@" or "*",
        })
        actorIds[#actorIds + 1] = id
    end
end

local function spawnEmitters()
    local sprite = makeSprite(".", C.white, C.black)
    local configs = {
        {
            x = math.floor(W * 0.25), y = H - 3,
            spawnRate = 42, angle = -90, spread = 42,
            speedMin = 2, speedMax = 7, lifeMin = 0.8, lifeMax = 1.6,
            colors = { C.red, C.orange, C.yellow, C.white },
            chars = { ".", "*", "+" }, gravityScale = -0.15, drag = 0.3,
        },
        {
            x = math.floor(W * 0.5), y = math.floor(H * 0.55),
            spawnRate = 34, angle = 0, spread = 360,
            speedMin = 3, speedMax = 10, lifeMin = 0.6, lifeMax = 1.5,
            colors = { C.purple, C.magenta, C.pink, C.white },
            chars = { "*", "+", "." }, gravityScale = 0.08, drag = 0.12,
        },
        {
            x = math.floor(W * 0.76), y = H - 3,
            spawnRate = 38, angle = -90, spread = 24,
            speedMin = 3, speedMax = 8, lifeMin = 0.7, lifeMax = 1.4,
            colors = { C.blue, C.cyan, C.lightBlue, C.white },
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
        { "linear", tween.easing.linear, C.cyan },
        { "cubicOut", tween.easing.cubicOut, C.magenta },
        { "elasticOut", tween.easing.elasticOut, C.purple },
        { "bounceOut", tween.easing.bounceOut, C.pink },
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

    local pulse = 0.5 + math.sin(t * 3) * 0.5
    local gemColor = pulse > 0.45 and C.magenta or C.purple
    local gem = {
        "       /\\       ",
        "    __/  \\__    ",
        "   /  /\\ /\\  \\   ",
        "  <  <  V  >  >  ",
        "   \\  \\/ \\/  /   ",
        "    \\__\\/__/    ",
        "       \\/       ",
    }
    local startY = math.max(5, math.floor((H - #gem) / 2))
    for row, line in ipairs(gem) do
        center(startY + row - 1, line, row % 2 == 0 and C.purple or gemColor)
    end

    local titleY = math.min(H - 4, startY + #gem + 1)
    center(titleY, "OBSIDIAN ENGINE", C.white)
    center(titleY + 1, "BUILD WORLDS. MOVE FAST.", C.cyan)
    progressDots(1)
end

local function drawECS(t)
    header("01 / ECS", "Composition over inheritance - thousands of possibilities")

    local viewX, viewY = 2, 5
    local sideW = W >= 62 and 19 or 15
    local viewW = W - sideW - 4
    local viewH = H - 7
    panel(viewX, viewY, viewW, viewH, "LIVE WORLD", C.cyan)

    for gx = viewX + 2, viewX + viewW - 2, 6 do
        for gy = viewY + 2, viewY + viewH - 2, 3 do
            text(gx, gy, ".", C.gray)
        end
    end

    for _, id in ipairs(actorIds) do
        local pos = scene:get(id, "pos")
        local actor = scene:get(id, "showcaseActor")
        if pos and actor then
            local x = viewX + 1 + ((math.floor(pos.x) - 1) % math.max(1, viewW - 2))
            local y = viewY + 1 + ((math.floor(pos.y) - 1) % math.max(1, viewH - 2))
            text(x, y, actor.char, actor.color)
        end
    end

    local sideX = viewX + viewW + 2
    text(sideX, viewY, "WORLD", C.purple)
    text(sideX, viewY + 2, "entities", C.lightGray)
    text(sideX, viewY + 3, tostring(#actorIds), C.white)
    text(sideX, viewY + 5, "systems", C.lightGray)
    text(sideX, viewY + 6, "4 active", C.cyan)
    if H >= 18 then
        text(sideX, viewY + 8, "pos", C.magenta)
        text(sideX + 4, viewY + 8, "velocity", C.purple)
        text(sideX, viewY + 9, "sprite", C.cyan)
    end
    progressDots(2)
end

local function drawParticles(t)
    header("02 / VFX", "ECS-powered particles - emit, update, render, recycle")

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
        if pos then text(math.floor(pos.x), math.floor(pos.y), "^", C.white) end
    end

    tag(2, H - 2, "3 EMITTERS", C.purple)
    tag(16, H - 2, tostring(#live) .. " LIVE", C.magenta)
    tag(math.max(28, W - 17), H - 2, "REAL-TIME VFX", C.cyan)
    progressDots(3)
end

local function drawPathfinding(t)
    header("03 / AI", "A* pathfinding with collision-aware navigation")

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
                value, color = "..", C.purple
            elseif (x + y) % 2 == 0 then
                value, color = " .", C.gray
            end
            text(ox + (x - 1) * 2, oy + y - 1, value, color)
        end
    end

    if #path > 0 then
        local speed = 4
        local index = (math.floor(t * speed) % #path) + 1
        local node = path[index]
        text(ox + (node.x - 1) * 2, oy + node.y - 1, "@@", C.black, C.cyan)
        local goal = path[#path]
        text(ox + (goal.x - 1) * 2, oy + goal.y - 1, "XX", C.black, C.magenta)
    end

    local sideX = ox + gridW * 2 + 2
    if sideX <= W - 8 then
        text(sideX, oy, "NAVIGATION", C.magenta)
        text(sideX, oy + 2, "A* search", C.white)
        text(sideX, oy + 3, "8-way grid", C.lightGray)
        text(sideX, oy + 5, "waypoints", C.lightGray)
        text(sideX, oy + 6, tostring(#path), C.cyan)
        text(sideX, oy + 8, "collision", C.lightGray)
        text(sideX, oy + 9, "aware", C.lime)
    end
    progressDots(4)
end

local function drawTweens(t)
    header("04 / MOTION", "Tweening, easing and frame diagnostics")

    local labelW = 12
    local trackX = labelW + 3
    local trackW = math.max(12, W - trackX - 2)
    for index, row in ipairs(tweenRows) do
        local y = 5 + (index - 1) * 2
        text(2, y, row.name, C.lightGray)
        text(trackX, y, string.rep("-", trackW), C.gray)
        local x = trackX + math.floor(clamp(row.target.x, 0, 1) * (trackW - 1))
        text(x, y, "#", row.color)
    end

    local statsY = math.min(H - 4, 14)
    text(2, statsY, "FRAME PIPELINE", C.purple)
    local labels = { "update", "systems", "render", "present" }
    local colors = { C.cyan, C.magenta, C.purple, C.lightBlue }
    local bx = 2
    for index, label in ipairs(labels) do
        local width = math.max(7, math.floor((W - 7) / #labels))
        fill(bx, statsY + 2, width, 2, C.black)
        text(bx, statsY + 2, label, colors[index])
        text(bx, statsY + 3, tostring(index + 1) .. " ms", C.white)
        bx = bx + width + 1
    end
    progressDots(5)
end

local function drawFinale(t)
    header("READY", "One engine. A complete toolbox for your next CC:Tweaked game.")

    local y = math.max(5, math.floor(H * 0.28))
    center(y, "OBSIDIAN", C.white)
    center(y + 1, "2D GAME ENGINE", C.purple)

    local tags = {
        { "ECS", C.cyan },
        { "PHYSICS", C.magenta },
        { "PARTICLES", C.purple },
        { "AI", C.lightBlue },
    }
    local total = 0
    for _, item in ipairs(tags) do total = total + #item[1] + 3 end
    local x = math.floor((W - total) / 2) + 1
    for _, item in ipairs(tags) do
        tag(x, y + 4, item[1], item[2])
        x = x + #item[1] + 3
    end

    center(y + 7, "github.com/Pyroxenium/Obsidian", C.lightGray)
    center(math.min(H - 2, y + 9), "START BUILDING", C.cyan)
    progressDots(6)
end

scene.onLoad = function()
    W, H = buffer:getSize()
    math.randomseed(2501)
    particles.registerAll(scene)
    spawnActors()
    spawnEmitters()
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

    local particlesActive = pageIndex == 3
    for _, id in ipairs(emitterIds) do
        local emitter = scene:get(id, "emitter")
        if emitter then emitter.active = particlesActive end
    end

    if elapsed >= totalDuration then
        if auto then
            Engine.stop()
        else
            elapsed = 0
        end
    end
end

scene.onDraw = function()
    pageIndex, pageTime = currentPage(elapsed)
    if pageIndex == 1 then
        drawIntro(pageTime)
    elseif pageIndex == 2 then
        drawECS(pageTime)
    elseif pageIndex == 3 then
        drawParticles(pageTime)
    elseif pageIndex == 4 then
        drawPathfinding(pageTime)
    elseif pageIndex == 5 then
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
