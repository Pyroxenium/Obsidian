local Event = {}
local listeners = {}
local logger = require("core.logger")

function Event.on(eventName, callback)
    if not listeners[eventName] then
        listeners[eventName] = {}
    end

    local id = {}
    listeners[eventName][id] = callback

    return function()
        if listeners[eventName] then
            listeners[eventName][id] = nil
        end
    end
end

function Event.once(eventName, callback)
    local unsubscribe
    unsubscribe = Event.on(eventName, function(...)
        unsubscribe()
        callback(...)
    end)
    return unsubscribe
end

-- Removes all listeners for an event.
function Event.offAll(eventName)
    listeners[eventName] = nil
end

-- Backward-compatible alias.
Event.off = Event.offAll

function Event.emit(eventName, ...)
    if listeners[eventName] then
        for id, callback in pairs(listeners[eventName]) do
            local ok, err = pcall(callback, ...)
            if not ok then
                logger.error(string.format("Event '%s' failed: %s", eventName, tostring(err)))
            end
        end
    end
end

return Event