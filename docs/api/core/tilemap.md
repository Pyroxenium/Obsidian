# tilemap

## Types

### `TilemapInstance`

A tilemap instance representing a multi-layer tile map. Tilemaps manage tile definitions, layers, and integration with scenes. They can be saved and loaded from storage, but sprite objects must be reloaded and re-attached after loading.

| Field | Type | Description |
| --- | --- | --- |
| tileW | `number` | Tile width in pixels |
| tileH | `number` | Tile height in pixels |

### `TilemapModule`

This is the tilemap module for managing multi-layer tile maps in the engine. It provides functions to define tile types, manage layers, read/write tiles, and integrate with scenes. Tilemaps can be saved and loaded from storage, but sprite objects must be reloaded and re-attached after loading.

## TilemapModule

### TilemapModule.new(opts)

Create a new empty tilemap.

- **opts** (`table|nil`, optional) { tileW=number, tileH=number } Tile size in pixels (default tileW=2, tileH=1)

- **returns** **tilemap** (`TilemapInstance`) A new tilemap instance

## TilemapInstance

### tilemap:defineTile(id, opts)

Register a tile type.

- **id** (`number`) Positive integer tile ID (0 = empty)
- **opts** (`{spritePath:string|nil, solid:boolean|nil, type:string|nil, hL:number|nil, hR:number|nil}`) Tile properties: spritePath = path to sprite for this tile; solid = whether it blocks movement; type = "slope" or "one-way"; hL/hR = slope heights (0-1) for left/right edges (only for slopes)

### tilemap:getTileDef(id)

Get the definition table for a tile id (read-only).

### tilemap:addLayer(name, opts)

Add a new data layer.

- **name** (`string`) Unique layer name
- **opts** (`{ z:number|nil, collision:boolean|nil }`) Layer properties: z = rendering order (lower renders first); collision = whether this layer is used for collision (first layer with collision=true is used by the engine)

- **returns** **map** (`table`) The new layer object (with name, z, collision, and data fields)

### tilemap:removeLayer(name)

Remove a layer by name.

- **name** (`string`) Name of the layer to remove

- **returns** **success** (`boolean`) True if the layer was found and removed, false if no such layer exists

### tilemap:getLayer(name)

Get the data table for a layer (raw access for bulk operations).

- **name** (`string`) Name of the layer

- **returns** (`table|nil`) The layer data table, or nil if the layer doesn't exist

### tilemap:setTile(layerName, tx, ty, tileId)

Set a single tile.

- **layerName** (`string`) 
- **tx** (`number`) 1-based column
- **ty** (`number`) 1-based row
- **tileId** (`number`) 0 or nil = clear; positive = place

### tilemap:getTile(layerName, tx, ty)

Get the tile id at (tx, ty) on a layer.  Returns nil for empty.

- **layerName** (`string`) 
- **tx** (`number`) 1-based column
- **ty** (`number`) 1-based row

- **returns** **tileId** (`number|nil`) The tile ID at the specified location, or nil if empty or out of bounds

### tilemap:fill(layerName, tileId, x1, y1, x2, y2)

Fill the entire layer (or a rectangular region) with a single tile id.

- **layerName** (`string`) Name of the layer to fill
- **tileId** (`number`) 0 or nil = clear; positive = place
- **x1** (`number|nil`, optional) 1-based left column of the fill area (optional, defaults to full layer)
- **y1** (`number|nil`, optional) 1-based top row of the fill area (optional, defaults to full layer)
- **x2** (`number|nil`, optional) 1-based right column of the fill area (optional, defaults to full layer)
- **y2** (`number|nil`, optional) 1-based bottom row of the fill area (optional, defaults to full layer)

### tilemap:copyRect(srcLayer, dstLayer, sx1, sy1, sx2, sy2, dx, dy)

Copy a rectangular region from one layer/position to another.

- **srcLayer** (`string`) Name of the source layer
- **dstLayer** (`string`) Name of the destination layer
- **sx1** (`number`) 1-based left column of the source rectangle
- **sy1** (`number`) 1-based top row of the source rectangle
- **sx2** (`number`) 1-based right column of the source rectangle
- **sy2** (`number`) 1-based bottom row of the source rectangle
- **dx** (`number`) 1-based left column of the destination rectangle
- **dy** (`number`) 1-based top row of the destination rectangle

### tilemap:worldToTile(wx, wy)

Convert world position to tile coordinates.

- **returns** (`number`) tx, number ty  -- 1-based, may be outside map bounds

### tilemap:tileToWorld(tx, ty)

Convert tile coordinates to the world position of its top-left corner.

- **returns** (`number`) wx, number wy

### tilemap:forArea(wx1, wy1, wx2, wy2, fn)

Iterate all non-empty tiles within a world-space rectangle.

- **wx1** (`number`) Left edge of the rectangle
- **wy1** (`number`) Top edge of the rectangle
- **wx2** (`number`) Right edge of the rectangle
- **wy2** (`number`) Bottom edge of the rectangle
- **fn** (`fun(layerName:string, tx:number, ty:number, tileId:number)`) Callback function

### tilemap:getNeighbors(layerName, tx, ty)

Return a table of { name, tx, ty, tileId } for the 4 cardinal neighbors
of (tx, ty) on a specific layer.

- **layerName** (`string`) Name of the layer to check
- **tx** (`number`) 1-based column
- **ty** (`number`) 1-based row

- **returns** **neighbors** (`table[]`) List of neighbor info tables with fields: name (layer name), tx, ty, tileId (nil if empty)

### tilemap:attach(scene)

Attach this tilemap to a scene.  Preloads sprites and writes the scene's
`tilemap` field in the format the engine renderer and collision system expect.

- **scene** (`SceneInstance`) The scene to attach to. The tilemap will write to scene.tilemap and mark scene._staticDirty when modified.

### tilemap:detach()

Detach from the scene (clears scene.tilemap).

### tilemap:save(name)

Save the tilemap's layer data (definitions and tile arrays) to storage.
Sprites are NOT saved — re-define them with defineTile() on load.

- **name** (`string`) Storage key (passed to storage.save)

### tilemap:load(name)

Load layer data from storage. Does NOT re-attach to a scene;
call map:attach(scene) afterwards.

- **name** (`string`) Same key used in map:save()

- **returns** (`TilemapInstance|nil, string|nil`) The tilemap instance (self) if successful, or nil and an error message if loading failed
