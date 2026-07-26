# pathfinding

Obsidian Engine: Pathfinding Module
Efficient A* implementation with Min-Heap and LOS smoothing.
Injected by the bundler / init.lua loader; see src/init.lua.

## Types

### `PathfindingModule`

The main pathfinding module with the `findPath` function.

| Field | Type | Description |
| --- | --- | --- |
| MAX_ITERATIONS | `number` | Maximum A* node expansions before giving up.  Raise for bigger maps. |

## Methods

### Pathfinding.findPath(scene, startPos, endPos, collider, ignoreId, layerMask, smooth, maxIterations)

Find a walkable path from `startPos` to `endPos` on `scene`.

- **scene** (`SceneInstance`) Active scene
- **startPos** (`Vec2`) World start position
- **endPos** (`Vec2`) World goal position
- **collider** (`table`, optional) { w, h } entity size (default {w=1,h=1})
- **ignoreId** (`number`, optional) Entity ID excluded from collision checks
- **layerMask** (`number`, optional) Collision layer bitmask
- **smooth** (`boolean`, optional) Apply LOS waypoint reduction (default true)
- **maxIterations** (`number`, optional) Max A* expansions before giving up (default Pathfinding.MAX_ITERATIONS)

- **returns** (`Vec2[]|nil`) Ordered waypoints start→goal, or nil if unreachable
