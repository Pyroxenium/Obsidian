-- Obsidian smoke test (a tool, not part of the engine).
--
-- Loads the engine the way a user does and checks that every subsystem came
-- up. It does not start the main loop, so it needs no terminal interaction and
-- can run headless in CI.
--
-- Place this file next to an installed engine and run it:
--   /obsidian/      the installed source tree, or
--   /obsidian.lua   a release bundle dropped in under that name
--   /smoketest.lua  this file
--
-- Both layouts answer require("obsidian"), so the same test covers the source
-- install and every bundle variant, and proves the bundle is a drop-in
-- replacement for the directory.

---@diagnostic disable: undefined-global

local function fail(message)
    printError("smoketest: " .. message)
    error("smoketest failed", 0)
end

if type(require) ~= "function" then
    fail("no require in this environment; run me through the shell")
end

local ok, result = pcall(require, "obsidian")
if not ok then fail('require("obsidian") raised: ' .. tostring(result)) end
local Engine = result

if type(Engine) ~= "table" then
    fail("expected a table, got " .. type(Engine))
end

-- tools/bundle.lua reads this string out of engine.lua to label releases, so a
-- missing or malformed version silently produces "Obsidian ? bundled".
if type(Engine.VERSION) ~= "string"
    or not Engine.VERSION:match("^%d+%.%d+%.%d+") then
    fail("Engine.VERSION is not a semver string: " .. tostring(Engine.VERSION))
end
print("version: " .. Engine.VERSION)

-- Every subsystem engine.lua wires up must be present. A module that failed to
-- resolve shows up here rather than at the first frame of someone's game.
local subsystems = {
    "ecs", "scene", "thread", "buffer", "renderer", "input", "loader",
    "inputMapper", "ui", "tween", "timer", "camera", "tilemap", "event",
    "logger", "math", "physics", "audio", "ai", "pathfinding",
    "serialization", "network", "server", "storage", "db", "particles",
    "console", "error", "flimg", "color",
}

local missing = {}
for _, name in ipairs(subsystems) do
    if Engine[name] == nil then missing[#missing + 1] = name end
end
if #missing > 0 then
    fail("missing subsystems: " .. table.concat(missing, ", "))
end

local functions = {
    "start", "stop", "isRunning", "setScene", "getScene", "setFPS",
    "onUpdate", "onRender", "onEvent", "rgb", "addRenderLayer",
}
for _, name in ipairs(functions) do
    if type(Engine[name]) ~= "function" then
        fail("Engine." .. name .. " is " .. type(Engine[name]) .. ", expected function")
    end
end

-- Exercise a few subsystems that do real work at call time.
local scene = Engine.scene.new()
if type(scene) ~= "table" then fail("scene.new() did not return a scene") end

local id = scene:spawn()
scene:attach(id, "pos", Engine.math.vec2(1, 2))
if not scene:has(id, "pos") then fail("ECS attach/has round trip failed") end

local handle = Engine.rgb("#3366CC")
if type(handle) ~= "number" then fail("Engine.rgb did not return a handle") end

local layer = Engine.addRenderLayer("smoketest", 5)
if type(layer) ~= "table" then fail("addRenderLayer did not return a layer") end
Engine.removeRenderLayer(layer)

Engine.buffer:drawText(1, 1, "obsidian", "0", "f")
Engine.buffer:restorePalette()

print(("smoketest passed: %d subsystems, %d entry points")
    :format(#subsystems, #functions))
