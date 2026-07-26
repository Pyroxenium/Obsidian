# error

## Types

### `ErrorModule`

| Field | Type | Description |
| --- | --- | --- |
| handler | `fun(msg: string)\|nil` | Custom error handler function (optional) |

## Methods

### Error.report(msg, trace)

Report an error through the configured handler or show panic screen.

- **msg** (`any`) 
- **trace** (`string`, optional) 

- **returns** (`nil`) 
