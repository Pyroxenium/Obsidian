# math

Obsidian Engine: Math & Vector Module

## Types

### `MathModule`

The Math module provides utility functions and a Vec2 class for 2D vector math.

### `Vec2`

Vec2 class definition and operations

| Field | Type | Description |
| --- | --- | --- |
| x | `number` | The x component of the vector |
| y | `number` | The y component of the vector |

## MathModule

### Math.vec2(x, y)

Create a new 2D vector.

- **x** (`number`, optional) x component (default 0)
- **y** (`number`, optional) y component (default 0)

- **returns** (`Vec2`) Vec2 New vector instance

### Math.lerp(a, b, t)

Linear interpolation between two numbers.

- **a** (`number`) Starting value
- **b** (`number`) Ending value
- **t** (`number`) Interpolation factor (0-1)

- **returns** (`number`) Interpolated value

### Math.applyDamping(velocity, amount, dt)

Apply frame-rate independent damping to a velocity vector.

- **velocity** (`Vec2`) The velocity vector to apply damping to (mutated in place)
- **amount** (`number`) Damping strength (0-1)
- **dt** (`number`) Delta time in seconds

### Math.isVec2(v)

Checks if a value is a Vec2 instance.

- **v** (`any`) The value to check

- **returns** **isVec2** (`boolean`) True if the value is a Vec2, false otherwise

### Math.clamp(val, min, max)

Clamp a value between min and max.

- **val** (`number`) The value to clamp
- **min** (`number`) The minimum allowed value
- **max** (`number`) The maximum allowed value

- **returns** (`number`) The clamped value

### Math.dist(x1, y1, x2, y2)

Calculate distance between two points.

- **x1** (`number`) x coordinate of the first point
- **y1** (`number`) y coordinate of the first point
- **x2** (`number`) x coordinate of the second point
- **y2** (`number`) y coordinate of the second point

- **returns** **distance** (`number`) The distance between the two points

### Math.normalize(x, y)

Returns a normalised Vec2.  Returns zero-vec if length is 0.

- **x** (`number`) The x component of the vector
- **y** (`number`) The y component of the vector

- **returns** **normalized** (`Vec2`) The normalized vector

### Math.normalizeRaw(x, y)

Returns nx, ny, length as raw numbers (for callers that need the length too).

- **x** (`number`) The x component of the vector
- **y** (`number`) The y component of the vector

- **returns** **nx** (`number`) The normalized x component
- **returns** **ny** (`number`) The normalized y component
- **returns** **length** (`number`) The length of the vector

### Math.round(val)

- **val** (`number`) The value to round

- **returns** **rounded** (`number`) The rounded value

### Math.sign(val)

- **val** (`number`) The value to get the sign of

- **returns** **sign** (`number`) The sign of the value: 1 for positive, -1 for negative, 0 for zero

### Math.angleBetween(x1, y1, x2, y2)

Returns the angle in radians between two points.

- **x1** (`number`) x coordinate of the first point
- **y1** (`number`) y coordinate of the first point
- **x2** (`number`) x coordinate of the second point
- **y2** (`number`) y coordinate of the second point

- **returns** **angle** (`number`) The angle in radians between the two points

### Math.fromAngle(angle, length)

Create a vector from an angle and length.

- **angle** (`number`) The angle in radians
- **length** (`number`, optional) The length of the vector (default 1)

- **returns** (`Vec2`) The resulting vector

## Vec2

### Vector2:dist(other)

Calculate distance to another vector.

- **other** (`Vec2`) The other vector to measure distance to

- **returns** **distance** (`number`) The distance between this vector and the other

### Vector2:sqDist(other)

Calculate squared distance to another vector (faster, no sqrt).

- **other** (`Vec2`) The other vector to measure squared distance to

- **returns** **distance** (`number`) The squared distance between this vector and the other

### Vector2:len()

Returns the magnitude (length) of the vector.

- **returns** **length** (`number`) The length of the vector

### Vector2:sqLen()

Returns the squared magnitude of the vector.

- **returns** **length** (`number`) The squared length of the vector

### Vector2:normalize()

Returns a normalized (length=1) version of this vector.

- **returns** **normalized** (`Vec2`) The normalized vector, or zero vector if length is 0

### Vector2:lerp(other, t)

Returns a vector linearly interpolated between this and other.

- **other** (`Vec2`) The other vector to interpolate towards
- **t** (`number`) Interpolation factor (0-1)

- **returns** (`Vec2`) The interpolated vector

### Vector2:dot(other)

Dot product of two vectors.

- **other** (`Vec2`) The second vector to dot with

- **returns** (`number`) The dot product result

### Vector2:unpack()

Unpack vector into x, y.

- **returns** (`number`) x, number y

### Vector2:set(x, y)

Mutate: set vector components.

- **x** (`number`, optional) New x component (optional)
- **y** (`number`, optional) New y component (optional)

- **returns** **self** (`Vec2`) 

### Vector2:add(v)

Mutate: add another vector to this one.

- **v** (`Vec2`) The vector to add

- **returns** **self** (`Vec2`) 

### Vector2:mul(s)

Mutate: multiply this vector by a scalar.

- **s** (`number`) The scalar to multiply by

- **returns** **self** (`Vec2`) 

### Vector2:limit(max)

Mutate: Limit the length of this vector.

- **max** (`number`) The maximum length

- **returns** **self** (`Vec2`) 

### Vector2:cross(other)

2D cross product (scalar z-component: x1*y2 - y1*x2).

- **other** (`Vec2`) The second vector

- **returns** (`number`) The z-component of the cross product

### Vector2:clone()

Returns a new Vec2 with the same values.

- **returns** (`Vec2`) Vec2 The cloned vector

### Vector2:rotate(angle)

Non-mutating: Returns vector rotated by radians.

- **angle** (`number`) The angle in radians to rotate by

- **returns** (`Vec2`) Vec2 The rotated vector
