# thread

## Types

### `ThreadModule`

| Field | Type | Description |
| --- | --- | --- |
| errorHandler | `any\|nil` | Optional global error handler function for uncaught thread errors |

### `Thread`

Public Thread handle class with methods to control individual threads. The actual thread data is stored in the ThreadModule's internal threads table, and the handle provides a safe interface to interact with it.

| Field | Type | Description |
| --- | --- | --- |
| id | `number` | Unique thread ID |

## Thread

### thread:stop()

Stop the thread. Returns true if the thread was successfully stopped, false if it was not found.

- **returns** **success** (`boolean`) True if the thread was stopped, false if not found

### thread:isAlive()

Check if the thread is still alive (not dead). Returns false if the thread has finished or was stopped.

- **returns** **alive** (`boolean`) True if the thread is alive, false if dead or not found

### thread:getStatus()

Get the current status of the thread ("running", "suspended", "dead"). Returns nil if the thread is not found.

- **returns** **status** (`string|nil`) The current status of the thread, or nil if not found

### thread:yield(eventFilter)

Yield the current thread with an optional event filter. The thread will be resumed when an event matching the filter occurs (or on any event if filter is nil). Returns the event arguments when resumed.

- **eventFilter** (`any|nil`, optional) Optional event filter to yield on (e.g. "timer", "redstone", etc.). If nil, the thread will resume on any event.

- **returns** (`...`) The event arguments passed to coroutine.resume when the thread is resumed

## ThreadModule

### ThreadModule.start(fn)

Start a new thread running the given function. The function will be wrapped in error handling to catch uncaught errors. Returns a Thread handle object.

- **returns** (`Thread`) 

### ThreadModule.stop(idOrHandle)

Stop a thread by its ID or handle. Returns true if the thread was successfully stopped, false if it was not found.

- **idOrHandle** (`number|Thread`) The thread ID or handle to stop

- **returns** **success** (`boolean`) True if the thread was stopped, false if not found

### ThreadModule.getAll()

Returns a shallow copy of the active threads table (id → {co, status, filter}).
Note that the coroutines themselves cannot be safely exposed, so only the thread metadata is included. Use with caution as this is a snapshot and may not reflect the current state of threads.

- **returns** (`table`) A copy of the active threads table with thread metadata (id → {status,

### ThreadModule.count()

Returns the number of threads that are still alive.

- **returns** **count** (`number`) The number of alive threads

### ThreadModule.reset()

Resets the thread system by clearing all threads and resetting the ID counter. Use with caution as this will stop all active threads without cleanup.

### ThreadModule.yield(eventFilter)

Yield the current thread with an optional event filter. The thread will be resumed when an event matching the filter occurs (or on any event if filter is nil). Returns the event arguments when resumed.

- **eventFilter** (`any|nil`, optional) Optional event filter to yield on (e.g. "timer", "redstone", etc.). If nil, the thread will resume on any event.

- **returns** (`...`) The event arguments passed to coroutine.resume when the thread is resumed

### ThreadModule.update(...)

Internal function to update threads based on events. Should be called by the engine's main loop with the current event.

- **...** (`any`) The event arguments
