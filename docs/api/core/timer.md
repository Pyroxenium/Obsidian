# timer

Obsidian Timer Module
Scheduling system for delayed and repeating callbacks
Injected by the bundler / init.lua loader; see src/init.lua.

## Types

### `TimerHandle`

```lua
TimerHandle = table Opaque handle returned by timer functions
```

### `TimerModule`

This module provides functions to schedule delayed and repeating callbacks, useful for timed events, animations, or game logic. Timers can be created, paused, resumed, and cancelled via their handles.

## Methods

### TimerModule.after(delay, callback)

Schedule a one-shot callback after a delay

- **delay** (`number`) Seconds to wait
- **callback** (`function`) Callback to execute

- **returns** **handle** (`TimerHandle`) Opaque handle for cancellation

### TimerModule.every(interval, callback, maxTimes)

Schedule a repeating callback

- **interval** (`number`) Seconds between each execution
- **callback** (`function`) Callback to execute
- **maxTimes** (`number|nil`, optional) Maximum executions (nil = infinite)

- **returns** **handle** (`TimerHandle`) Opaque handle for cancellation

### TimerModule.nextFrame(callback)

Schedule callback for next frame (shorthand for after(0, fn))

- **callback** (`function`) Callback to execute

- **returns** **handle** (`TimerHandle`) Opaque handle for cancellation

### TimerModule.cancel(handle)

Cancel a timer by handle

- **handle** (`TimerHandle`) Opaque handle returned by timer functions

- **returns** (`boolean`) True if timer was found and cancelled, false if not found

### TimerModule.pause(handle)

Pause a specific timer

- **handle** (`TimerHandle`) Opaque handle returned by timer functions

- **returns** (`boolean`) True if timer was found and paused, false if not found

### TimerModule.resume(handle)

Resume a specific timer

- **handle** (`TimerHandle`) Opaque handle returned by timer functions

- **returns** (`boolean`) True if timer was found and resumed, false if not found

### TimerModule.pauseAll()

Pause all active timers

### TimerModule.resumeAll()

Resume all paused timers

### TimerModule.cancelAll()

Cancel all active timers

### TimerModule.isActive(handle)

Check if a timer is still active

- **handle** (`TimerHandle`) Opaque handle returned by timer functions

- **returns** (`boolean`) True if timer is active, false if not

### TimerModule.count()

Get number of active timers

- **returns** (`number`) Count of active timers

### TimerModule.getRemaining(handle)

Get remaining time for a timer

- **handle** (`TimerHandle`) Opaque handle returned by timer functions

- **returns** (`number|nil`) Remaining time in seconds, or nil if timer not found

### TimerModule.getFiredCount(handle)

Get how many times a repeating timer has fired

- **handle** (`TimerHandle`) Opaque handle returned by timer functions

- **returns** (`number|nil`) Fired count, or nil if timer not found

### TimerModule.update(dt)

Update all timers (called by engine each frame)

- **dt** (`number`) Delta time in seconds

### TimerModule.getDebugInfo()

Get debug info for all active timers

- **returns** **info** (`table[]`) List of timer info tables with remaining time, interval, repeating, fired count, max times, and paused state
