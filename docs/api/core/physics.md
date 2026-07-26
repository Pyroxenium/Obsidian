# physics

## Types

### `PhysicsBody`

This is a physics body configuration table.  It does not store state like position or velocity;

| Field | Type | Description |
| --- | --- | --- |
| mass | `number` | The mass of the object (0 or negative = infinite mass/unmovable) |
| bounciness | `number` | Elasticity from 0 (no bounce) to 1 (perfect reflection) |
| friction | `number` | Friction coefficient (0 to 1, exponential decay) |
| gravityScale | `number` | Multiplier for the global gravity |
| isKinematic | `boolean` | If true, the object is moved only by script, not by physics forces |
| useGravity | `boolean` | Whether gravity should be applied to this body |

### `PhysicsModule`

This is the main physics module with utility functions and an ECS system for integration.

| Field | Type | Description |
| --- | --- | --- |
| GRAVITY_VECTOR | `Vec2` | Default gravity vector (world units/s²). Change via Physics.setGravity(). |

## Methods

### Physics.gravity()

Returns a copy of the current gravity vector (immutable-safe).

- **returns** (`Vec2`) Current gravity vector

### Physics.setGravity(x, y)

Override the global gravity.

- **x** (`number`) Gravity X component (world units/s²)
- **y** (`number`) Gravity Y component (world units/s²)

### Physics.createBody(config)

Create a physics body configuration table.

- **config** (`{mass:number, bounciness:number, friction:number, gravityScale:number, isKinematic:boolean, useGravity:boolean}`, optional) Optional configuration parameters (see PhysicsBody fields)

- **returns** **body** (`PhysicsBody`) New physics body configuration

### Physics.resolveBounce(velocity, normal, bounciness)

Reflect `velocity` off a surface described by `normal`.
Mutates `velocity` in place and returns it.

- **velocity** (`Vec2`) Incoming velocity vector
- **normal** (`Vec2`) Surface normal (unit vector)
- **bounciness** (`number`, optional) 0 = no bounce, 1 = perfect elastic

- **returns** **vector** (`Vec2`) Resulting velocity vector after bounce

### Physics.resolveCollision(body1, vel1, body2, vel2, normal)

Resolve an impulse-based collision between two dynamic bodies.
Mutates vel1 and vel2 in place.

- **body1** (`PhysicsBody`) First body's physics configuration
- **vel1** (`Vec2`) Velocity of body1 before collision, modified in place to the post-collision velocity
- **body2** (`PhysicsBody`) Second body's physics configuration
- **vel2** (`Vec2`) Velocity of body2 before collision, modified in place to the post-collision velocity
- **normal** (`Vec2`) Collision normal pointing from body2 → body1

### Physics.applyImpulse(velocity, force, mass)

Apply a force or scalar impulse to `velocity`.

- **velocity** (`Vec2`) Velocity vector to be modified
- **force** (`Vec2|number`) Force vector or scalar
- **mass** (`number`, optional) Mass of the object (default 1.0)

### Physics.aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh)

Returns true if two axis-aligned bounding boxes overlap.
All values in world units.  x/y are the top-left corner.

- **ax** (`number`) X-coordinate of AABB A
- **ay** (`number`) Y-coordinate of AABB A
- **aw** (`number`) Width of AABB A
- **ah** (`number`) Height of AABB A
- **bx** (`number`) X-coordinate of AABB B
- **by** (`number`) Y-coordinate of AABB B
- **bw** (`number`) Width of AABB B
- **bh** (`number`) Height of AABB B

- **returns** (`boolean`) True if the AABBs overlap

### Physics.getAABBOverlap(ax, ay, aw, ah, bx, by, bw, bh)

Returns the collision normal (Vec2) and penetration depth (number) for two
overlapping AABBs.  normal points from B into A (push A out of B).
Returns nil, 0 if there is no overlap.

- **ax** (`number`) X-coordinate of AABB A
- **ay** (`number`) Y-coordinate of AABB A
- **aw** (`number`) Width of AABB A
- **ah** (`number`) Height of AABB A
- **bx** (`number`) X-coordinate of AABB B
- **by** (`number`) Y-coordinate of AABB B
- **bw** (`number`) Width of AABB B
- **bh** (`number`) Height of AABB B

- **returns** **normal** (`Vec2|nil`) Collision normal vector (unit vector) pointing from B into A, or nil if no collision
- **returns** **depth** (`number`) Penetration depth (overlap amount) along the collision normal, or 0 if no collision

### Physics.system(scene, steps)

Returns an ECS system function that applies gravity, friction, and
velocity integration to all entities that have `pos`, `vel`, and `body`
components.

- **scene** (`SceneInstance`) The scene to which the system will be added
- **steps** (`number`, optional) Sub-steps per frame (default 1). Higher values prevent tunneling for fast-moving objects.

- **returns** (`fun(dt:number, ids:number[], components:table)`) ECS system function to be added to the scene
