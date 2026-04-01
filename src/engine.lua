-- Obsidian Engine core
local Engine = {}

local FPS = 20
local FRAME_TIME = 1 / FPS

local updateCallbacks = {}
local renderCallbacks = {}
local eventCallbacks = {}
local running = false
local activeScene = nil
local manualViewport = false
local designW, designH = nil, nil
local transitionData = nil

local lastDeltaTime = 0
local dtHistory = {}
local dtHistorySize = 10

local currentFPS = 0
local frames = 0
local timer = os.clock()

Engine.ecs = require("core.ecs")
Engine.scene = require("core.scene")
Engine.thread = require("core.thread")
Engine.buffer = require("core.buffer")
Engine.input = require("core.input")
Engine.loader = require("core.loader")
Engine.inputMapper = require("core.input_mapper")
Engine.ui = require("core.ui")
Engine.tween = require("core.tween")
Engine.event = require("core.event")
Engine.logger = require("core.logger")
Engine.math = require("core.math")
Engine.physics = require("core.physics")
Engine.audio = require("core.audio")
Engine.ai = require("core.ai")
Engine.pathfinding = require("core.pathfinding")
Engine.serialization = require("core.serialization")
Engine.network = require("core.network")
Engine.storage = require("core.storage")
Engine.particles = require("core.particles")
local debug       = require("core.debug")
local errorModule = require("core.error")

local _luaDebug = _G and _G.debug

local function tracebackHandler(e)
    return (_luaDebug and _luaDebug.traceback)
        and _luaDebug.traceback(tostring(e), 2)
        or  tostring(e)
end

-- Wire the thread error handler so uncaught coroutine errors reach the panic screen.
-- This is set at module load time so it applies to all threads started by the engine.
Engine.thread.errorHandler = function(err)
    errorModule.report(err)
    running = false
end

function Engine.onError(fn)
    errorModule.handler = fn
end

function Engine._reportError(msg, trace)
    errorModule.report(msg, trace)
    running = false
end

function Engine.onUpdate(fn)
    table.insert(updateCallbacks, fn)
end

function Engine.onRender(fn)
    table.insert(renderCallbacks, fn)
end

function Engine.onEvent(fn)
    table.insert(eventCallbacks, fn)
end

function Engine.setScene(scene)
    if activeScene and activeScene.onUnload then
        activeScene:onUnload()
    end

    Engine.tween.stopAll()
    errorModule._shouldStop = false
    activeScene = scene

    if activeScene and activeScene.onLoad then
        activeScene:onLoad()
    end

    require("core.logger").info("Scene changed: " .. (activeScene.name or "Unnamed"))
end

function Engine.transition(targetScene, duration)
    transitionData = {
        target = targetScene,
        duration = duration or 1,
        elapsed = 0,
        stage = "out"
    }
end

function Engine.setViewport(w, h)
    manualViewport = true
    Engine.buffer.setSize(w, h)
    if activeScene then activeScene.staticDirty = true end
end

function Engine.setDesignResolution(w, h)
    debug.designW, debug.designH = w, h
end

function Engine.setMinResolution(w, h)
    debug.minW = w
    debug.minH = h
end

function Engine.getDesignResolution()
    return debug.designW, debug.designH
end

function Engine.getViewportOffset()
    if not debug.designW or not debug.designH then return 0, 0 end
    local tw, th = Engine.buffer.getSize()
    return math.floor((tw - debug.designW) / 2), math.floor((th - debug.designH) / 2)
end

function Engine.screenToViewport(sx, sy)
    local ox, oy = Engine.getViewportOffset()
    return sx - ox, sy - oy
end

function Engine.showDebug(state)
    debug.enabled = state
end

function Engine.start()
    running = true
    local lastTime = os.epoch("utc") / 1000

    Engine.thread.start(function()
        while running do
            local curW, curH = term.getSize()
            if debug.minW and debug.minH and (curW < debug.minW or curH < debug.minH) then
                debug.unsupportedResolution = true
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
                term.clear()
                term.setCursorPos(1, 1)
                term.write("Terminal size not supported.")
                term.setCursorPos(1, 2)
                term.write(string.format("Required: %dx%d | Current: %dx%d", debug.minW, debug.minH, curW, curH))
                os.sleep(0.2)
                lastTime = os.epoch("utc") / 1000
            else
                debug.unsupportedResolution = false
            local frameStart = os.epoch("utc")
            local currentTime = os.epoch("utc") / 1000
            local rawDelta = currentTime - lastTime
            lastTime = currentTime

            table.insert(dtHistory, rawDelta)
            if #dtHistory > dtHistorySize then
                table.remove(dtHistory, 1)
            end

            local sum = 0
            for _, dt in ipairs(dtHistory) do
                sum = sum + dt
            end
            lastDeltaTime = sum / #dtHistory

            Engine.tween.update(lastDeltaTime)

            if activeScene then activeScene:update(lastDeltaTime) end

            -- Scene may have signalled a handled error via errorModule._shouldStop
            if errorModule._shouldStop then running = false; break end

            for _, fn in ipairs(updateCallbacks) do
                fn(lastDeltaTime)
            end
            debug.updateTime = os.epoch("utc") - frameStart

            Engine.input._endFrame()

            local drawStart = os.epoch("utc")

            if transitionData and activeScene then activeScene.staticDirty = true end

            if activeScene then activeScene:draw() end

            for _, fn in ipairs(renderCallbacks) do
                fn()
            end

            if transitionData then
                transitionData.elapsed = transitionData.elapsed + lastDeltaTime
                local half = transitionData.duration / 2
                local progress = 0

                if transitionData.stage == "out" then
                    progress = math.min(1, transitionData.elapsed / half)
                    if transitionData.elapsed >= half then
                        Engine.setScene(transitionData.target)
                        transitionData.stage = "in"
                    end
                else
                    progress = math.max(0, 1 - (transitionData.elapsed - half) / half)
                    if transitionData.elapsed >= transitionData.duration then
                        transitionData = nil
                    end
                end

                if transitionData then
                    local tw, th = Engine.buffer.getSize()
                    local curtainH = math.floor((th / 2) * progress)
                    if curtainH > 0 then
                        Engine.buffer.drawRect(1, 1, tw, curtainH, " ", "0", "f") -- Oben (Schwarz: Back="f")
                        Engine.buffer.drawRect(1, th - curtainH + 1, tw, curtainH, " ", "0", "f") -- Unten (Schwarz: Back="f")
                    end
                end
            end

            Engine.buffer.present()
            debug.drawTime = os.epoch("utc") - drawStart

            frames = frames + 1
            local now = os.clock()
            if now - timer >= 1 then
                currentFPS = frames
                debug.fps = frames
                frames = 0
                timer = now
            end

            local workTime = (os.epoch("utc") - frameStart) / 1000
            local sleepTime = math.max(0, FRAME_TIME - workTime)

            local t = os.startTimer(sleepTime)
            repeat
                local _, tid = os.pullEvent("timer")
            until tid == t
            end
        end
    end)

    while running do
        local event = { os.pullEvent() }

        local consumed = false
        if activeScene and activeScene.ui then
            local ox, oy = Engine.getViewportOffset()
            consumed = activeScene.ui:handleEvent(event, ox, oy)
        end

        if consumed then
            if event[1] == "mouse_click" then Engine.input.clear() end
        else
            Engine.input._update(table.unpack(event))

            Engine.network._handleRawEvent(event)

            if activeScene and activeScene.onEvent then
                local ok, err = xpcall(activeScene.onEvent, tracebackHandler, event)
                if not ok then
                    Engine._reportError(err)
                end
            end
        end

        if event[1] == "key" and debug.enabled then
            if event[2] == keys.f1 then debug.showLogs = not debug.showLogs end
        end

        if event[1] == "term_resize" and not manualViewport then
            local nw, nh = term.getSize()
            Engine.buffer.setSize(nw, nh)
            if activeScene then activeScene.staticDirty = true end
        end

        for _, fn in ipairs(eventCallbacks) do
            fn(event)
        end

        Engine.thread.update(table.unpack(event))
    end
end

function Engine.getDeltaTime()
    return lastDeltaTime
end

function Engine.stop()
    running = false
end

function Engine.getFPS()
    return currentFPS
end

return Engine