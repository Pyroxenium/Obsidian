# ECS Guide — What ECS Is and Why Use It

This short guide explains the core ideas behind the Entity‑Component‑System (ECS) pattern and why it is a good fit for many game and simulation projects. It also shows how ECS maps to Obsidian's `Scene`/World API.

## What is ECS?

- Entity: a lightweight identifier (usually a number). An entity itself holds no logic or data—just an ID.
- Component: a plain data container attached to an entity (position, velocity, health, sprite, etc.). Components are usually just Lua tables.
- System: a function that operates on all entities that have a specific set of components. Systems encapsulate behavior and update components each frame.

ECS separates data (components) from behavior (systems) and composes game objects by attaching different components to entities.

## Why use ECS?

- Composition over inheritance: Easily build varied behaviors by combining small components instead of deep class hierarchies.
- Decoupling: Systems don't depend on concrete object types—only on component presence, making code more modular and easier to test.
- Performance: Iterating arrays of components can be cache-friendly and easy to optimize; it often maps well to batch-processing updates.
- Flexibility: Add/remove components at runtime to change an entity's behavior without changing code structure.

Tradeoffs: ECS introduces an indirection layer and may feel verbose for very small or strictly static object graphs.

## ECS patterns in Obsidian

Obsidian exposes an easy-to-use Scene/World API that follows ECS principles.

- Use the `Scene` instance as the world (the example project uses this pattern).
- Entities are created with `scene:spawn()`.
- Components are attached via `scene:attach(id, "componentName", data)`.
- Systems are registered with `scene:addSystem(componentList, fn)` where `fn(dt, entities, comps)` is called each frame.

### Example (minimal)

```lua
local demo = Engine.scene.new()
Engine.setScene(demo)
Engine.start()

-- spawn
local e = demo:spawn()
demo:attach(e, "pos", { x = 10, y = 5 })
demo:attach(e, "vel", { x = 1, y = 0 })

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

### HUD & Input

- Keep rendering/UI updates out of systems when possible: use `scene:bindHUD` to update UI elements each frame.
- For input, prefer `Engine.input` hooks (`onKey`, `onCombo`) instead of polling input from systems—this keeps systems focused on game logic.

## When to choose something else

- For very small projects with only a few object types, the added indirection of ECS might not be worth it.
- If objects have deeply interwoven behavior that is best expressed via methods and inheritance, an OOP approach could be simpler.

## Example reference

See the working example in `examples/ecs_example.lua` for a complete demo that uses these patterns.