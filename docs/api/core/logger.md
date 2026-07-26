# logger

## Types

### `LogLevel`

Obsidian Logger Module
Provides logging functionality with different levels (info, warn, error, debug).

```lua
LogLevel = "debug"|"info"|"warn"|"error"|"off"
```

### `LoggerModule`

| Field | Type | Description |
| --- | --- | --- |
| history | `table<number, { level:string, text:string, color:string }>` | Buffered log history entries |
| maxHistory | `number` | Maximum number of log entries to keep in history |
| logFile | `string` | Path to the log file |
| level | `LogLevel` | Lowest level that is recorded; "off" silences the logger |
| fileEnabled | `boolean` | Whether entries are also written to `logFile` |

## Methods

### logger.setLevel(level)

Set the lowest level that is recorded.

- **level** (`LogLevel`) "debug", "info", "warn", "error", or "off"

### logger.setFileEnabled(enabled)

Enable or disable writing entries to the log file. History and the console
hook are unaffected.

- **enabled** (`boolean`) 

### logger.info(msg)

Log an info-level message.

- **msg** (`any`) 

### logger.warn(msg)

Log a warn-level message.

- **msg** (`any`) 

### logger.error(msg)

Log an error-level message.

- **msg** (`any`) 

### logger.debug(msg)

Log a debug-level message.

- **msg** (`any`) 

### logger.getHistory()

Return the buffered log history.

- **returns** (`table`) 
