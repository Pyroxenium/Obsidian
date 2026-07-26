# engine

Obsidian Engine core

## Types

### `Engine`

| Field | Type | Description |
| --- | --- | --- |
| ecs | `ECSModule` | Entity-Component-System for managing game entities and their components |
| error | `ErrorModule` | Global error handling and panic screen |
| scene | `SceneModule` | Scene management system with entity storage, rendering, and update loops |
| thread | `ThreadModule` | Lightweight cooperative threading system for concurrent tasks |
| buffer | `BufferInstance` | Centralized drawing buffer for rendering to the terminal with support for letterboxing and design resolution |
| renderer | `BufferInstance` | Alias for buffer; exposes layers, subpixels and palette control |
| rgb | `fun(r:number\|string, g:number\|nil, b:number\|nil):number` | Registers a reusable logical RGB color |
| input | `InputModule` | Handles keyboard and mouse input, including state tracking and event processing |
| loader | `LoaderModule` | Resource loading system for sprites, audio, and other assets with caching |
| inputMapper | `InputMapperModule` | Configurable input mapping system to abstract raw input into game actions |
| ui | `UIModule` | Simple immediate-mode UI system for buttons, text, and basic layout |
| tween | `TweenModule` | Tweening system for smooth transitions of values over time with various easing functions |
| timer | `TimerModule` | Scheduling system for delayed and repeating callbacks, useful for timed events and animations |
| camera | `CameraModule` | 2D camera system for managing viewports, following entities, and applying transformations |
| tilemap | `TilemapModule` | Support for tile-based maps with rendering, collision, and properties |
| event | `EventEmitter` | Global event bus for decoupled communication between systems and scenes |
| logger | `LoggerModule` | Logging system with multiple levels and optional console output |
| math | `MathModule` | Utility functions for math operations, including vector math and easing functions |
| physics | `PhysicsModule` | Basic physics system with support for static and dynamic bodies, collision detection, and response |
| audio | `AudioModule` | Audio playback system for sound effects and music with support for multiple channels and basic controls |
| ai | `AIModule` | Artificial intelligence system for NPC behavior and decision-making |
| pathfinding | `PathfindingModule` | Pathfinding system for navigating complex environments |
| serialization | `SerializationModule` | System for saving and loading game state |
| network | `NetworkModule` | Networking system for multiplayer and online features |
| server | `ServerModule` | Server management system for hosting multiplayer games |
| storage | `StorageModule` | Local and cloud storage system for game data |
| db | `DatabaseModule` | Database management system for structured data storage |
| particles | `ParticlesModule` | Particle system for visual effects like explosions, smoke, and magic |
| console | `ConsoleModule` | In-game console for debugging, command execution, and log viewing |
| VERSION | `string` | Semantic version of this Obsidian build |

## Methods

### Engine.addRenderLayer(name, zIndex)

Create an optional retained render layer. Existing drawing continues to use
Engine.buffer's opaque default layer.

- **name** (`string`) Unique layer name
- **zIndex** (`number|nil`, optional) Lower values render first

- **returns** **layer** (`table`) 

### Engine.getRenderLayer(name)

- **name** (`string`) Layer name

- **returns** **layer** (`table|nil`) 

### Engine.removeRenderLayer(layerOrName)

- **layerOrName** (`table|string`) 

- **returns** **removed** (`boolean`) 

### Engine.onError(fn)

Set custom error handler

- **fn** (`function`) Custom error handler function that takes a single string argument (the error message)

### Engine.setFPS(fps)

Set target frames per second

- **fps** (`number`) Desired frames per second (e.g. 30)

### Engine.getTargetFPS()

Get target FPS

- **returns** **fps** (`number`) returns configured target frames per second

### Engine.getFPS()

Get actual measured FPS

- **returns** **fps** (`number`) returns the actual measured frames per second

### Engine.getDeltaTime()

Get averaged delta time in seconds

- **returns** **deltaTime** (`number`) returns the averaged delta time in seconds

### Engine.onUpdate(fn)

Register per-frame update callback

- **fn** (`fun(dt:number)`) Callback function that receives delta time in seconds as an argument

### Engine.onRender(fn)

Register per-frame render callback

- **fn** (`fun()`) Callback function that is called every frame for rendering

### Engine.onEvent(fn)

Register event callback (receives raw OS event table)

- **fn** (`fun(event:table)`) Callback function that receives raw OS event table as an argument

### Engine.setScene(scene)

Set the active scene (calls onUnload/onLoad hooks)

- **scene** (`SceneInstance`) Scene instance to set as active

### Engine.getScene()

Get the currently active scene

- **returns** **scene** (`SceneInstance|nil`) the currently active scene instance, or nil if no scene is active

### Engine.transition(targetScene, duration)

Transition to another scene with fade effect

- **targetScene** (`SceneInstance`) Scene instance to transition to
- **duration** (`number|nil`, optional) Default: 1 second

### Engine.isTransitioning()

Check if a transition is currently active

- **returns** **isTransitioning** (`boolean`) returns true if a scene transition is currently in progress

### Engine.setViewport(w, h)

Set explicit viewport size on the Engine buffer

- **w** (`number`) Width of the viewport
- **h** (`number`) Height of the viewport

### Engine.setDesignResolution(w, h)

Set the design resolution used for letterboxing and UI

- **w** (`number`) Width of the design resolution
- **h** (`number`) Height of the design resolution

### Engine.setMinResolution(w, h)

Set minimum required resolution

- **w** (`number`) Minimum width of the terminal for the engine to run (e.g. 40)
- **h** (`number`) Minimum height of the terminal for the engine to run (e.g. 20)

### Engine.getDesignResolution()

Get currently configured design resolution

- **returns** **resolution** (`number|nil, number|nil`) width and height of the design resolution, or nil if not set

### Engine.getViewportOffset()

Get viewport offset for letterboxing

- **returns** **offset** (`number, number`) x and y offset of the viewport for letterboxing based on current terminal size and design resolution

### Engine.screenToViewport(sx, sy)

Convert screen coordinates to viewport coordinates

- **sx** (`number`) Screen x coordinate
- **sy** (`number`) Screen y coordinate

- **returns** **viewport** (`number, number`) Viewport x and y coordinates converted from screen coordinates based on current viewport offset

### Engine.showDebug(enabled, alwaysOnTop)

Enable or disable debug overlay

- **enabled** (`boolean`) Whether to enable or disable the debug overlay
- **alwaysOnTop** (`boolean|nil`, optional) Optional parameter to keep the debug overlay always on top

### Engine.enableConsole(enabled)

Enable or disable console

- **enabled** (`boolean`) Whether to enable or disable the in-game console

### Engine.isConsoleEnabled()

Check if console is enabled

- **returns** **isEnabled** (`boolean`) returns true if the in-game console is enabled, false otherwise

### Engine.disableConsole()

### Engine.start()

Start the main engine loop (blocking)

### Engine.stop()

Stop the engine loop

### Engine.isRunning()

Check if engine is running

- **returns** **isRunning** (`boolean`) returns true if the engine loop is currently running, false otherwise
