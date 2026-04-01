local Thread = {}

local threads = {}
local nextId  = 1

Thread.errorHandler = nil

local function tracebackHandler(e)
    local d = _G and _G.debug
    return (d and d.traceback) and d.traceback(tostring(e), 2) or tostring(e)
end

function Thread.start(fn)
    local co = coroutine.create(function(...)
        local ok, err = xpcall(fn, tracebackHandler, ...)
        if not ok then
            if Thread.errorHandler then
                Thread.errorHandler(err)
            else
                print("[Thread] Uncaught error: " .. tostring(err))
            end
        end
    end)
    local id = nextId
    nextId = nextId + 1
    threads[id] = { co = co, status = "running" }
    return id
end

function Thread.stop(id)
    threads[id] = nil
end

function Thread.getAll()
    return threads
end

function Thread.update(...)
    local event = { ... }
    for id, t in pairs(threads) do
        if coroutine.status(t.co) ~= "dead" then
            if t.filter == event[1] or t.filter == nil then
                local ok, result = coroutine.resume(t.co, table.unpack(event))
                if not ok then
                    -- Fallback: xpcall wrapper should catch everything first,
                    -- but handle raw coroutine errors just in case.
                    if Thread.errorHandler then
                        Thread.errorHandler(result)
                    else
                        print("[Thread] Error in Thread " .. id .. ": " .. tostring(result))
                    end
                    threads[id] = nil
                else
                    t.filter = result
                end
            end
        else
            threads[id] = nil
        end
    end
end

return Thread
