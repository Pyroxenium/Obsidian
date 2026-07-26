# Engine Quickstart — Minimal Patterns

This short guide shows the minimal patterns to use Obsidian's `Engine` with a `Scene` as a world: spawning entities, registering systems, adding a HUD, handling input via hooks, and cleaning up.

## Setup

```lua
local Engine = require("obsidian") -- adjust require path if needed
local demo = Engine.scene.new()
demo.name = "Quickstart"

Engine.setScene(demo)
Engine.start()
```

## Spawn an entity & attach components

```lua
local id = demo:spawn()
demo:attach(id, "pos", { x = 10, y = 5 })
demo:attach(id, "vel", { x = 1, y = 0 })
-- small 1x1 sprite frame
local frame = {
  { { "*" } }, -- chars
  { { "f" } }, -- fg colors
  { { "0" } }, -- bg colors
}
demo:attach(id, "sprite", { width = 1, height = 1, [1] = frame })
```

## Register an update system

Systems run each frame for entities that have the listed components. System signature: `fn(dt, entities, comps)`.

```lua
demo:addSystem({"pos", "vel"}, function(dt, entities, comps)
  for _, id in ipairs(entities) do
    local p = comps.pos[id]
    local v = comps.vel[id]
    if p and v then
      p.x = p.x + v.x * dt
      p.y = p.y + v.y * dt
    end
  end
end)
```

## Add a HUD (UI)

Create a UI element and update it using `Scene:bindHUD` so it runs outside of ECS systems.

```lua
local W, H = Engine.buffer:getSize()
demo.ui:text("hud", 2, H, { text = "", z = 500 })
local hudId = demo:bindHUD("hud", function(scene, dt)
  local stats = demo:stats()
  scene.ui:update("hud", { text = string.format("Entities: %d", stats.entities) })
end)
```

## Handle input with hooks

Use the Input hook API instead of polling within systems.

```lua
local spawnKey = Engine.input.onKey("space", function()
  -- spawn or other action
  demo:spawn()
end, { repeatable = true, repeatDelay = 0.5, repeatInterval = 0.15 })

-- remove when done
Engine.input.offKey(spawnKey)
```

## Cleanup and lifecycle

Use scene events for cleanup:

```lua
demo.event:once("unload", function()
  Engine.input.offKey(spawnKey)
  demo:unbindHUD(hudId)
  demo:clear()
end)
```

## Example reference

See the working example at:
[examples/ecs_example.lua](https://github.com/Pyroxenium/Obsidian/blob/master/examples/ecs_example.lua)
