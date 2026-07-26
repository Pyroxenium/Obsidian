# scene

Obsidian Scene module
Combines ECS World with spatial systems, rendering, and game logic
Injected by the bundler / init.lua loader; see src/init.lua.

## Types

### `TileID`

The tile id

```lua
TileID = number
```

### `TileProperties`

The tile properties structure for slopes and one-way platforms

| Field | Type | Description |
| --- | --- | --- |
| type | `"slope"\|"one-way"\|string` | Type of tile (slope, one-way platform, or custom) |
| hL *(optional)* | `number` | Height left (for slopes) |
| hR *(optional)* | `number` | Height right (for slopes) |

### `Tilemap`

The tilemap structure used by the scene

| Field | Type | Description |
| --- | --- | --- |
| sprite | `table` | Tileset sprite |
| spritePath | `string\|nil` | Original path to the tileset sprite (for reloading) |
| data | `TileID[][]` | Tile data grid |
| solidTiles | `table<TileID, boolean>` | Set of solid tile IDs for quick lookup |
| tileProperties | `table<TileID, TileProperties>` | Tile properties by ID |
| tileW | `number` | Tile width in pixels |
| tileH | `number` | Tile height in pixels |
| layers | `table[]\|nil` | Optional multi-layer format: array of { name=string, data=TileID[][] } |

### `TriggerZone`

A trigger zone that can call callbacks when entities enter or exit.

| Field | Type | Description |
| --- | --- | --- |
| x | `number` | World X coordinate |
| y | `number` | World Y coordinate |
| w | `number` | Width of the trigger zone |
| h | `number` | Height of the trigger zone |
| onEnter | `function\|nil` | Callback when an entity enters the zone (receives entityId) |
| onExit | `function\|nil` | Callback when an entity exits the zone (receives entityId) |
| entitiesInside | `table<number, boolean>` | Set of entity IDs currently inside the trigger |

### `SceneModule`

| Field | Type | Description |
| --- | --- | --- |
| activeScene | `SceneInstance\|nil` | Currently active scene instance |

### `SceneInstance`

*extends World*

| Field | Type | Description |
| --- | --- | --- |
| name | `string` | Scene name (for debugging) |
| memory | `table` | General-purpose table for storing scene-specific data across systems and scripts |
| camera | `Vec2` | Current camera position |
| event | `EventEmitter` | Event system for the scene |
| ui | `table` | UI system instance |
| tilemap | `Tilemap\|nil` | Tilemap data for collision and rendering |
| onDraw | `function\|nil` | User-defined hook called after the engine's default drawing (for overlays) |
| onUpdate | `function\|nil` | User-defined hook called during the update phase (after systems) |
| onEvent | `function\|nil` | User-defined hook called when an event is emitted in the scene |
| onLoad | `function\|nil` | User-defined hook called when the scene is loaded |
| onUnload | `function\|nil` | User-defined hook called when the scene is unloaded |

## SceneModule

### Scene.setBuffer(buf)

Must be called once before any Scene.new() is used
Called by engine during initialization to provide the buffer for rendering and UI.

- **buf** (`BufferInstance`) The buffer to use for rendering (injected by engine)

### Scene.new()

Create a new Scene instance (wraps an ECS registry with scene systems).

- **returns** (`SceneInstance`) 

### Scene.newStaticElement(sprite, x, y, config)

Creates a new static element definition (background tile or decorative object).
This is a helper function for defining static elements without needing to construct the full table manually.

- **sprite** (`Sprite|nil`, optional) Sprite to draw (optional if collider-only)
- **x** (`number`) World X coordinate
- **y** (`number`) World Y coordinate
- **config** (`{spritePath?:string, z?:number, collider?:table|boolean, layer?:number, oneWay?:boolean}|nil`, optional) Additional configuration for the static element

### Scene.newTriggerZone(x, y, w, h, onEnter, onExit, onStay)

Creates a new trigger zone definition.
This is a helper function for defining trigger zones without needing to construct the full table manually.

- **x** (`number`) World X coordinate
- **y** (`number`) World Y coordinate
- **w** (`number`) Width of the trigger zone
- **h** (`number`) Height of the trigger zone
- **onEnter** (`function|nil`, optional) Callback when an entity enters the zone (receives entityId)
- **onExit** (`function|nil`, optional) Callback when an entity exits the zone (receives entityId)
- **onStay** (`function|nil`, optional) Callback when an entity stays in the zone (receives entityId)

- **returns** (`TriggerZone`) 

### Scene.newTilemap(sprite, data, solidTiles, tileProperties, spritePath)

Creates a new tilemap definition.
This is a helper function for defining tilemaps without needing to construct the full table manually.

- **sprite** (`Sprite`) Tileset sprite
- **data** (`TileID[][]`) Tile data grid
- **solidTiles** (`table<TileID, boolean>`) Set of solid tile IDs for quick lookup
- **tileProperties** (`table<TileID, TileProperties>`) Tile properties by ID
- **spritePath** (`string|nil`, optional) Original path to the tileset sprite (for reloading)

- **returns** (`Tilemap`) 

## SceneInstance

### SceneInstance:setTilemap(sprite, data, solidTiles, tileProperties, spritePath)

Set the tilemap for the scene (legacy single-layer or multi-layer format).

- **sprite** (`Sprite`) Tileset sprite (processed)
- **data** (`table`) Tile data grid or layers
- **solidTiles** (`table|nil`, optional) 
- **tileProperties** (`table|nil`, optional) 
- **spritePath** (`string|nil`, optional) 

### SceneInstance:instantiate(template, x, y)

Instantiate an entity from a template (table of components).

- **template** (`table`) Component template
- **x** (`number|nil`, optional) Initial X position (optional, requires 'pos' component in template)
- **y** (`number|nil`, optional) Initial Y position (optional, requires 'pos' component in template)

- **returns** **id** (`number`) ID of the newly created entity

### SceneInstance:setParent(childId, parentId, offsetX, offsetY)

Set a parent for an entity with optional offset.

- **childId** (`number`) ID of the child entity
- **parentId** (`number`) ID of the parent entity
- **offsetX** (`number|nil`, optional) X offset from the parent
- **offsetY** (`number|nil`, optional) Y offset from the parent

### SceneInstance:addStatic(sprite, x, y, config)

Add a static (background) element to the scene.

- **sprite** (`Sprite`) Sprite to draw (optional if collider-only)
- **x** (`number`) World X coordinate
- **y** (`number`) World Y coordinate
- **config** (`{spritePath?:string, z?:number, collider?:table|boolean, layer?:number, oneWay?:boolean}|nil`, optional) Additional configuration for the static element

### SceneInstance:addForeground(sprite, x, y, z)

Add a foreground element drawn after dynamic entities.

- **sprite** (`Sprite`) Sprite to draw
- **x** (`number`) World X coordinate
- **y** (`number`) World Y coordinate
- **z** (`number|nil`, optional) Render order (lower renders behind, default 100)

### SceneInstance:getEntityAt(worldX, worldY, ignoreId)

Return entity id at world coordinates (or nil).

- **worldX** (`number`) World X coordinate
- **worldY** (`number`) World Y coordinate
- **ignoreId** (`number|nil`, optional) Entity ID to ignore (optional)

- **returns** (`number|nil`) ID of the entity at the given coordinates, or nil if none

### SceneInstance:getDistance(id1, id2)

Get Euclidean distance between two entities (by id).

- **id1** (`number`) Entity ID of the first entity
- **id2** (`number`) Entity ID of the second entity

- **returns** **distance** (`number`) Distance between the two entities, or 9999 if either entity doesn't exist or lacks a `pos` component

### SceneInstance:queryRect(x, y, w, h, layerMask)

Query dynamic entities whose collider intersects rect.

- **x** (`number`) World X coordinate of the rect
- **y** (`number`) World Y coordinate of the rect
- **w** (`number`) Width of the rect
- **h** (`number`) Height of the rect
- **layerMask** (`number|nil`, optional) Collision layer bitmask to filter entities (optional)

- **returns** (`number[]`) List of entity IDs whose colliders intersect the given rect and match the layer mask

### SceneInstance:getUIAt(screenX, screenY)

Return UI element name at screen coordinates or nil.

- **screenX** (`number`) Screen X coordinate
- **screenY** (`number`) Screen Y coordinate

- **returns** **ui** (`string|nil`) Name of the UI element at the given screen coordinates, or nil if none

### SceneInstance:castRay(startX, startY, targetX, targetY, maxDist, ignoreId, layerMask)

Cast a ray and return hit info: (hit:boolean, x:number, y:number, entityId?:number)

- **startX** (`number`) Starting X coordinate of the ray
- **startY** (`number`) Starting Y coordinate of the ray
- **targetX** (`number`) Target X coordinate of the ray
- **targetY** (`number`) Target Y coordinate of the ray
- **maxDist** (`number|nil`, optional) Maximum distance to check along the ray (optional, default 100)
- **ignoreId** (`number|nil`, optional) Entity ID to ignore during the raycast (optional)
- **layerMask** (`number|nil`, optional) Collision layer bitmask to filter entities during the raycast (optional)

- **returns** **hit** (`boolean, number, number, number|nil`) Whether the ray hit an obstacle, the X and Y coordinates of the hit or end point, and the ID of the hit entity (if applicable)

### SceneInstance:hasLOS(ax, ay, bx, by, cw, ch, ignoreId, layerMask)

Line-of-sight check between two cells (Bresenham-based).

- **ax** (`number`) Starting X coordinate
- **ay** (`number`) Starting Y coordinate
- **bx** (`number`) Target X coordinate
- **by** (`number`) Target Y coordinate
- **cw** (`number|nil`, optional) Width of the area to check around the line (optional, default 1)
- **ch** (`number|nil`, optional) Height of the area to check around the line (optional, default 1)
- **ignoreId** (`number|nil`, optional) Entity ID to ignore during the LOS check (optional)
- **layerMask** (`number|nil`, optional) Collision layer bitmask to filter entities during the LOS check (optional)

- **returns** **hasLOS** (`boolean`) True if there is a clear line of sight between the two points, false if blocked by any obstacle

### SceneInstance:isAreaBlocked(x, y, w, h, ignoreId, layerMask)

Check whether an axis-aligned area is blocked by tiles/statics/dynamics.

- **x** (`number`) World X coordinate of the area
- **y** (`number`) World Y coordinate of the area
- **w** (`number`) Width of the area
- **h** (`number`) Height of the area
- **ignoreId** (`number|nil`, optional) Entity ID to ignore during the check (optional)
- **layerMask** (`number|nil`, optional) Collision layer bitmask to filter entities during the check (optional)

- **returns** **isBlocked** (`boolean, string|number|nil, number|nil`) True if the area is blocked, the type of obstacle ("tile", "static", or entity ID), and for slopes/platforms the Y coordinate of the ground

### SceneInstance:addTrigger(x, y, w, h, onEnter, onExit)

Add a trigger zone with enter/exit callbacks.

- **x** (`number`) World X coordinate of the trigger zone
- **y** (`number`) World Y coordinate of the trigger zone
- **w** (`number`) Width of the trigger zone
- **h** (`number`) Height of the trigger zone
- **onEnter** (`fun(id:number)|nil`, optional) Callback function that is called when an entity enters the trigger zone. Receives the entity ID as an argument. Can be nil if no callback is needed.
- **onExit** (`fun(id:number)|nil`, optional) Callback function that is called when an entity exits the trigger zone. Receives the entity ID as an argument. Can be nil if no callback is needed.

### SceneInstance:loadUI(path, x, y)

Load OUI file and add elements to UI.

- **path** (`string`) Path to the OUI file to load
- **x** (`number|nil`, optional) Optional X offset to apply to all loaded UI elements (default 0)
- **y** (`number|nil`, optional) Optional Y offset to apply to all loaded UI elements (default 0)

### SceneInstance:unloadUI(path)

Unload OUI elements from UI by path.

- **path** (`string`) Path to the OUI file to unload (must match the path used in loadUI)

### SceneInstance:addUI(name, type, x, y, config)

Add a UI element (proxy to ui module).

- **name** (`string`) Unique name for the UI element
- **type** (`string`) Type of the UI element (e.g., "text", "image", "button")
- **x** (`number`) Screen X coordinate
- **y** (`number`) Screen Y coordinate
- **config** (`table|nil`, optional) Additional configuration for the UI element (e.g., text content, sprite path, size, etc.)

- **returns** **element** (`table`) The created UI element, or nil if creation failed (e.g., due to duplicate name)

### SceneInstance:updateUI(name, config)

Update a UI element configuration.

- **name** (`string`) Unique name of the UI element to update
- **config** (`table`) New configuration for the UI element (e.g., text content, sprite path, size, etc.)

### SceneInstance:bindHUD(name, fn)

Bind a HUD updater function to a UI element name. The function is called
every frame from the scene update loop and receives the scene instance.

- **name** (`string`) Name of the UI element this HUD callback is associated with (for organizational purposes, not used for lookup)
- **fn** (`fun(scene:SceneInstance, dt:number)`) Function that updates the HUD element. Receives the scene instance and delta time as arguments.

- **returns** **id** (`number`) Unique ID for the bound HUD callback, which can be used to unbind it later

### SceneInstance:unbindHUD(id)

Unbind a previously bound HUD updater by id.

- **id** (`number`) Unique ID of the HUD callback to unbind (returned from bindHUD)

### SceneInstance:addSystem(filter, fn)

Register an update system. `filter` is an array of component names.

- **filter** (`string[]`) Array of component names that an entity must have to be included in this system's update calls
- **fn** (`fun(dt:number, entities:number[], components:table)`) Function that updates entities matching the filter. Receives delta time, list of entity IDs, and a components table for accessing component data.

### SceneInstance:attach(id, component, data)

Attach component to entity and mark z-order dirty for render-relevant components.

- **id** (`number`) Unique ID of the entity
- **component** (`string`) Name of the component to attach
- **data** (`any`) Data associated with the component

### SceneInstance:despawn(id)

Despawn entity and mark affected rows for restoration.

- **id** (`number`) Unique ID of the entity to despawn

### SceneInstance:update(dt)

Update scene systems and user `onUpdate` hook.

- **dt** (`number`) Delta time since last update (in seconds)

### SceneInstance:draw()

Draw scene: static layers, entities, foreground and UI.
