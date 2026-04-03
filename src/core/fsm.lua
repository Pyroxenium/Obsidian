--- Obsidian FSM — Finite State Machine
-- Fully instanced: each call to fsm.new() returns an independent machine.
-- No global state; no engine update hook required.
--
-- Usage:
--   local m = Engine.fsm.new()
--   m:addState("idle", {
--       onEnter  = function(fsm, prev) end,
--       onExit   = function(fsm, next) end,
--       onUpdate = function(fsm, dt)   end,
--       onDraw   = function(fsm)       end,
--   })
--   m:addTransition("idle", "walk", function(fsm) return fsm.speed > 0 end)
--   m:start("idle")
--   -- each frame:
--   m:update(dt)
--   m:draw()

local fsm = {}
fsm.__index = fsm

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------
function fsm.new(data)
    local self = setmetatable({}, fsm)
    self._states      = {}        -- [name] = { onEnter, onExit, onUpdate, onDraw }
    self._transitions = {}        -- { from, to, condition }[]
    self._stack       = {}        -- push/pop stack (top = current)
    self.current      = nil       -- name of current state (string)
    self._started     = false

    -- Optional: arbitrary user data attached to the FSM instance.
    -- Useful so callbacks can read/write shared context via the `fsm` arg.
    if data then
        for k, v in pairs(data) do self[k] = v end
    end

    return self
end

-- ---------------------------------------------------------------------------
-- State registration
-- ---------------------------------------------------------------------------

--- Register a state.
--- @param name      string
--- @param callbacks table  Any combination of onEnter/onExit/onUpdate/onDraw
function fsm:addState(name, callbacks)
    assert(type(name) == "string", "FSM state name must be a string")
    self._states[name] = callbacks or {}
end

--- Register an automatic conditional transition.
--- Evaluated in registration order during update() BEFORE onUpdate runs.
--- @param from      string
--- @param to        string
--- @param condition function(fsm) -> bool
function fsm:addTransition(from, to, condition)
    table.insert(self._transitions, { from = from, to = to, cond = condition })
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

--- Set the initial state and call its onEnter.  Must be called before update().
--- @param name  string  Initial state name
function fsm:start(name)
    assert(self._states[name], "FSM: unknown state '" .. tostring(name) .. "'")
    self.current  = name
    self._stack   = { name }
    self._started = true
    local s = self._states[name]
    if s.onEnter then s.onEnter(self, nil) end
end

--- Force an immediate transition to `name`, ignoring any conditions.
--- Calls onExit on the old state and onEnter on the new state.
--- @param name  string
function fsm:go(name)
    assert(self._states[name], "FSM: unknown state '" .. tostring(name) .. "'")
    if name == self.current then return end
    local prev = self.current
    -- exit old
    if prev then
        local old = self._states[prev]
        if old.onExit then old.onExit(self, name) end
    end
    -- update stack top
    self._stack[#self._stack] = name
    self.current = name
    -- enter new
    local new = self._states[name]
    if new.onEnter then new.onEnter(self, prev) end
end

--- Push a new state onto the stack.
--- The previous state's onExit is called with `"push"` as the next-state hint.
--- @param name  string
function fsm:push(name)
    assert(self._states[name], "FSM: unknown state '" .. tostring(name) .. "'")
    local prev = self.current
    if prev then
        local old = self._states[prev]
        if old.onExit then old.onExit(self, name) end
    end
    table.insert(self._stack, name)
    self.current = name
    local new = self._states[name]
    if new.onEnter then new.onEnter(self, prev) end
end

--- Pop the current state and resume the previous one.
--- Does nothing if the stack has only one entry.
function fsm:pop()
    if #self._stack <= 1 then return end
    local prev = self.current
    local old  = self._states[prev]
    table.remove(self._stack)
    local next = self._stack[#self._stack]
    if old.onExit then old.onExit(self, next) end
    self.current = next
    local new = self._states[next]
    if new.onEnter then new.onEnter(self, prev) end
end

-- ---------------------------------------------------------------------------
-- Per-frame update & draw
-- ---------------------------------------------------------------------------

--- Call every frame with the smoothed delta time.
--- Evaluates auto-transitions first, then calls onUpdate on the active state.
--- @param dt  number  Delta time in seconds
function fsm:update(dt)
    if not self._started or not self.current then return end

    -- Check auto-transitions in order
    for _, tr in ipairs(self._transitions) do
        if tr.from == self.current and tr.cond(self) then
            self:go(tr.to)
            break  -- only one transition per frame
        end
    end

    -- Run update on (possibly new) current state
    local s = self._states[self.current]
    if s and s.onUpdate then s.onUpdate(self, dt) end
end

--- Call every frame after update to allow states to issue draw commands.
function fsm:draw()
    if not self._started or not self.current then return end
    local s = self._states[self.current]
    if s and s.onDraw then s.onDraw(self) end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Returns true if the current state matches `name`.
--- @param name  string
function fsm:is(name)
    return self.current == name
end

--- Returns how many states are registered.
function fsm:stateCount()
    return #(function()
        local n = 0
        for _ in pairs(self._states) do n = n + 1 end
        return n
    end)()
end

--- Returns the depth of the push/pop stack.
function fsm:stackDepth()
    return #self._stack
end

-- Module-level factory (so require("core.fsm").new() works)
return fsm
