local timer = {}
timer._timers = {}

-- Returns a new handle (unique table reference, same pattern as tween)
local function newHandle()
    return {}
end

--- Schedule a one-shot callback after `delay` seconds.
--- @param delay  number   Seconds to wait
--- @param fn     function Callback
--- @return handle  Opaque handle usable with timer.cancel()
function timer.after(delay, fn)
    local h = newHandle()
    table.insert(timer._timers, {
        handle   = h,
        elapsed  = 0,
        interval = delay,
        fn       = fn,
        repeat_  = false,
        times    = 1,
        fired    = 0,
    })
    return h
end

--- Schedule a repeating callback every `interval` seconds.
--- @param interval  number    Seconds between each call
--- @param fn        function  Callback
--- @param times     number|nil  Max number of times to fire (nil = infinite)
--- @return handle  Opaque handle usable with timer.cancel()
function timer.every(interval, fn, times)
    local h = newHandle()
    table.insert(timer._timers, {
        handle   = h,
        elapsed  = 0,
        interval = interval,
        fn       = fn,
        repeat_  = true,
        times    = times or math.huge,
        fired    = 0,
    })
    return h
end

--- Cancel a timer by its handle.
--- @param handle  The value returned by timer.after() or timer.every()
function timer.cancel(handle)
    for i = #timer._timers, 1, -1 do
        if timer._timers[i].handle == handle then
            table.remove(timer._timers, i)
            return
        end
    end
end

--- Cancel all active timers.
function timer.cancelAll()
    timer._timers = {}
end

--- Returns the number of currently active timers.
function timer.count()
    return #timer._timers
end

--- Called each frame by the engine with the smoothed delta time in seconds.
--- @param dt  number  Delta time in seconds
function timer.update(dt)
    for i = #timer._timers, 1, -1 do
        local t = timer._timers[i]
        t.elapsed = t.elapsed + dt
        if t.elapsed >= t.interval then
            t.elapsed = t.elapsed - t.interval
            t.fired   = t.fired + 1
            local ok, err = pcall(t.fn)
            if not ok then
                -- Eat the error silently so one bad timer doesn't crash everything;
                -- remove it to prevent repeated failures.
                table.remove(timer._timers, i)
            elseif not t.repeat_ or (t.times ~= math.huge and t.fired >= t.times) then
                table.remove(timer._timers, i)
            end
        end
    end
end

return timer
