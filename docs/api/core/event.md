# event

## Types

### `EventEmitter`

EventEmitter — instanced event bus.
Create a new bus with EventEmitter.new().
Each Engine and each Scene owns one bus:
  Engine.event   → global, always active
  scene.event    → scene-local, only forwarded when the scene is active

## Methods

### EventEmitter.new()

Create a new EventEmitter instance.

- **returns** (`EventEmitter`) 

### EventEmitter:on(name, fn)

Subscribe to an event.

- **name** (`string`) event name
- **fn** (`function`) event handler callback

- **returns** (`function`) Unsubscribe call to remove this listener

### EventEmitter:once(name, fn)

Subscribe to an event exactly once; auto-removes after first call.

- **name** (`string`) event name
- **fn** (`function`) event handler callback

- **returns** (`function`) Unsubscribe call to remove this listener

### EventEmitter:emit(name, ...)

Emit an event, calling all registered listeners.
Errors in listeners are caught and logged so one bad handler cannot
break the chain.

- **name** (`string`) event name
- **...** (`any`) additional arguments to pass to listeners

### EventEmitter:off(name)

Remove all listeners for a specific event name.

- **name** (`string`) event name

### EventEmitter:clear()

Remove all listeners on this emitter.
