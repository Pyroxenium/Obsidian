# logger

## Types

### `LoggerModule`

Obsidian Logger Module
Provides logging functionality with different levels (info, warn, error, debug).

| Field | Type | Description |
| --- | --- | --- |
| history | `table<number, { level:string, text:string, color:string }>` | Buffered log history entries |
| maxHistory | `number` | Maximum number of log entries to keep in history |
| logFile | `string` | Path to the log file |

## Methods

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
