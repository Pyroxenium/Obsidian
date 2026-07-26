# camera

Obsidian Engine: Camera module
Provides a camera prototype used by scenes to follow entities, perform
world<->screen coordinate conversions, and apply simple screen-space
effects (shake, flash). Create instances with `camera.new(scene)`; methods
are available on the `CameraInstance` prototype.
Camera module. Manages a virtual camera position that maps world coordinates to screen coordinates.

## Types

### `CameraInstance`

Camera instance class. Each scene has one camera instance that drives its .camera vec2.

| Field | Type | Description |
| --- | --- | --- |
| lerpFactor | `number` | 0-1 smoothing factor for camera movement (default 0.1) |
| offsetX | `number` | Horizontal offset added to the camera position (useful for looking ahead of movement) |
| offsetY | `number` | Vertical offset added to the camera position |

## CameraModule

### camera.new(scene)

Create a new camera bound to a scene.

- **scene** (`SceneInstance`) The scene whose .camera vec2 will be driven

- **returns** (`CameraInstance`) 

## CameraInstance

### CameraInstance:follow(id, opts)

Follow an entity by its id.

- **id** (`number`) Entity id (must have a `pos` component or the component named via `comp`)
- **opts** (`table|nil`, optional) Optional settings

### CameraInstance:unfollow()

Stop following any entity.

### CameraInstance:setBounds(x1, y1, x2, y2)

Clamp the camera so it never shows world area outside the given rectangle.
Pass nil values to remove clamping.

- **x1** (`number`) Left bound in world units
- **y1** (`number`) Top bound in world units
- **x2** (`number`) Right bound in world units
- **y2** (`number`) Bottom bound in world units

### CameraInstance:clearBounds()

Remove world bounds.

### CameraInstance:setOffset(ox, oy)

Set a camera lead offset (useful for making the camera look ahead of movement).

- **ox** (`number`) Horizontal offset in world units
- **oy** (`number`) Vertical offset in world units

### CameraInstance:moveTo(wx, wy)

Snap the camera to an exact world position (no lerp this frame).

- **wx** (`number`) World X
- **wy** (`number`) World Y

### CameraInstance:pan(dx, dy)

Pan by a delta (adds to the current target position).

- **dx** (`number`) 
- **dy** (`number`) 

### CameraInstance:update(dt)

Advance the camera each frame.
Reads the followed entity's pos, evaluates the deadzone, lerps, clamps to
bounds, and writes the result into scene.camera.

- **dt** (`number`) Delta time in seconds

### CameraInstance:shake(intensity, duration)

Shake the camera with a given intensity and duration.

- **intensity** (`number`) Max pixel-offset per frame
- **duration** (`number`) Seconds the shake lasts

### CameraInstance:flash(color, duration)

Flash the screen with a solid color overlay for a short duration.

- **color** (`string`) CC blit color character (e.g. "e" = red)
- **duration** (`number`) Seconds the flash lasts

### CameraInstance:isShaking()

Whether a shake started with `shake()` is still running.

- **returns** (`boolean`) 

### CameraInstance:getShakeOffset()

Current shake displacement, to be added to the camera position when
rendering. Returns zero offsets while no shake is active.

- **returns** **shakeX** (`number`) World-space pixel offset this frame
- **returns** **shakeY** (`number`) World-space pixel offset this frame

### CameraInstance:isFlashing()

Whether a screen flash started with `flash()` is still running.

- **returns** (`boolean`) 

### CameraInstance:getFlashColor()

Colour the scene overlays while a flash is active.

- **returns** (`string`) CC blit color character

### CameraInstance:worldToScreen(wx, wy)

Convert a world position to screen (terminal character) position.
Accounts for the current camera and the engine's design-resolution letterbox offset.

- **wx** (`number`) World X
- **wy** (`number`) World Y

- **returns** **sx** (`number`) 1-based screen X character position
- **returns** **sy** (`number`) 1-based screen Y character position

### CameraInstance:screenToWorld(sx, sy)

Convert a screen (terminal) position back to world coordinates.

- **sx** (`number`) 1-based screen X character position
- **sy** (`number`) 1-based screen Y character position

- **returns** **wx** (`number`) World X
- **returns** **wy** (`number`) World Y

### CameraInstance:getPosition()

Read the camera's current world position (what the top-left corner maps to).

- **returns** **x** (`number`) 
- **returns** **y** (`number`) 
