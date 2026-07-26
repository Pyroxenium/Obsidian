# input_mapper

## Types

### `InputMapperModule`

| Field | Type | Description |
| --- | --- | --- |
| mappings | `table<string, (number\|string)[]>` | Mapping of action names to lists of keys |

## Methods

### InputMapper.bind(actionName, keysTable)

Bind an action name to one or more keys.

- **actionName** (`string`) Name of the action to bind (e.g. "jump", "moveLeft")
- **keysTable** (`number|string|table`) A key code, key name, or list of key codes/names to bind to the action

### InputMapper.isActive(actionName)

Check whether an action mapping is currently active (any bound key down).

- **actionName** (`string`) Name of the action to check (e.g. "jump", "moveLeft")

- **returns** (`boolean`) True if any key bound to the action is currently pressed, false otherwise

### InputMapper.loadDefaultWASD()

Populate standard WASD bindings (calls `InputMapper.bind` internally).
