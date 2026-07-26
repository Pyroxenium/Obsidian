# ui

## Types

### `UIContext`

| Field | Type | Description |
| --- | --- | --- |
| buf | `BufferInstance` |  |
| elements | `table<string, table>` |  |
| sorted | `table[]` |  |
| dirty | `boolean` |  |
| pressedElement | `table\|nil` |  |
| pressedAbsX | `number\|nil` |  |
| pressedAbsY | `number\|nil` |  |
| focusedElement | `table\|nil` |  |

## Methods

### UI.new(buf)

Create a new UI context bound to a Buffer instance.

- **buf** (`BufferInstance`) A Buffer.new() instance

- **returns** (`UIContext`) 
