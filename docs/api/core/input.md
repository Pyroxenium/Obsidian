# input

## Types

### `InputModule`

| Field | Type | Description |
| --- | --- | --- |
| keysDown | `table<number, boolean>` | Keys currently held down |
| keysDownPrevious | `table<number, boolean>` | Keys held down in the previous frame |
| mouseDown | `table<number, boolean>` | Mouse buttons currently held down |
| mouseDownPrevious | `table<number, boolean>` | Mouse buttons held down in the previous frame |
| mouseX | `number` | Current mouse X position |
| mouseY | `number` | Current mouse Y position |

## Methods

### input.processEvent(event, ...)

Process a raw input event.
This is called by the engine when an input event occurs. It updates internal state and triggers any relevant hooks.

- **event** (`string`) The event type (e.g. "key", "key_up", "mouse_click", etc.)
- **...** (`any`) Event-specific parameters (e.g. key code, mouse button, coordinates)

### input.clear()

Clear all input state (useful when switching scenes).

### input.isKeyDown(key)

Check if a key is currently held down.

- **key** (`number|string`) Key code or key name

- **returns** (`boolean`) True if the key is currently down

### input.isJustPressed(key)

True if key pressed this frame (was not down previous frame).

- **key** (`number|string`) Key code or key name

- **returns** (`boolean`) True if the key was just pressed this frame

### input.isJustReleased(key)

True if key was released this frame.

- **key** (`number|string`) Key code or key name

- **returns** (`boolean`) True if the key was just released this frame

### input.isMouseDown(button)

Check if a mouse button is currently down.

- **button** (`number`) Mouse button index (1 = left, 2 = right, 3 = middle)

- **returns** (`boolean`) True if the mouse button is currently down

### input.isMouseJustPressed(button)

True if mouse button pressed this frame.

- **button** (`number`) Mouse button index (1 = left, 2 = right, 3 = middle)

- **returns** (`boolean`) True if the mouse button was just pressed this frame

### input.isMouseJustReleased(button)

True if mouse button was released this frame.

- **button** (`number`) Mouse button index (1 = left, 2 = right, 3 = middle)

- **returns** (`boolean`) True if the mouse button was just released this frame

### input.getMousePos()

Get current mouse position.

- **returns** (`number`) x, number y Current mouse coordinates

### input.onKey(key, handler, opts)

Register a handler for a key press. Returns a numeric id.
`key` may be a number (keycode), a string key name, or a table of such values.

- **key** (`number|string|table`) Key code, key name, or array of codes/names to bind
- **handler** (`fun(key:any, info:table)`) Function to call when the key is pressed. Receives the normalized key code and an info table with an `event` field ("pressed" or "repeat").
- **opts** (`table`, optional) Optional settings

- **returns** **id** (`number`) Numeric ID for the registered hook, used for unregistration

### input.offKey(id)

Unregister a key hook by id.

- **id** (`number`) ID of the hook to unregister (returned by onKey)

### input.onCombo(keys, handler, opts)

Register a simultaneous combo (array of keys). Returns id.

- **keys** (`table`) Array of key codes or key names that must be held simultaneously to trigger
- **handler** (`fun(keys:table)`) Function to call when the combo is activated. Receives an array of the normalized key codes.
- **opts** (`table`, optional) Optional settings

- **returns** **id** (`number`) Numeric ID for the registered combo hook, used for unregistration

### input.offCombo(id)

Unregister a combo hook by id.

- **id** (`number`) ID of the combo hook to unregister (returned by onCombo)

### input.clearHooks()

Remove all registered hooks.
