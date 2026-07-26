# Welcome to the Obsidian Wiki

Obsidian is a 2D game engine for **CC:Tweaked**. It combines an Entity
Component System with a retained renderer, so game logic stays decoupled from
data while drawing keeps the terminal redraws down to what actually changed.

![Obsidian showcase](https://pyroxenium.github.io/Obsidian/preview.gif)

## Features

- **ECS architecture:** entities, components and systems, with a spatial grid
  behind rect queries, triggers, raycasting and line-of-sight checks
- **Retained renderer:** z-ordered layers with per-channel transparency,
  nested translation and clipping contexts, and dirty-region tracking
- **Colour beyond the 16 slots:** register logical RGB colours and let the
  palette mapper assign them to hardware slots per frame
- **Subpixels:** a 2x3 virtual canvas compiled into CC mosaic characters
- **FLIMG images:** a binary image format that keeps RGB and subpixels intact
  instead of baking them into terminal cells
- **Scenes and tilemaps:** multi-layer maps with collision, slopes and one-way
  platforms, plus static, dynamic and foreground rendering passes
- **Gameplay systems:** physics, particles, tweens, timers, pathfinding, AI
  behaviour trees, audio, save/load, and a document store
- **Multiplayer:** a rednet wrapper with heartbeats plus a high-level server
  with rooms, middleware and an optional console
- **Developer friendly:**
  - LuaLS type information for editor support
  - Generated API documentation that stays synchronized with the source
  - Source, minified and compressed release bundles

## Installation

The installer places the engine into your computer as `obsidian`, so it is
loaded by name:

```lua
local Engine = require("obsidian")
```

A release bundle works the same way: drop `obsidian.lua` in next to your
program and `require("obsidian")` finds it.

## Quick Start

```lua
local Engine = require("obsidian")

local scene = Engine.scene.new()
scene.name = "Hello"

local player = scene:spawn()
scene:attach(player, "pos", Engine.math.vec2(10, 5))

scene.onDraw = function()
    Engine.buffer:drawText(2, 2, "Hello Obsidian", "0", "f")
end

Engine.setScene(scene)
Engine.start()
```

## Where to go next

- [Engine Quickstart](/guides/engine_quickstart) walks through a first project
- [ECS Guide](/guides/ecs_guide) explains entities, components and systems
- The [API Reference](/api/) documents every module, generated from the sources
