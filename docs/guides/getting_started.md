# Getting Started — Installation and Your First Project

This guide installs Obsidian and builds a small first game: a player character
that can move around the screen with the arrow keys or WASD.

## Prerequisites

You need:

- a computer running [CC:Tweaked](https://tweaked.cc/) or CraftOS-PC
- access to the HTTP API
- an internet connection during installation

An Advanced Computer is recommended so the game can use colour.

## Create a project

Create a directory for the game:

```sh
mkdir my-game
```

Start the Obsidian installer:

```sh
wget run https://pyroxenium.github.io/Obsidian/install.lua
```

Choose **Minified** and set the target to `my-game/obsidian.lua`.

You can perform the same installation directly from the command line:

```sh
wget run https://pyroxenium.github.io/Obsidian/install.lua minified my-game/obsidian.lua
```

Enter the project directory:

```sh
cd my-game
```

The project directory should now contain:

```text
my-game/
└── obsidian.lua
```

### Installation variants

The installer offers four versions of the engine:

| Variant | Installed as | Use it when |
| --- | --- | --- |
| `source` | `obsidian/` | You want readable, editable source files |
| `bundled` | `obsidian.lua` | You want the engine in one readable file |
| `minified` | `obsidian.lua` | You want the recommended small, fast-loading build |
| `compressed` | `obsidian.lua` | Storage matters more than startup time |

All variants are loaded in exactly the same way:

```lua
local Engine = require("obsidian")
```

## Create the game

Open a new file named `main.lua`:

```sh
edit main.lua
```

Paste in the following program:

```lua
local Engine = require("obsidian")

local game = Engine.scene.new()
local player
local screenWidth
local screenHeight
local playerSpeed = 10

game.name = "My first Obsidian game"

local function makeSprite(character, foreground, background)
    return {
        width = 1,
        height = 1,
        [1] = {
            { { character } },
            { { foreground } },
            { { background } },
        },
    }
end

game.onLoad = function()
    screenWidth, screenHeight = Engine.buffer:getSize()

    player = game:spawn()
    game:attach(player, "pos", Engine.math.vec2(
        math.floor(screenWidth / 2),
        math.floor(screenHeight / 2)
    ))
    game:attach(player, "sprite", makeSprite("@", "9", "f"))

    game.ui:text("title", 2, 2, {
        text = "My first Obsidian game",
        fore = "a",
        back = "f",
        z = 100,
    })

    game.ui:text("help", 2, screenHeight, {
        text = "Arrow keys / WASD to move - Q to quit",
        fore = "8",
        back = "f",
        z = 100,
    })
end

Engine.onUpdate(function(dt)
    local dx = 0
    local dy = 0

    if Engine.input.isKeyDown("left") or Engine.input.isKeyDown("a") then
        dx = dx - 1
    end
    if Engine.input.isKeyDown("right") or Engine.input.isKeyDown("d") then
        dx = dx + 1
    end
    if Engine.input.isKeyDown("up") or Engine.input.isKeyDown("w") then
        dy = dy - 1
    end
    if Engine.input.isKeyDown("down") or Engine.input.isKeyDown("s") then
        dy = dy + 1
    end

    local pos = game:get(player, "pos")
    pos.x = math.max(1, math.min(
        screenWidth,
        pos.x + dx * playerSpeed * dt
    ))
    pos.y = math.max(1, math.min(
        screenHeight,
        pos.y + dy * playerSpeed * dt
    ))

    if Engine.input.isJustPressed("q") then
        Engine.stop()
    end
end)

Engine.setScene(game)
Engine.start()
```

Save the file, leave the editor, and start the game:

```sh
main
```

Move the `@` character with the arrow keys or WASD. Press `Q` to stop the
engine and return to the shell.

Your finished project now looks like this:

```text
my-game/
├── main.lua
└── obsidian.lua
```

## How the project works

### Loading the engine

```lua
local Engine = require("obsidian")
```

`require` finds `obsidian.lua` next to `main.lua` and returns the engine. A
source installation works too: Lua finds `obsidian/init.lua` instead.

### Creating a scene

```lua
local game = Engine.scene.new()
```

A scene is the world that owns the game's entities, components, systems, UI,
and lifecycle callbacks.

### Spawning the player

```lua
local player = game:spawn()
game:attach(player, "pos", Engine.math.vec2(10, 5))
game:attach(player, "sprite", makeSprite("@", "9", "f"))
```

`spawn` creates an entity ID. The `pos` component gives that entity a location,
while the `sprite` component makes it visible. Obsidian automatically renders
entities that have both components.

The example sprite contains one frame with three layers: characters,
foreground colours, and background colours. Later projects will normally load
sprites from asset files instead of defining them in code.

### Handling input

Obsidian processes CraftOS events through `Engine.input`. The update callback
runs once per frame and receives `dt`, the number of seconds since the previous
frame:

```lua
Engine.onUpdate(function(dt)
    if Engine.input.isKeyDown("left") then
        -- Move while the key is held.
    end
end)
```

`isKeyDown` is useful for continuous movement. Multiplying the movement speed
by `dt` keeps the result independent of the configured frame rate.
`isJustPressed` is useful for actions that should happen only once, such as
pressing `Q` to stop the engine.

### Starting the engine

```lua
Engine.setScene(game)
Engine.start()
```

`Engine.setScene` activates the scene and calls its `onLoad` callback.
`Engine.start` then enters the main game loop and returns only after
`Engine.stop` is called.

## Troubleshooting

### The installer says that HTTP is disabled

Enable the HTTP API in the CC:Tweaked or CraftOS-PC configuration, then run the
installer again. The installer needs access to GitHub to download the engine.

### The installer says that the target already exists

The installer does not overwrite an existing engine file. Keep the existing
file, move it somewhere else, or remove it after making a backup before
installing a replacement.

### `require("obsidian")` cannot find the engine

Make sure `obsidian.lua` or the `obsidian/` source directory is in the same
directory as `main.lua`, and run `main` from that directory.

## Next steps

- [Engine Quickstart](/guides/engine_quickstart) introduces systems, HUD
  bindings, input hooks, and scene cleanup.
- [ECS Guide](/guides/ecs_guide) explains how entities, components, and systems
  fit together.
- Read the [`Engine` API](/api/engine), [scene API](/api/core/scene), and
  [input API](/api/core/input) for the complete reference.
