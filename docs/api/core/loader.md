# loader

Obsidian Engine: Asset Loader
Handles loading and caching of sprites, UI, and emitters.
Injected by the bundler / init.lua loader; see src/init.lua.

## Types

### `SpriteLayer`

```lua
SpriteLayer = table<number, table|string> Each layer contains legacy string rows or per-cell value tables. Color layers may contain RGB handles/#RRGGBB values.
```

### `SpriteFrame`

```lua
SpriteFrame = table<number, SpriteLayer> [1]=Chars, [2]=Fore, [3]=Back
```

### `Sprite`

Represents a multi-frame sprite with character, foreground, and background layers.

| Field | Type | Description |
| --- | --- | --- |
| width | `number` | The width of the sprite |
| height | `number` | The height of the sprite |
| frameCount | `number` | The number of frames in the sprite |
| path | `string` | The original file path of the sprite (for reference) |
| [number] | `SpriteFrame` | Frames indexed from 1 to frameCount |

### `UIData`

Represents UI layout data loaded from .oui files.

| Field | Type | Description |
| --- | --- | --- |
| elements | `table<string, table>` | A table of UI elements, where each key is an element name and the value is a table of properties. |

### `EmitterData`

Represents particle emitter configuration loaded from .pe files.

| Field | Type | Description |
| --- | --- | --- |
| sprite | `Sprite\|nil` | The sprite associated with the emitter, if any |
| [string] | `any` | Additional emitter properties |

### `LoaderModule`

Loader module definition

| Field | Type | Description |
| --- | --- | --- |
| basePath | `string\|nil` | Optional base path for resolving asset files |
| spriteCache | `table<string, Sprite>` | Cache of loaded sprites, keyed by full file path |
| uiCache | `table<string, UIData>` | Cache of loaded UI data, keyed by full file path |
| emitterCache | `table<string, EmitterData>` | Cache of loaded emitter data, keyed by full file path |

## Methods

### loader.setBasePath(path)

Set a base path for asset loading. Relative paths will be resolved against this base path.

- **path** (`string|nil`, optional) The base path to set, or nil to disable

### loader.loadSprite(path)

Load a sprite (.obs file) from disk or cache.

- **path** (`string`) The file path of the sprite to load

- **returns** **sprite** (`Sprite|nil`) The loaded sprite data, or nil if loading failed

### loader.loadImage(path)

- **path** (`string`) 

- **returns** **image** (`table|nil`) 
- **returns** **error** (`string?`) 

### loader.loadUI(path)

Load UI data (.oui file) from disk or cache.

- **path** (`string`) The file path of the UI data to load

- **returns** **oui** (`UIData|nil`) The loaded UI data, or nil if loading failed
- **returns** **err** (`string?`) An error message if loading failed

### loader.loadEmitter(path)

Load emitter configuration (.pe file) from disk or cache.

- **path** (`string`) The file path of the emitter data to load

- **returns** **pe** (`EmitterData|nil`) The loaded emitter data, or nil if loading failed

### loader.unload(path)

Remove an asset from all caches.

- **path** (`string`) The file path of the asset to unload

### loader.clearCache()

Clear all cached assets.
