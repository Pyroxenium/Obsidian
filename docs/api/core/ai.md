# ai

## Types

### `BrainTimer`

| Field | Type | Description |
| --- | --- | --- |
| kind | `"once"\|"repeat"` | "once" = one-shot, removed after firing; "repeat" = rescheduled after firing |
| interval *(optional)* | `number` | Interval for "repeat" timers (ignored for "once") |
| remaining | `number` | Seconds until the timer fires |
| fn | `any` | Callback function to call when the timer fires. Signature: `fn(brain)` |

### `BrainTransition`

| Field | Type | Description |
| --- | --- | --- |
| from | `string` | Source state name |
| to | `string` | Destination state name |
| cond | `any` | Condition function evaluated each frame. Signature: `fn(brain: Brain) -> bool`. If true, the transition triggers. |

### `BrainState`

| Field | Type | Description |
| --- | --- | --- |
| onEnter *(optional)* | `fun(self: Brain, fromState: string\|nil)` | Called when the state is entered. |
| onUpdate *(optional)* | `fun(self: Brain, dt: number): string\|nil` | Called every frame. Return a state name to transition. |
| onExit *(optional)* | `fun(self: Brain, toState: string\|nil)` | Called when the state is exited. |
| onDraw *(optional)* | `fun(self: Brain)` | Called every frame after update for debug drawing. |

### `Brain`

| Field | Type | Description |
| --- | --- | --- |
| current | `string\|nil` | Current state name (nil if not started) |
| previousState | `string\|nil` | Previous state name (for onEnter/onExit callbacks) |
| timer | `number` | Time spent in current state |
| memory | `table` | Free-form data storage |
| id | `number\|nil` | Entity ID (set during update) |
| scene | `SceneInstance\|nil` | Reference to current scene (set during update) |

## BrainTimer

### BrainTimer.new(kind, seconds, fn)

Create a new BrainTimer.

- **kind** (`"once"|"repeat"`) "once" = one-shot, removed after firing
- **seconds** (`number`) Seconds until the timer fires (and interval for "repeat")
- **fn** (`any`) Callback function to call when the timer fires. Signature: `fn(brain: Brain)`

- **returns** (`BrainTimer`) 

## BrainTransition

### BrainTransition.new(from, to, cond)

Create a new BrainTransition.

- **from** (`string`) Source state name
- **to** (`string`) Destination state name
- **cond** (`any`) Condition function evaluated each frame.

- **returns** (`BrainTransition`) 

## BrainState

### BrainState.new(onEnter, onUpdate, onExit, onDraw)

Create a new BrainState.

- **onEnter** (`fun(self: Brain, fromState: string|nil)`, optional) Called when the state is entered.
- **onUpdate** (`fun(self: Brain, dt: number): string|nil`, optional) Called
- **onExit** (`fun(self: Brain, toState: string|nil)`, optional) Called when the state is exited.
- **onDraw** (`fun(self: Brain)`, optional) Called every frame after update for debug drawing

- **returns** (`BrainState`) 

## Brain

### Brain.new(states, initialState, data)

Create a new Brain.

- **states** (`table<string, BrainState>`) State definitions
- **initialState** (`string`, optional) Starting state name (optional, call brain:start() later).
- **data** (`table`, optional) Optional arbitrary fields merged into the brain instance.

- **returns** (`Brain`) 

### Brain:addState(name, callbacks)

Dynamically add or replace a state.

- **name** (`string`) State name
- **callbacks** (`BrainState`) State callbacks (onEnter, onUpdate, onExit, onDraw)

### Brain:addTransition(from, to, condition)

Register an automatic conditional transition evaluated each frame before onUpdate.
Only the first matching transition fires per frame.

- **from** (`string`) Source state name
- **to** (`string`) Destination state name
- **condition** (`function`) Condition function evaluated each frame. Signature: `fn(brain) -> bool`. If true, the transition triggers.

### Brain:start(name)

Set the initial state and call its onEnter.  Safe to call multiple times
(resets the stack and restarts the machine).

- **name** (`string`) State name to start

### Brain:go(name)

Force an immediate transition to `name`.
Calls onExit on the old state and onEnter on the new state.

- **name** (`string`) State name to transition to

### Brain:push(name)

Push a new state onto the stack (suspends the current one).
The suspended state's onExit is called; the new state's onEnter is called.

- **name** (`string`) State name to push and transition to

### Brain:pop()

Pop the current state and resume the one below it.
Does nothing if the stack has only one entry.

### Brain:after(seconds, fn)

Schedule a one-shot callback after `seconds` in the current state.
Automatically cancelled on any state change.

- **seconds** (`number`) Seconds to wait before firing
- **fn** (`fun(brain: Brain)`) Callback function to call when the timer fires. Signature: `fn(brain)`

### Brain:every(seconds, fn)

Schedule a repeating callback every `seconds` while in the current state.
Automatically cancelled on any state change.

- **seconds** (`number`) Seconds between each callback
- **fn** (`fun(brain: Brain)`) Callback function to call each time the timer fires. Signature: `fn(brain)`

### Brain:update(dt)

Call every frame.  Evaluates auto-transitions, ticks timers, runs onUpdate.
onUpdate may return a state name to trigger a transition.

- **dt** (`number`) Delta time in seconds

### Brain:draw()

Call every frame (after update) to allow the current state to issue draw commands.

### Brain:is(name)

Returns true if the current state matches `name`.

- **name** (`string`) State name to check

- **returns** **state** (`boolean`) True if current state is `name`

### Brain:was(name)

Returns true if the previous state matches `name`.

- **name** (`string`) State name to check

- **returns** **state** (`boolean`) True if previous state is `name`

### Brain:timeInState()

Returns seconds spent in the current state.

- **returns** **time** (`number`) Seconds spent in the current state

### Brain:stackDepth()

Returns the push/pop stack depth.

- **returns** **depth** (`number`) Depth of the pushdown stack (number of states, including the current one)

### Brain:stateCount()

Returns the number of registered states.

- **returns** **count** (`number`) Number of registered states

## AIModule

### ai.canSee(id, targetId, scene, maxDist, layerMask)

Returns true if entity `id` has line-of-sight to `targetId`.

- **id** (`number`) Observer entity ID
- **targetId** (`number`) Target entity ID
- **scene** (`SceneInstance`) Active scene
- **maxDist** (`number`, optional) Optional max distance (world units)
- **layerMask** (`number`, optional) Optional collision layer bitmask

- **returns** **canSee** (`boolean`) True if `id` can see `targetId`

### ai.canHear(id, targetId, scene, maxDist)

Returns true if entity `id` is within `maxDist` of `targetId` (no raycast — cheap).

- **id** (`number`) 
- **targetId** (`number`) 
- **scene** (`SceneInstance`) 
- **maxDist** (`number`) 

- **returns** **canHear** (`boolean`) True if `id` can hear `targetId`

### ai.nearest(id, scene, tag, maxDist)

Returns the entity ID and distance of the nearest entity with `tag`,
within `maxDist`, excluding `id` itself.  Returns nil, nil if none found.
Assumes scene.components.tags[id] is a set-table: { tagName = true }.

- **id** (`number`) Observer entity ID
- **scene** (`SceneInstance`) Active scene
- **tag** (`string`, optional) If nil, searches all entities with a position.
- **maxDist** (`number`, optional) Search radius (infinite if nil)

- **returns** (`number|nil`) id, number|nil distance

### ai.system(scene)

Returns an ECS system function that drives all Brain components.
Sets brain.id and brain.scene each frame so callbacks can access them.

- **scene** (`SceneInstance`) Active scene (passed to callbacks via brain.scene)

- **returns** (`fun(dt:number, ids:number[], components:table)`) 
