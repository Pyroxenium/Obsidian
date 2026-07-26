# tween

## Types

### `TweenHandle`

```lua
TweenHandle = table Opaque handle for tween control
```

### `EasingFunction`

```lua
EasingFunction = fun(t:number):number Easing function that takes normalized time (0.0 - 1.0) and returns eased value (0.0 - 1.0)
```

### `TweenEntry`

Tween entry structure

| Field | Type | Description |
| --- | --- | --- |
| handle | `TweenHandle` | Opaque handle for control |
| target | `table` | Object being tweened |
| duration | `number` | Tween duration in seconds |
| elapsed | `number` | Time elapsed since tween started |
| startValues | `table` | Starting property values {key = value} |
| endValues | `table` | Target property values {key = value} |
| easing | `EasingFunction` | Easing function to apply |
| onComplete | `function\|nil` | Optional callback to call when tween completes |
| delay | `number` | Optional delay before tween starts |
| loop | `boolean` | Whether to loop the tween indefinitely |
| pingpong | `boolean` | Whether to reverse direction on each loop |
| paused | `boolean` | Whether the tween is currently paused |

### `TweenModule`

This module provides functions to animate properties of tables over time with various easing functions. Useful for smooth transitions, animations, and timed effects. Tweens can be created, paused, resumed, cancelled, and completed via their handles.

| Field | Type | Description |
| --- | --- | --- |
| easing | `table<string, EasingFunction>` | Predefined easing functions |

## TweenEntry

### handle_methods:pause()

- Pause a tween by handle

- **returns** **isPaused** (`boolean`) True if tween was found and paused, false if not found

### handle_methods:resume()

Resume a paused tween

- **returns** **isPaused** (`boolean`) True if tween was found and resumed, false if not found

### handle_methods:cancel()

Cancel a tween by handle (onComplete not called)

- **returns** **isCancelled** (`boolean`) True if tween was found and cancelled, false if not found

### handle_methods:complete()

Complete a tween immediately (jumps to end, calls onComplete)

- **returns** **isCompleted** (`boolean`) True if tween was found and completed, false if not found

### handle_methods:isActive()

Check if a tween is active

- **returns** **isActive** (`boolean`) True if tween is active, false if not found

### handle_methods:isPaused()

Check if a tween is paused

- **returns** **isPaused** (`boolean`) True if tween is paused, false if not found or not paused

### handle_methods:getProgress()

Get tween progress (0.0 - 1.0)

- **returns** (`number|nil`) Progress value between 0.0 and 1.0, or nil if tween not found

### handle_methods:seek(progress)

Seek a tween to a given normalized progress (0.0 - 1.0) without completing

- **progress** (`number`) Normalized progress to seek to (0.0 - 1.0)

- **returns** **found** (`boolean`) True if tween was found and seeked, false if not found or invalid progress

## TweenModule

### TweenModule.to(target, duration, properties, easingFunc, onComplete)

Animate properties of a target object

- **target** (`table`) Object to animate
- **duration** (`number`) Animation duration in seconds
- **properties** (`table`) Target property values {key = value}
- **easingFunc** (`function|table|nil`, optional) Easing function or options table
- **onComplete** (`function|nil`, optional) Completion callback (if easingFunc is function)

- **returns** **handle** (`TweenHandle`) Opaque handle for control

### TweenModule.from(target, duration, fromProperties, options)

Animate from specific values to current values

- **target** (`table`) Object to animate
- **duration** (`number`) Animation duration in seconds
- **fromProperties** (`table`) Start property values {key = value}
- **options** (`table|nil`, optional) Options {easing, onComplete, delay, loop, pingpong}

- **returns** **handle** (`TweenHandle`) Opaque handle for control

### TweenModule.pause(handle)

Pause a tween by handle

- **handle** (`TweenHandle`) Opaque handle returned by tween functions

- **returns** **isPaused** (`boolean`) True if tween was found and paused, false if not found

### TweenModule.resume(handle)

Resume a paused tween

- **handle** (`TweenHandle`) Opaque handle returned by tween functions

- **returns** **isResumed** (`boolean`) True if tween was found and resumed, false if not found

### TweenModule.cancel(handle)

Cancel a tween by handle (onComplete not called)

- **handle** (`TweenHandle`) Opaque handle returned by tween functions

- **returns** **isCancelled** (`boolean`) True if tween was found and cancelled, false if not found

### TweenModule.stop(target)

Stop all tweens targeting a specific object (onComplete not called)

- **target** (`table`) Object whose tweens should be stopped

- **returns** **removed** (`number`) Count of tweens that were removed

### TweenModule.stopAll()

Stop all active tweens (onComplete not called)

### TweenModule.complete(handle)

Complete a tween immediately (jumps to end, calls onComplete)

- **handle** (`TweenHandle`) Opaque handle returned by tween functions

- **returns** **isCompleted** (`boolean`) True if tween was found and completed, false if not found

### TweenModule.seek(handle, progress)

Seek a tween to a given normalized progress (0.0 - 1.0) without completing

- **handle** (`TweenHandle`) Opaque handle returned by tween functions
- **progress** (`number`) Normalized progress to seek to (0.0 - 1.0)

- **returns** **found** (`boolean`) True if tween was found and seeked, false if not found or invalid progress

### TweenModule.getTweensForTarget(target)

Return a list of tween handles currently targeting `target`

- **target** (`table`) Object to check for active tweens

- **returns** **handles** (`TweenHandle[]`) List of tween handles targeting the specified object

### TweenModule.count()

Get number of active tweens

- **returns** (`number`) 

### TweenModule.isActive(handle)

Check if a tween is active

- **handle** (`TweenHandle`) Opaque handle returned by tween functions

- **returns** **isActive** (`boolean`) True if tween is active, false if not found

### TweenModule.isPaused(handle)

Check if a tween is paused

- **handle** (`TweenHandle`) Opaque handle returned by tween functions

- **returns** **isPaused** (`boolean`) True if tween is paused, false if not found

### TweenModule.getProgress(handle)

Get tween progress (0.0 - 1.0)

- **handle** (`TweenHandle`) Opaque handle returned by tween functions

- **returns** (`number|nil`) Progress value between 0.0 and 1.0, or nil if tween not found

### TweenModule.update(dt)

Update all tweens (called by engine each frame)

- **dt** (`number`) Delta time in seconds

### TweenModule.getDebugInfo()

Get debug info for all active tweens

- **returns** **info** (`table[]`) List of tween info tables with target, progress, duration, paused state, loop, and pingpong
