local sources, paths = {}, {}
sources["engine"] = [=[

local require = ...
local Engine = {}
Engine.VERSION = "1.0.0"
local config = {
    fps = 20,
    frameTime = 1 / 20,
    deltaHistorySize = 10,
}
local state = {
    running = false,
    activeScene = nil,
    manualViewport = false,
    consoleEnabled = true,
    lastDeltaTime = 0,
    deltaHistory = {},
    lastTime = 0,
    currentFPS = 0,
    frameCount = 0,
    fpsTimer = 0,
    transition = nil,
}
local callbacks = {
    update = {},
    render = {},
    event = {},
}
Engine.ecs = require("core.ecs")
Engine.scene = require("core.scene")
Engine.thread = require("core.thread")
local bufferModule = require("core.buffer")
Engine.buffer = bufferModule.new()
Engine.renderer = Engine.buffer
Engine.rgb = bufferModule.rgb
Engine.color = bufferModule.color
Engine.input = require("core.input")
Engine.loader = require("core.loader")
Engine.flimg = Engine.loader.flimg
Engine.inputMapper = require("core.input_mapper")
Engine.ui = require("core.ui")
Engine.tween = require("core.tween")
Engine.timer = require("core.timer")
Engine.camera = require("core.camera")
Engine.tilemap = require("core.tilemap")
Engine.event = require("core.event").new()
Engine.logger = require("core.logger")
Engine.math = require("core.math")
Engine.physics = require("core.physics")
Engine.audio = require("core.audio")
Engine.ai = require("core.ai")
Engine.pathfinding = require("core.pathfinding")
Engine.serialization = require("core.serialization")
Engine.network = require("core.network")
Engine.server = require("core.server")
Engine.storage = require("core.storage")
Engine.db = require("core.db")
Engine.particles = require("core.particles")
Engine.console = require("core.console")
Engine.error = require("core.error")
local debug = require("core.debug")
local errorModule = Engine.error
Engine.scene.setBuffer(Engine.buffer)
function Engine.addRenderLayer(name, zIndex)
    return Engine.buffer:addLayer(name, zIndex)
end
function Engine.getRenderLayer(name)
    return Engine.buffer:getLayer(name)
end
function Engine.removeRenderLayer(layerOrName)
    return Engine.buffer:removeLayer(layerOrName)
end
Engine.logger._consoleHook = function(text, fg)
    Engine.console.addLine(text, fg)
end
local function engineEmit(name, ...)
    Engine.event:emit(name, ...)
    if state.activeScene and state.activeScene.event then
        state.activeScene.event:emit(name, ...)
    end
end
Engine.network._emit = engineEmit
Engine.server._emit = engineEmit
Engine.thread.errorHandler = function(err)
    Engine.buffer:restorePalette()
    errorModule.report(err)
    state.running = false
end
local _luaDebug = _G and _G.debug
local function tracebackHandler(e)
    return (_luaDebug and _luaDebug.traceback)
        and _luaDebug.traceback(tostring(e), 2)
        or tostring(e)
end
function Engine.onError(fn)
    errorModule.handler = fn
end
function Engine._reportError(msg, trace)
    Engine.buffer:restorePalette()
    errorModule.report(msg, trace)
    state.running = false
end
function Engine.setFPS(fps)
    config.fps = fps
    config.frameTime = 1 / fps
end
function Engine.getTargetFPS()
    return config.fps
end
function Engine.getFPS()
    return state.currentFPS
end
function Engine.getDeltaTime()
    return state.lastDeltaTime
end
function Engine.onUpdate(fn)
    table.insert(callbacks.update, fn)
end
function Engine.onRender(fn)
    table.insert(callbacks.render, fn)
end
function Engine.onEvent(fn)
    table.insert(callbacks.event, fn)
end
function Engine.setScene(scene)
    if state.activeScene then
        if state.activeScene.event then
            state.activeScene.event:emit("unload")
        end
        if state.activeScene.onUnload then
            state.activeScene:onUnload()
        end
    end
    Engine.tween.stopAll()
    errorModule._shouldStop = false
    state.activeScene = scene
    Engine.scene.activeScene = scene
    if state.activeScene and state.activeScene.onLoad then
        state.activeScene:onLoad()
    end
    if state.activeScene and state.activeScene.event then
        state.activeScene.event:emit("load")
    end
    Engine.logger.info("Scene changed: " .. (state.activeScene.name or "Unnamed"))
end
function Engine.getScene()
    return state.activeScene
end
function Engine.transition(targetScene, duration)
    state.transition = {
        target = targetScene,
        duration = duration or 1,
        elapsed = 0,
        stage = "out"
    }
end
function Engine.isTransitioning()
    return state.transition ~= nil
end
function Engine.setViewport(w, h)
    state.manualViewport = true
    Engine.buffer:setSize(w, h)
    if state.activeScene then
        state.activeScene._staticDirty = true
    end
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
    if not debug.designW or not debug.designH then
        return 0, 0
    end
    local tw, th = Engine.buffer:getSize()
    return math.floor((tw - debug.designW) / 2),
           math.floor((th - debug.designH) / 2)
end
function Engine.screenToViewport(sx, sy)
    local ox, oy = Engine.getViewportOffset()
    return sx - ox, sy - oy
end
function Engine.showDebug(enabled, alwaysOnTop)
    debug.enabled = enabled
    if alwaysOnTop ~= nil then
        debug.alwaysOnTop = alwaysOnTop
    end
end
function Engine._renderDebug()
    if not debug.enabled then return end
    local stats = string.format(
        "FPS: %d | Upd: %dms | Draw: %dms",
        debug.fps, debug.updateTime, debug.drawTime
    )
    local staticCount = 0
    if state.activeScene and state.activeScene._staticElements then
        staticCount = #state.activeScene._staticElements
    end
    local entInfo = string.format(
        "Entities: %d (Dyn) | %d (Stat)",
        debug.dynamicCount or 0, staticCount
    )
    Engine.buffer:drawText(1, 1, stats, "0", "f")
    Engine.buffer:drawText(1, 2, entInfo, "7", "f")
    if state.activeScene then
        state.activeScene._rowsToRestore[1] = true
        state.activeScene._rowsToRestore[2] = true
    end
    if debug.showLogs then
        local history = Engine.logger.getHistory()
        for i, entry in ipairs(history) do
            Engine.buffer:drawText(1, 3 + i, entry.text, entry.color, "f")
            if state.activeScene then
                state.activeScene._rowsToRestore[3 + i] = true
            end
        end
    end
end
function Engine.enableConsole(enabled)
    state.consoleEnabled = enabled
    if not enabled then
        Engine.console.close()
    end
end
function Engine.isConsoleEnabled()
    return state.consoleEnabled
end
function Engine.disableConsole()
    Engine.enableConsole(false)
end
function Engine._renderDebugTop()
    if not debug.enabled or not debug.alwaysOnTop then return end
    local termW, termH = Engine.buffer:getSize()
    local stats = string.format(
        "FPS: %d | Upd: %dms | Draw: %dms",
        debug.fps, debug.updateTime, debug.drawTime
    )
    local staticCount = 0
    if state.activeScene and state.activeScene._staticElements then
        staticCount = #state.activeScene._staticElements
    end
    local entInfo = string.format(
        "Entities: %d (Dyn) | %d (Stat)",
        debug.dynamicCount or 0, staticCount
    )
    Engine.buffer:drawText(1, 1, stats, "0", "f")
    Engine.buffer:drawText(1, 2, entInfo, "7", "f")
    if state.activeScene then
        state.activeScene._rowsToRestore[1] = true
        state.activeScene._rowsToRestore[2] = true
    end
    if debug.showLogs then
        local history = Engine.logger.getHistory()
        for i, entry in ipairs(history) do
            Engine.buffer:drawText(1, 3 + i, entry.text, entry.color, "f")
            if state.activeScene then
                state.activeScene._rowsToRestore[3 + i] = true
            end
        end
    end
end
local function updateDeltaTime()
    local currentTime = os.epoch("utc") / 1000
    local rawDelta = currentTime - state.lastTime
    state.lastTime = currentTime
    table.insert(state.deltaHistory, rawDelta)
    if #state.deltaHistory > config.deltaHistorySize then
        table.remove(state.deltaHistory, 1)
    end
    local sum = 0
    for _, dt in ipairs(state.deltaHistory) do
        sum = sum + dt
    end
    state.lastDeltaTime = sum / #state.deltaHistory
end
local function renderTransition()
    if not state.transition then return end
    state.transition.elapsed = state.transition.elapsed + state.lastDeltaTime
    local half = state.transition.duration / 2
    local progress = 0
    if state.transition.stage == "out" then
        progress = math.min(1, state.transition.elapsed / half)
        if state.transition.elapsed >= half then
            Engine.setScene(state.transition.target)
            state.transition.stage = "in"
        end
    else
        progress = math.max(0, 1 - (state.transition.elapsed - half) / half)
        if state.transition.elapsed >= state.transition.duration then
            state.transition = nil
            return
        end
    end
    local tw, th = Engine.buffer:getSize()
    local curtainH = math.floor((th / 2) * progress)
    if curtainH > 0 then
        Engine.buffer:drawRect(1, 1, tw, curtainH, " ", "0", "f")
        Engine.buffer:drawRect(1, th - curtainH + 1, tw, curtainH, " ", "0", "f")
    end
end
local function updateFrame()
    local frameStart = os.epoch("utc")
    local curW, curH = term.getSize()
    if debug.minW and debug.minH and (curW < debug.minW or curH < debug.minH) then
        debug.unsupportedResolution = true
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Terminal size not supported.")
        term.setCursorPos(1, 2)
        term.write(string.format("Required: %dx%d | Current: %dx%d",
            debug.minW, debug.minH, curW, curH))
        os.sleep(0.2)
        state.lastTime = os.epoch("utc") / 1000
        return
    end
    debug.unsupportedResolution = false
    updateDeltaTime()
    Engine.tween.update(state.lastDeltaTime)
    Engine.timer.update(state.lastDeltaTime)
    if state.activeScene then
        state.activeScene:update(state.lastDeltaTime)
    end
    if state.activeScene then
        local ok, list = pcall(function() return state.activeScene:select("pos", "sprite") end)
        if ok and list then
            debug.dynamicCount = #list
        else
            debug.dynamicCount = 0
        end
    else
        debug.dynamicCount = 0
    end
    if errorModule._shouldStop then
        state.running = false
        return
    end
    for _, fn in ipairs(callbacks.update) do
        fn(state.lastDeltaTime)
    end
    debug.updateTime = os.epoch("utc") - frameStart
    Engine.input._endFrame()
    local drawStart = os.epoch("utc")
    if state.transition and state.activeScene then
        state.activeScene._staticDirty = true
    end
    if state.activeScene then
        state.activeScene:draw()
    end
    for _, fn in ipairs(callbacks.render) do
        fn()
    end
    renderTransition()
    if state.consoleEnabled then
        Engine.console.draw(Engine.buffer)
    end
    Engine._renderDebugTop()
    Engine.buffer:present()
    debug.drawTime = os.epoch("utc") - drawStart
    state.frameCount = state.frameCount + 1
    local now = os.clock()
    if now - state.fpsTimer >= 1 then
        state.currentFPS = state.frameCount
        debug.fps = state.frameCount
        state.frameCount = 0
        state.fpsTimer = now
    end
    local workTime = (os.epoch("utc") - frameStart) / 1000
    local sleepTime = math.max(0, config.frameTime - workTime)
    local t = os.startTimer(sleepTime)
    repeat
        local _, tid = os.pullEvent("timer")
    until tid == t
end
local function handleEvent(event)
    local consumed = false
    if state.activeScene and state.activeScene.ui then
        local ox, oy = Engine.getViewportOffset()
        consumed = state.activeScene.ui:handleEvent(event, ox, oy)
    end
    local consoleConsumed = false
    if state.consoleEnabled then
        local wasOpen = Engine.console.isOpen()
        consoleConsumed = Engine.console.handleEvent(event, consumed)
        if wasOpen and not Engine.console.isOpen() and state.activeScene then
            state.activeScene._staticDirty = true
        end
    end
    if consumed then
        if event[1] == "mouse_click" then
            Engine.input.clear()
        end
    elseif not consoleConsumed then
        Engine.input.processEvent(table.unpack(event))
        Engine.network.processEvent(event)
        Engine.server.processEvent(event)
        Engine.event:emit(event[1], table.unpack(event, 2))
        if state.activeScene and state.activeScene.event then
            state.activeScene.event:emit(event[1], table.unpack(event, 2))
        end
        if state.activeScene and state.activeScene.onEvent then
            local ok, err = xpcall(state.activeScene.onEvent, tracebackHandler, event)
            if not ok then
                Engine._reportError(err)
            end
        end
    end
    if event[1] == "term_resize" and not state.manualViewport then
        local nw, nh = term.getSize()
        Engine.buffer:setSize(nw, nh)
        if state.activeScene then
            state.activeScene._staticDirty = true
        end
    end
    for _, fn in ipairs(callbacks.event) do
        fn(event)
    end
    Engine.thread.update(table.unpack(event))
end
function Engine.start()
    state.running = true
    state.lastTime = os.epoch("utc") / 1000
    state.fpsTimer = os.clock()
    Engine.audio.refresh()
    Engine.console.setEnv(setmetatable({
        Engine = Engine,
        print = function(...)
            local parts = {}
            for i = 1, select("#", ...) do
                parts[i] = tostring(select(i, ...))
            end
            Engine.console.print(table.concat(parts, "\t"))
        end,
    }, { __index = _G }))
    Engine.thread.start(function()
        while state.running do
            updateFrame()
        end
    end)
    while state.running do
        local event = { os.pullEvent() }
        handleEvent(event)
    end
    Engine.buffer:restorePalette()
end
function Engine.stop()
    state.running = false
    Engine.buffer:restorePalette()
end
function Engine.isRunning()
    return state.running
end
return Engine
]=]
paths["engine"] = "engine"
sources["flimg"] = [=[

local flimg = {
    VERSION = 1,
    MAGIC = "FLMG",
    MODE_PIXEL = "pixel",
    MODE_CELL = "cell",
    ENCODING_RAW = 0,
    ENCODING_RLE = 1,
}
local char, byte, sub, rep = string.char, string.byte, string.sub, string.rep
local floor, min, max = math.floor, math.min, math.max
local MODE_TO_BYTE = { pixel = 1, cell = 2 }
local BYTE_TO_MODE = { [1] = "pixel", [2] = "cell" }
local NATIVE_RGB = {
    [0] = 0xF0F0F0, 0xF2B233, 0xE57FD8, 0x99B2F2,
    0xDEDE6C, 0x7FCC19, 0xF2B2CC, 0x4C4C4C,
    0x999999, 0x4C99B2, 0xB266E5, 0x3366CC,
    0x7F664C, 0x57A64E, 0xCC4C4C, 0x111111,
}
flimg.NATIVE_RGB = NATIVE_RGB
local function fail(message, level)
    error("FLIMG: " .. message, (level or 1) + 1)
end
local function integer(value, name, low, high)
    if type(value) ~= "number" or value ~= floor(value)
        or value < low or value > high then
        fail(name .. " must be an integer from " .. low .. " to " .. high, 2)
    end
    return value
end
local function u8(value)
    return char(value)
end
local function u16(value)
    return char(value % 256, floor(value / 256) % 256)
end
local function i16(value)
    if value < 0 then value = value + 65536 end
    return u16(value)
end
local function u32(value)
    return char(
        value % 256,
        floor(value / 256) % 256,
        floor(value / 65536) % 256,
        floor(value / 16777216) % 256)
end
local Reader = {}
Reader.__index = Reader
function Reader.new(data)
    return setmetatable({ data = data, pos = 1, size = #data }, Reader)
end
function Reader:take(length, label)
    if length < 0 or self.pos + length - 1 > self.size then
        fail("truncated " .. (label or "data") .. " at byte " .. self.pos, 2)
    end
    local result = sub(self.data, self.pos, self.pos + length - 1)
    self.pos = self.pos + length
    return result
end
function Reader:u8(label)
    local value = byte(self.data, self.pos)
    if value == nil then fail("truncated " .. (label or "u8"), 2) end
    self.pos = self.pos + 1
    return value
end
function Reader:u16(label)
    local a, b = byte(self:take(2, label), 1, 2)
    return a + b * 256
end
function Reader:i16(label)
    local value = self:u16(label)
    return value >= 32768 and value - 65536 or value
end
function Reader:u32(label)
    local a, b, c, d = byte(self:take(4, label), 1, 4)
    return a + b * 256 + c * 65536 + d * 16777216
end
local function hasFlag(value, flag)
    return value % (flag * 2) >= flag
end
local function parseRGB(value, label)
    if type(value) == "string" then
        local hex = value:gsub("#", "")
        if hex:match("^%x%x%x$") then
            hex = hex:sub(1, 1):rep(2)
                .. hex:sub(2, 2):rep(2)
                .. hex:sub(3, 3):rep(2)
        elseif hex:match("^%x%x%x%x%x%x%x%x$") then
            hex = hex:sub(3)
        end
        if not hex:match("^%x%x%x%x%x%x$") then
            fail((label or "color") .. " must be #RGB, #RRGGBB, #AARRGGBB, or 0xRRGGBB", 2)
        end
        value = tonumber(hex, 16)
    end
    return integer(value, label or "color", 0, 0xFFFFFF)
end
local function validatePaletteBytes(row, startIndex, label, paletteCount)
    local i, length = startIndex or 1, #row
    while i + 7 <= length do
        local a, b, c, d, e, f, g, h = byte(row, i, i + 7)
        local invalid = a > paletteCount and a or b > paletteCount and b
            or c > paletteCount and c or d > paletteCount and d
            or e > paletteCount and e or f > paletteCount and f
            or g > paletteCount and g or h > paletteCount and h
        if invalid then fail(label .. " references missing palette index " .. invalid, 2) end
        i = i + 8
    end
    while i <= length do
        local value = byte(row, i)
        if value > paletteCount then fail(label .. " references missing palette index " .. value, 2) end
        i = i + 1
    end
end
local function normalizePixelRow(row, width, label, paletteCount)
    if type(row) == "string" then
        if #row ~= width then fail(label .. " has width " .. #row .. ", expected " .. width, 2) end
        validatePaletteBytes(row, 1, label, paletteCount)
        return row
    end
    if type(row) ~= "table" or #row ~= width then
        fail(label .. " must be a byte string or an array of width " .. width, 2)
    end
    local out = {}
    for x = 1, width do
        local value = integer(row[x], label .. " pixel " .. x, 0, 255)
        if value > paletteCount then
            fail(label .. " pixel " .. x .. " references missing palette index " .. value, 2)
        end
        out[x] = char(value)
    end
    return table.concat(out)
end
local function normalizeCellRow(row, width, label, paletteCount)
    if type(row) ~= "table" then fail(label .. " must be {text, foreground, background}", 2) end
    local text, fg, bg = row[1] or row.text, row[2] or row.fg, row[3] or row.bg
    if type(text) ~= "string" or type(fg) ~= "string" or type(bg) ~= "string"
        or #text ~= width or #fg ~= width or #bg ~= width then
        fail(label .. " planes must be byte strings of width " .. width, 2)
    end
    validatePaletteBytes(fg, 1, label .. " foreground", paletteCount)
    validatePaletteBytes(bg, 1, label .. " background", paletteCount)
    return { text, fg, bg }
end
local function blankRows(mode, width, height)
    local rows = {}
    if mode == "pixel" then
        local blank = rep("\0", width)
        for y = 1, height do rows[y] = blank end
    else
        local blank = rep("\0", width)
        for y = 1, height do rows[y] = { blank, blank, blank } end
    end
    return rows
end
local function cloneRows(mode, rows)
    local result = {}
    if mode == "pixel" then
        for y = 1, #rows do result[y] = rows[y] end
    else
        for y = 1, #rows do
            local row = rows[y]
            result[y] = { row[1], row[2], row[3] }
        end
    end
    return result
end
local function normalizeImage(source)
    if type(source) ~= "table" then fail("image must be a table", 2) end
    local mode = source.mode or "pixel"
    if not MODE_TO_BYTE[mode] then fail("mode must be 'pixel' or 'cell'", 2) end
    local width = integer(source.width, "width", 1, 65535)
    local height = integer(source.height, "height", 1, 65535)
    local palette = {}
    if type(source.palette) ~= "table" or #source.palette < 1 or #source.palette > 255 then
        fail("palette must contain 1 to 255 colors", 2)
    end
    for i = 1, #source.palette do palette[i] = parseRGB(source.palette[i], "palette color " .. i) end
    local sourceLayers = source.layers
    if type(sourceLayers) ~= "table" or #sourceLayers < 1 or #sourceLayers > 255 then
        fail("layers must contain 1 to 255 layer descriptors", 2)
    end
    local layers = {}
    for i = 1, #sourceLayers do
        local layer = sourceLayers[i]
        if type(layer) ~= "table" then fail("layer " .. i .. " must be a table", 2) end
        local name = layer.name or ("Layer " .. i)
        if type(name) ~= "string" or #name > 255 then fail("layer " .. i .. " name is too long", 2) end
        layers[i] = {
            name = name,
            x = integer(layer.x or 1, "layer " .. i .. " x", -32768, 32767),
            y = integer(layer.y or 1, "layer " .. i .. " y", -32768, 32767),
            width = integer(layer.width or width, "layer " .. i .. " width", 1, 65535),
            height = integer(layer.height or height, "layer " .. i .. " height", 1, 65535),
            z = integer(layer.z or i, "layer " .. i .. " z", -32768, 32767),
            visible = layer.visible ~= false,
        }
    end
    local sourceFrames = source.frames
    if type(sourceFrames) ~= "table" or #sourceFrames < 1 or #sourceFrames > 65535 then
        fail("frames must contain 1 to 65535 frames", 2)
    end
    local frames, previous = {}, {}
    for frameIndex = 1, #sourceFrames do
        local sourceFrame = sourceFrames[frameIndex]
        if type(sourceFrame) ~= "table" then fail("frame " .. frameIndex .. " must be a table", 2) end
        local sourceData = sourceFrame.layers or sourceFrame
        local frame = {
            duration = integer(sourceFrame.duration or source.defaultDuration or 100,
                "frame " .. frameIndex .. " duration", 1, 65535),
            layers = {},
        }
        for layerIndex = 1, #layers do
            local descriptor = layers[layerIndex]
            local layerData = sourceData[layerIndex]
            local rows
            if layerData == nil and previous[layerIndex] ~= nil then
                rows = cloneRows(mode, previous[layerIndex])
            elseif layerData == nil then
                rows = blankRows(mode, descriptor.width, descriptor.height)
            else
                rows = layerData.rows or layerData
                if type(rows) ~= "table" or #rows ~= descriptor.height then
                    fail("frame " .. frameIndex .. " layer " .. layerIndex
                        .. " must have " .. descriptor.height .. " rows", 2)
                end
                local normalized = {}
                for y = 1, descriptor.height do
                    local label = "frame " .. frameIndex .. " layer " .. layerIndex .. " row " .. y
                    normalized[y] = mode == "pixel"
                        and normalizePixelRow(rows[y], descriptor.width, label, #palette)
                        or normalizeCellRow(rows[y], descriptor.width, label, #palette)
                end
                rows = normalized
            end
            frame.layers[layerIndex] = { rows = rows }
            previous[layerIndex] = rows
        end
        frames[frameIndex] = frame
    end
    return {
        format = "FLIMG",
        version = 1,
        mode = mode,
        width = width,
        height = height,
        palette = palette,
        layers = layers,
        frames = frames,
        loop = source.loop ~= false,
        pingPong = source.pingPong == true,
        keyframeInterval = integer(source.keyframeInterval or 16,
            "keyframeInterval", 1, 255),
    }
end
function flimg.normalize(source)
    return normalizeImage(source)
end
function flimg.rleEncode(data)
    if type(data) ~= "string" then fail("rleEncode expects a string", 2) end
    local out, length, i = {}, #data, 1
    while i <= length do
        local value = byte(data, i)
        local run = 1
        while run < 128 and i + run <= length and byte(data, i + run) == value do
            run = run + 1
        end
        if run >= 3 then
            out[#out + 1] = char(257 - run, value)
            i = i + run
        else
            local start = i
            local literalLength = 0
            while i <= length and literalLength < 128 do
                value = byte(data, i)
                local nextRun = 1
                while nextRun < 128 and i + nextRun <= length
                    and byte(data, i + nextRun) == value do
                    nextRun = nextRun + 1
                end
                if nextRun >= 3 then break end
                local take = min(nextRun, 128 - literalLength)
                i = i + take
                literalLength = literalLength + take
                if take < nextRun then break end
            end
            out[#out + 1] = char(literalLength - 1)
            out[#out + 1] = sub(data, start, i - 1)
        end
    end
    return table.concat(out)
end
function flimg.rleDecode(data, expectedLength)
    if type(data) ~= "string" then fail("rleDecode expects a string", 2) end
    local reader, out, produced = Reader.new(data), {}, 0
    while reader.pos <= reader.size do
        local control = reader:u8("RLE control byte")
        if control <= 127 then
            local length = control + 1
            out[#out + 1] = reader:take(length, "RLE literal")
            produced = produced + length
        elseif control >= 129 then
            local length = 257 - control
            out[#out + 1] = rep(char(reader:u8("RLE repeated byte")), length)
            produced = produced + length
        end
        if expectedLength and produced > expectedLength then fail("RLE output exceeds expected length", 2) end
    end
    local result = table.concat(out)
    if expectedLength and #result ~= expectedLength then
        fail("RLE produced " .. #result .. " bytes, expected " .. expectedLength, 2)
    end
    return result
end
local function cellDifferent(a, b, x)
    return byte(a[1], x) ~= byte(b[1], x)
        or byte(a[2], x) ~= byte(b[2], x)
        or byte(a[3], x) ~= byte(b[3], x)
end
local function differenceBounds(mode, current, previous, width, height, full)
    if full then return 1, 1, width, height end
    local x1, y1, x2, y2 = width + 1, height + 1, 0, 0
    for y = 1, height do
        local a, b = current[y], previous[y]
        if a ~= b then
            for x = 1, width do
                local changed
                if mode == "pixel" then
                    changed = byte(a, x) ~= byte(b, x)
                else
                    changed = cellDifferent(a, b, x)
                end
                if changed then
                    if x < x1 then x1 = x end
                    if x > x2 then x2 = x end
                    if y < y1 then y1 = y end
                    if y > y2 then y2 = y end
                end
            end
        end
    end
    if x2 == 0 then return nil end
    return x1, y1, x2, y2
end
local function extractPatch(mode, rows, x1, y1, x2, y2)
    local out = {}
    if mode == "pixel" then
        for y = y1, y2 do out[#out + 1] = sub(rows[y], x1, x2) end
    else
        for plane = 1, 3 do
            for y = y1, y2 do out[#out + 1] = sub(rows[y][plane], x1, x2) end
        end
    end
    return table.concat(out)
end
local function encodePatch(layerIndex, x1, y1, x2, y2, raw)
    local compressed = flimg.rleEncode(raw)
    local encoding, payload = flimg.ENCODING_RAW, raw
    if #compressed < #raw then encoding, payload = flimg.ENCODING_RLE, compressed end
    return table.concat({
        u8(layerIndex), u16(x1 - 1), u16(y1 - 1),
        u16(x2 - x1 + 1), u16(y2 - y1 + 1), u8(encoding),
        u32(#raw), u32(#payload), payload,
    })
end
function flimg.encode(source, options)
    local image = normalizeImage(source)
    options = options or {}
    local interval = integer(options.keyframeInterval or image.keyframeInterval,
        "keyframeInterval", 1, 255)
    local framePayloads, frameEntries = {}, {}
    for frameIndex = 1, #image.frames do
        local keyframe = frameIndex == 1 or (frameIndex - 1) % interval == 0
        local patches = {}
        for layerIndex = 1, #image.layers do
            local descriptor = image.layers[layerIndex]
            local current = image.frames[frameIndex].layers[layerIndex].rows
            local previous = frameIndex > 1 and image.frames[frameIndex - 1].layers[layerIndex].rows
                or blankRows(image.mode, descriptor.width, descriptor.height)
            local x1, y1, x2, y2 = differenceBounds(image.mode, current, previous,
                descriptor.width, descriptor.height, keyframe)
            if x1 then
                local raw = extractPatch(image.mode, current, x1, y1, x2, y2)
                patches[#patches + 1] = encodePatch(layerIndex, x1, y1, x2, y2, raw)
            end
        end
        local payload = u8(#patches) .. table.concat(patches)
        framePayloads[frameIndex] = payload
        frameEntries[frameIndex] = {
            duration = image.frames[frameIndex].duration,
            keyframe = keyframe,
            length = #payload,
        }
    end
    local flags = (image.loop and 1 or 0) + (image.pingPong and 2 or 0)
    local header = {
        flimg.MAGIC, u8(flimg.VERSION), u8(MODE_TO_BYTE[image.mode]), u8(flags),
        u16(image.width), u16(image.height), u8(#image.palette),
        u8(#image.layers), u16(#image.frames), u8(interval), u8(0),
    }
    for i = 1, #image.palette do
        local rgb = image.palette[i]
        header[#header + 1] = char(floor(rgb / 65536), floor(rgb / 256) % 256, rgb % 256)
    end
    for i = 1, #image.layers do
        local layer = image.layers[i]
        header[#header + 1] = table.concat({
            u8(#layer.name), layer.name, i16(layer.x), i16(layer.y),
            u16(layer.width), u16(layer.height), i16(layer.z),
            u8(layer.visible and 1 or 0),
        })
    end
    local offset, directory = 0, {}
    for i = 1, #frameEntries do
        local entry = frameEntries[i]
        directory[i] = u16(entry.duration) .. u8(entry.keyframe and 1 or 0)
            .. u32(offset) .. u32(entry.length)
        offset = offset + entry.length
    end
    return table.concat(header) .. table.concat(directory) .. table.concat(framePayloads)
end
local function replaceSpan(source, startIndex, replacement)
    return sub(source, 1, startIndex - 1) .. replacement
        .. sub(source, startIndex + #replacement)
end
local function applyPatch(mode, rows, x, y, width, height, raw)
    local pos = 1
    if mode == "pixel" then
        for row = y, y + height - 1 do
            local span = sub(raw, pos, pos + width - 1)
            rows[row] = replaceSpan(rows[row], x, span)
            pos = pos + width
        end
    else
        local spans = { {}, {}, {} }
        for plane = 1, 3 do
            for row = y, y + height - 1 do
                spans[plane][row] = sub(raw, pos, pos + width - 1)
                pos = pos + width
            end
        end
        for row = y, y + height - 1 do
            local old = rows[row]
            rows[row] = {
                replaceSpan(old[1], x, spans[1][row]),
                replaceSpan(old[2], x, spans[2][row]),
                replaceSpan(old[3], x, spans[3][row]),
            }
        end
    end
end
function flimg.decode(data)
    if type(data) ~= "string" then fail("decode expects a binary string", 2) end
    local reader = Reader.new(data)
    if reader:take(4, "magic") ~= flimg.MAGIC then fail("invalid magic bytes", 2) end
    local version = reader:u8("version")
    if version ~= flimg.VERSION then fail("unsupported version " .. version, 2) end
    local modeByte = reader:u8("mode")
    local mode = BYTE_TO_MODE[modeByte]
    if not mode then fail("unsupported mode " .. modeByte, 2) end
    local flags = reader:u8("flags")
    local width, height = reader:u16("width"), reader:u16("height")
    if width == 0 or height == 0 then fail("canvas dimensions must be non-zero", 2) end
    local paletteCount, layerCount = reader:u8("palette count"), reader:u8("layer count")
    local frameCount = reader:u16("frame count")
    local interval = reader:u8("keyframe interval")
    reader:u8("reserved byte")
    if paletteCount == 0 or layerCount == 0 or frameCount == 0 then
        fail("palette, layer, and frame counts must be non-zero", 2)
    end
    if interval == 0 then fail("keyframe interval must be non-zero", 2) end
    local palette = {}
    for i = 1, paletteCount do
        local r, g, b = byte(reader:take(3, "palette"), 1, 3)
        palette[i] = r * 65536 + g * 256 + b
    end
    local layers = {}
    for i = 1, layerCount do
        local nameLength = reader:u8("layer name length")
        local layer = {
            name = reader:take(nameLength, "layer name"),
            x = reader:i16("layer x"), y = reader:i16("layer y"),
            width = reader:u16("layer width"), height = reader:u16("layer height"),
            z = reader:i16("layer z"),
            visible = hasFlag(reader:u8("layer flags"), 1),
        }
        if layer.width == 0 or layer.height == 0 then fail("layer dimensions must be non-zero", 2) end
        layers[i] = layer
    end
    local directory = {}
    for i = 1, frameCount do
        directory[i] = {
            duration = reader:u16("frame duration"),
            keyframe = hasFlag(reader:u8("frame flags"), 1),
            offset = reader:u32("frame offset"),
            length = reader:u32("frame length"),
        }
        if directory[i].duration == 0 then fail("frame duration must be non-zero", 2) end
    end
    local dataStart = reader.pos
    local frames, previous = {}, {}
    for i = 1, layerCount do
        previous[i] = blankRows(mode, layers[i].width, layers[i].height)
    end
    for frameIndex = 1, frameCount do
        local entry = directory[frameIndex]
        if entry.offset + entry.length > reader.size - dataStart + 1 then
            fail("frame " .. frameIndex .. " points outside the file", 2)
        end
        local frameReader = Reader.new(sub(data,
            dataStart + entry.offset, dataStart + entry.offset + entry.length - 1))
        local states = {}
        for layerIndex = 1, layerCount do
            states[layerIndex] = entry.keyframe
                and blankRows(mode, layers[layerIndex].width, layers[layerIndex].height)
                or cloneRows(mode, previous[layerIndex])
        end
        local patchCount = frameReader:u8("frame patch count")
        local seen = {}
        for patchIndex = 1, patchCount do
            local layerIndex = frameReader:u8("patch layer")
            local descriptor = layers[layerIndex]
            if not descriptor then fail("patch references missing layer " .. layerIndex, 2) end
            if seen[layerIndex] then fail("frame has multiple patches for layer " .. layerIndex, 2) end
            seen[layerIndex] = true
            local x, y = frameReader:u16("patch x") + 1, frameReader:u16("patch y") + 1
            local patchWidth, patchHeight = frameReader:u16("patch width"), frameReader:u16("patch height")
            local encoding = frameReader:u8("patch encoding")
            local rawLength, payloadLength = frameReader:u32("raw length"), frameReader:u32("payload length")
            if patchWidth == 0 or patchHeight == 0
                or x + patchWidth - 1 > descriptor.width
                or y + patchHeight - 1 > descriptor.height then
                fail("patch lies outside layer " .. layerIndex, 2)
            end
            local expected = patchWidth * patchHeight * (mode == "cell" and 3 or 1)
            if rawLength ~= expected then fail("patch raw length does not match its dimensions", 2) end
            local payload = frameReader:take(payloadLength, "patch payload")
            local raw
            if encoding == flimg.ENCODING_RAW then
                raw = payload
                if #raw ~= rawLength then fail("raw patch length mismatch", 2) end
            elseif encoding == flimg.ENCODING_RLE then
                raw = flimg.rleDecode(payload, rawLength)
            else
                fail("unsupported patch encoding " .. encoding, 2)
            end
            if mode == "pixel" then
                validatePaletteBytes(raw, 1, "pixel patch", paletteCount)
            else
                validatePaletteBytes(raw, patchWidth * patchHeight + 1,
                    "cell color patch", paletteCount)
            end
            applyPatch(mode, states[layerIndex], x, y, patchWidth, patchHeight, raw)
        end
        if frameReader.pos ~= frameReader.size + 1 then fail("unused bytes in frame " .. frameIndex, 2) end
        if entry.keyframe then
            for layerIndex = 1, layerCount do
                if not seen[layerIndex] then fail("keyframe omits layer " .. layerIndex, 2) end
            end
        end
        local frame = { duration = entry.duration, layers = {} }
        for layerIndex = 1, layerCount do
            frame.layers[layerIndex] = { rows = states[layerIndex] }
            previous[layerIndex] = states[layerIndex]
        end
        frames[frameIndex] = frame
    end
    return {
        format = "FLIMG", version = version, mode = mode,
        width = width, height = height, palette = palette,
        layers = layers, frames = frames,
        loop = hasFlag(flags, 1), pingPong = hasFlag(flags, 2),
        keyframeInterval = interval,
    }
end
local function readFile(path)
    if fs and fs.open then
        local handle = fs.open(path, "rb") or fs.open(path, "r")
        if not handle then fail("cannot open " .. tostring(path), 2) end
        local data = handle.readAll()
        handle.close()
        return data
    end
    local handle, err = io.open(path, "rb")
    if not handle then fail("cannot open " .. tostring(path) .. ": " .. tostring(err), 2) end
    local data = handle:read("*a")
    handle:close()
    return data
end
local function writeFile(path, data)
    if fs and fs.open then
        local handle = fs.open(path, "wb") or fs.open(path, "w")
        if not handle then fail("cannot write " .. tostring(path), 2) end
        handle.write(data)
        handle.close()
        return
    end
    local handle, err = io.open(path, "wb")
    if not handle then fail("cannot write " .. tostring(path) .. ": " .. tostring(err), 2) end
    handle:write(data)
    handle:close()
end
function flimg.load(path)
    return flimg.decode(readFile(path))
end
function flimg.save(path, image, options)
    local data = flimg.encode(image, options)
    writeFile(path, data)
    return #data
end
local function overlaySpan(target, source, targetX, sourceX, length)
    local out = {}
    for offset = 0, length - 1 do
        local value = byte(source, sourceX + offset)
        out[offset + 1] = value == 0
            and sub(target, targetX + offset, targetX + offset)
            or char(value)
    end
    return sub(target, 1, targetX - 1) .. table.concat(out)
        .. sub(target, targetX + length)
end
function flimg.compose(image, frameIndex)
    image = image.format == "FLIMG" and image or normalizeImage(image)
    local frame = image.frames[frameIndex or 1]
    if not frame then fail("frame " .. tostring(frameIndex) .. " does not exist", 2) end
    local rows = blankRows(image.mode, image.width, image.height)
    local order = {}
    for i = 1, #image.layers do order[i] = i end
    table.sort(order, function(a, b)
        local la, lb = image.layers[a], image.layers[b]
        return la.z == lb.z and a < b or la.z < lb.z
    end)
    for _, layerIndex in ipairs(order) do
        local layer = image.layers[layerIndex]
        if layer.visible then
            local source = frame.layers[layerIndex].rows
            local sourceX1 = max(1, 2 - layer.x)
            local sourceX2 = min(layer.width, image.width - layer.x + 1)
            for sy = 1, layer.height do
                local dy = layer.y + sy - 1
                if dy >= 1 and dy <= image.height and sourceX1 <= sourceX2 then
                    local targetX, length = layer.x + sourceX1 - 1, sourceX2 - sourceX1 + 1
                    if image.mode == "pixel" then
                        rows[dy] = overlaySpan(rows[dy], source[sy], targetX, sourceX1, length)
                    else
                        local target = rows[dy]
                        rows[dy] = {
                            overlaySpan(target[1], source[sy][1], targetX, sourceX1, length),
                            overlaySpan(target[2], source[sy][2], targetX, sourceX1, length),
                            overlaySpan(target[3], source[sy][3], targetX, sourceX1, length),
                        }
                    end
                end
            end
        end
    end
    return rows
end
local function addPaletteColor(palette, lookup, rgb)
    local known = lookup[rgb]
    if known then return known end
    if #palette >= 255 then fail("imported image uses more than 255 colors", 2) end
    palette[#palette + 1] = rgb
    lookup[rgb] = #palette
    return #palette
end
function flimg.fromBimg(bimg)
    if type(bimg) ~= "table" or type(bimg[1]) ~= "table" or type(bimg[1][1]) ~= "table" then
        fail("invalid BIMG table", 2)
    end
    local width, height = #bimg[1][1][1], #bimg[1]
    local palette, lookup = {}, {}
    local function fromBlit(value)
        local index = tonumber(value, 16)
        return index and addPaletteColor(palette, lookup, NATIVE_RGB[index]) or 0
    end
    local frames = {}
    for frameIndex = 1, #bimg do
        local sourceFrame, rows = bimg[frameIndex], {}
        if #sourceFrame ~= height then fail("BIMG frame dimensions differ", 2) end
        for y = 1, height do
            local line = sourceFrame[y]
            if type(line) ~= "table" or #line[1] ~= width or #line[2] ~= width or #line[3] ~= width then
                fail("invalid BIMG line", 2)
            end
            local fg, bg = {}, {}
            for x = 1, width do
                fg[x] = char(fromBlit(line[2]:sub(x, x)))
                bg[x] = char(fromBlit(line[3]:sub(x, x)))
            end
            rows[y] = { line[1], table.concat(fg), table.concat(bg) }
        end
        frames[frameIndex] = {
            duration = floor(((bimg.secondsPerFrame or 0.2) * 1000) + 0.5),
            layers = { { rows = rows } },
        }
    end
    return normalizeImage({
        mode = "cell", width = width, height = height,
        palette = palette, layers = { { name = "BIMG" } }, frames = frames,
        loop = true,
    })
end
local function rowCell(row, index)
    return type(row) == "string" and row:sub(index, index) or row[index]
end
local function nativeIndexOf(value)
    if type(value) ~= "number" or value < 1 or value > 32768 then return nil end
    local current = 1
    for index = 0, 15 do
        if value == current then return index end
        current = current * 2
    end
end
function flimg.fromSprite(sprite, options)
    options = options or {}
    if type(sprite) ~= "table" then fail("invalid sprite table", 2) end
    local width = integer(sprite.width, "sprite width", 1, 65535)
    local height = integer(sprite.height, "sprite height", 1, 65535)
    local frameCount = integer(sprite.frameCount or #sprite, "sprite frame count", 1, 65535)
    local palette, lookup = {}, {}
    local function colorIndex(value)
        if value == nil or value == false or value == " " or value == "" then return 0 end
        if options.resolveColor then value = options.resolveColor(value) end
        if type(value) == "string" and #value == 1 then
            local native = tonumber(value, 16)
            if native then return addPaletteColor(palette, lookup, NATIVE_RGB[native]) end
        end
        local native = nativeIndexOf(value)
        if native then return addPaletteColor(palette, lookup, NATIVE_RGB[native]) end
        return addPaletteColor(palette, lookup, parseRGB(value, "sprite color"))
    end
    local frames = {}
    for frameIndex = 1, frameCount do
        local frame = sprite[frameIndex]
        if type(frame) ~= "table" or not frame[1] or not frame[2] or not frame[3] then
            fail("sprite frame " .. frameIndex .. " must have character, foreground, and background layers", 2)
        end
        local rows = {}
        for y = 1, height do
            local charRow, fgRow, bgRow = frame[1][y], frame[2][y], frame[3][y]
            if type(charRow) ~= "table" and type(charRow) ~= "string" then
                fail("invalid sprite character row", 2)
            end
            local chars, foregrounds, backgrounds = {}, {}, {}
            for x = 1, width do
                local glyph = rowCell(charRow, x)
                if type(glyph) ~= "string" or #glyph ~= 1 then fail("invalid sprite character", 2) end
                chars[x] = glyph == " " and "\0" or glyph
                foregrounds[x] = char(colorIndex(rowCell(fgRow, x)))
                backgrounds[x] = char(colorIndex(rowCell(bgRow, x)))
            end
            rows[y] = { table.concat(chars), table.concat(foregrounds), table.concat(backgrounds) }
        end
        frames[frameIndex] = {
            duration = floor(((sprite.secondsPerFrame or options.secondsPerFrame or 0.1) * 1000) + 0.5),
            layers = { { rows = rows } },
        }
    end
    if #palette == 0 then palette[1] = NATIVE_RGB[15] end
    return normalizeImage({
        mode = "cell", width = width, height = height,
        palette = palette, layers = { { name = "Sprite" } }, frames = frames,
        loop = sprite.loop ~= false,
    })
end
return flimg
]=]
paths["flimg"] = "flimg"
sources["core.ai"] = [=[

local ai = {}
local BrainTimer = {}
function BrainTimer.new(kind, seconds, fn)
    assert(kind == "once" or kind == "repeat", "BrainTimer.new — invalid kind '" .. tostring(kind) .. "'")
    assert(type(seconds) == "number" and seconds >= 0, "BrainTimer.new — invalid seconds (must be non-negative number)")
    assert(type(fn) == "function", "BrainTimer.new — fn must be a function")
    return {
        kind = kind,
        interval = (kind == "repeat") and seconds or nil,
        remaining = seconds,
        fn = fn
    }
end
local BrainTransition = {}
function BrainTransition.new(from, to, cond)
    assert(type(from) == "string", "BrainTransition.new — from must be a string")
    assert(type(to) == "string", "BrainTransition.new — to must be a string")
    assert(type(cond) == "function", "BrainTransition.new — cond must be a function")
    return { from = from, to = to, cond = cond }
end
local BrainState = {}
function BrainState.new(onEnter, onUpdate, onExit, onDraw)
    return {
        onEnter = onEnter,
        onUpdate = onUpdate,
        onExit = onExit,
        onDraw = onDraw
    }
end
local Brain = {}
Brain.__index = Brain
function Brain.new(states, initialState, data)
    local self = setmetatable({}, Brain)
    self._states = states or {}
    self._transitions = {}
    self._stack = {}
    self._timers = {}
    self.current = nil
    self.previousState = nil
    self.timer = 0
    self.memory = {}
    self.id = nil
    self.scene = nil
    if data then
        for k, v in pairs(data) do self[k] = v end
    end
    if initialState then self:start(initialState) end
    return self
end
function Brain:addState(name, callbacks)
    assert(type(name) == "string", "Brain:addState — name must be a string")
    local cb = callbacks or {}
    self._states[name] = BrainState.new(cb.onEnter, cb.onUpdate, cb.onExit, cb.onDraw)
end
function Brain:addTransition(from, to, condition)
    table.insert(self._transitions, BrainTransition.new(from, to, condition))
end
function Brain:start(name)
    assert(self._states[name], "Brain:start — unknown state '" .. tostring(name) .. "'")
    self._stack = { name }
    self._timers = {}
    self.current = name
    self.previousState = nil
    self.timer = 0
    local s = self._states[name]
    if s and s.onEnter then s.onEnter(self, nil) end
end
function Brain:go(name)
    assert(self._states[name], "Brain:go — unknown state '" .. tostring(name) .. "'")
    if name == self.current then return end
    local prev = self.current
    if prev then
        local old = self._states[prev]
        if old and old.onExit then old.onExit(self, name) end
    end
    if #self._stack == 0 then
        table.insert(self._stack, name)
    else
        self._stack[#self._stack] = name
    end
    self.previousState = prev
    self.current = name
    self.timer = 0
    self._timers = {}
    local s = self._states[name]
    if s and s.onEnter then s.onEnter(self, prev) end
end
function Brain:push(name)
    assert(self._states[name], "Brain:push — unknown state '" .. tostring(name) .. "'")
    local prev = self.current
    if prev then
        local old = self._states[prev]
        if old and old.onExit then old.onExit(self, name) end
    end
    table.insert(self._stack, name)
    self.previousState = prev
    self.current = name
    self.timer = 0
    self._timers = {}
    local s = self._states[name]
    if s and s.onEnter then s.onEnter(self, prev) end
end
function Brain:pop()
    if #self._stack <= 1 then return end
    local prev = self.current
    local old  = self._states[prev]
    table.remove(self._stack)
    local next = self._stack[#self._stack]
    if old and old.onExit then old.onExit(self, next) end
    self.previousState = prev
    self.current = next
    self.timer = 0
    self._timers = {}
    local s = self._states[next]
    if s and s.onEnter then s.onEnter(self, prev) end
end
function Brain:after(seconds, fn)
    table.insert(self._timers, BrainTimer.new("once", seconds, fn))
end
function Brain:every(seconds, fn)
    table.insert(self._timers, BrainTimer.new("repeat", seconds, fn))
end
function Brain:_tickTimers(dt)
    local i = 1
    while i <= #self._timers do
        local t = self._timers[i]
        t.remaining = t.remaining - dt
        if t.remaining <= 0 then
            t.fn(self)
            if t.kind == "repeat" then
                t.remaining = t.interval
                i = i + 1
            else
                table.remove(self._timers, i)
            end
        else
            i = i + 1
        end
    end
end
function Brain:update(dt)
    if not self.current then return end
    for _, tr in ipairs(self._transitions) do
        if tr.from == self.current and tr.cond(self) then
            self:go(tr.to)
            break
        end
    end
    self.timer = self.timer + dt
    self:_tickTimers(dt)
    local s = self._states[self.current]
    if s and s.onUpdate then
        local next = s.onUpdate(self, dt)
        if next and next ~= self.current then
            self:go(next)
        end
    end
end
function Brain:draw()
    if not self.current then return end
    local s = self._states[self.current]
    if s and s.onDraw then s.onDraw(self) end
end
function Brain:is(name)
    return self.current == name
end
function Brain:was(name)
    return self.previousState == name
end
function Brain:timeInState()
    return self.timer
end
function Brain:stackDepth()
    return #self._stack
end
function Brain:stateCount()
    local n = 0
    for _ in pairs(self._states) do n = n + 1 end
    return n
end
function ai.canSee(id, targetId, scene, maxDist, layerMask)
    local pos  = scene.components.pos[id]
    local tPos = scene.components.pos[targetId]
    if not pos or not tPos then return false end
    if maxDist and pos:dist(tPos) > maxDist then return false end
    local hit, _, _, hitId = scene:castRay(pos.x, pos.y, tPos.x, tPos.y, maxDist or 100, id, layerMask)
    return (not hit) or (hitId == targetId)
end
function ai.canHear(id, targetId, scene, maxDist)
    local pos  = scene.components.pos[id]
    local tPos = scene.components.pos[targetId]
    if not pos or not tPos then return false end
    return pos:dist(tPos) <= maxDist
end
function ai.nearest(id, scene, tag, maxDist)
    local pos = scene.components.pos[id]
    if not pos then return nil, nil end
    local bestId, bestDist = nil, maxDist or math.huge
    local tags      = scene.components.tags
    local positions = scene.components.pos
    for otherId, otherPos in pairs(positions) do
        if otherId ~= id then
            local hasTag = not tag or (tags and tags[otherId] and tags[otherId][tag])
            if hasTag then
                local d = pos:dist(otherPos)
                if d < bestDist then
                    bestDist = d
                    bestId   = otherId
                end
            end
        end
    end
    return bestId, bestDist
end
function ai.system(scene)
    return function(dt, ids, components)
        local brains = components.brain
        if not brains then return end
        for _, id in ipairs(ids) do
            local brain = brains[id]
            if brain then
                brain.id    = id
                brain.scene = scene
                brain:update(dt)
            end
        end
    end
end
ai.Brain = Brain
ai.BrainState = BrainState
ai.BrainTimer = BrainTimer
ai.BrainTransition = BrainTransition
return ai
]=]
paths["core.ai"] = "core/ai"
sources["core.audio"] = [=[

local require = ...
local logger = require("core.logger")
local thread = require("core.thread")
local AudioModule = {
    _speakers = {},
    _initialized = false,
    _currentSong = nil,
    _songThread = nil,
    _sfxLibrary = {},
    _muted = false,
    _masterVolume = 1.0,
}
function AudioModule.refresh()
    AudioModule._speakers = { peripheral.find("speaker") }
    AudioModule._initialized = true
    if #AudioModule._speakers == 0 then
        logger.warn("Audio: No speakers found. Audio disabled.")
    else
        logger.info(string.format("Audio: %d speaker(s) detected.", #AudioModule._speakers))
    end
end
function AudioModule.isReady()
    return AudioModule._initialized and #AudioModule._speakers > 0
end
function AudioModule.getSpeakerCount()
    return #AudioModule._speakers
end
function AudioModule.setMuted(muted)
    AudioModule._muted = muted == true
end
function AudioModule.isMuted()
    return AudioModule._muted
end
function AudioModule.setVolume(volume)
    AudioModule._masterVolume = math.max(0, math.min(1, volume))
end
function AudioModule.getVolume()
    return AudioModule._masterVolume
end
function AudioModule.playNote(instrument, pitch, volume)
    if AudioModule._muted then return end
    if not AudioModule._initialized then AudioModule.refresh() end
    if #AudioModule._speakers == 0 then return end
    local finalVolume = math.max(0, math.min(3, (volume or 1) * AudioModule._masterVolume))
    local instr = instrument or "harp"
    local p = pitch or 12
    for _, speaker in ipairs(AudioModule._speakers) do
        pcall(function()
            speaker.playNote(instr, finalVolume, p)
        end)
    end
end
function AudioModule.registerSfx(name, sequence)
    if not name or type(sequence) ~= "table" then
        logger.error("Audio: Invalid SFX registration")
        return
    end
    AudioModule._sfxLibrary[name] = sequence
end
function AudioModule.playSfx(name)
    local sequence = AudioModule._sfxLibrary[name]
    if not sequence then
        logger.error("Audio: Unknown SFX '" .. tostring(name) .. "'")
        return
    end
    thread.start(function()
        for _, note in ipairs(sequence) do
            if note.delay then
                os.sleep(note.delay)
            end
            AudioModule.playNote(note.instrument, note.pitch, note.volume)
        end
    end)
end
function AudioModule.hasSfx(name)
    return AudioModule._sfxLibrary[name] ~= nil
end
function AudioModule.unregisterSfx(name)
    AudioModule._sfxLibrary[name] = nil
end
function AudioModule.getSfxList()
    local names = {}
    for name in pairs(AudioModule._sfxLibrary) do
        table.insert(names, name)
    end
    return names
end
function AudioModule.playSong(songData, loop)
    if not songData then
        logger.error("Audio: playSong called with nil songData")
        return
    end
    if not songData.tempo or songData.tempo <= 0 then
        logger.error("Audio: Invalid or missing tempo in songData")
        return
    end
    AudioModule.stopSong()
    AudioModule._currentSong = songData
    AudioModule._songThread = thread.start(function()
        local tickTime = 1 / songData.tempo
        local playing = true
        while playing do
            for tick = 0, songData.length do
                if AudioModule._currentSong ~= songData then
                    return
                end
                local notes = songData.ticks[tick]
                if notes then
                    for _, note in ipairs(notes) do
                        AudioModule.playNote(note.instrument, note.pitch, note.volume)
                    end
                end
                os.sleep(tickTime)
            end
            if not loop then
                playing = false
            end
        end
    end)
end
function AudioModule.stopSong()
    if AudioModule._songThread then
        thread.stop(AudioModule._songThread)
        AudioModule._songThread = nil
    end
    AudioModule._currentSong = nil
end
function AudioModule.isSongPlaying()
    return AudioModule._currentSong ~= nil
end
function AudioModule.getCurrentSong()
    return AudioModule._currentSong
end
function AudioModule.stopAll()
    AudioModule.stopSong()
end
return AudioModule
]=]
paths["core.audio"] = "core/audio"
sources["core.buffer"] = [=[

local require = ...
local color = require("core.color")
local flimg = require("flimg")
local buffer = {}
local WHITE = color.encode("0")
local BLACK = color.encode("f")
local rep, char = string.rep, string.char
local move = table.move or function(source, first, last, targetStart, target)
    target = target or source
    if target == source and targetStart > first and targetStart <= last then
        for i = last, first, -1 do target[targetStart + i - first] = source[i] end
    else
        for i = first, last do target[targetStart + i - first] = source[i] end
    end
    return target
end
local Buffer = {}
Buffer.__index = Buffer
local Surface = {}
Surface.__index = Surface
local mosaicChars = {}
for mask = 0, 31 do mosaicChars[mask] = string.char(128 + mask) end
local mosaicCache = {}
local function nearestOf(value, a, b)
    local v = color.getRGB(value:byte())
    local ar = color.getRGB(a:byte())
    local br = color.getRGB(b:byte())
    local adr, adg, adb = v[1] - ar[1], v[2] - ar[2], v[3] - ar[3]
    local bdr, bdg, bdb = v[1] - br[1], v[2] - br[2], v[3] - br[3]
    local da = adr * adr + adg * adg + adb * adb
    local db = bdr * bdr + bdg * bdg + bdb * bdb
    return da <= db and 0 or 1
end
local function compileMosaic(c1, c2, c3, c4, c5, c6)
    local key = c1 .. c2 .. c3 .. c4 .. c5 .. c6
    local cached = mosaicCache[key]
    if cached then return cached[1], cached[2], cached[3] end
    local values = { c1, c2, c3, c4, c5, c6 }
    local counts, order = {}, {}
    for i = 1, 6 do
        local c = values[i]
        if counts[c] == nil then
            counts[c] = 1
            order[#order + 1] = c
        else
            counts[c] = counts[c] + 1
        end
    end
    local a, b
    for _, c in ipairs(order) do
        if not a or counts[c] > counts[a] then
            b, a = a, c
        elseif not b or counts[c] > counts[b] then
            b = c
        end
    end
    if not b then
        cached = { " ", a, a }
        mosaicCache[key] = cached
        return cached[1], cached[2], cached[3]
    end
    local bits = {}
    for i = 1, 6 do
        local c = values[i]
        if c == a then bits[i] = 0
        elseif c == b then bits[i] = 1
        else bits[i] = nearestOf(c, a, b) end
    end
    local pivot = bits[6]
    local mask = 0
    if bits[1] ~= pivot then mask = mask + 1 end
    if bits[2] ~= pivot then mask = mask + 2 end
    if bits[3] ~= pivot then mask = mask + 4 end
    if bits[4] ~= pivot then mask = mask + 8 end
    if bits[5] ~= pivot then mask = mask + 16 end
    local fg, bg
    if pivot == 0 then fg, bg = b, a else fg, bg = a, b end
    cached = { mosaicChars[mask], fg, bg }
    mosaicCache[key] = cached
    return cached[1], cached[2], cached[3]
end
local function newRows(width, height, textValue, fgValue, bgValue)
    local text, fg, bg = {}, {}, {}
    for y = 1, height do
        local rowT, rowF, rowB = {}, {}, {}
        if textValue ~= nil or fgValue ~= nil or bgValue ~= nil then
            for x = 1, width do
                rowT[x], rowF[x], rowB[x] = textValue, fgValue, bgValue
            end
        end
        text[y], fg[y], bg[y] = rowT, rowF, rowB
    end
    return text, fg, bg
end
local function resetContext(surface)
    local owner = surface._owner
    surface._ox, surface._oy = 0, 0
    surface._clipX1, surface._clipY1 = 1, 1
    surface._clipX2, surface._clipY2 = owner._w, owner._h
    surface._stack, surface._stackN = {}, 0
end
local function markDirty(surface, x1, y1, x2, y2)
    local owner = surface._owner
    x1, y1 = math.max(1, x1), math.max(1, y1)
    x2, y2 = math.min(owner._w, x2), math.min(owner._h, y2)
    if x1 > x2 or y1 > y2 then return end
    if x1 < surface._dirtyX1 then surface._dirtyX1 = x1 end
    if y1 < surface._dirtyY1 then surface._dirtyY1 = y1 end
    if x2 > surface._dirtyX2 then surface._dirtyX2 = x2 end
    if y2 > surface._dirtyY2 then surface._dirtyY2 = y2 end
end
local function resetDirty(surface)
    surface._dirtyX1, surface._dirtyY1 = math.huge, math.huge
    surface._dirtyX2, surface._dirtyY2 = 0, 0
end
local function resetSurface(surface)
    local owner = surface._owner
    if surface._opaque then
        surface._text, surface._fg, surface._bg = newRows(
            owner._w, owner._h, " ", WHITE, BLACK)
    else
        surface._text, surface._fg, surface._bg = newRows(owner._w, owner._h)
    end
    surface._spFg, surface._spBg, surface._spBits = nil, nil, nil
    surface._spX1, surface._spY1 = math.huge, math.huge
    surface._spX2, surface._spY2 = 0, 0
    resetContext(surface)
    resetDirty(surface)
    markDirty(surface, 1, 1, owner._w, owner._h)
end
local function createSurface(owner, name, zIndex, opaque)
    local surface = setmetatable({
        _owner = owner,
        name = name,
        zIndex = zIndex or 0,
        visible = true,
        _opaque = opaque == true,
        _sequence = owner._nextSequence,
    }, Surface)
    owner._nextSequence = owner._nextSequence + 1
    resetSurface(surface)
    return surface
end
local function inClip(surface, x, y)
    return x >= surface._clipX1 and x <= surface._clipX2
        and y >= surface._clipY1 and y <= surface._clipY2
end
local function encodeSurfaceColor(surface, value, nativeDefault)
    if surface._opaque and value == nil then return color.encode(nativeDefault) end
    return color.encode(value)
end
local function ensureSubpixels(surface)
    if surface._spBits then return end
    surface._spFg, surface._spBg, surface._spBits = {}, {}, {}
end
local function virtualClip(surface)
    return (surface._clipX1 - 1) * 2 + 1,
        (surface._clipY1 - 1) * 3 + 1,
        surface._clipX2 * 2,
        surface._clipY2 * 3
end
local function storeSubpixel(surface, vx, vy, encoded, bgEncoded)
    local virtualWidth = surface._owner._w * 2
    local index = (vy - 1) * virtualWidth + vx
    surface._spFg[index] = encoded
    if bgEncoded ~= nil then surface._spBg[index] = bgEncoded end
    surface._spBits[index] = true
end
local function markSubpixelArea(surface, vx1, vy1, vx2, vy2)
    local cellX1 = math.floor((vx1 + 1) / 2)
    local cellY1 = math.floor((vy1 + 2) / 3)
    local cellX2 = math.floor((vx2 + 1) / 2)
    local cellY2 = math.floor((vy2 + 2) / 3)
    if cellX1 < surface._spX1 then surface._spX1 = cellX1 end
    if cellY1 < surface._spY1 then surface._spY1 = cellY1 end
    if cellX2 > surface._spX2 then surface._spX2 = cellX2 end
    if cellY2 > surface._spY2 then surface._spY2 = cellY2 end
    markDirty(surface, cellX1, cellY1, cellX2, cellY2)
end
local function rowValue(row, index)
    if type(row) == "string" then return row:sub(index, index) end
    return row and row[index] or nil
end
function Surface:getSize()
    return self._owner._w, self._owner._h
end
function Surface:getVirtualSize()
    return self._owner._w * 2, self._owner._h * 3
end
function Surface:setVisible(visible)
    visible = visible ~= false
    if self.visible ~= visible then
        self.visible = visible
        self._owner:_markFullComposition()
    end
    return self
end
function Surface:setZIndex(zIndex)
    zIndex = tonumber(zIndex) or 0
    if self.zIndex ~= zIndex then
        self.zIndex = zIndex
        self._owner:_sortLayers()
        self._owner:_markFullComposition()
    end
    return self
end
function Surface:push(x, y, width, height)
    x, y = math.floor(x or 1), math.floor(y or 1)
    width, height = math.floor(width or 0), math.floor(height or 0)
    local n, stack = self._stackN, self._stack
    stack[n + 1], stack[n + 2] = self._ox, self._oy
    stack[n + 3], stack[n + 4] = self._clipX1, self._clipY1
    stack[n + 5], stack[n + 6] = self._clipX2, self._clipY2
    self._stackN = n + 6
    local ox, oy = self._ox + x - 1, self._oy + y - 1
    self._ox, self._oy = ox, oy
    self._clipX1 = math.max(self._clipX1, ox + 1)
    self._clipY1 = math.max(self._clipY1, oy + 1)
    self._clipX2 = math.min(self._clipX2, ox + width)
    self._clipY2 = math.min(self._clipY2, oy + height)
    return self
end
function Surface:pop()
    local n, stack = self._stackN, self._stack
    if n < 6 then error("Obsidian Buffer: clip stack underflow", 2) end
    self._ox, self._oy = stack[n - 5], stack[n - 4]
    self._clipX1, self._clipY1 = stack[n - 3], stack[n - 2]
    self._clipX2, self._clipY2 = stack[n - 1], stack[n]
    for i = n - 5, n do stack[i] = nil end
    self._stackN = n - 6
    return self
end
function Surface:setClip(x1, y1, x2, y2)
    local owner = self._owner
    self._clipX1 = math.max(1, math.floor(x1 or 1))
    self._clipY1 = math.max(1, math.floor(y1 or 1))
    self._clipX2 = math.min(owner._w, math.floor(x2 or owner._w))
    self._clipY2 = math.min(owner._h, math.floor(y2 or owner._h))
    return self
end
function Surface:clearClip()
    local owner = self._owner
    self._clipX1, self._clipY1 = 1, 1
    self._clipX2, self._clipY2 = owner._w, owner._h
    return self
end
function Surface:clear(charValue, fore, back)
    local owner = self._owner
    local textValue, fgValue, bgValue
    if self._opaque then
        textValue = charValue == nil and " " or tostring(charValue):sub(1, 1)
        fgValue = color.encode(fore, "0") or WHITE
        bgValue = color.encode(back, "f") or BLACK
    else
        textValue = charValue ~= nil and charValue ~= false
            and tostring(charValue):sub(1, 1) or nil
        fgValue = color.encode(fore)
        bgValue = color.encode(back)
    end
    self._text, self._fg, self._bg = newRows(
        owner._w, owner._h, textValue, fgValue, bgValue)
    self._spFg, self._spBg, self._spBits = nil, nil, nil
    self._spX1, self._spY1 = math.huge, math.huge
    self._spX2, self._spY2 = 0, 0
    markDirty(self, 1, 1, owner._w, owner._h)
    return self
end
function Surface:drawText(x, y, text, fore, back)
    x, y = math.floor(x or 1) + self._ox, math.floor(y or 1) + self._oy
    text = tostring(text or "")
    if y < self._clipY1 or y > self._clipY2 or #text == 0 then return self end
    local sourceStart = 1
    local drawStart, drawEnd = x, x + #text - 1
    if drawStart < self._clipX1 then
        sourceStart = sourceStart + self._clipX1 - drawStart
        drawStart = self._clipX1
    end
    drawEnd = math.min(drawEnd, self._clipX2)
    if drawStart > drawEnd then return self end
    local fgValue = encodeSurfaceColor(self, fore, "0")
    local bgValue = encodeSurfaceColor(self, back, "f")
    local rowT, rowF, rowB = self._text[y], self._fg[y], self._bg[y]
    for tx = drawStart, drawEnd do
        rowT[tx] = text:sub(sourceStart, sourceStart)
        if fgValue ~= nil then rowF[tx] = fgValue end
        if bgValue ~= nil then rowB[tx] = bgValue end
        sourceStart = sourceStart + 1
    end
    markDirty(self, drawStart, y, drawEnd, y)
    return self
end
function Surface:drawLine(y, text, fore, back)
    local width = self._owner._w
    text = tostring(text or "")
    if #text < width then text = text .. rep(" ", width - #text)
    elseif #text > width then text = text:sub(1, width) end
    return self:drawText(1, y, text, fore, back)
end
function Surface:drawRect(x, y, width, height, charValue, fore, back)
    width, height = math.floor(width or 0), math.floor(height or 0)
    if width <= 0 or height <= 0 then return self end
    local ch = tostring(charValue or " ")
    local row
    if #ch == 1 then
        row = rep(ch, width)
    else
        row = (ch .. rep(" ", width)):sub(1, width)
    end
    for dy = 0, height - 1 do self:drawText(x, y + dy, row, fore, back) end
    return self
end
function Surface:drawSprite(frame, x, y, camX, camY)
    if not frame or not frame[1] or not frame[2] or not frame[3] then return self end
    local sx = math.floor((x or 1) - (camX or 0)) + self._ox
    local sy = math.floor((y or 1) - (camY or 0)) + self._oy
    for rowIndex = 1, #frame[1] do
        local ty = sy + rowIndex - 1
        if ty >= self._clipY1 and ty <= self._clipY2 then
            local chars = frame[1][rowIndex]
            local fgs = frame[2][rowIndex]
            local bgs = frame[3][rowIndex]
            local rowLength = type(chars) == "string" and #chars or #(chars or {})
            local rowT, rowF, rowB = self._text[ty], self._fg[ty], self._bg[ty]
            local changedX1, changedX2 = math.huge, 0
            for column = 1, rowLength do
                local tx = sx + column - 1
                if inClip(self, tx, ty) then
                    local didChange = false
                    local c = rowValue(chars, column)
                    local fg = rowValue(fgs, column)
                    local bg = rowValue(bgs, column)
                    if c and c ~= " " then rowT[tx], didChange = c, true end
                    if fg and fg ~= " " then
                        rowF[tx], didChange = color.encode(fg), true
                    end
                    if bg and bg ~= " " then
                        rowB[tx], didChange = color.encode(bg), true
                    end
                    if didChange then
                        if tx < changedX1 then changedX1 = tx end
                        if tx > changedX2 then changedX2 = tx end
                    end
                end
            end
            if changedX1 <= changedX2 then
                markDirty(self, changedX1, ty, changedX2, ty)
            end
        end
    end
    return self
end
local function imagePalette(image)
    if image._obsidianPalette then return image._obsidianPalette end
    local mapped = {}
    for paletteIndex = 1, #image.palette do
        local rgb, encoded = image.palette[paletteIndex]
        for nativeIndex = 0, 15 do
            if rgb == flimg.NATIVE_RGB[nativeIndex] then
                encoded = color.encode(2 ^ nativeIndex)
                break
            end
        end
        mapped[paletteIndex] = encoded or color.encode(color.rgb(rgb))
    end
    image._obsidianPalette = mapped
    image._composedFrames = image._composedFrames or {}
    return mapped
end
function Surface:drawImage(image, x, y, frameIndex, camX, camY)
    if type(image) ~= "table" or image.format ~= "FLIMG" then
        error("Obsidian: drawImage expects a decoded FLIMG image", 2)
    end
    frameIndex = math.max(1, math.min(#image.frames, frameIndex or 1))
    local composed = image._composedFrames and image._composedFrames[frameIndex]
    if not composed then
        composed = flimg.compose(image, frameIndex)
        image._composedFrames = image._composedFrames or {}
        image._composedFrames[frameIndex] = composed
    end
    local palette = imagePalette(image)
    local cellX = math.floor((x or 1) - (camX or 0)) + self._ox
    local cellY = math.floor((y or 1) - (camY or 0)) + self._oy
    if image.mode == "pixel" then
        local clipX1, clipY1, clipX2, clipY2 = virtualClip(self)
        local originX, originY = (cellX - 1) * 2, (cellY - 1) * 3
        local dirtyX1, dirtyY1, dirtyX2, dirtyY2 = math.huge, math.huge, 0, 0
        for sourceY = 1, image.height do
            local targetY = originY + sourceY
            if targetY >= clipY1 and targetY <= clipY2 then
                local row = composed[sourceY]
                for sourceX = 1, image.width do
                    local targetX, paletteIndex = originX + sourceX, row:byte(sourceX)
                    if paletteIndex ~= 0 and targetX >= clipX1 and targetX <= clipX2 then
                        local encoded = palette[paletteIndex]
                        if not encoded then error("Obsidian: FLIMG palette index " .. paletteIndex .. " is missing", 2) end
                        ensureSubpixels(self)
                        storeSubpixel(self, targetX, targetY, encoded)
                        if targetX < dirtyX1 then dirtyX1 = targetX end
                        if targetY < dirtyY1 then dirtyY1 = targetY end
                        if targetX > dirtyX2 then dirtyX2 = targetX end
                        if targetY > dirtyY2 then dirtyY2 = targetY end
                    end
                end
            end
        end
        if dirtyX1 <= dirtyX2 then markSubpixelArea(self, dirtyX1, dirtyY1, dirtyX2, dirtyY2) end
        return self
    end
    for sourceY = 1, image.height do
        local targetY = cellY + sourceY - 1
        if targetY >= self._clipY1 and targetY <= self._clipY2 then
            local line, changedX1, changedX2 = composed[sourceY], math.huge, 0
            for sourceX = 1, image.width do
                local targetX = cellX + sourceX - 1
                if inClip(self, targetX, targetY) then
                    local glyph = line[1]:byte(sourceX)
                    local fgIndex, bgIndex = line[2]:byte(sourceX), line[3]:byte(sourceX)
                    local changed = false
                    if glyph ~= 0 then self._text[targetY][targetX], changed = char(glyph), true end
                    if fgIndex ~= 0 then self._fg[targetY][targetX], changed = palette[fgIndex], true end
                    if bgIndex ~= 0 then self._bg[targetY][targetX], changed = palette[bgIndex], true end
                    if changed then
                        if targetX < changedX1 then changedX1 = targetX end
                        if targetX > changedX2 then changedX2 = targetX end
                    end
                end
            end
            if changedX1 <= changedX2 then markDirty(self, changedX1, targetY, changedX2, targetY) end
        end
    end
    return self
end
function Surface:drawSubpixel(vx, vy, value, bgValue)
    vx, vy = math.floor(vx or 1) + self._ox * 2,
        math.floor(vy or 1) + self._oy * 3
    local clipVx1, clipVy1, clipVx2, clipVy2 = virtualClip(self)
    if vx < clipVx1 or vx > clipVx2 or vy < clipVy1 or vy > clipVy2 then return self end
    local encoded = color.encode(value)
    if not encoded then return self end
    local bgEncoded
    if bgValue ~= nil and bgValue ~= false and bgValue ~= " " then
        bgEncoded = color.encode(bgValue)
    end
    ensureSubpixels(self)
    storeSubpixel(self, vx, vy, encoded, bgEncoded)
    markSubpixelArea(self, vx, vy, vx, vy)
    return self
end
function Surface:drawSubpixelRect(vx, vy, width, height, value, bgValue)
    width, height = math.floor(width or 0), math.floor(height or 0)
    if width <= 0 or height <= 0 then return self end
    local x1 = math.floor(vx or 1) + self._ox * 2
    local y1 = math.floor(vy or 1) + self._oy * 3
    local x2, y2 = x1 + width - 1, y1 + height - 1
    local clipX1, clipY1, clipX2, clipY2 = virtualClip(self)
    x1, y1 = math.max(x1, clipX1), math.max(y1, clipY1)
    x2, y2 = math.min(x2, clipX2), math.min(y2, clipY2)
    if x1 > x2 or y1 > y2 then return self end
    local encoded = color.encode(value)
    if not encoded then return self end
    local bgEncoded
    if bgValue ~= nil and bgValue ~= false and bgValue ~= " " then
        bgEncoded = color.encode(bgValue)
    end
    ensureSubpixels(self)
    for py = y1, y2 do
        for px = x1, x2 do
            storeSubpixel(self, px, py, encoded, bgEncoded)
        end
    end
    markSubpixelArea(self, x1, y1, x2, y2)
    return self
end
function Surface:drawSubpixelLine(x1, y1, x2, y2, value)
    x1, y1 = math.floor(x1) + self._ox * 2, math.floor(y1) + self._oy * 3
    x2, y2 = math.floor(x2) + self._ox * 2, math.floor(y2) + self._oy * 3
    local encoded = color.encode(value)
    if not encoded then return self end
    ensureSubpixels(self)
    local clipX1, clipY1, clipX2, clipY2 = virtualClip(self)
    local boundX1, boundY1 = math.max(clipX1, math.min(x1, x2)), math.max(clipY1, math.min(y1, y2))
    local boundX2, boundY2 = math.min(clipX2, math.max(x1, x2)), math.min(clipY2, math.max(y1, y2))
    local dx, dy = math.abs(x2 - x1), math.abs(y2 - y1)
    local sx, sy = x1 < x2 and 1 or -1, y1 < y2 and 1 or -1
    local err = dx - dy
    while true do
        if x1 >= clipX1 and x1 <= clipX2 and y1 >= clipY1 and y1 <= clipY2 then
            storeSubpixel(self, x1, y1, encoded)
        end
        if x1 == x2 and y1 == y2 then break end
        local twice = 2 * err
        if twice > -dy then err, x1 = err - dy, x1 + sx end
        if twice < dx then err, y1 = err + dx, y1 + sy end
    end
    if boundX1 <= boundX2 and boundY1 <= boundY2 then
        markSubpixelArea(self, boundX1, boundY1, boundX2, boundY2)
    end
    return self
end
Surface.drawPixel = Surface.drawSubpixel
function Surface:clearSubpixels()
    if self._spX1 <= self._spX2 and self._spY1 <= self._spY2 then
        markDirty(self, self._spX1, self._spY1, self._spX2, self._spY2)
    end
    self._spFg, self._spBg, self._spBits = nil, nil, nil
    self._spX1, self._spY1 = math.huge, math.huge
    self._spX2, self._spY2 = 0, 0
    return self
end
function Surface:copyTo(target)
    target.t, target.f, target.b = target.t or {}, target.f or {}, target.b or {}
    local width, height = self._owner._w, self._owner._h
    for y = 1, height do
        target.t[y], target.f[y], target.b[y] = target.t[y] or {}, target.f[y] or {}, target.b[y] or {}
        move(self._text[y], 1, width, 1, target.t[y])
        move(self._fg[y], 1, width, 1, target.f[y])
        move(self._bg[y], 1, width, 1, target.b[y])
    end
    if self._spBits then
        local size = width * 2 * height * 3
        target.spFg, target.spBg, target.spBits = {}, {}, {}
        move(self._spFg, 1, size, 1, target.spFg)
        move(self._spBg, 1, size, 1, target.spBg)
        move(self._spBits, 1, size, 1, target.spBits)
    else
        target.spFg, target.spBg, target.spBits = nil, nil, nil
    end
    return target
end
function Surface:copyFrom(source)
    local width, height = self._owner._w, self._owner._h
    for y = 1, height do
        if source.t and source.t[y] then
            move(source.t[y], 1, width, 1, self._text[y])
            move(source.f[y], 1, width, 1, self._fg[y])
            move(source.b[y], 1, width, 1, self._bg[y])
        end
    end
    if source.spBits then
        local size = width * 2 * height * 3
        self._spFg, self._spBg, self._spBits = {}, {}, {}
        move(source.spFg, 1, size, 1, self._spFg)
        move(source.spBg, 1, size, 1, self._spBg)
        move(source.spBits, 1, size, 1, self._spBits)
        self._spX1, self._spY1, self._spX2, self._spY2 = 1, 1, width, height
    else
        self._spFg, self._spBg, self._spBits = nil, nil, nil
        self._spX1, self._spY1, self._spX2, self._spY2 = math.huge, math.huge, 0, 0
    end
    markDirty(self, 1, 1, width, height)
    return self
end
function Surface:restoreLine(y, source)
    local width, height = self._owner._w, self._owner._h
    if y < 1 or y > height or not source.t or not source.t[y] then return self end
    move(source.t[y], 1, width, 1, self._text[y])
    move(source.f[y], 1, width, 1, self._fg[y])
    move(source.b[y], 1, width, 1, self._bg[y])
    local virtualWidth = width * 2
    if source.spBits then ensureSubpixels(self) end
    if self._spBits then
        for subRow = (y - 1) * 3 + 1, y * 3 do
            local first = (subRow - 1) * virtualWidth + 1
            local last = first + virtualWidth - 1
            if source.spBits then
                move(source.spFg, first, last, first, self._spFg)
                move(source.spBg, first, last, first, self._spBg)
                move(source.spBits, first, last, first, self._spBits)
            else
                for index = first, last do
                    self._spFg[index], self._spBg[index], self._spBits[index] = nil, nil, nil
                end
            end
        end
        self._spX1, self._spY1, self._spX2, self._spY2 = 1, 1, width, height
    end
    markDirty(self, 1, y, width, y)
    return self
end
function Surface:present()
    return self._owner:present()
end
local function initComposite(self)
    self._screenT, self._screenF, self._screenB = newRows(
        self._w, self._h, " ", WHITE, BLACK)
    self._lastT, self._lastF, self._lastB = {}, {}, {}
    self._dirty = {}
    for y = 1, self._h do self._dirty[y] = true end
end
function buffer.new(width, height, targetTerm)
    if type(width) == "table" then
        targetTerm, width, height = width, nil, nil
    end
    local target = targetTerm or term
    local terminalWidth, terminalHeight = target.getSize()
    local self = setmetatable({
        _term = target,
        _w = width or terminalWidth,
        _h = height or terminalHeight,
        _layers = {},
        _layerByName = {},
        _nextSequence = 1,
        _fullComposition = true,
        BufferModule = buffer,
    }, Buffer)
    self._mapper = color.newMapper(target)
    self._default = createSurface(self, "default", 0, true)
    self._layers[1], self._layerByName.default = self._default, self._default
    initComposite(self)
    return self
end
function Buffer:_sortLayers()
    table.sort(self._layers, function(a, b)
        if a.zIndex == b.zIndex then return a._sequence < b._sequence end
        return a.zIndex < b.zIndex
    end)
end
function Buffer:_markFullComposition()
    self._fullComposition = true
    for y = 1, self._h do self._dirty[y] = true end
end
function Buffer:getSize()
    return self._w, self._h
end
function Buffer:getVirtualSize()
    return self._w * 2, self._h * 3
end
function Buffer:setSize(width, height)
    width, height = math.floor(width), math.floor(height)
    if width < 1 or height < 1 then return self end
    self._w, self._h = width, height
    for _, layer in ipairs(self._layers) do resetSurface(layer) end
    initComposite(self)
    self._fullComposition = true
    return self
end
function Buffer:getTarget()
    return self._term
end
function Buffer:addLayer(name, zIndex)
    assert(type(name) == "string" and name ~= "", "Buffer:addLayer requires a name")
    if self._layerByName[name] then
        error("Obsidian Buffer: layer already exists: " .. name, 2)
    end
    local layer = createSurface(self, name, zIndex or 0, false)
    self._layers[#self._layers + 1] = layer
    self._layerByName[name] = layer
    self:_sortLayers()
    self:_markFullComposition()
    return layer
end
Buffer.createLayer = Buffer.addLayer
function Buffer:getLayer(name)
    return self._layerByName[name]
end
function Buffer:getLayers()
    local result = {}
    for i, layer in ipairs(self._layers) do result[i] = layer end
    return result
end
function Buffer:removeLayer(layerOrName)
    local layer = type(layerOrName) == "string" and self._layerByName[layerOrName]
        or layerOrName
    if not layer or layer == self._default then return false end
    for i, item in ipairs(self._layers) do
        if item == layer then table.remove(self._layers, i); break end
    end
    self._layerByName[layer.name] = nil
    self:_markFullComposition()
    return true
end
function Buffer:getDefaultLayer()
    return self._default
end
local function flushPixels(pixels)
    return compileMosaic(pixels[1], pixels[2], pixels[3],
        pixels[4], pixels[5], pixels[6])
end
function Buffer:_composeCell(x, y)
    local outT, outF, outB = " ", WHITE, BLACK
    local pixels
    local spIndices
    for _, layer in ipairs(self._layers) do
        if layer.visible then
            local lt, lf, lb = layer._text[y][x], layer._fg[y][x], layer._bg[y][x]
            if lt ~= nil or lf ~= nil or lb ~= nil then
                if pixels then
                    outT, outF, outB = flushPixels(pixels)
                    pixels = nil
                end
                if lt ~= nil then outT = lt end
                if lf ~= nil then outF = lf end
                if lb ~= nil then outB = lb end
            end
            if layer._spBits then
                if not spIndices then
                    local virtualWidth = self._w * 2
                    local vy1 = (y - 1) * 3 + 1
                    local vx1 = (x - 1) * 2 + 1
                    spIndices = {
                        (vy1 - 1) * virtualWidth + vx1,
                        (vy1 - 1) * virtualWidth + vx1 + 1,
                        vy1 * virtualWidth + vx1,
                        vy1 * virtualWidth + vx1 + 1,
                        (vy1 + 1) * virtualWidth + vx1,
                        (vy1 + 1) * virtualWidth + vx1 + 1,
                    }
                end
                local hasSubpixels = false
                for i = 1, 6 do
                    local index = spIndices[i]
                    if layer._spBits[index] or layer._spBg[index] ~= nil then
                        hasSubpixels = true
                        break
                    end
                end
                if hasSubpixels then
                    if not pixels then pixels = { outB, outB, outB, outB, outB, outB } end
                    for i = 1, 6 do
                        local index = spIndices[i]
                        if layer._spBits[index] then
                            pixels[i] = layer._spFg[index] or outF
                        elseif layer._spBg[index] ~= nil then
                            pixels[i] = layer._spBg[index]
                        end
                    end
                end
            end
        end
    end
    if pixels then outT, outF, outB = flushPixels(pixels) end
    return outT, outF, outB
end
function Buffer:_compose()
    local x1, y1, x2, y2 = math.huge, math.huge, 0, 0
    if self._fullComposition then
        x1, y1, x2, y2 = 1, 1, self._w, self._h
    else
        for _, layer in ipairs(self._layers) do
            if layer._dirtyX1 < x1 then x1 = layer._dirtyX1 end
            if layer._dirtyY1 < y1 then y1 = layer._dirtyY1 end
            if layer._dirtyX2 > x2 then x2 = layer._dirtyX2 end
            if layer._dirtyY2 > y2 then y2 = layer._dirtyY2 end
        end
    end
    if x1 > x2 or y1 > y2 then return false end
    x1, y1 = math.max(1, x1), math.max(1, y1)
    x2, y2 = math.min(self._w, x2), math.min(self._h, y2)
    for y = y1, y2 do
        local rowT, rowF, rowB = self._screenT[y], self._screenF[y], self._screenB[y]
        for x = x1, x2 do
            rowT[x], rowF[x], rowB[x] = self:_composeCell(x, y)
        end
        self._dirty[y] = true
    end
    for _, layer in ipairs(self._layers) do resetDirty(layer) end
    self._fullComposition = false
    return true
end
local function scanColors(row, used)
    for x = 1, #row do used[row:byte(x)] = true end
end
function Buffer:present()
    self:_compose()
    local hasDirty = false
    for y = 1, self._h do
        if self._dirty[y] then hasDirty = true; break end
    end
    if not hasDirty then return self end
    local logicalT, logicalF, logicalB = {}, {}, {}
    local used = {}
    for y = 1, self._h do
        logicalT[y] = table.concat(self._screenT[y])
        logicalF[y] = table.concat(self._screenF[y])
        logicalB[y] = table.concat(self._screenB[y])
        scanColors(logicalF[y], used)
        scanColors(logicalB[y], used)
    end
    local map, force = self._mapper:build(used)
    for y = 1, self._h do
        if force or self._dirty[y] then
            local text, fg, bg = logicalT[y], logicalF[y], logicalB[y]
            if force or text ~= self._lastT[y] or fg ~= self._lastF[y] or bg ~= self._lastB[y] then
                self._term.setCursorPos(1, y)
                self._term.blit(text, (fg:gsub(".", map)), (bg:gsub(".", map)))
                self._lastT[y], self._lastF[y], self._lastB[y] = text, fg, bg
            end
            self._dirty[y] = false
        end
    end
    return self
end
Buffer.flush = Buffer.present
function Buffer:invalidate()
    self._lastT, self._lastF, self._lastB = {}, {}, {}
    self:_markFullComposition()
    return self
end
function Buffer:restorePalette()
    self._mapper:restore()
    return self
end
function Buffer:compileSubpixels()
    self:_compose()
    return self
end
local delegated = {
    "push", "pop", "setClip", "clearClip", "clear",
    "drawText", "drawLine", "drawRect", "drawSprite",
    "drawImage",
    "drawSubpixel", "drawSubpixelRect", "drawSubpixelLine",
    "drawPixel", "clearSubpixels", "copyTo", "copyFrom", "restoreLine",
}
for _, method in ipairs(delegated) do
    Buffer[method] = function(self, ...)
        return self._default[method](self._default, ...)
    end
end
buffer.rgb = color.rgb
buffer.color = color
buffer.Buffer = Buffer
buffer.Surface = Surface
return buffer
]=]
paths["core.buffer"] = "core/buffer"
sources["core.camera"] = [=[

local camera = {}
local CameraInstance = {}
CameraInstance.__index = CameraInstance
function camera.new(scene)
    assert(scene and scene.camera, "camera.new: scene must have a .camera vec2")
    local self = setmetatable({}, CameraInstance)
    self._scene       = scene
    self._targetX     = scene.camera.x
    self._targetY     = scene.camera.y
    self.lerpFactor   = 0.1
    self._followId    = nil
    self._followComp  = "pos"
    self._deadzone    = nil
    self._boundsX1    = nil
    self._boundsY1    = nil
    self._boundsX2    = nil
    self._boundsY2    = nil
    self.offsetX      = 0
    self.offsetY      = 0
    self._shakeIntensity   = 0
    self._shakeDuration    = 0
    self._shakeDurationMax = 0
    self._shakeOffsetX     = 0
    self._shakeOffsetY     = 0
    self._flashColor       = "0"
    self._flashDuration    = 0
    scene._camera = self
    return self
end
function CameraInstance:follow(id, opts)
    opts = opts or {}
    self._followId   = id
    self._followComp = opts.comp or "pos"
    if opts.lerp    ~= nil then self.lerpFactor = opts.lerp end
    if opts.deadzone       then self._deadzone  = opts.deadzone end
end
function CameraInstance:unfollow()
    self._followId = nil
end
function CameraInstance:setBounds(x1, y1, x2, y2)
    self._boundsX1 = x1
    self._boundsY1 = y1
    self._boundsX2 = x2
    self._boundsY2 = y2
end
function CameraInstance:clearBounds()
    self._boundsX1, self._boundsY1 = nil, nil
    self._boundsX2, self._boundsY2 = nil, nil
end
function CameraInstance:setOffset(ox, oy)
    self.offsetX = ox or 0
    self.offsetY = oy or 0
end
function CameraInstance:moveTo(wx, wy)
    self._targetX = wx + self.offsetX
    self._targetY = wy + self.offsetY
    self:_applyBounds()
    self._scene.camera.x = self._targetX
    self._scene.camera.y = self._targetY
end
function CameraInstance:pan(dx, dy)
    self._targetX = self._targetX + (dx or 0)
    self._targetY = self._targetY + (dy or 0)
    self:_applyBounds()
    self._scene.camera.x = self._targetX
    self._scene.camera.y = self._targetY
end
function CameraInstance:update(dt)
    local scene = self._scene
    if self._followId then
        local comp = scene.components[self._followComp]
        local pos  = comp and comp[self._followId]
        if pos then
            local desiredX = pos.x + self.offsetX
            local desiredY = pos.y + self.offsetY
            if self._deadzone then
                local hw = self._deadzone.w * 0.5
                local hh = self._deadzone.h * 0.5
                local cx = self._targetX
                local cy = self._targetY
                if desiredX < cx - hw then
                    self._targetX = desiredX + hw
                elseif desiredX > cx + hw then
                    self._targetX = desiredX - hw
                end
                if desiredY < cy - hh then
                    self._targetY = desiredY + hh
                elseif desiredY > cy + hh then
                    self._targetY = desiredY - hh
                end
            else
                self._targetX = desiredX
                self._targetY = desiredY
            end
        end
    end
    self:_applyBounds()
    local f = math.min(1, self.lerpFactor * (dt * 60))
    scene.camera.x = scene.camera.x + (self._targetX - scene.camera.x) * f
    scene.camera.y = scene.camera.y + (self._targetY - scene.camera.y) * f
    if self._shakeDuration > 0 then
        self._shakeDuration = self._shakeDuration - dt
        if self._shakeDuration <= 0 then
            self._shakeDuration = 0
            self._shakeOffsetX  = 0
            self._shakeOffsetY  = 0
            scene._staticDirty   = true
        else
            local falloff = self._shakeDuration / self._shakeDurationMax
            local intensity = self._shakeIntensity * falloff
            self._shakeOffsetX = (math.random() - 0.5) * 2 * intensity
            self._shakeOffsetY = (math.random() - 0.5) * 2 * intensity
        end
    end
    if self._flashDuration > 0 then
        self._flashDuration = self._flashDuration - dt
    end
end
function CameraInstance:shake(intensity, duration)
    self._shakeIntensity   = intensity or 1
    self._shakeDuration    = duration  or 0.5
    self._shakeDurationMax = self._shakeDuration
end
function CameraInstance:flash(color, duration)
    self._flashColor    = color    or "0"
    self._flashDuration = duration or 0.2
end
function CameraInstance:isShaking()
    return self._shakeDuration > 0
end
function CameraInstance:getShakeOffset()
    return self._shakeOffsetX, self._shakeOffsetY
end
function CameraInstance:isFlashing()
    return self._flashDuration > 0
end
function CameraInstance:getFlashColor()
    return self._flashColor
end
function CameraInstance:worldToScreen(wx, wy)
    local scene = self._scene
    local termW, termH
    if scene and scene.ui and scene.ui.buf and type(scene.ui.buf.getSize) == "function" then
        termW, termH = scene.ui.buf:getSize()
    else
        termW, termH = term.getSize()
    end
    local designW, designH = debug.designW, debug.designH
    local offsetX, offsetY = 0, 0
    if designW and designH then
        offsetX = math.max(0, math.floor((termW - designW) / 2))
        offsetY = math.max(0, math.floor((termH - designH) / 2))
    end
    local sx = math.floor(wx - scene.camera.x + offsetX) + 1
    local sy = math.floor(wy - scene.camera.y + offsetY) + 1
    return sx, sy
end
function CameraInstance:screenToWorld(sx, sy)
    local scene = self._scene
    local termW, termH
    if scene and scene.ui and scene.ui.buf and type(scene.ui.buf.getSize) == "function" then
        termW, termH = scene.ui.buf:getSize()
    else
        termW, termH = term.getSize()
    end
    local designW, designH = debug.designW, debug.designH
    local offsetX, offsetY = 0, 0
    if designW and designH then
        offsetX = math.max(0, math.floor((termW - designW) / 2))
        offsetY = math.max(0, math.floor((termH - designH) / 2))
    end
    local wx = (sx - 1) + scene.camera.x - offsetX
    local wy = (sy - 1) + scene.camera.y - offsetY
    return wx, wy
end
function CameraInstance:getPosition()
    return self._scene.camera.x, self._scene.camera.y
end
function CameraInstance:_applyBounds()
    if self._boundsX1 ~= nil and self._targetX < self._boundsX1 then
        self._targetX = self._boundsX1
    end
    if self._boundsY1 ~= nil and self._targetY < self._boundsY1 then
        self._targetY = self._boundsY1
    end
    if self._boundsX2 ~= nil and self._targetX > self._boundsX2 then
        self._targetX = self._boundsX2
    end
    if self._boundsY2 ~= nil and self._targetY > self._boundsY2 then
        self._targetY = self._boundsY2
    end
end
return camera
]=]
paths["core.camera"] = "core/camera"
sources["core.color"] = [=[

local color = {}
local floor = math.floor
local char = string.char
local NATIVE_HEX = {
    [0] = 0xF0F0F0, 0xF2B233, 0xE57FD8, 0x99B2F2,
    0xDEDE6C, 0x7FCC19, 0xF2B2CC, 0x4C4C4C,
    0x999999, 0x4C99B2, 0xB266E5, 0x3366CC,
    0x7F664C, 0x57A64E, 0xCC4C4C, 0x111111,
}
local HEX = {}
local HEX_TO_INDEX = {}
local NATIVE_VALUE_TO_INDEX = {}
for i = 0, 15 do
    local h = ("%x"):format(i)
    HEX[i] = h
    HEX_TO_INDEX[h] = i
    HEX_TO_INDEX[h:upper()] = i
    NATIVE_VALUE_TO_INDEX[2 ^ i] = i
end
local function hexToRGB(n)
    return floor(n / 65536) / 255,
        floor(n / 256) % 256 / 255,
        (n % 256) / 255
end
local registry = {}
for i = 0, 15 do registry[i] = { hexToRGB(NATIVE_HEX[i]) } end
local nextIndex = 16
local dedupe = {}
local HANDLE_BASE = 0x1000000
for i = 0, 15 do dedupe[NATIVE_HEX[i]] = i end
local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end
local function parseRGB(r, g, b)
    if type(r) == "string" then
        local value = r:gsub("#", "")
        if value:match("^%x%x%x$") then
            value = value:sub(1, 1):rep(2)
                .. value:sub(2, 2):rep(2)
                .. value:sub(3, 3):rep(2)
        elseif value:match("^%x%x%x%x%x%x%x%x$") then
            value = value:sub(3)
        elseif not value:match("^%x%x%x%x%x%x$") then
            error("Obsidian: invalid RGB color '" .. tostring(r)
                .. "' (expected #RGB, #RRGGBB or #AARRGGBB)", 3)
        end
        return hexToRGB(tonumber(value, 16))
    end
    if type(r) ~= "number" then
        error("Obsidian: invalid color value " .. tostring(r), 3)
    end
    if g == nil then
        if r < 0 or r > 0xFFFFFF or r % 1 ~= 0 then
            error("Obsidian: invalid RGB number " .. tostring(r)
                .. " (expected 0x000000-0xFFFFFF)", 3)
        end
        return hexToRGB(r)
    end
    if type(g) ~= "number" or type(b) ~= "number" then
        error("Obsidian: rgb requires three numeric components", 3)
    end
    if r > 1 or g > 1 or b > 1 then
        r, g, b = r / 255, g / 255, b / 255
    end
    return clamp01(r), clamp01(g), clamp01(b)
end
local function registerRGB(r, g, b)
    local rr, gg, bb = parseRGB(r, g, b)
    local key = floor(rr * 255 + 0.5) * 65536
        + floor(gg * 255 + 0.5) * 256
        + floor(bb * 255 + 0.5)
    local known = dedupe[key]
    if known then return known end
    if nextIndex > 255 then
        local best, bestDistance = 0, math.huge
        for index = 0, 255 do
            local rgb = registry[index]
            local distance = (rr - rgb[1]) ^ 2 + (gg - rgb[2]) ^ 2 + (bb - rgb[3]) ^ 2
            if distance < bestDistance then best, bestDistance = index, distance end
        end
        dedupe[key] = best
        return best
    end
    local idx = nextIndex
    nextIndex = nextIndex + 1
    registry[idx] = { rr, gg, bb }
    dedupe[key] = idx
    return idx
end
function color.rgb(r, g, b)
    return HANDLE_BASE + registerRGB(r, g, b)
end
local function indexOf(value)
    if value == nil or value == false or value == " " then return nil end
    if type(value) == "string" then
        if #value == 1 and HEX_TO_INDEX[value] ~= nil then
            return HEX_TO_INDEX[value]
        end
        return registerRGB(value)
    end
    if type(value) == "number" then
        if value >= HANDLE_BASE then
            local idx = value - HANDLE_BASE
            if idx >= 0 and idx <= 255 and registry[idx] then return idx end
            error("Obsidian: invalid RGB color handle " .. tostring(value), 3)
        end
        local native = NATIVE_VALUE_TO_INDEX[value]
        if native ~= nil then return native end
        return registerRGB(value)
    end
    error("Obsidian: unsupported color value " .. tostring(value), 3)
end
function color.encode(value, default)
    if value == nil then value = default end
    local idx = indexOf(value)
    return idx ~= nil and char(idx) or nil
end
function color.indexOf(value)
    return indexOf(value)
end
function color.getRGB(index)
    return registry[index]
end
color.identityMap = {}
for i = 0, 15 do color.identityMap[char(i)] = HEX[i] end
local Mapper = {}
Mapper.__index = Mapper
local function rgbDistance(a, b)
    local dr, dg, db = a[1] - b[1], a[2] - b[2], a[3] - b[3]
    return dr * dr + dg * dg + db * db
end
local function readPalette(t, index)
    local getter = t.getPaletteColour or t.getPaletteColor
    if getter then
        local ok, r, g, b = pcall(getter, 2 ^ index)
        if ok and r ~= nil then return { r, g, b } end
    end
    return { hexToRGB(NATIVE_HEX[index]) }
end
function color.newMapper(t)
    local native = {}
    for i = 0, 15 do native[i] = readPalette(t, i) end
    return setmetatable({
        term = t,
        native = native,
        overridden = {},
        previousSlot = {},
        previousMap = {},
    }, Mapper)
end
local function setPalette(mapper, slot, rgb, registryIndex)
    local setter = mapper.term.setPaletteColour or mapper.term.setPaletteColor
    if not setter then return end
    if mapper.overridden[slot] == registryIndex then return end
    setter(2 ^ slot, rgb[1], rgb[2], rgb[3])
    mapper.overridden[slot] = registryIndex
end
function Mapper:build(used)
    local setter = self.term.setPaletteColour or self.term.setPaletteColor
    local map, occupant = {}, {}
    for i = 0, 15 do
        map[char(i)] = HEX[i]
        if used[i] then
            occupant[i] = i
            if setter and self.overridden[i] ~= nil then
                setter(2 ^ i, self.native[i][1], self.native[i][2], self.native[i][3])
                self.overridden[i] = nil
            end
        end
    end
    local custom = {}
    for idx in pairs(used) do
        if idx > 15 then custom[#custom + 1] = idx end
    end
    table.sort(custom)
    local leftovers = {}
    if setter then
        local function assign(idx, slot)
            occupant[slot] = idx
            self.previousSlot[idx] = slot
            setPalette(self, slot, registry[idx], idx)
            map[char(idx)] = HEX[slot]
        end
        local pending = {}
        for _, idx in ipairs(custom) do
            local slot = self.previousSlot[idx]
            if slot ~= nil and occupant[slot] == nil then
                assign(idx, slot)
            else
                pending[#pending + 1] = idx
            end
        end
        local nextSlot = 0
        for _, idx in ipairs(pending) do
            while nextSlot <= 15 and occupant[nextSlot] ~= nil do
                nextSlot = nextSlot + 1
            end
            if nextSlot <= 15 then
                assign(idx, nextSlot)
                nextSlot = nextSlot + 1
            else
                leftovers[#leftovers + 1] = idx
            end
        end
    else
        for i = 0, 15 do occupant[i] = i end
        leftovers = custom
    end
    for _, idx in ipairs(leftovers) do
        local bestSlot, bestDistance = 15, math.huge
        for slot = 0, 15 do
            local shownIndex = occupant[slot]
            if shownIndex ~= nil then
                local shown = shownIndex <= 15 and self.native[shownIndex]
                    or registry[shownIndex]
                local distance = rgbDistance(registry[idx], shown)
                if distance < bestDistance then
                    bestSlot, bestDistance = slot, distance
                end
            end
        end
        map[char(idx)] = HEX[bestSlot]
    end
    local force = false
    for byte, slot in pairs(map) do
        local previous = self.previousMap[byte]
        if previous ~= nil and previous ~= slot then
            force = true
            break
        end
    end
    self.previousMap = map
    return map, force
end
function Mapper:restore()
    local setter = self.term.setPaletteColour or self.term.setPaletteColor
    if setter then
        for slot in pairs(self.overridden) do
            local rgb = self.native[slot]
            setter(2 ^ slot, rgb[1], rgb[2], rgb[3])
        end
    end
    self.overridden, self.previousSlot, self.previousMap = {}, {}, {}
end
return color
]=]
paths["core.color"] = "core/color"
sources["core.console"] = [=[

local Console = {}
local HEIGHT = 10
local PROMPT = "> "
local MAX_HIST = 300
local state = {
    open    = false,
    input   = "",
    scroll  = 0,
    history = {},
    cmdHist = {},
    cmdIdx  = 0,
    env     = nil,
    commands = {},
}
function Console.isOpen()
    return state.open
end
function Console.open()
    state.open   = true
    state.scroll = 0
end
function Console.close()
    state.open   = false
    state.input  = ""
    state.cmdIdx = 0
    state.scroll = 0
end
function Console.toggle()
    if state.open then Console.close() else Console.open() end
end
function Console.setEnv(env)
    state.env = env
end
local function wrapText(text, maxW)
    local lines = {}
    for para in (tostring(text) .. "\n"):gmatch("([^\n]*)\n") do
        if #para == 0 then
            table.insert(lines, "")
        elseif #para <= maxW then
            table.insert(lines, para)
        else
            local words = {}
            for w in para:gmatch("%S+") do table.insert(words, w) end
            local cur = ""
            for _, word in ipairs(words) do
                if #cur == 0 then
                    if #word > maxW then
                        while #word > maxW do
                            table.insert(lines, word:sub(1, maxW))
                            word = word:sub(maxW + 1)
                        end
                        cur = word
                    else
                        cur = word
                    end
                elseif #cur + 1 + #word <= maxW then
                    cur = cur .. " " .. word
                else
                    table.insert(lines, cur)
                    cur = word
                end
            end
            if #cur > 0 then table.insert(lines, cur) end
        end
    end
    return lines
end
local currentWrapWidth = 48
function Console.addLine(text, fg)
    local lines = wrapText(tostring(text), currentWrapWidth - 2)
    for _, line in ipairs(lines) do
        table.insert(state.history, { text = line, fg = fg or "0" })
    end
    while #state.history > MAX_HIST do
        table.remove(state.history, 1)
    end
end
function Console.print(text)
    Console.addLine(tostring(text), "b")
end
function Console.addCommand(name, fn, description)
    state.commands[name] = { fn = fn, desc = description or "" }
end
function Console.removeCommand(name)
    state.commands[name] = nil
end
function Console.exec(cmd)
    if cmd == "" then return end
    if state.cmdHist[#state.cmdHist] ~= cmd then
        table.insert(state.cmdHist, cmd)
    end
    state.cmdIdx = 0
    state.scroll = 0
    Console.addLine(PROMPT .. cmd, "7")
    if cmd == "help" then
        Console.addLine("  Registered commands:", "7")
        local found = false
        for name, entry in pairs(state.commands) do
            found = true
            local line = "  " .. name
            if entry.desc ~= "" then line = line .. "  —  " .. entry.desc end
            Console.addLine(line, "b")
        end
        if not found then Console.addLine("  (none registered)", "8") end
        return
    end
    local cmdName, rest = cmd:match("^(%S+)(.*)$")
    if cmdName and state.commands[cmdName] then
        local args = {}
        for arg in (rest or ""):gmatch("%S+") do
            table.insert(args, arg)
        end
        local oldPrint = _G.print
        _G.print = Console.print
        local ok, err = pcall(state.commands[cmdName].fn, table.unpack(args))
        _G.print = oldPrint
        if not ok then
            Console.addLine("  " .. tostring(err), "e")
        end
        return
    end
    local env = state.env or _ENV
    local chunk, err = load("return " .. cmd, "console", "t", env)
    if not chunk then
        chunk, err = load(cmd, "console", "t", env)
    end
    if not chunk then
        Console.addLine("  " .. tostring(err), "e")
        return
    end
    local results = table.pack(pcall(chunk))
    local ok = results[1]
    if not ok then
        Console.addLine("  " .. tostring(results[2]), "e")
    elseif results.n > 1 then
        local parts = {}
        for i = 2, results.n do
            parts[i - 1] = tostring(results[i])
        end
        Console.addLine("  = " .. table.concat(parts, ", "), "5")
    end
end
function Console.handleEvent(event, consumed)
    local etype = event[1]
    if not state.open then
        if not consumed and etype == "key" and event[2] == keys.f1 then
            Console.open()
            return true
        end
        return false
    end
    if etype == "term_resize" then return false end
    if etype == "char" then
        state.input = state.input .. event[2]
    elseif etype == "key" then
        local k = event[2]
        if k == keys.f1 then
            Console.close()
            return true
        elseif k == keys.enter then
            Console.exec(state.input)
            state.input  = ""
            state.cmdIdx = 0
        elseif k == keys.backspace then
            state.input = state.input:sub(1, -2)
        elseif k == keys.up then
            if #state.cmdHist > 0 then
                state.cmdIdx = math.min(state.cmdIdx + 1, #state.cmdHist)
                state.input  = state.cmdHist[#state.cmdHist - state.cmdIdx + 1]
            end
        elseif k == keys.down then
            if state.cmdIdx > 1 then
                state.cmdIdx = state.cmdIdx - 1
                state.input  = state.cmdHist[#state.cmdHist - state.cmdIdx + 1]
            else
                state.cmdIdx = 0
                state.input  = ""
            end
        elseif k == keys.pageUp then
            local maxOut = HEIGHT - 3
            state.scroll = math.min(state.scroll + math.floor(maxOut / 2), #state.history - maxOut)
            state.scroll = math.max(0, state.scroll)
        elseif k == keys.pageDown then
            state.scroll = math.max(0, state.scroll - math.floor((HEIGHT - 3) / 2))
        end
    elseif etype == "mouse_scroll" then
        state.scroll = state.scroll - event[2]
        local maxOut = HEIGHT - 3
        state.scroll = math.max(0, math.min(state.scroll, math.max(0, #state.history - maxOut)))
    end
    return true
end
function Console.draw(buf)
    if not state.open then return end
    local w, h = buf:getSize()
    local top  = h - HEIGHT + 1
    currentWrapWidth = w
    buf:drawRect(1, top, w, HEIGHT, " ", "f", "8")
    buf:drawRect(1, top, w, 1, " ", "0", "7")
    local title = " Obsidian Console   F1 toggle  PgUp/PgDn scroll"
    buf:drawText(1, top, title:sub(1, w), "0", "7")
    local maxOut   = HEIGHT - 3
    local total    = #state.history
    local startIdx = math.max(1, total - maxOut + 1 - state.scroll)
    local endIdx   = math.min(total, startIdx + maxOut - 1)
    local row = top + 1
    for i = startIdx, endIdx do
        local line = state.history[i]
        buf:drawText(2, row, line.text, line.fg, "8")
        row = row + 1
    end
    if state.scroll > 0 then
        local indicator = string.format(" ^%d ", state.scroll)
        buf:drawText(w - #indicator, top + 1, indicator, "5", "8")
    end
    local sepRow = top + HEIGHT - 2
    buf:drawRect(1, sepRow, w, 1, string.rep("\140", w), "7", "8")
    local inputRow  = top + HEIGHT - 1
    local available = w - #PROMPT - 1
    local display   = PROMPT .. state.input:sub(-available)
    buf:drawRect(1, inputRow, w, 1, " ", "f", "0")
    buf:drawText(1, inputRow, display:sub(1, w), "f", "0")
end
return Console
]=]
paths["core.console"] = "core/console"
sources["core.db"] = [=[

local require = ...
local logger  = require("core.logger")
local DatabaseModule = {}
local Collection = {}
Collection.__index = Collection
local function _matches(record, filter)
    for k, v in pairs(filter) do
        local rv = record[k]
        if type(v) == "function" then
            if not v(rv) then return false end
        else
            if rv ~= v then return false end
        end
    end
    return true
end
local function _copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = _copy(v)
    end
    return out
end
function DatabaseModule.open(name, opts)
    opts = opts or {}
    local self = setmetatable({}, Collection)
    self._name = name
    self._dir = opts.dir or "db/"
    self._autosave = (opts.autosave ~= false)
    self._records = {}
    self._nextId = 1
    local path = fs.combine(self._dir, name .. ".dat")
    if fs.exists(path) then
        local file = fs.open(path, "r")
        if file then
            local ok, saved = pcall(textutils.unserialize, file.readAll())
            file.close()
            if ok and saved then
                self._records = saved.records or {}
                self._nextId  = saved.nextId  or 1
                logger.info("DB: Loaded collection '" .. name .. "' (" .. #self._records .. " records)")
            else
                logger.error("DB: Failed to parse '" .. path .. "'")
            end
        end
    end
    return self
end
function Collection:insert(record)
    local r = _copy(record)
    if r._id == nil then
        r._id = self._nextId
        self._nextId = self._nextId + 1
    else
        if type(r._id) == "number" and r._id >= self._nextId then
            self._nextId = r._id + 1
        end
    end
    table.insert(self._records, r)
    if self._autosave then self:flush() end
    return _copy(r)
end
function Collection:insertMany(list)
    local out = {}
    for _, rec in ipairs(list) do
        out[#out + 1] = self:insert(rec)
    end
    return out
end
function Collection:update(filter, patch)
    local count = 0
    for _, rec in ipairs(self._records) do
        if _matches(rec, filter) then
            for k, v in pairs(patch) do
                if k ~= "_id" then
                    rec[k] = _copy(v)
                end
            end
            count = count + 1
        end
    end
    if count > 0 and self._autosave then self:flush() end
    return count
end
function Collection:upsert(filter, data)
    local existing = self:findOne(filter)
    if existing then
        self:update({ _id = existing._id }, data)
        return "updated"
    else
        self:insert(data)
        return "inserted"
    end
end
function Collection:delete(filter)
    local kept  = {}
    local count = 0
    for _, rec in ipairs(self._records) do
        if _matches(rec, filter) then
            count = count + 1
        else
            kept[#kept + 1] = rec
        end
    end
    self._records = kept
    if count > 0 and self._autosave then self:flush() end
    return count
end
function Collection:clear()
    local count = #self._records
    self._records = {}
    self._nextId  = 1
    if self._autosave then self:flush() end
    return count
end
function Collection:find(filter, opts)
    opts = opts or {}
    local results = {}
    for _, rec in ipairs(self._records) do
        if not filter or _matches(rec, filter) then
            results[#results + 1] = _copy(rec)
        end
    end
    if opts.orderBy then
        local field = opts.orderBy
        local desc  = opts.desc == true
        table.sort(results, function(a, b)
            local av, bv = a[field], b[field]
            if av == nil then return false end
            if bv == nil then return true  end
            if desc then return av > bv else return av < bv end
        end)
    end
    if opts.offset or opts.limit then
        local start = (opts.offset or 0) + 1
        local stop  = opts.limit and (start + opts.limit - 1) or #results
        local sliced = {}
        for i = start, math.min(stop, #results) do
            sliced[#sliced + 1] = results[i]
        end
        return sliced
    end
    return results
end
function Collection:findOne(filter)
    for _, rec in ipairs(self._records) do
        if not filter or _matches(rec, filter) then
            return _copy(rec)
        end
    end
    return nil
end
function Collection:findById(id)
    return self:findOne({ _id = id })
end
function Collection:count(filter)
    if not filter then return #self._records end
    local n = 0
    for _, rec in ipairs(self._records) do
        if _matches(rec, filter) then n = n + 1 end
    end
    return n
end
function Collection:flush()
    if not fs.exists(self._dir) then fs.makeDir(self._dir) end
    local path = fs.combine(self._dir, self._name .. ".dat")
    local file = fs.open(path, "w")
    if not file then
        logger.error("DB: Failed to open '" .. path .. "' for writing")
        return false
    end
    local ok, err = pcall(function()
        file.write(textutils.serialize({ records = self._records, nextId = self._nextId }))
    end)
    file.close()
    if not ok then
        logger.error("DB: Failed to flush '" .. self._name .. "': " .. tostring(err))
    end
    return ok
end
function Collection:drop()
    self:clear()
    local path = fs.combine(self._dir, self._name .. ".dat")
    if fs.exists(path) then fs.delete(path) end
    logger.info("DB: Dropped collection '" .. self._name .. "'")
end
function Collection:disableAutosave()
    self._autosave = false
end
function Collection:enableAutosave()
    self._autosave = true
end
return DatabaseModule
]=]
paths["core.db"] = "core/db"
sources["core.debug"] = [=[

return {
    enabled = false,
    showLogs = false,
    alwaysOnTop = true,
    updateTime = 0,
    drawTime = 0,
    fps = 0,
    dynamicCount = 0,
    designW = nil,
    designH = nil,
    minW = nil,
    minH = nil,
    unsupportedResolution = false
}
]=]
paths["core.debug"] = "core/debug"
sources["core.ecs"] = [=[

local World = {}
World.__index = World
function World.new()
    local self = setmetatable({}, World)
    self._nextId = 1
    self._entities = {}
    self._store = {}
    self._tags = {}
    self._index = {}
    return self
end
function World:spawn()
    local id = self._nextId
    self._nextId = id + 1
    self._entities[id] = true
    self._tags[id] = {}
    return id
end
function World:alive(id)
    return self._entities[id] == true
end
function World:despawn(id)
    if not self:alive(id) then
        logger.warn("ECS: Attempted to despawn non-existent entity " .. tostring(id))
        return
    end
    for component in pairs(self._tags[id] or {}) do
        self:detach(id, component)
    end
    self._entities[id] = nil
    self._tags[id] = nil
end
function World:entities()
    local result = {}
    for id in pairs(self._entities) do
        table.insert(result, id)
    end
    return result
end
function World:count()
    local n = 0
    for _ in pairs(self._entities) do
        n = n + 1
    end
    return n
end
function World:attach(id, component, data)
    if id == nil then
        logger.error("ECS: attach() called with nil entity (component='" .. tostring(component) .. "')")
        return
    end
    if component == nil then
        logger.error("ECS: attach() called with nil component for entity " .. tostring(id))
        return
    end
    if not self:alive(id) then
        logger.error("ECS: attach() called on dead entity " .. tostring(id))
        return
    end
    if not self._store[component] then
        self._store[component] = {}
        self._index[component] = {}
    end
    self._store[component][id] = data
    self._tags[id][component] = true
    self._index[component][id] = true
end
function World:get(id, component)
    if not self:alive(id) then
        return nil
    end
    local storage = self._store[component]
    return storage and storage[id]
end
function World:has(id, component)
    return self._tags[id] ~= nil and self._tags[id][component] == true
end
function World:detach(id, component)
    if not self:alive(id) then
        return
    end
    if self._store[component] then
        self._store[component][id] = nil
    end
    if self._tags[id] then
        self._tags[id][component] = nil
    end
    if self._index[component] then
        self._index[component][id] = nil
    end
end
function World:components(id)
    if not self:alive(id) then
        return {}
    end
    local result = {}
    for component in pairs(self._tags[id] or {}) do
        result[component] = self:get(id, component)
    end
    return result
end
function World:update(id, component, fn)
    local current = self:get(id, component)
    if current then
        local updated = fn(current)
        if updated ~= nil then
            self:attach(id, component, updated)
        end
    end
end
function World:select(...)
    local components = {...}
    if #components == 0 then
        return self:entities()
    end
    local smallest = components[1]
    local smallestSize = math.huge
    for _, comp in ipairs(components) do
        local index = self._index[comp]
        if not index then
            return {}
        end
        local size = self:countType(comp)
        if size < smallestSize then
            smallestSize = size
            smallest = comp
        end
    end
    local source = self._index[smallest]
    local results = {}
    for id in pairs(source) do
        local match = true
        local tags = self._tags[id]
        for _, comp in ipairs(components) do
            if not tags[comp] then
                match = false
                break
            end
        end
        if match then
            table.insert(results, id)
        end
    end
    return results
end
function World:selectAny(...)
    local components = {...}
    if #components == 0 then
        return {}
    end
    local resultSet = {}
    for _, comp in ipairs(components) do
        local index = self._index[comp]
        if index then
            for id in pairs(index) do
                resultSet[id] = true
            end
        end
    end
    local results = {}
    for id in pairs(resultSet) do
        table.insert(results, id)
    end
    return results
end
function World:exclude(...)
    local components = {...}
    local results = {}
    for id in pairs(self._entities) do
        local hasAny = false
        local tags = self._tags[id]
        for _, comp in ipairs(components) do
            if tags[comp] then
                hasAny = true
                break
            end
        end
        if not hasAny then
            table.insert(results, id)
        end
    end
    return results
end
function World:first(...)
    local results = self:select(...)
    return results[1]
end
function World:each(...)
    local components = {...}
    local entities = self:select(...)
    local i = 0
    return function()
        i = i + 1
        local id = entities[i]
        if not id then return nil end
        local values = {}
        for _, comp in ipairs(components) do
            table.insert(values, self:get(id, comp))
        end
        return id, table.unpack(values)
    end
end
function World:forEach(fn, ...)
    for id in self:each(...) do
        fn(id)
    end
end
function World:countWith(...)
    return #self:select(...)
end
function World:types()
    local result = {}
    for name in pairs(self._store) do
        table.insert(result, name)
    end
    return result
end
function World:countType(component)
    local index = self._index[component]
    if not index then return 0 end
    local n = 0
    for _ in pairs(index) do
        n = n + 1
    end
    return n
end
function World:stats()
    local componentCounts = {}
    for comp, index in pairs(self._index) do
        local count = 0
        for _ in pairs(index) do
            count = count + 1
        end
        componentCounts[comp] = count
    end
    return {
        entities = self:count(),
        types = #self:types(),
        components = componentCounts,
    }
end
function World:clear()
    self._nextId = 1
    self._entities = {}
    self._tags = {}
    for comp in pairs(self._store) do
        self._store[comp] = {}
        self._index[comp] = {}
    end
end
function World:debug()
    logger.info("=== ECS World Debug ===")
    logger.info("Entities: " .. self:count())
    logger.info("Component Types: " .. #self:types())
    for _, comp in ipairs(self:types()) do
        logger.info("  - " .. comp .. ": " .. self:countType(comp) .. " instances")
    end
    for id in pairs(self._entities) do
        local comps = {}
        for comp in pairs(self._tags[id]) do
            table.insert(comps, comp)
        end
        logger.info("Entity " .. id .. ": [" .. table.concat(comps, ", ") .. "]")
    end
end
local ECS = {}
function ECS.createWorld()
    return World.new()
end
function ECS.new()
    return World.new()
end
return ECS
]=]
paths["core.ecs"] = "core/ecs"
sources["core.error"] = [=[

local require = ...
local logger = require("core.logger")
local Error = {
    handler = nil,
    _shouldStop = false
}
local function writeLog(msg)
    logger.error("[PANIC] " .. tostring(msg))
end
local function drawPanic(msg)
    writeLog(msg)
    local mainMsg, trace = msg, nil
    local splitPos = msg:find("\nstack traceback:")
    if splitPos then
        mainMsg = msg:sub(1, splitPos - 1)
        trace   = msg:sub(splitPos + 1)
    end
    local w, h = term.getSize()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setBackgroundColor(colors.red)
    term.setCursorPos(1, 1)
    term.clearLine()
    local title = " OBSIDIAN ERROR "
    term.setCursorPos(math.max(1, math.floor((w - #title) / 2) + 1), 1)
    term.setTextColor(colors.white)
    term.write(title)
    term.setBackgroundColor(colors.black)
    local y = 3
    term.setTextColor(colors.yellow)
    for line in mainMsg:gmatch("[^\n]+") do
        if y > h - 5 then break end
        term.setCursorPos(2, y)
        term.write(line:sub(1, w - 2))
        y = y + 1
    end
    if trace and y < h - 2 then
        y = y + 1
        if y <= h - 2 then
            term.setCursorPos(2, y)
            term.setTextColor(colors.lightGray)
            term.write("Stack Traceback:")
            y = y + 1
        end
        for line in trace:gmatch("[^\n]+") do
            if y > h - 2 then break end
            if line ~= "stack traceback:" then
                local isInternal = line:find("/core/")
                    or line:find("engine%.lua")
                    or line:find("error%.lua")
                    or line:find("%[C%]")
                term.setTextColor(isInternal and colors.gray or colors.white)
                term.setCursorPos(3, y)
                term.write(line:sub(1, w - 3))
                y = y + 1
            end
        end
    end
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.setCursorPos(1, h)
    term.clearLine()
    local footer = " Press any key to exit  |  crash saved to obsidian.log "
    term.setCursorPos(math.max(1, math.floor((w - #footer) / 2) + 1), h)
    term.write(footer:sub(1, w))
    os.pullEvent("key")
end
function Error.report(msg, trace)
    local fullMsg
    if trace and #tostring(trace) > 0 then
        fullMsg = tostring(msg) .. "\n" .. tostring(trace)
    else
        fullMsg = tostring(msg)
    end
    if Error.handler then
        Error.handler(fullMsg)
    else
        drawPanic(fullMsg)
    end
    Error._shouldStop = true
end
return Error
]=]
paths["core.error"] = "core/error"
sources["core.event"] = [=[

local require = ...
local logger = require("core.logger")
local EventEmitter = {}
EventEmitter.__index = EventEmitter
function EventEmitter.new()
    return setmetatable({ _listeners = {} }, EventEmitter)
end
function EventEmitter:on(name, fn)
    if not self._listeners[name] then
        self._listeners[name] = {}
    end
    local id = {}
    self._listeners[name][id] = fn
    return function()
        local bucket = self._listeners[name]
        if bucket then bucket[id] = nil end
    end
end
function EventEmitter:once(name, fn)
    local unsub
    unsub = self:on(name, function(...)
        unsub()
        fn(...)
    end)
    return unsub
end
function EventEmitter:emit(name, ...)
    local bucket = self._listeners[name]
    if not bucket then return end
    for _, fn in pairs(bucket) do
        local ok, err = pcall(fn, ...)
        if not ok then
            logger.error(string.format("EventEmitter '%s' handler failed: %s", name, tostring(err)))
        end
    end
end
function EventEmitter:off(name)
    self._listeners[name] = nil
end
function EventEmitter:clear()
    self._listeners = {}
end
return EventEmitter
]=]
paths["core.event"] = "core/event"
sources["core.input"] = [=[

local input = {
    keysDown         = {},
    keysDownPrevious = {},
    mouseDown         = {},
    mouseDownPrevious = {},
    mouseX = 0,
    mouseY = 0,
    _keyHooks = {},
    _comboHooks = {},
    _nextHookId = 0,
    _defaultRepeatDelay = 0.4,
    _defaultRepeatInterval = 0.12,
}
function input.processEvent(event, ...)
    local p1, p2, p3 = ...
    if event == "key" then
        input.keysDown[p1] = true
        if input.isJustPressed(p1) then
            local hooks = input._keyHooks[p1]
            if hooks then
                local now = os.clock()
                for _, h in ipairs(hooks) do
                    local ok, _ = pcall(h.handler, p1, { event = "pressed" })
                    if not ok then end
                    local wantsRepeat = false
                    if h.opts then
                        if h.opts.repeatable ~= nil then
                            wantsRepeat = h.opts.repeatable
                        elseif h.opts["repeat"] ~= nil then
                            wantsRepeat = h.opts["repeat"]
                        elseif h.opts.repeating ~= nil then
                            wantsRepeat = h.opts.repeating
                        elseif h.opts.repeats ~= nil then
                            wantsRepeat = h.opts.repeats
                        end
                    end
                    if wantsRepeat then
                        h._holding = true
                        local delay = h.opts.repeatDelay or h.opts.repeatInterval or input._defaultRepeatDelay
                        h._nextRepeat = now + (delay or input._defaultRepeatDelay)
                    end
                end
            end
        end
        for _, combo in ipairs(input._comboHooks) do
            local allDown = true
            for _, k in ipairs(combo.keys) do
                if not input.keysDown[k] then allDown = false; break end
            end
            if allDown and not combo._fired then
                combo._fired = true
                pcall(combo.handler, combo.keys)
            end
        end
    elseif event == "key_up" then
        input.keysDown[p1] = false
        for _, combo in ipairs(input._comboHooks) do
            for _, k in ipairs(combo.keys) do
                if k == p1 then combo._fired = false; break end
            end
        end
        local hooks = input._keyHooks[p1]
        if hooks then
            for _, h in ipairs(hooks) do
                h._holding = false
                h._nextRepeat = nil
            end
        end
    elseif event == "mouse_click" or event == "mouse_drag" then
        input.mouseDown[p1] = true
        input.mouseX = p2
        input.mouseY = p3
    elseif event == "mouse_up" then
        input.mouseDown[p1] = false
        input.mouseX = p2
        input.mouseY = p3
    elseif event == "mouse_scroll" then
        input.mouseX = p2
        input.mouseY = p3
    elseif event == "mouse_move" then
        input.mouseX = p1
        input.mouseY = p2
    end
end
function input._endFrame()
    local now = os.clock()
    for k, hooks in pairs(input._keyHooks) do
        for _, h in ipairs(hooks) do
            if h._holding and h._nextRepeat and now >= h._nextRepeat then
                local ok, _ = pcall(h.handler, k, { event = "repeat" })
                if not ok then end
                local interval = (h.opts and h.opts.repeatInterval) or input._defaultRepeatInterval
                h._nextRepeat = now + interval
            end
        end
    end
    for k, v in pairs(input.keysDown)  do input.keysDownPrevious[k]  = v end
    for k, v in pairs(input.mouseDown) do input.mouseDownPrevious[k] = v end
    for k in pairs(input.keysDownPrevious) do
        if not input.keysDown[k] then input.keysDownPrevious[k] = nil end
    end
    for k in pairs(input.mouseDownPrevious) do
        if not input.mouseDown[k] then input.mouseDownPrevious[k] = nil end
    end
end
function input.clear()
    input.keysDown = {}
    input.keysDownPrevious = {}
    input.mouseDown = {}
    input.mouseDownPrevious = {}
end
function input.isKeyDown(key)
    if type(key) == "string" then key = keys[key] end
    return input.keysDown[key] == true
end
function input.isJustPressed(key)
    if type(key) == "string" then key = keys[key] end
    return input.keysDown[key] == true and not (input.keysDownPrevious[key] == true)
end
function input.isJustReleased(key)
    if type(key) == "string" then key = keys[key] end
    return not (input.keysDown[key] == true) and input.keysDownPrevious[key] == true
end
function input.isMouseDown(button)
    return input.mouseDown[button] == true
end
function input.isMouseJustPressed(button)
    return input.mouseDown[button] == true and not (input.mouseDownPrevious[button] == true)
end
function input.isMouseJustReleased(button)
    return not (input.mouseDown[button] == true) and input.mouseDownPrevious[button] == true
end
function input.getMousePos()
    return input.mouseX, input.mouseY
end
local function _normalizeKey(k)
    if type(k) == "string" then return keys[k] end
    return k
end
function input.onKey(key, handler, opts)
    opts = opts or {}
    input._nextHookId = input._nextHookId + 1
    local id = input._nextHookId
    local keysToRegister = {}
    if type(key) == "table" then
        for _, k in ipairs(key) do
            local nk = _normalizeKey(k)
            if nk ~= nil then table.insert(keysToRegister, nk) end
        end
    else
        local nk = _normalizeKey(key)
        if nk ~= nil then table.insert(keysToRegister, nk) end
    end
    if #keysToRegister == 0 then return nil end
    for _, k in ipairs(keysToRegister) do
        if not input._keyHooks[k] then input._keyHooks[k] = {} end
        table.insert(input._keyHooks[k], { id = id, handler = handler, opts = opts, _holding = false, _nextRepeat = nil })
    end
    return id
end
function input.offKey(id)
    for k, list in pairs(input._keyHooks) do
        for i = #list, 1, -1 do
            if list[i].id == id then table.remove(list, i) end
        end
        if #list == 0 then input._keyHooks[k] = nil end
    end
end
function input.onCombo(keys, handler, opts)
    opts = opts or {}
    input._nextHookId = input._nextHookId + 1
    local id = input._nextHookId
    local normalized = {}
    for _, k in ipairs(keys) do
        local nk = _normalizeKey(k)
        if nk ~= nil then table.insert(normalized, nk) end
    end
    if #normalized == 0 then return nil end
    table.insert(input._comboHooks, { id = id, keys = normalized, handler = handler, opts = opts, _fired = false })
    return id
end
function input.offCombo(id)
    for i = #input._comboHooks, 1, -1 do
        if input._comboHooks[i].id == id then table.remove(input._comboHooks, i) end
    end
end
function input.clearHooks()
    input._keyHooks = {}
    input._comboHooks = {}
    input._nextHookId = 0
end
return input
]=]
paths["core.input"] = "core/input"
sources["core.input_mapper"] = [=[

local require = ...
local input = require("core.input")
local InputMapper = {
    mappings = {}
}
function InputMapper.bind(actionName, keysTable)
    if type(keysTable) ~= "table" then keysTable = {keysTable} end
    InputMapper.mappings[actionName] = keysTable
end
function InputMapper.isActive(actionName)
    local keysToCheck = InputMapper.mappings[actionName]
    if not keysToCheck then return false end
    for _, key in ipairs(keysToCheck) do
        if input.isKeyDown(key) then return true end
    end
    return false
end
function InputMapper.loadDefaultWASD()
    InputMapper.bind("up",    {keys.w, keys.up})
    InputMapper.bind("down",  {keys.s, keys.down})
    InputMapper.bind("left",  {keys.a, keys.left})
    InputMapper.bind("right", {keys.d, keys.right})
    InputMapper.bind("jump",  {keys.space})
    InputMapper.bind("use",   {keys.e, keys.enter})
end
return InputMapper
]=]
paths["core.input_mapper"] = "core/input_mapper"
sources["core.loader"] = [=[

local require = ...
local logger = require("core.logger")
local flimg = require("flimg")
local loader = {
    basePath = nil,
    spriteCache = {},
    imageCache = {},
    uiCache = {},
    emitterCache = {}
}
loader.flimg = flimg
local function resolvePath(path)
    if not path or path:sub(1,1) == "/" then return path end
    if loader.basePath then
        return fs.combine(loader.basePath, path)
    end
    if shell then
        local runningProg = shell.getRunningProgram()
        if runningProg then
            return fs.combine(fs.getDir(runningProg), path)
        end
    end
    return path
end
function loader.setBasePath(path)
    loader.basePath = path
end
local function toTable(str)
    local t = {}
    for i = 1, #str do t[i] = str:sub(i, i) end
    return t
end
local function _loadFile(path)
    local fullPath = resolvePath(path)
    if not fs.exists(fullPath) then
        return false, "File not found: " .. fullPath
    end
    local file = fs.open(fullPath, "r")
    if not file then
        return false, "Could not open file: " .. fullPath
    end
    local raw = file.readAll()
    file.close()
    local ok, data = pcall(textutils.unserialize, raw)
    if not ok or data == nil then
        return false, "Failed to unserialize: " .. fullPath
    end
    return true, data, fullPath
end
function loader._processSprite(data)
    if not data then return end
    for i = 1, (data.frameCount or #data) do
        local frame = data[i]
        if frame then
            for layer = 1, 3 do
                if frame[layer] then
                    for rowIdx, row in ipairs(frame[layer]) do
                        if type(row) == "string" then
                            frame[layer][rowIdx] = toTable(row)
                        end
                    end
                end
            end
        end
    end
end
function loader._validateSprite(path, data)
    if not data or type(data) ~= "table" then
        return false, "File is not a valid table."
    end
    local req = {"width", "height", "frameCount"}
    for _, field in ipairs(req) do
        if not data[field] then return false, "Missing field: " .. field end
    end
    for f = 1, data.frameCount do
        local frame = data[f]
        if not frame or #frame ~= 3 then
            return false, string.format("Frame %d must have exactly 3 layers (Chars, Fore, Back).", f)
        end
        for layer = 1, 3 do
            if #frame[layer] ~= data.height then
                return false, string.format("Frame %d, layer %d: row count (%d) does not match height (%d).", f, layer, #frame[layer], data.height)
            end
            for r = 1, data.height do
                local row = frame[layer][r]
                local len = #row
                if len ~= data.width then
                    return false, string.format("Frame %d, layer %d, row %d: length (%d) does not match width (%d).", f, layer, r, len, data.width)
                end
                if type(row) == "table" then
                    for c = 1, data.width do
                        local cell = row[c]
                        local validCell
                        if layer == 1 then
                            validCell = type(cell) == "string" and #cell == 1
                        else
                            validCell = type(cell) == "number"
                                or (type(cell) == "string" and (
                                    #cell == 1
                                    or cell:match("^#%x%x%x$")
                                    or cell:match("^#%x%x%x%x%x%x$")
                                    or cell:match("^#%x%x%x%x%x%x%x%x$")
                                ))
                        end
                        if not validCell then
                            local content = tostring(cell)
                            return false, string.format(
                                "Frame %d, layer %d, row %d, column %d: invalid %s value '%s'.",
                                f, layer, r, c, layer == 1 and "character" or "color", content)
                        end
                    end
                end
            end
        end
    end
    return true
end
function loader.loadSprite(path)
    local fullPath = resolvePath(path)
    if loader.spriteCache[fullPath] then
        return loader.spriteCache[fullPath]
    end
    local ok, data, fp = _loadFile(path)
    if not ok then
        logger.error("Loader: " .. data)
        return nil, data
    end
    local valid, verr = loader._validateSprite(path, data)
    if not valid then
        logger.error("Loader: Validation error in " .. path .. ": " .. verr)
        return nil, verr
    end
    loader._processSprite(data)
    data.path = path
    loader.spriteCache[fp] = data
    logger.info("Loader: Cached sprite: " .. fp)
    return data
end
function loader.loadImage(path)
    local fullPath = resolvePath(path)
    if loader.imageCache[fullPath] then return loader.imageCache[fullPath] end
    if not fs.exists(fullPath) then return nil, "File not found: " .. fullPath end
    local handle = fs.open(fullPath, "rb") or fs.open(fullPath, "r")
    if not handle then return nil, "Could not open file: " .. fullPath end
    local raw = handle.readAll()
    handle.close()
    local ok, image = pcall(flimg.decode, raw)
    if not ok then
        logger.error("Loader: " .. tostring(image))
        return nil, tostring(image)
    end
    image.path = path
    loader.imageCache[fullPath] = image
    logger.info("Loader: Cached FLIMG image: " .. fullPath)
    return image
end
function loader.loadUI(path)
    local fullPath = resolvePath(path)
    if loader.uiCache[fullPath] then
        return loader.uiCache[fullPath]
    end
    local ok, data, fp = _loadFile(path)
    if not ok then
        logger.error("Loader: " .. data)
        return nil, data
    end
    loader.uiCache[fp] = data
    return data
end
function loader.loadEmitter(path)
    local fullPath = resolvePath(path)
    if loader.emitterCache[fullPath] then
        return loader.emitterCache[fullPath]
    end
    local ok, data, fp = _loadFile(path)
    if not ok then
        logger.error("Loader: " .. data)
        return nil, data
    end
    if data.sprite then loader._processSprite(data.sprite) end
    loader.emitterCache[fp] = data
    return data
end
function loader.unload(path)
    local fullPath = resolvePath(path)
    loader.spriteCache[fullPath] = nil
    loader.imageCache[fullPath] = nil
    loader.uiCache[fullPath] = nil
    loader.emitterCache[fullPath] = nil
    logger.info("Loader: Unloaded asset: " .. tostring(fullPath))
end
function loader.clearCache()
    loader.spriteCache = {}
    loader.imageCache = {}
    loader.uiCache = {}
    loader.emitterCache = {}
    logger.info("Loader: Asset cache cleared.")
end
return loader
]=]
paths["core.loader"] = "core/loader"
sources["core.logger"] = [=[

local logger = {
    history = {},
    maxHistory = 8,
    logFile = "obsidian.log",
    _fileInitialized = false,
    _consoleHook = nil,
}
local colors = {
    INFO = "0",
    WARN = "1",
    ERROR = "e",
    DEBUG = "7"
}
function logger._add(level, msg)
    local timestamp = os.date("%H:%M:%S")
    local logLine = string.format("[%s] [%s] %s", timestamp, level, tostring(msg))
    local entry = {
        level = level,
        text = logLine,
        color = colors[level] or "0"
    }
    table.insert(logger.history, entry)
    if #logger.history > logger.maxHistory then
        table.remove(logger.history, 1)
    end
    local mode = logger._fileInitialized and "a" or "w"
    local f = fs.open(logger.logFile, mode)
    if f then
        logger._fileInitialized = true
        f.writeLine(logLine)
        f.close()
    end
    if logger._consoleHook then
        logger._consoleHook(logLine, colors[level] or "0")
    end
end
function logger.info(msg) logger._add("INFO", msg) end
function logger.warn(msg) logger._add("WARN", msg) end
function logger.error(msg) logger._add("ERROR", msg) end
function logger.debug(msg) logger._add("DEBUG", msg) end
function logger.getHistory() return logger.history end
return logger
]=]
paths["core.logger"] = "core/logger"
sources["core.math"] = [=[

local m_sqrt  = math.sqrt
local m_cos   = math.cos
local m_sin   = math.sin
local m_atan2 = math.atan2
local m_floor = math.floor
local m_abs   = math.abs
local m_min   = math.min
local m_max   = math.max
local Math = {}
local Vector2 = {}
Vector2.__index = Vector2
function Math.vec2(x, y)
    local v = { x = x or 0, y = y or 0 }
    setmetatable(v, Vector2)
    return v
end
function Vector2.__add(v1, v2) return Math.vec2(v1.x + v2.x, v1.y + v2.y) end
function Vector2.__sub(v1, v2) return Math.vec2(v1.x - v2.x, v1.y - v2.y) end
function Vector2.__eq(v1, v2)  return v1.x == v2.x and v1.y == v2.y end
function Vector2.__mul(v, s)
    if type(v) == "number" then return Math.vec2(s.x * v, s.y * v) end
    if type(s) == "number" then return Math.vec2(v.x * s, v.y * s) end
    return Math.vec2(v.x * s.x, v.y * s.y)
end
function Vector2.__div(v, s) return Math.vec2(v.x / s, v.y / s) end
function Vector2.__unm(v) return Math.vec2(-v.x, -v.y) end
function Vector2.__tostring(v) return string.format("Vec2(%.2f, %.2f)", v.x, v.y) end
function Vector2:dist(other)
    if not other then return math.huge end
    return Math.dist(self.x, self.y, other.x, other.y)
end
function Vector2:sqDist(other)
    if not other then return math.huge end
    local dx = self.x - other.x
    local dy = self.y - other.y
    return dx * dx + dy * dy
end
function Vector2:len()
    return m_sqrt(self.x * self.x + self.y * self.y)
end
function Vector2:sqLen()
    return self.x * self.x + self.y * self.y
end
function Vector2:normalize()
    local l = self:len()
    if l == 0 then return Math.vec2(0, 0) end
    return Math.vec2(self.x / l, self.y / l)
end
function Vector2:lerp(other, t)
    return Math.vec2(Math.lerp(self.x, other.x, t), Math.lerp(self.y, other.y, t))
end
function Vector2:dot(other)
    return self.x * other.x + self.y * other.y
end
function Vector2:unpack() return self.x, self.y end
function Vector2:set(x, y)
    if x ~= nil then self.x = x end
    if y ~= nil then self.y = y end
    return self
end
function Vector2:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    return self
end
function Vector2:mul(s)
    self.x = self.x * s
    self.y = self.y * s
    return self
end
function Vector2:limit(max)
    local sq = self:sqLen()
    if sq > max * max then
        local l = m_sqrt(sq)
        self.x, self.y = (self.x / l) * max, (self.y / l) * max
    end
    return self
end
function Vector2:cross(other)
    return self.x * other.y - self.y * other.x
end
function Vector2:clone()
    return Math.vec2(self.x, self.y)
end
function Vector2:rotate(angle)
    local c = m_cos(angle)
    local s = m_sin(angle)
    return Math.vec2(self.x * c - self.y * s, self.x * s + self.y * c)
end
function Math.lerp(a, b, t)
    return a + (b - a) * t
end
function Math.applyDamping(velocity, amount, dt)
    local factor = (1 - amount) ^ (dt * 20)
    velocity.x = velocity.x * factor
    velocity.y = velocity.y * factor
end
function Math.isVec2(v)
    return type(v) == "table" and getmetatable(v) == Vector2
end
function Math.clamp(val, min, max)
    return m_min(m_max(val, min), max)
end
function Math.dist(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return m_sqrt(dx * dx + dy * dy)
end
function Math.normalize(x, y)
    local length = m_sqrt(x * x + y * y)
    if length == 0 then return Math.vec2(0, 0) end
    return Math.vec2(x / length, y / length)
end
function Math.normalizeRaw(x, y)
    local length = m_sqrt(x * x + y * y)
    if length == 0 then return 0, 0, 0 end
    return x / length, y / length, length
end
function Math.round(val)
    return m_floor(val + 0.5)
end
function Math.sign(val)
    if val > 0 then return 1 elseif val < 0 then return -1 else return 0 end
end
function Math.angleBetween(x1, y1, x2, y2)
    return m_atan2(y2 - y1, x2 - x1)
end
function Math.fromAngle(angle, length)
    length = length or 1
    return Math.vec2(m_cos(angle) * length, m_sin(angle) * length)
end
return Math
]=]
paths["core.math"] = "core/math"
sources["core.network"] = [=[

local require = ...
local logger = require("core.logger")
local network = {
    modemSide = nil,
    isOpen = false,
    isHost = false,
    serverId = nil,
    clients = {},
    _protocol = nil,
    _hostname = nil,
    _connectCallback = nil,
    _connecting = false,
    _emit = function() end,
    _heartbeatInterval = 10,
    _heartbeatTimeout = 30,
    _lastPingTime = {},
    _heartbeatThread = nil
}
local _anyMessageHandlers = {}
local _msgTypeHandlers = {}
function network.onMessage(fn)
    table.insert(_anyMessageHandlers, fn)
    return function()
        for i, h in ipairs(_anyMessageHandlers) do
            if h == fn then table.remove(_anyMessageHandlers, i); break end
        end
    end
end
function network.offMessage(fn)
    for i, h in ipairs(_anyMessageHandlers) do
        if h == fn then table.remove(_anyMessageHandlers, i); break end
    end
end
function network.onMessageType(typeName, fn)
    if not _msgTypeHandlers[typeName] then _msgTypeHandlers[typeName] = {} end
    table.insert(_msgTypeHandlers[typeName], fn)
    return function()
        local bucket = _msgTypeHandlers[typeName]
        if not bucket then return end
        for i, h in ipairs(bucket) do
            if h == fn then table.remove(bucket, i); break end
        end
    end
end
function network.offMessageType(typeName, fn)
    local bucket = _msgTypeHandlers[typeName]
    if not bucket then return end
    for i, h in ipairs(bucket) do
        if h == fn then table.remove(bucket, i); break end
    end
end
local function _startHeartbeat()
    if network._heartbeatThread then return end
    local thread = require("core.thread")
    network._heartbeatThread = thread.start(function()
        while network.isOpen and (network.isHost or network.serverId) do
            local now = os.epoch("utc")
            if network.isHost then
                local deadClients = {}
                for clientId, client in pairs(network.clients) do
                    local lastPing = client.lastPing or client.connectedAt
                    if (now - lastPing) > (network._heartbeatTimeout * 1000) then
                        logger.warn("Network: Client " .. clientId .. " timed out (no ping for " ..
                                  math.floor((now - lastPing) / 1000) .. "s)")
                        table.insert(deadClients, clientId)
                    else
                        network.send(clientId, { type = "PING", t = now }, network._protocol)
                    end
                end
                for _, clientId in ipairs(deadClients) do
                    network.clients[clientId] = nil
                    network._emit("network.clientTimeout", clientId)
                end
            elseif network.serverId then
                local lastPing = network._lastPingTime[network.serverId]
                if lastPing and (now - lastPing) > (network._heartbeatTimeout * 1000) then
                    logger.warn("Network: Server " .. network.serverId .. " timed out")
                    local oldServerId = network.serverId
                    network.serverId = nil
                    network._emit("network.serverTimeout", oldServerId)
                    break
                else
                    network.send(network.serverId, { type = "PING", t = now }, network._protocol)
                end
            end
            sleep(network._heartbeatInterval)
        end
        network._heartbeatThread = nil
        logger.info("Network: Heartbeat thread stopped")
    end)
end
local function _stopHeartbeat()
    if network._heartbeatThread then
        local thread = require("core.thread")
        thread.stop(network._heartbeatThread)
        network._heartbeatThread = nil
        logger.info("Network: Heartbeat stopped")
    end
end
function network.open(side)
    if side then
        if peripheral.getType(side) == "modem" then
            rednet.open(side)
            network.modemSide = side
            network.isOpen = true
            logger.info("Network: Modem opened on side " .. side .. " (ID: " .. os.getComputerID() .. ")")
            return true
        end
    else
        local modems = { peripheral.find("modem") }
        if #modems > 0 then
            for _, m in ipairs(modems) do
                local s = peripheral.getName(m)
                rednet.open(s)
                network.modemSide = s
            end
            network.isOpen = true
            logger.info("Network: " .. #modems .. " modem(s) opened. Local ID: " .. os.getComputerID())
            return true
        end
    end
    return false
end
function network.close()
    if network.isOpen then
        _stopHeartbeat()
        local modems = { peripheral.find("modem") }
        for _, m in ipairs(modems) do
            rednet.close(peripheral.getName(m))
        end
        network.isOpen = false
        logger.info("Network: All modems closed")
    end
end
function network.disconnect()
    if not network.isOpen then return end
    local protocol = network._protocol
    if network.isHost then
        network.broadcast({ type = "SERVER_SHUTDOWN" }, protocol)
    elseif network.serverId then
        network.send(network.serverId, { type = "CLIENT_LEAVE" }, protocol)
    end
    network.isHost = false
    network.serverId = nil
    network._protocol = nil
    network._hostname = nil
    network.clients = {}
    network._lastPingTime = {}
    network.close()
end
function network.send(targetId, message, protocol)
    if not network.isOpen then return false end
    local proto = protocol or network._protocol
    if not proto then
        logger.warn("Network: send() called with no protocol specified and no default set")
        return false
    end
    rednet.send(targetId, message, proto)
    return true
end
function network.broadcast(message, protocol)
    if not network.isOpen then return false end
    local proto = protocol or network._protocol
    if not proto then
        logger.warn("Network: broadcast() called with no protocol specified and no default set")
        return false
    end
    rednet.broadcast(message, proto)
    return true
end
function network.connect(protocol, hostname, callback, timeout)
    timeout = timeout or 5
    logger.info("Network: connect() called — protocol='" .. tostring(protocol) .. "' hostname='" .. tostring(hostname) .. "' timeout=" .. tostring(timeout))
    if not network.isOpen then
        logger.info("Network: modem not open, attempting auto-open")
        local opened = network.open()
        if not opened then
            local err = "No modem found"
            logger.warn("Network: connect() failed — " .. err)
            if callback then callback(false, err) end
            return false, err
        end
    end
    if network._connecting then
        local err = "Already connecting"
        logger.warn("Network: connect() rejected — " .. err)
        if callback then callback(false, err) end
        return false, err
    end
    network._connecting      = true
    network._connectCallback = callback
    network._protocol        = protocol
    logger.info("Network: starting connect thread")
    local function _cleanup(ok, reason)
        local cb = network._connectCallback
        network._connectCallback = nil
        network._connecting = false
        if cb then cb(ok, reason) end
    end
    local thread = require("core.thread")
    thread.start(function()
        local success, err = pcall(function()
            logger.info("Network: [thread] looking up '" .. tostring(hostname) .. "' on protocol '" .. tostring(protocol) .. "'")
            local lookupOk, id_or_err = pcall(rednet.lookup, protocol, hostname)
            local id = lookupOk and id_or_err or nil
            logger.info("Network: [thread] lookup result — ok=" .. tostring(lookupOk) .. " id=" .. tostring(id))
            if not id then
                logger.info("Network: [thread] DNS lookup failed, trying broadcast DISCOVER")
                rednet.broadcast({ type = "DISCOVER", hostname = hostname }, protocol)
                local discoverTimer = os.startTimer(3)
                while true do
                    local ev, p1, p2, p3 = os.pullEvent()
                    if ev == "rednet_message" then
                        local msg, proto2 = p2, p3
                        if type(msg) == "table" and msg.type == "DISCOVER_REPLY"
                                and msg.hostname == hostname and proto2 == protocol then
                            id = p1
                            logger.info("Network: [thread] DISCOVER_REPLY from " .. tostring(id))
                            os.cancelTimer(discoverTimer)
                            break
                        end
                    elseif ev == "timer" and p1 == discoverTimer then
                        logger.warn("Network: [thread] broadcast discovery timed out")
                        break
                    end
                end
            end
            if not id then
                local errMsg = (not lookupOk) and tostring(id_or_err) or "Server not found"
                logger.warn("Network: [thread] connect failed — " .. errMsg)
                _cleanup(false, errMsg)
                network._emit("network.connectionFailed", protocol, hostname)
                return
            end
            logger.info("Network: [thread] sending CONNECT_REQUEST to server ID " .. tostring(id))
            rednet.send(id, { type = "CONNECT_REQUEST" }, protocol)
            logger.info("Network: [thread] waiting up to " .. timeout .. "s for CONNECT_ACCEPT")
            local t = os.startTimer(timeout)
            local connectionEvent = "network_connect_" .. tostring(id)
            while true do
                local ev, p1 = os.pullEvent()
                if ev == "timer" and p1 == t then
                    if network._connecting then
                        logger.warn("Network: [thread] timed out waiting for CONNECT_ACCEPT")
                        _cleanup(false, "Connection timed out")
                        network._emit("network.connectionFailed", protocol, hostname)
                    end
                    break
                elseif ev == connectionEvent then
                    os.cancelTimer(t)
                    logger.info("Network: [thread] connection established")
                    _cleanup(true, id)
                    break
                elseif not network._connecting then
                    os.cancelTimer(t)
                    if network.serverId == id then
                        logger.info("Network: [thread] connection established by processEvent")
                        _cleanup(true, id)
                    else
                        logger.info("Network: [thread] _connecting cleared externally, exiting wait")
                    end
                    break
                end
            end
        end)
        if not success then
            logger.error("Network: [thread] crashed: " .. tostring(err))
            _cleanup(false, "Internal error: " .. tostring(err))
            network._emit("network.connectionFailed", protocol, hostname)
        end
    end)
    return true
end
function network.cancelConnect(reason)
    if not network._connecting then return end
    local cb = network._connectCallback
    network._connectCallback = nil
    network._connecting = false
    if cb then cb(false, reason or "Cancelled") end
    logger.info("Network: Connection cancelled — " .. (reason or "No reason"))
end
function network.host(protocol, hostname)
    if not network.isOpen then
        logger.warn("Network: Cannot host, modem not open")
        return false
    end
    rednet.host(protocol, hostname)
    network.isHost    = true
    network._protocol = protocol
    network._hostname = hostname
    logger.info("Network: Now hosting protocol '" .. protocol .. "' as '" .. hostname .. "'")
    _startHeartbeat()
    return true
end
function network.lookup(protocol, hostname)
    if not network.isOpen then return nil end
    return rednet.lookup(protocol, hostname)
end
function network.setHeartbeat(interval, timeout)
    if interval then network._heartbeatInterval = interval end
    if timeout then network._heartbeatTimeout = timeout end
    logger.info("Network: Heartbeat configured — interval=" .. network._heartbeatInterval .. "s, timeout=" .. network._heartbeatTimeout .. "s")
end
function network.processEvent(eventData)
    if eventData[1] ~= "rednet_message" then return end
    local senderID, message, protocol = eventData[2], eventData[3], eventData[4]
    if senderID == network.serverId and protocol == network._protocol then
        network._lastPingTime[senderID] = os.epoch("utc")
    end
    if type(message) ~= "table" then
        network._emit("network.message", senderID, message, protocol)
        for _, h in ipairs(_anyMessageHandlers) do
            local ok, err = pcall(h, senderID, message, protocol)
            if not ok then logger.error("Network handler failed: " .. tostring(err)) end
        end
        return
    end
    local msgType = message.type
    if msgType == "DISCOVER" and network.isHost then
        if message.hostname == network._hostname then
            network.send(senderID, { type = "DISCOVER_REPLY", hostname = network._hostname }, protocol)
        end
        return
    end
    if msgType == "CONNECT_REQUEST" and network.isHost then
        logger.info("Network: CONNECT_REQUEST from ID " .. senderID)
        network.clients[senderID] = {
            id = senderID,
            connectedAt = os.epoch("utc"),
            lastPing = os.epoch("utc")
        }
        network.send(senderID, { type = "CONNECT_ACCEPT" }, protocol)
        network._emit("network.clientConnect", senderID)
        return
    end
    if msgType == "CONNECT_ACCEPT" then
        logger.info("Network: connected to server " .. senderID)
        network.serverId    = senderID
        network._connecting = false
        network._lastPingTime[senderID] = os.epoch("utc")
        os.queueEvent("network_connect_" .. tostring(senderID))
        network._emit("network.connected", senderID)
        _startHeartbeat()
        return
    end
    if msgType == "PING" then
        if network.isHost and network.clients[senderID] then
            network.clients[senderID].lastPing = os.epoch("utc")
        elseif senderID == network.serverId then
            network._lastPingTime[senderID] = os.epoch("utc")
        end
        network.send(senderID, { type = "PONG", t = message.t }, protocol)
        return
    end
    if msgType == "PONG" then
        if network.isHost and network.clients[senderID] then
            network.clients[senderID].lastPing = os.epoch("utc")
        elseif senderID == network.serverId then
            network._lastPingTime[senderID] = os.epoch("utc")
        end
        return
    end
    if msgType == "CLIENT_LEAVE" and network.isHost then
        network.clients[senderID] = nil
        network._emit("network.clientDisconnect", senderID)
        return
    end
    if msgType == "SERVER_SHUTDOWN" and not network.isHost then
        network.serverId = nil
        _stopHeartbeat()
        network._emit("network.serverShutdown", senderID)
        return
    end
    network._emit("network.message", senderID, message, protocol)
    for _, h in ipairs(_anyMessageHandlers) do
        local ok, err = pcall(h, senderID, message, protocol)
        if not ok then logger.error("Network handler failed: " .. tostring(err)) end
    end
    if msgType and _msgTypeHandlers[msgType] then
        for _, h in ipairs(_msgTypeHandlers[msgType]) do
            local ok, err = pcall(h, senderID, message, protocol)
            if not ok then logger.error("Network type handler failed: " .. tostring(err)) end
        end
    end
end
return network
]=]
paths["core.network"] = "core/network"
sources["core.particles"] = [=[

local require = ...
local mathUtils = require("core.math")
local physics = require("core.physics")
local logger = require("core.logger")
local loader = require("core.loader")
local particles = {}
function particles.createEmitter(config)
    return {
        active = config.active ~= false,
        spawnRate = math.max(0.001, config.spawnRate or 10),
        accumulator = 0,
        angle = config.angle or 0,
        spread = config.spread or 360,
        speedMin = config.speedMin or 5,
        speedMax = config.speedMax or 10,
        lifeMin = config.lifeMin or 1,
        lifeMax = config.lifeMax or 2,
        sprite = config.sprite,
        colors = config.colors,
        chars = config.chars,
        bgColors = config.bgColors,
        z = config.z or 1,
        bounce = config.bounce or false,
        gravityScale = config.gravityScale or 0,
        drag = config.drag or 0
    }
end
function particles.load(path)
    local config = loader.loadEmitter(path)
    if not config then
        logger.error("[particles] Failed to load emitter: " .. tostring(path))
        return nil
    end
    return particles.createEmitter(config)
end
function particles.emitterSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            local emitter = components.emitter[id]
            local pos = components.pos[id]
            if emitter.active and pos then
                emitter.accumulator = emitter.accumulator + dt
                local waitTime = 1 / emitter.spawnRate
                while emitter.accumulator >= waitTime do
                    emitter.accumulator = emitter.accumulator - waitTime
                    local p = scene:spawn()
                    local angle = math.rad(emitter.angle + (math.random() - 0.5) * emitter.spread)
                    local speed = emitter.speedMin + math.random() * (emitter.speedMax - emitter.speedMin)
                    local life = emitter.lifeMin + math.random() * (emitter.lifeMax - emitter.lifeMin)
                    scene:attach(p, "pos", mathUtils.vec2(pos.x, pos.y))
                    scene:attach(p, "velocity", mathUtils.vec2(math.cos(angle) * speed, math.sin(angle) * speed))
                    scene:attach(p, "lifetime", life)
                    scene:attach(p, "maxLifetime", life)
                    scene:attach(p, "isParticle", true)
                    scene:attach(p, "z", emitter.z)
                    if emitter.bounce then scene:attach(p, "particleBounce", true) end
                    if emitter.gravityScale ~= 0 then scene:attach(p, "particleGravity", emitter.gravityScale) end
                    if emitter.drag > 0 then scene:attach(p, "particleDrag", emitter.drag) end
                    if emitter.sprite then scene:attach(p, "sprite", emitter.sprite) end
                    if emitter.colors then scene:attach(p, "particleColors", emitter.colors) end
                    if emitter.chars then scene:attach(p, "particleChars", emitter.chars) end
                    if emitter.bgColors then scene:attach(p, "particleBgColors", emitter.bgColors) end
                end
            end
        end
    end
end
function particles.motionSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            local pos = components.pos[id]
            local vel = components.velocity[id]
            local hasBounce = components.particleBounce and components.particleBounce[id]
            local drag = components.particleDrag and components.particleDrag[id]
            if drag then
                mathUtils.applyDamping(vel, drag, dt)
            end
            local gScale = components.particleGravity and components.particleGravity[id]
            if gScale then
                vel.y = vel.y + physics.GRAVITY_VECTOR.y * gScale * dt
            end
            if hasBounce then
                local oldX = pos.x
                pos.x = pos.x + vel.x * dt
                local hitX, _, slopeYX = scene:isAreaBlocked(pos.x, pos.y, 1, 1, id)
                if hitX and not slopeYX then
                    pos.x = oldX
                    vel.x = -vel.x * 0.5
                end
                local oldY = pos.y
                pos.y = pos.y + vel.y * dt
                local hitY, _, slopeY = scene:isAreaBlocked(pos.x, pos.y, 1, 1, id)
                if hitY then
                    if slopeY then pos.y = slopeY - 1 else pos.y = oldY end
                    vel.y = -vel.y * 0.5
                end
            else
                pos.x = pos.x + vel.x * dt
                pos.y = pos.y + vel.y * dt
            end
        end
    end
end
function particles.updateSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            local life = components.lifetime[id]
            local maxLife = components.maxLifetime[id]
            local colors = components.particleColors and components.particleColors[id]
            local chars = components.particleChars and components.particleChars[id]
            local progress = math.max(0, math.min(1, 1 - (life / (maxLife > 0 and maxLife or 1))))
            if colors then
                local idx = math.max(1, math.min(#colors, math.ceil(progress * #colors)))
                scene:attach(id, "colorOverride", colors[idx])
            end
            if chars then
                local idx = math.max(1, math.min(#chars, math.ceil(progress * #chars)))
                scene:attach(id, "charOverride", chars[idx])
            end
            local bgColors = components.particleBgColors and components.particleBgColors[id]
            if bgColors then
                local idx = math.max(1, math.min(#bgColors, math.ceil(progress * #bgColors)))
                scene:attach(id, "bgOverride", bgColors[idx])
            end
        end
    end
end
function particles.cleanupSystem(scene)
    return function(dt, ids, components)
        for _, id in ipairs(ids) do
            components.lifetime[id] = components.lifetime[id] - dt
            if components.lifetime[id] <= 0 then
                scene:despawn(id)
            end
        end
    end
end
function particles.registerAll(scene)
    scene:addSystem({"emitter", "pos"}, particles.emitterSystem(scene))
    scene:addSystem({"pos", "velocity", "isParticle"}, particles.motionSystem(scene))
    scene:addSystem({"lifetime", "maxLifetime", "isParticle"}, particles.updateSystem(scene))
    scene:addSystem({"lifetime", "isParticle"},  particles.cleanupSystem(scene))
end
return particles
]=]
paths["core.particles"] = "core/particles"
sources["core.pathfinding"] = [=[

local require = ...
local mathUtils = require("core.math")
local logger = require("core.logger")
local m_floor = math.floor
local m_abs = math.abs
local m_min = math.min
local Pathfinding = {}
Pathfinding.MAX_ITERATIONS = 4000
local function createHeap()
    local data = {}
    local size = 0
    local function push(node, priority)
        size = size + 1
        data[size] = { node = node, priority = priority }
        local i = size
        while i > 1 do
            local p = m_floor(i / 2)
            if data[i].priority < data[p].priority then
                data[i], data[p] = data[p], data[i]
                i = p
            else break end
        end
    end
    local function pop()
        if size == 0 then return nil end
        local root = data[1].node
        data[1]    = data[size]
        data[size] = nil
        size       = size - 1
        local i = 1
        while true do
            local l, r, s = i * 2, i * 2 + 1, i
            if l <= size and data[l].priority < data[s].priority then s = l end
            if r <= size and data[r].priority < data[s].priority then s = r end
            if s ~= i then
                data[i], data[s] = data[s], data[i]
                i = s
            else break end
        end
        return root
    end
    local function isEmpty() return size == 0 end
    return { push = push, pop = pop, isEmpty = isEmpty }
end
local KEY_W = 10000
local function nodeKey(x, y) return y * KEY_W + x end
local function keyToX(k) return k % KEY_W end
local function keyToY(k) return m_floor(k / KEY_W) end
local CARD = 1
local DIAG = 1.414
local DIAG_ADJ = DIAG - 2 * CARD
local function heuristic(ax, ay, bx, by)
    local dx = m_abs(ax - bx)
    local dy = m_abs(ay - by)
    return CARD * (dx + dy) + DIAG_ADJ * m_min(dx, dy)
end
local _nb = {
    { dx =  1, dy =  0, cost = CARD },
    { dx = -1, dy =  0, cost = CARD },
    { dx =  0, dy =  1, cost = CARD },
    { dx =  0, dy = -1, cost = CARD },
    { dx =  1, dy =  1, cost = DIAG },
    { dx = -1, dy =  1, cost = DIAG },
    { dx =  1, dy = -1, cost = DIAG },
    { dx = -1, dy = -1, cost = DIAG },
}
local A_PAD = 0
local function isBlocked(scene, nx, ny, cw, ch, ignoreId, mask)
    return scene:isAreaBlocked(
        nx - A_PAD, ny - A_PAD,
        cw + A_PAD * 2, ch + A_PAD * 2,
        ignoreId, mask)
end
local function hasLOS(scene, ax, ay, bx, by, cw, ch, ignoreId, mask)
    return scene:hasLOS(ax, ay, bx, by, cw, ch, ignoreId, mask)
end
local function smoothPath(scene, path, cw, ch, ignoreId, mask)
    if #path <= 2 then return path end
    local out    = { path[1] }
    local anchor = 1
    while anchor < #path do
        local far = anchor + 1
        for i = #path, anchor + 2, -1 do
            local a, b = path[anchor], path[i]
            if hasLOS(scene, a.x, a.y, b.x, b.y, cw, ch, ignoreId, mask) then
                far = i
                break
            end
        end
        table.insert(out, path[far])
        anchor = far
    end
    return out
end
function Pathfinding.findPath(scene, startPos, endPos, collider, ignoreId, layerMask, smooth, maxIterations)
    if not startPos or not endPos then
        logger.error("[pathfinding] findPath: startPos or endPos is nil")
        return nil
    end
    collider = collider or { w = 1, h = 1 }
    local cw, ch = collider.w, collider.h
    smooth = smooth ~= false
    local sx, sy = m_floor(startPos.x), m_floor(startPos.y)
    local gx, gy = m_floor(endPos.x),   m_floor(endPos.y)
    if sx == gx and sy == gy then
        return { mathUtils.vec2(sx, sy) }
    end
    local openSet  = createHeap()
    local gScore   = {}
    local cameFrom = {}
    local closed   = {}
    local startKey = nodeKey(sx, sy)
    local goalKey  = nodeKey(gx, gy)
    gScore[startKey] = 0
    openSet.push({ x = sx, y = sy }, heuristic(sx, sy, gx, gy))
    local iters   = 0
    local maxIter = maxIterations or Pathfinding.MAX_ITERATIONS
    while not openSet.isEmpty() do
        local cur    = openSet.pop()
        local cx, cy = cur.x, cur.y
        local ck     = nodeKey(cx, cy)
        if not closed[ck] then
            closed[ck] = true
            iters = iters + 1
            if iters > maxIter then
                logger.error("[pathfinding] MAX_ITERATIONS (" .. maxIter .. ") exceeded — map may be too large or goal unreachable")
                return nil
            end
            if cx == gx and cy == gy then
                local raw = {}
                local k   = ck
                while k ~= nil do
                    table.insert(raw, mathUtils.vec2(keyToX(k), keyToY(k)))
                    k = cameFrom[k]
                end
                local lo, hi = 1, #raw
                while lo < hi do
                    raw[lo], raw[hi] = raw[hi], raw[lo]
                    lo = lo + 1; hi = hi - 1
                end
                if smooth then
                    return smoothPath(scene, raw, cw, ch, ignoreId, layerMask)
                end
                return raw
            end
            local cg = gScore[ck]
            for i = 1, 8 do
                local nb = _nb[i]
                local nx = cx + nb.dx
                local ny = cy + nb.dy
                local nk = nodeKey(nx, ny)
                local isGoal = (nk == goalKey)
                if not closed[nk]
                and (isGoal or not isBlocked(scene, nx, ny, cw, ch, ignoreId, layerMask)) then
                    local ok = true
                    if not isGoal and nb.dx ~= 0 and nb.dy ~= 0 then
                        if isBlocked(scene, nx, cy, cw, ch, ignoreId, layerMask)
                        or isBlocked(scene, cx, ny, cw, ch, ignoreId, layerMask) then
                            ok = false
                        end
                    end
                    if ok then
                        local tg = cg + nb.cost
                        if not gScore[nk] or tg < gScore[nk] then
                            gScore[nk]   = tg
                            cameFrom[nk] = ck
                            openSet.push({ x = nx, y = ny },
                                tg + heuristic(nx, ny, gx, gy))
                        end
                    end
                end
            end
        end
    end
end
return Pathfinding
]=]
paths["core.pathfinding"] = "core/pathfinding"
sources["core.physics"] = [=[

local require = ...
local M = require("core.math")
local Physics = {}
Physics.GRAVITY_VECTOR = M.vec2(0, 50)
function Physics.gravity()
    return M.vec2(Physics.GRAVITY_VECTOR.x, Physics.GRAVITY_VECTOR.y)
end
function Physics.setGravity(x, y)
    Physics.GRAVITY_VECTOR.x = x
    Physics.GRAVITY_VECTOR.y = y
end
function Physics.createBody(config)
    config = config or {}
    return {
        mass = config.mass or 1.0,
        bounciness = config.bounciness or 0.0,
        friction = config.friction or 0.15,
        gravityScale = config.gravityScale or 1.0,
        isKinematic = config.isKinematic or false,
        useGravity = config.useGravity ~= false,
    }
end
function Physics.resolveBounce(velocity, normal, bounciness)
    bounciness = bounciness or 1.0
    local dot = velocity:dot(normal)
    if dot < 0 then
        velocity:add(normal * (-(1 + bounciness) * dot))
    end
    return velocity
end
function Physics.resolveCollision(body1, vel1, body2, vel2, normal)
    local m1 = body1.mass or 1.0
    local m2 = body2.mass or 1.0
    if m1 <= 0 and m2 <= 0 then return end
    local e = math.min(body1.bounciness or 0, body2.bounciness or 0)
    local relVel = vel1 - vel2
    local velAlongNormal = relVel:dot(normal)
    if velAlongNormal > 0 then return end
    local invM1 = m1 > 0 and (1 / m1) or 0
    local invM2 = m2 > 0 and (1 / m2) or 0
    local j     = -(1 + e) * velAlongNormal / (invM1 + invM2)
    local impulse = normal * j
    vel1:add(impulse *  invM1)
    vel2:add(impulse * -invM2)
end
function Physics.applyImpulse(velocity, force, mass)
    local m = mass or 1.0
    if m <= 0 then return end
    if type(force) == "table" and force.x then
        velocity:add(force * (1 / m))
    else
        velocity.x = velocity.x + (force / m)
    end
end
function Physics.aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx
       and ay < by + bh and ay + ah > by
end
function Physics.getAABBOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    if not Physics.aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh) then
        return nil, 0
    end
    local overlapX = math.min(ax + aw, bx + bw) - math.max(ax, bx)
    local overlapY = math.min(ay + ah, by + bh) - math.max(ay, by)
    local cax, cay = ax + aw * 0.5, ay + ah * 0.5
    local cbx, cby = bx + bw * 0.5, by + bh * 0.5
    local normDx = math.abs(cax - cbx) / ((aw + bw) * 0.5)
    local normDy = math.abs(cay - cby) / ((ah + bh) * 0.5)
    if normDx >= normDy then
        local nx = cax < cbx and -1 or 1
        return M.vec2(nx, 0), overlapX
    else
        local ny = cay < cby and -1 or 1
        return M.vec2(0, ny), overlapY
    end
end
function Physics.system(scene, steps)
    steps = math.max(1, math.floor(steps or 1))
    return function(dt, ids, components)
        local positions = components.pos
        local velocities = components.vel
        local bodies = components.body
        if not positions or not velocities or not bodies then return end
        local grav  = Physics.gravity()
        local subDt = dt / steps
        for _ = 1, steps do
            for _, id in ipairs(ids) do
                local pos  = positions[id]
                local vel  = velocities[id]
                local body = bodies[id]
                if pos and vel and body and not body.isKinematic then
                    if body.useGravity and body.gravityScale ~= 0 then
                        vel.x = vel.x + grav.x * body.gravityScale * subDt
                        vel.y = vel.y + grav.y * body.gravityScale * subDt
                    end
                    if body.friction and body.friction > 0 then
                        local factor = (1 - body.friction) ^ (subDt * 20)
                        vel.x = vel.x * factor
                        vel.y = vel.y * factor
                    end
                    local col = components.collider and components.collider[id]
                    if col and scene and scene.isAreaBlocked then
                        local oldX = pos.x
                        pos.x = pos.x + vel.x * subDt
                        local hitX = scene:isAreaBlocked(pos.x, pos.y, col.w or 1, col.h or 1, id)
                        if hitX then
                            pos.x = oldX
                            vel.x = -(vel.x or 0) * (body.bounciness or 0)
                        end
                        local oldY = pos.y
                        pos.y = pos.y + vel.y * subDt
                        local hitY, _, slopeY = scene:isAreaBlocked(pos.x, pos.y, col.w or 1, col.h or 1, id)
                        if hitY then
                            if slopeY then
                                pos.y = slopeY - (col.h or 1)
                            else
                                pos.y = oldY
                            end
                            vel.y = -(vel.y or 0) * (body.bounciness or 0)
                        end
                    else
                        pos.x = pos.x + vel.x * subDt
                        pos.y = pos.y + vel.y * subDt
                    end
                end
            end
            if components.onSubStep then
                components.onSubStep(ids)
            end
        end
    end
end
return Physics
]=]
paths["core.physics"] = "core/physics"
sources["core.scene"] = [=[

local require = ...
local ecs = require("core.ecs")
local logger = require("core.logger")
local loader = require("core.loader")
local mathUtils = require("core.math")
local uiModule = require("core.ui")
local errorModule = require("core.error")
local EventEmitter = require("core.event")
local debug = require("core.debug")
local buffer = nil
local Scene = {}
local WorldProto = getmetatable(ecs.new())
local SceneInstance = setmetatable({}, { __index = WorldProto })
SceneInstance.__index = SceneInstance
function Scene.setBuffer(buf)
    buffer = buf
end
local _luaDebug = _G and _G.debug
local function tracebackHandler(e)
    return (_luaDebug and _luaDebug.traceback)
        and _luaDebug.traceback(tostring(e), 2)
        or tostring(e)
end
local function deepCopy(orig)
    local copy
    if type(orig) ~= 'table' then return orig end
    copy = {}
    for k, v in pairs(orig) do copy[deepCopy(k)] = deepCopy(v) end
    setmetatable(copy, deepCopy(getmetatable(orig)))
    return copy
end
function Scene.new()
    local self = ecs.new()
    setmetatable(self, SceneInstance)
    self.name = ""
    self.memory = {}
    self.camera = mathUtils.vec2(0, 0)
    self._lastCam = mathUtils.vec2(0, 0)
    self._camera = nil
    self.event = EventEmitter.new()
    self.ui = uiModule.new(buffer)
    self.tilemap = nil
    self._staticElements = {}
    self._staticCache = { t = {}, f = {}, b = {} }
    self._staticDirty = true
    self._staticSortDirty = false
    self._foregroundElements = {}
    self._foregroundSortDirty = false
    self._rowsToRestore = {}
    self._sortedEntities = {}
    self._zDirty = true
    self._cellSize = 10
    self._spatialGrid = {}
    self._activeDynamicCells = {}
    self._triggers = {}
    self._systems = {
        update = {},
        render = {}
    }
    self._hudCallbacks = {}
    self._nextHudId = 0
    self.onUpdate = nil
    self.onDraw = nil
    self.onEvent = nil
    self.onLoad = nil
    self.onUnload = nil
    return self
end
function Scene.newStaticElement(sprite, x, y, config)
    config = config or {}
    return {
        sprite = sprite,
        spritePath = config.spritePath or (sprite and sprite.path),
        x = x,
        y = y,
        z = config.z or -100,
        w = sprite and sprite.width or (config.collider and config.collider.w or 0),
        h = sprite and sprite.height or (config.collider and config.collider.h or 0),
        collider = config.collider,
        layer = config.layer or 1,
        oneWay = config.oneWay or false
    }
end
function Scene.newTriggerZone(x, y, w, h, onEnter, onExit, onStay)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        onEnter = onEnter,
        onExit = onExit,
        onStay = onStay,
        entitiesInside = {}
    }
end
function Scene.newTilemap(sprite, data, solidTiles, tileProperties, spritePath)
    return {
        sprite = sprite,
        spritePath = spritePath or (sprite and sprite.path),
        data = data,
        solidTiles = solidTiles or {},
        tileProperties = tileProperties or {},
        tileW = sprite and sprite.width or 1,
        tileH = sprite and sprite.height or 1
    }
end
function SceneInstance:setTilemap(sprite, data, solidTiles, tileProperties, spritePath)
    self.tilemap = {
        sprite = sprite,
        spritePath = spritePath,
        data = data,
        solidTiles = solidTiles or {},
        tileProperties = tileProperties or {},
        tileW = sprite and sprite.width or 1,
        tileH = sprite and sprite.height or 1
    }
    self._staticDirty = true
end
function SceneInstance:instantiate(template, x, y)
    local id = self:spawn()
    for compName, data in pairs(template) do
        self:attach(id, compName, deepCopy(data))
    end
    if x and y then
        if self:has(id, "pos") then
            self:get(id, "pos"):set(x, y)
        else
            self:attach(id, "pos", mathUtils.vec2(x, y))
        end
    end
    return id
end
function SceneInstance:setParent(childId, parentId, offsetX, offsetY)
    self:attach(childId, "parent", {
        id = parentId,
        offset = mathUtils.vec2(offsetX or 0, offsetY or 0)
    })
end
function SceneInstance:addStatic(sprite, x, y, config)
    config = config or {}
    if not sprite and not config.collider then
        logger.warn(string.format(
            "Scene: addStatic at (%.1f, %.1f) with nil sprite and no collider",
            x or 0, y or 0
        ))
    end
    local item = {
        sprite = sprite,
        spritePath = config.spritePath or (sprite and sprite.path),
        x = x,
        y = y,
        z = config.z or -100,
        w = sprite and sprite.width or (config.collider and config.collider.w or 0),
        h = sprite and sprite.height or (config.collider and config.collider.h or 0),
        collider = config.collider,
        layer = config.layer or 1,
        oneWay = config.oneWay or false
    }
    table.insert(self._staticElements, item)
    self._staticSortDirty = true
    self._staticDirty = true
    self:_addToGrid(item, true)
end
function SceneInstance:addForeground(sprite, x, y, z)
    table.insert(self._foregroundElements, {
        sprite = sprite,
        x = x,
        y = y,
        z = z or 100,
        w = sprite.width,
        h = sprite.height
    })
    self._foregroundSortDirty = true
end
function SceneInstance:_addToGrid(obj, isStatic, id)
    if obj.collider == false then return end
    local col = obj.collider or { x = 0, y = 0, w = obj.w, h = obj.h }
    local x1 = math.floor((obj.x + col.x) / self._cellSize)
    local y1 = math.floor((obj.y + col.y) / self._cellSize)
    local x2 = math.floor((obj.x + col.x + col.w - 0.001) / self._cellSize)
    local y2 = math.floor((obj.y + col.y + col.h - 0.001) / self._cellSize)
    for cx = x1, x2 do
        for cy = y1, y2 do
            self._spatialGrid[cx] = self._spatialGrid[cx] or {}
            self._spatialGrid[cx][cy] = self._spatialGrid[cx][cy] or {
                static = {},
                dynamic = {}
            }
            local cell = self._spatialGrid[cx][cy]
            obj.layer = obj.layer or 1
            if isStatic then
                table.insert(cell.static, obj)
            else
                if not next(cell.dynamic) then
                    table.insert(self._activeDynamicCells, cell)
                end
                cell.dynamic[id] = obj
            end
        end
    end
end
function SceneInstance:_updateDynamicGrid()
    for i = 1, #self._activeDynamicCells do
        self._activeDynamicCells[i].dynamic = {}
    end
    self._activeDynamicCells = {}
    local entities = self:select("pos", "collider")
    for _, id in ipairs(entities) do
        local p = self:get(id, "pos")
        local c = self:get(id, "collider")
        local l = self:get(id, "layer") or 1
        self:_addToGrid({
            x = p.x,
            y = p.y,
            w = c.w,
            h = c.h,
            collider = c,
            layer = l
        }, false, id)
    end
end
function SceneInstance:getEntityAt(worldX, worldY, ignoreId)
    local cx = math.floor(worldX / self._cellSize)
    local cy = math.floor(worldY / self._cellSize)
    local cell = self._spatialGrid[cx] and self._spatialGrid[cx][cy]
    if cell then
        for id, obj in pairs(cell.dynamic) do
            if id ~= ignoreId then
                local col = obj.collider
                local icx = obj.x + col.x
                local icy = obj.y + col.y
                if worldX >= icx and worldX < icx + col.w and
                   worldY >= icy and worldY < icy + col.h then
                    return id
                end
            end
        end
    end
    return nil
end
function SceneInstance:getDistance(id1, id2)
    local p1 = self:get(id1, "pos")
    local p2 = self:get(id2, "pos")
    if not p1 or not p2 then return 9999 end
    return mathUtils.dist(p1.x, p1.y, p2.x, p2.y)
end
function SceneInstance:queryRect(x, y, w, h, layerMask)
    local results = {}
    local x1 = math.floor(x / self._cellSize)
    local y1 = math.floor(y / self._cellSize)
    local x2 = math.floor((x + w) / self._cellSize)
    local y2 = math.floor((y + h) / self._cellSize)
    for cx = x1, x2 do
        if self._spatialGrid[cx] then
            for cy = y1, y2 do
                local cell = self._spatialGrid[cx][cy]
                if cell then
                    for id, obj in pairs(cell.dynamic) do
                        if not layerMask or bit.band(obj.layer or 1, layerMask) > 0 then
                            local c = obj.collider
                            local icx = obj.x + c.x
                            local icy = obj.y + c.y
                            if x < icx + c.w and x + w > icx and
                               y < icy + c.h and y + h > icy then
                                table.insert(results, id)
                            end
                        end
                    end
                end
            end
        end
    end
    return results
end
function SceneInstance:getUIAt(screenX, screenY)
    local ox, oy = 0, 0
    if debug.designW and debug.designH then
        local tw, th = buffer:getSize()
        ox = math.floor((tw - debug.designW) / 2)
        oy = math.floor((th - debug.designH) / 2)
    end
    for i = #self.ui.sorted, 1, -1 do
        local el = self.ui.sorted[i]
        local ex, ey = self.ui:getAbsolutePos(el, ox, oy)
        if screenX >= ex and screenX < ex + el.w and
           screenY >= ey and screenY < ey + el.h then
            return el.name
        end
    end
end
function SceneInstance:castRay(startX, startY, targetX, targetY, maxDist, ignoreId, layerMask)
    local stepX, stepY, dist = mathUtils.normalizeRaw(targetX - startX, targetY - startY)
    if dist == 0 then
        return false, startX, startY
    end
    local checkDist = math.min(dist, maxDist or 100)
    for d = 0, checkDist, 0.5 do
        local curX = startX + stepX * d
        local curY = startY + stepY * d
        local cx = math.floor(curX / self._cellSize)
        local cy = math.floor(curY / self._cellSize)
        local cell = self._spatialGrid[cx] and self._spatialGrid[cx][cy]
        if cell then
            for id, obj in pairs(cell.dynamic) do
                if id ~= ignoreId and (not layerMask or bit.band(obj.layer or 1, layerMask) > 0) then
                    local c = obj.collider
                    local ox = (obj.x or 0) + (c.x or 0)
                    local oy = (obj.y or 0) + (c.y or 0)
                    if curX >= ox and curX < ox + (c.w or 0) and
                       curY >= oy and curY < oy + (c.h or 0) then
                        return true, curX, curY, id
                    end
                end
            end
            for _, item in ipairs(cell.static) do
                if item.collider ~= false and
                   (not layerMask or bit.band(item.layer or 1, layerMask) > 0) then
                    local col = item.collider
                    local ox = (item.x or 0) + (col and col.x or 0)
                    local oy = (item.y or 0) + (col and col.y or 0)
                    local ow = col and col.w or item.w or 0
                    local oh = col and col.h or item.h or 0
                    if curX >= ox and curX < ox + ow and
                       curY >= oy and curY < oy + oh then
                        return true, curX, curY, nil
                    end
                end
            end
        end
    end
    return false, startX + stepX * checkDist, startY + stepY * checkDist
end
function SceneInstance:hasLOS(ax, ay, bx, by, cw, ch, ignoreId, layerMask)
    cw = cw or 1
    ch = ch or 1
    local x0, y0 = math.floor(ax), math.floor(ay)
    local x1, y1 = math.floor(bx), math.floor(by)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    local cx, cy = x0, y0
    while cx ~= x1 or cy ~= y1 do
        local e2 = 2 * err
        local stepX = e2 > -dy
        local stepY = e2 < dx
        if stepX and stepY then
            if self:isAreaBlocked(cx + sx, cy, cw, ch, ignoreId, layerMask) or
               self:isAreaBlocked(cx, cy + sy, cw, ch, ignoreId, layerMask) then
                return false
            end
        end
        if stepX then err = err - dy; cx = cx + sx end
        if stepY then err = err + dx; cy = cy + sy end
        if (cx ~= x1 or cy ~= y1) and
           self:isAreaBlocked(cx, cy, cw, ch, ignoreId, layerMask) then
            return false
        end
    end
    return true
end
function SceneInstance:isAreaBlocked(x, y, w, h, ignoreId, layerMask)
    local bestSlopeY = nil
    if self.tilemap then
        local tm = self.tilemap
        local startX = math.floor(x / tm.tileW) + 1
        local startY = math.floor(y / tm.tileH) + 1
        local endX = math.floor((x + w - 0.001) / tm.tileW) + 1
        local endY = math.floor((y + h - 0.001) / tm.tileH) + 1
        for ty = startY, endY do
            if tm.data[ty] then
                for tx = startX, endX do
                    local tileId = tm.data[ty][tx]
                    if tileId then
                        local prop = tm.tileProperties[tileId]
                        if prop and prop.type == "slope" then
                            local relX = (x + w/2 - (tx-1)*tm.tileW) / tm.tileW
                            relX = mathUtils.clamp(relX, 0, 1)
                            local slopeHeight = mathUtils.lerp(prop.hL, prop.hR, relX) * tm.tileH
                            local groundY = (ty-1)*tm.tileH + (tm.tileH - slopeHeight)
                            if y + h > groundY then
                                bestSlopeY = groundY
                            end
                        elseif prop and prop.type == "one-way" then
                            local platformY = (ty-1)*tm.tileH
                            if ignoreId then
                                local vel = self:get(ignoreId, "velocity")
                                if vel and vel.y > 0 and
                                (y + h - vel.y * 0.1) <= platformY then
                                    if y + h > platformY then
                                        bestSlopeY = platformY
                                    end
                                end
                            end
                        elseif tm.solidTiles[tileId] then
                            return true, "tile"
                        end
                    end
                end
            end
        end
    end
    if bestSlopeY then
        return true, "tile", bestSlopeY
    end
    local x1 = math.floor(x / self._cellSize)
    local y1 = math.floor(y / self._cellSize)
    local x2 = math.floor((x + w - 0.001) / self._cellSize)
    local y2 = math.floor((y + h - 0.001) / self._cellSize)
    for cx = x1, x2 do
        if self._spatialGrid[cx] then
            for cy = y1, y2 do
                local cell = self._spatialGrid[cx][cy]
                if cell then
                    for _, item in ipairs(cell.static) do
                        if item.collider ~= false and
                           (not layerMask or bit.band(item.layer or 1, layerMask) > 0) then
                            local col = item.collider
                            local ox, oy, ow, oh
                            if col then
                                ox = item.x + (col.x or 0)
                                oy = item.y + (col.y or 0)
                                ow = col.w or item.w or 0
                                oh = col.h or item.h or 0
                            else
                                ox = item.x or 0
                                oy = item.y or 0
                                ow = item.w or 0
                                oh = item.h or 0
                            end
                            if x < ox + ow and x + w > ox and
                               y < oy + oh and y + h > oy then
                                if item.oneWay then
                                    if ignoreId then
                                        local vel = self:get(ignoreId, "velocity")
                                        if vel and vel.y >= 0 and
                                        (y + h - vel.y * 0.1) <= oy then
                                            return true, "static"
                                        end
                                    end
                                else
                                    return true, "static"
                                end
                            end
                        end
                    end
                    for id, obj in pairs(cell.dynamic) do
                        if id ~= ignoreId and
                           (not layerMask or bit.band(obj.layer or 1, layerMask) > 0) then
                            local col = obj.collider
                            local ox = (obj.x or 0) + (col.x or 0)
                            local oy = (obj.y or 0) + (col.y or 0)
                            if x < ox + (col.w or 0) and x + w > ox and
                               y < oy + (col.h or 0) and y + h > oy then
                                return true, id
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end
function SceneInstance:addTrigger(x, y, w, h, onEnter, onExit)
    table.insert(self._triggers, {
        x = x,
        y = y,
        w = w,
        h = h,
        onEnter = onEnter,
        onExit = onExit,
        entitiesInside = {}
    })
end
function SceneInstance:_updateTriggers()
    for _, trigger in ipairs(self._triggers) do
        local entities = self:queryRect(trigger.x, trigger.y, trigger.w, trigger.h)
        local entityMap = {}
        for _, id in ipairs(entities) do
            entityMap[id] = true
        end
        for id in pairs(trigger.entitiesInside) do
            if not entityMap[id] then
                if trigger.onExit then
                    trigger.onExit(id)
                end
                trigger.entitiesInside[id] = nil
            end
        end
        for _, id in ipairs(entities) do
            if not trigger.entitiesInside[id] then
                if trigger.onEnter then
                    trigger.onEnter(id)
                end
                trigger.entitiesInside[id] = true
            end
        end
    end
end
function SceneInstance:loadUI(path, x, y)
    local uiData, err = loader.loadUI(path)
    if not uiData then
        logger.error("Failed to load OUI: " .. tostring(err))
        return
    end
    for name, el in pairs(uiData.elements) do
        self.ui:add(name, el.type, (x or 0) + (el.x or 0), (y or 0) + (el.y or 0), el)
    end
end
function SceneInstance:unloadUI(path)
    local uiData = loader.loadUI(path)
    if uiData then
        for name in pairs(uiData.elements) do
            self.ui:remove(name)
        end
    end
end
function SceneInstance:addUI(name, type, x, y, config)
    return self.ui:add(name, type, x, y, config)
end
function SceneInstance:updateUI(name, config)
    self.ui:update(name, config)
end
function SceneInstance:bindHUD(name, fn)
    self._nextHudId = (self._nextHudId or 0) + 1
    local id = self._nextHudId
    table.insert(self._hudCallbacks, { id = id, name = name, fn = fn })
    return id
end
function SceneInstance:unbindHUD(id)
    for i = #self._hudCallbacks, 1, -1 do
        if self._hudCallbacks[i].id == id then
            table.remove(self._hudCallbacks, i)
        end
    end
end
function SceneInstance:addSystem(filter, fn)
    table.insert(self._systems.update, {
        filter = filter,
        update = fn
    })
end
function SceneInstance:attach(id, component, data)
    WorldProto.attach(self, id, component, data)
    if component == "z" or component == "sprite" then
        if component == "sprite" and data == nil then
            logger.warn("Scene: Sprite component set to nil for entity " .. tostring(id))
        end
        self._zDirty = true
    end
end
function SceneInstance:despawn(id)
    local p = self:get(id, "pos")
    local s = self:get(id, "sprite")
    if p and s then
        local termW, termH = buffer:getSize()
        local designW, designH = debug.designW, debug.designH
        local offsetY = (designW and designH) and math.floor((termH - designH) / 2) or 0
        local totalCamY = self.camera.y - offsetY
        local sy = math.floor(p.y - totalCamY)
        for i = 0, s.height - 1 do
            local targetY = sy + i
            if targetY >= 1 and targetY <= termH then
                self._rowsToRestore[targetY] = true
            end
        end
    end
    WorldProto.despawn(self, id)
    self._zDirty = true
end
function SceneInstance:update(dt)
    self:_updateDynamicGrid()
    local children = self:select("pos", "parent")
    for _, id in ipairs(children) do
        local parentData = self:get(id, "parent")
        local parentPos = self:get(parentData.id, "pos")
        local childPos = self:get(id, "pos")
        if parentPos and childPos then
            childPos:set(
                parentPos.x + parentData.offset.x,
                parentPos.y + parentData.offset.y
            )
        end
    end
    for _, system in ipairs(self._systems.update) do
        local entities = self:select(table.unpack(system.filter))
        local ok, err = xpcall(function()
            system.update(dt, entities, self._store)
        end, tracebackHandler)
        if not ok then
            local filterStr = "[" .. table.concat(system.filter, ", ") .. "]"
            errorModule.report("System " .. filterStr .. ":\n" .. err)
            return
        end
    end
    self:_updateTriggers()
    if self.onUpdate then
        local ok, err = xpcall(self.onUpdate, tracebackHandler, dt)
        if not ok then
            errorModule.report("Scene.onUpdate:\n" .. err)
            return
        end
    end
    for _, hud in ipairs(self._hudCallbacks) do
        local ok, err = xpcall(function() hud.fn(self, dt) end, tracebackHandler)
        if not ok then
            errorModule.report("HUD callback:\n" .. err)
        end
    end
end
function SceneInstance:draw()
    local camMoved = self.camera.x ~= self._lastCam.x or
                    self.camera.y ~= self._lastCam.y
    local termW, termH = buffer:getSize()
    local designW, designH = debug.designW, debug.designH
    local offsetX, offsetY = 0, 0
    if designW and designH then
        offsetX = math.max(0, math.floor((termW - designW) / 2))
        offsetY = math.max(0, math.floor((termH - designH) / 2))
    end
    local shakeX, shakeY = 0, 0
    if self._camera and self._camera:isShaking() then
        shakeX, shakeY = self._camera:getShakeOffset()
    end
    local totalCamX = self.camera.x - offsetX + shakeX
    local totalCamY = self.camera.y - offsetY + shakeY
    if self._staticSortDirty then
        table.sort(self._staticElements, function(a, b)
            return a.z < b.z
        end)
        self._staticSortDirty = false
    end
    if self._foregroundSortDirty then
        table.sort(self._foregroundElements, function(a, b)
            return a.z < b.z
        end)
        self._foregroundSortDirty = false
    end
    if self._staticDirty or camMoved or
       (self._camera and self._camera:isShaking()) then
        self:_renderStatic(totalCamX, totalCamY, termW, termH)
    else
        self:_restoreRows()
    end
    self:_renderEntities(totalCamX, totalCamY, termW, termH)
    self:_renderForeground(totalCamX, totalCamY, termW, termH)
    if not debug.unsupportedResolution then
        self.ui:draw(offsetX, offsetY, self._rowsToRestore)
    end
    if self._camera and self._camera:isFlashing() then
        local fc = self._camera:getFlashColor()
        buffer:drawRect(1, 1, termW, termH, " ", fc, fc)
    end
    if debug.enabled then
        self:_renderDebug(termW, termH)
    end
    if self.onDraw then
        local ok, err = xpcall(self.onDraw, tracebackHandler)
        if not ok then
            errorModule.report("Scene.onDraw:\n" .. err)
        end
    end
end
function SceneInstance:_renderStatic(camX, camY, termW, termH)
    buffer:clear()
    if self.tilemap then
        local tm = self.tilemap
        local startX = math.max(1, math.floor(camX / tm.tileW) + 1)
        local startY = math.max(1, math.floor(camY / tm.tileH) + 1)
        local endX = math.floor((camX + termW) / tm.tileW) + 1
        local endY = math.floor((camY + termH) / tm.tileH) + 1
        if tm.layers then
            for _, layer in ipairs(tm.layers) do
                for ty = startY, endY do
                    if layer.data[ty] then
                        for tx = startX, endX do
                            local tid = layer.data[ty][tx]
                            if tid and tid > 0 and tm.sprite[tid] then
                                buffer:drawSprite(
                                    tm.sprite[tid],
                                    (tx-1) * tm.tileW,
                                    (ty-1) * tm.tileH,
                                    camX, camY
                                )
                            end
                        end
                    end
                end
            end
        else
            for ty = startY, endY do
                if tm.data[ty] then
                    for tx = startX, endX do
                        local tid = tm.data[ty][tx]
                        if tid and tid > 0 and tm.sprite[tid] then
                            buffer:drawSprite(
                                tm.sprite[tid],
                                (tx-1) * tm.tileW,
                                (ty-1) * tm.tileH,
                                camX, camY
                            )
                        end
                    end
                end
            end
        end
    end
    for _, item in ipairs(self._staticElements) do
        local s = item.sprite
        local sx = math.floor(item.x - camX)
        local sy = math.floor(item.y - camY)
        if s and s[1] and
           sx + s.width >= 1 and sx <= termW and
           sy + s.height >= 1 and sy <= termH then
            buffer:drawSprite(s[1], item.x, item.y, camX, camY)
        end
    end
    buffer:copyTo(self._staticCache)
    self._staticDirty = false
    self._rowsToRestore = {}
    self._lastCam.x, self._lastCam.y = self.camera.x, self.camera.y
end
function SceneInstance:_restoreRows()
    for y in pairs(self._rowsToRestore) do
        buffer:restoreLine(y, self._staticCache)
    end
    self._rowsToRestore = {}
end
function SceneInstance:_renderEntities(camX, camY, termW, termH)
    if self._zDirty then
        self._sortedEntities = self:select("pos", "sprite")
        table.sort(self._sortedEntities, function(a, b)
            local za = self:get(a, "z") or 0
            local zb = self:get(b, "z") or 0
            return za < zb
        end)
        self._zDirty = false
    end
    debug.dynamicCount = #self._sortedEntities
    for _, id in ipairs(self._sortedEntities) do
        local p = self:get(id, "pos")
        local s = self:get(id, "sprite")
        local anim = self:get(id, "animation")
        local frameIdx = 1
        if anim and anim.sequences and anim.state then
            local seq = anim.sequences[anim.state]
            frameIdx = seq and seq[anim.currentFrame or 1] or (anim.currentFrame or 1)
        elseif anim then
            frameIdx = anim.currentFrame or 1
        end
        local currentFrame = s and s[frameIdx]
        if currentFrame then
            local sx = math.floor(p.x - camX)
            local sy = math.floor(p.y - camY)
            local frameW = s.width or 0
            local frameH = s.height or 0
            if sx + frameW >= 1 and sx <= termW and
               sy + frameH >= 1 and sy <= termH then
                local colorOverride = self:get(id, "colorOverride")
                local charOverride = self:get(id, "charOverride")
                local bgOverride = self:get(id, "bgOverride")
                if colorOverride or charOverride or bgOverride then
                    for row = 0, frameH - 1 do
                        local ty = math.floor(p.y - camY) + row
                        local rowStr
                        if charOverride then
                            rowStr = string.rep(charOverride:sub(1, 1), frameW)
                        elseif currentFrame[1] and currentFrame[1][row + 1] then
                            rowStr = table.concat(currentFrame[1][row + 1])
                        else
                            rowStr = string.rep(" ", frameW)
                        end
                        buffer:drawText(math.floor(p.x - camX), ty, rowStr, colorOverride or " ", bgOverride or " ")
                    end
                else
                    buffer:drawSprite(currentFrame, p.x, p.y, camX, camY)
                end
                for i = 0, frameH - 1 do
                    local targetY = sy + i
                    if targetY >= 1 and targetY <= termH then
                        self._rowsToRestore[targetY] = true
                    end
                end
            end
        end
    end
end
function SceneInstance:_renderForeground(camX, camY, termW, termH)
    for _, item in ipairs(self._foregroundElements) do
        local s = item.sprite
        local sx = math.floor(item.x - camX)
        local sy = math.floor(item.y - camY)
        if s and s[1] and
           sx + s.width >= 1 and sx <= termW and
           sy + s.height >= 1 and sy <= termH then
            buffer:drawSprite(s[1], item.x, item.y, camX, camY)
            for i = 0, s.height - 1 do
                self._rowsToRestore[sy + i] = true
            end
        end
    end
end
function SceneInstance:_renderDebug()
    if debug.alwaysOnTop then return end
    local stats = string.format(
        "FPS: %d | Upd: %dms | Draw: %dms",
        debug.fps, debug.updateTime, debug.drawTime
    )
    local entInfo = string.format(
        "Entities: %d (Dyn) | %d (Stat)",
        debug.dynamicCount, #self._staticElements
    )
    buffer:drawText(1, 1, stats, "0", "f")
    buffer:drawText(1, 2, entInfo, "7", "f")
    self._rowsToRestore[1] = true
    self._rowsToRestore[2] = true
    if debug.showLogs then
        local history = logger.getHistory()
        for i, entry in ipairs(history) do
            buffer:drawText(1, 3 + i, entry.text, entry.color, "f")
            self._rowsToRestore[3 + i] = true
        end
    end
end
return Scene
]=]
paths["core.scene"] = "core/scene"
sources["core.serialization"] = [=[

local require = ...
local logger = require("core.logger")
local loader = require("core.loader")
local mathUtils = require("core.math")
local Serialization = {}
function Serialization.pack(scene)
    local data = {
        name = scene.name or "Unnamed Scene",
        camera = { x = scene.camera.x, y = scene.camera.y },
        tilemap = nil,
        statics = {},
        entities = {}
    }
    if scene.tilemap then
        data.tilemap = {
            spritePath = scene.tilemap.spritePath,
            data = scene.tilemap.data,
            solidTiles = scene.tilemap.solidTiles,
            tileProperties = scene.tilemap.tileProperties
        }
    end
    for _, item in ipairs(scene._staticElements) do
        table.insert(data.statics, {
            spritePath = item.spritePath,
            x = item.x,
            y = item.y,
            z = item.z,
            collider = item.collider,
            layer = item.layer
        })
    end
    for id, _ in pairs(scene._entities) do
        local entData = { id = id, components = {} }
        local signature = scene._tags[id]
        for compName, _ in pairs(signature) do
            local comp = scene._store[compName][id]
            if compName == "sprite" then
                entData.components[compName] = { spritePath = comp.path }
            elseif mathUtils.isVec2(comp) then
                entData.components[compName] = { __type = "vec2", x = comp.x, y = comp.y }
            elseif type(comp) == "table" then
                local copy = {}
                for k, v in pairs(comp) do if type(v) ~= "function" then copy[k] = v end end
                entData.components[compName] = copy
            else
                entData.components[compName] = comp
            end
        end
        table.insert(data.entities, entData)
    end
    return data
end
function Serialization.save(scene, path)
    local data = Serialization.pack(scene)
    local file = fs.open(path, "w")
    if not file then
        logger.error("Serialization: Could not open file for writing: " .. tostring(path))
        return false
    end
    local ok, err = pcall(function() file.write(textutils.serialize(data)) end)
    file.close()
    if not ok then
        logger.error("Serialization: Failed to serialize scene: " .. tostring(err))
        return false
    end
    logger.info("Scene serialized to " .. path)
    return true
end
function Serialization.apply(scene, data)
    local toDestroy = {}
    for id in pairs(scene._entities) do
        toDestroy[#toDestroy + 1] = id
    end
    for _, id in ipairs(toDestroy) do
        scene:despawn(id)
    end
    scene._staticElements = {}
    scene._foregroundElements = {}
    scene.tilemap = nil
    scene._spatialGrid = {}
    scene._activeDynamicCells = {}
    scene._staticDirty = true
    scene.name = data.name
    scene.camera:set(data.camera.x, data.camera.y)
    if data.tilemap and data.tilemap.spritePath then
        local sprite = loader.loadSprite(data.tilemap.spritePath)
        scene:setTilemap(sprite, data.tilemap.data, data.tilemap.solidTiles, data.tilemap.tileProperties)
        scene.tilemap.spritePath = data.tilemap.spritePath
    end
    for _, s in ipairs(data.statics) do
        local sprite = s.spritePath and loader.loadSprite(s.spritePath) or nil
        scene:addStatic(sprite, s.x, s.y, {
            z        = s.z,
            collider = s.collider,
            layer    = s.layer,
        })
        scene._staticElements[#scene._staticElements].spritePath = s.spritePath
    end
    local idMap = {}
    for _, entData in ipairs(data.entities) do
        local newId = scene:spawn()
        idMap[entData.id] = newId
    end
    for _, entData in ipairs(data.entities) do
        local id = idMap[entData.id]
        for compName, compData in pairs(entData.components) do
            if compName == "sprite" then
                local s = loader.loadSprite(compData.spritePath)
                scene:attach(id, "sprite", s)
            elseif type(compData) == "table" and compData.__type == "vec2" then
                scene:attach(id, compName, mathUtils.vec2(compData.x, compData.y))
            elseif compName == "pos" then
                scene:attach(id, "pos", mathUtils.vec2(compData.x or 0, compData.y or 0))
            elseif compName == "parent" and type(compData) == "table" and compData.id then
                local remapped = { id = idMap[compData.id] or compData.id }
                if compData.offset then
                    remapped.offset = mathUtils.vec2(compData.offset.x or 0, compData.offset.y or 0)
                end
                scene:attach(id, "parent", remapped)
            else
                scene:attach(id, compName, compData)
            end
        end
    end
end
return Serialization
]=]
paths["core.serialization"] = "core/serialization"
sources["core.server"] = [=[

local require = ...
local logger  = require("core.logger")
local network = require("core.network")
local buffer  = require("core.buffer")
local server = {}
server._emit = function() end
local _auth
local _clients = {}
local _rooms = {}
local _handlers = {}
local _middleware = {}
local _tickCbs = {}
local _onConnectCb = nil
local _onDisconnectCb = nil
local _running = false
local _protocol = nil
local _hostname = nil
local _tickRate = 20
local _timeout = 30
local _heartbeat = 5
local _seqEnabled = false
local _con = {
    enabled = false,
    title = "Obsidian Server",
    maxEntries = 200,
    log = {},
    lines = {},
    lastWidth = 0,
    lastHeight = 0,
    startTime = nil,
    dirty = true,
    buf = nil,
}
local CON_LEVEL = {
    info = { fore = "0", prefix = "[INFO ] " },
    warn = { fore = "1", prefix = "[WARN ] " },
    error = { fore = "e", prefix = "[ERROR] " },
    success = { fore = "d", prefix = "[OK   ] " },
    system = { fore = "b", prefix = "[SYS  ] " },
    debug = { fore = "7", prefix = "[DEBUG] " },
}
local CON_PREFIX_W = 0
local function _conTimestamp()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end
local function _wrapText(fullLine, width, indentW)
    if width <= 0 or #fullLine <= width then return { fullLine } end
    local result = {}
    local indent = string.rep(" ", indentW)
    local remaining = fullLine
    while #remaining > width do
        local cut = width
        for i = width, indentW + 1, -1 do
            if remaining:sub(i, i) == " " then
                cut = i - 1
                break
            end
        end
        result[#result + 1] = remaining:sub(1, cut)
        local rest = remaining:sub(cut + 1):match("^%s*(.*)")
        remaining = (#rest > 0) and (indent .. rest) or ""
    end
    if #remaining > 0 then
        result[#result + 1] = remaining
    end
    return result
end
local function _rebuildLines(width)
    _con.lines = {}
    for _, entry in ipairs(_con.log) do
        local full = entry.ts .. "  " .. entry.prefix .. entry.raw
        for _, wl in ipairs(_wrapText(full, width, CON_PREFIX_W)) do
            _con.lines[#_con.lines + 1] = { text = wl, fore = entry.fore }
        end
    end
    _con.lastWidth = width
end
local function _consolePush(text, level)
    level = CON_LEVEL[level] or CON_LEVEL.info
    local entry = {
        ts = _conTimestamp(),
        prefix = level.prefix,
        raw = tostring(text),
        fore = level.fore,
    }
    table.insert(_con.log, entry)
    if #_con.log > _con.maxEntries then
        table.remove(_con.log, 1)
        if _con.lastWidth > 0 then
            _rebuildLines(_con.lastWidth)
        end
    else
        if _con.lastWidth > 0 then
            local full = entry.ts .. "  " .. entry.prefix .. entry.raw
            for _, wl in ipairs(_wrapText(full, _con.lastWidth, CON_PREFIX_W)) do
                _con.lines[#_con.lines + 1] = { text = wl, fore = entry.fore }
            end
        end
    end
    _con.dirty = true
end
local function _consoleRender()
    if not _con.enabled or not _con.dirty then return end
    _con.dirty = false
    local sw, sh = term.getSize()
    if sw == 0 or sh == 0 then return end
    if not _con.buf then
        _con.buf = buffer.new(sw, sh)
        _con.lastWidth = sw
        _con.lastHeight = sh
    elseif sw ~= _con.lastWidth or sh ~= _con.lastHeight then
        _con.buf:setSize(sw, sh)
        _con.lastWidth = sw
        _con.lastHeight = sh
    end
    if sw ~= _con.lastWidth then
        _rebuildLines(sw)
    end
    local buf = _con.buf
    local uptime = ""
    if _con.startTime then
        local secs = math.floor(os.epoch("utc") / 1000 - _con.startTime)
        local m = math.floor(secs / 60)
        local s = secs % 60
        uptime = string.format("up %dm%02ds", m, s)
    end
    local right = string.format("ID:%-3d  %s ", os.getComputerID(), uptime)
    local header = (" " .. _con.title .. string.rep(" ", sw)):sub(1, sw - #right) .. right
    buf:drawLine(1, header, "f", "5")
    local proto = _protocol or "(no protocol)"
    local nClients = 0
    for _ in pairs(_clients) do nClients = nClients + 1 end
    local status = string.format(" proto: %-20s  clients: %d", proto, nClients)
    buf:drawLine(sh, status, "0", "8")
    local logH = sh - 2
    local startIdx = math.max(1, #_con.lines - logH + 1)
    local row = 2
    for i = startIdx, math.min(startIdx + logH - 1, #_con.lines) do
        local line = _con.lines[i]
        buf:drawLine(row, line.text, line.fore, "f")
        row = row + 1
    end
    while row < sh do
        buf:drawLine(row, "", "0", "f")
        row = row + 1
    end
    buf:present()
end
function server.showConsole(title)
    _con.enabled = true
    if title then _con.title = title end
end
function server.log(text, level)
    _consolePush(tostring(text), level or "info")
end
local function makePacket(msgType, data)
    return {
        type = msgType,
        data = data or {},
        sender = os.getComputerID(),
        timestamp = os.epoch("utc"),
    }
end
function server.getClients()
    local list = {}
    for id in pairs(_clients) do
        list[#list + 1] = id
    end
    return list
end
function server.clientCount()
    local n = 0
    for _ in pairs(_clients) do n = n + 1 end
    return n
end
function server.isConnected(clientId)
    return _clients[clientId] ~= nil
end
function server.setMeta(clientId, key, value)
    if _clients[clientId] then
        _clients[clientId].meta[key] = value
    end
end
function server.getMeta(clientId, key)
    if _clients[clientId] then
        return _clients[clientId].meta[key]
    end
    return nil
end
local function _removeClient(clientId)
    if not _clients[clientId] then return end
    _clients[clientId] = nil
    _auth.sessions[clientId] = nil
    _auth.nonces[clientId] = nil
    for roomName, members in pairs(_rooms) do
        members[clientId] = nil
        local count = 0
        for _ in pairs(members) do count = count + 1 end
        if count == 0 then _rooms[roomName] = nil end
    end
    if _onDisconnectCb then
        pcall(_onDisconnectCb, clientId)
    end
    server._emit("server.clientDisconnect", clientId)
    logger.info("Server: Client " .. clientId .. " disconnected")
    _consolePush("Client #" .. clientId .. " disconnected", "warn")
end
function server.kick(clientId, reason)
    if not _clients[clientId] then return end
    server.send(clientId, "SERVER_KICK", { reason = reason or "Kicked by server" })
    _removeClient(clientId)
end
function server.joinRoom(clientId, roomName)
    if not _clients[clientId] then return end
    if not _rooms[roomName] then _rooms[roomName] = {} end
    _rooms[roomName][clientId] = true
end
function server.leaveRoom(clientId, roomName)
    if _rooms[roomName] then
        _rooms[roomName][clientId] = nil
    end
end
function server.getRoomClients(roomName)
    local list = {}
    if _rooms[roomName] then
        for id in pairs(_rooms[roomName]) do
            list[#list + 1] = id
        end
    end
    return list
end
function server.getClientRooms(clientId)
    local list = {}
    for roomName, members in pairs(_rooms) do
        if members[clientId] then
            list[#list + 1] = roomName
        end
    end
    return list
end
function server.send(clientId, msgType, data)
    if not network.isOpen then return false end
    local pkt = makePacket(msgType, data)
    rednet.send(clientId, pkt, _protocol)
    return true
end
function server.broadcast(msgType, data, exceptId)
    if not network.isOpen then return end
    local pkt = makePacket(msgType, data)
    for id in pairs(_clients) do
        if id ~= exceptId then
            rednet.send(id, pkt, _protocol)
        end
    end
end
function server.broadcastRoom(roomName, msgType, data, exceptId)
    if not _rooms[roomName] then return end
    local pkt = makePacket(msgType, data)
    for id in pairs(_rooms[roomName]) do
        if id ~= exceptId and _clients[id] then
            rednet.send(id, pkt, _protocol)
        end
    end
end
function server.on(msgType, fn)
    _handlers[msgType] = fn
end
function server.off(msgType)
    _handlers[msgType] = nil
end
function server.use(fn)
    _middleware[#_middleware + 1] = fn
end
local function _dispatch(clientId, packet)
    local i = 0
    local function next()
        i = i + 1
        if i <= #_middleware then
            local ok, err = pcall(_middleware[i], clientId, packet, next)
            if not ok then
                logger.error("Server middleware error: " .. tostring(err))
            end
        else
            local handler = _handlers[packet.type]
            if handler then
                local ok, err = pcall(handler, clientId, packet.data or {}, packet)
                if not ok then
                    logger.error("Server handler error [" .. tostring(packet.type) .. "]: " .. tostring(err))
                end
            end
        end
    end
    next()
end
function server.onConnect(fn)
    _onConnectCb = fn
end
function server.onDisconnect(fn)
    _onDisconnectCb = fn
end
_auth = {
    enabled = false,
    db = nil,
    sessions = {},
    nonces = {},
    attempts = {},
    opts = {},
}
local function _djb2(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + string.byte(str, i)) % 2147483647
    end
    return tostring(h)
end
local function _safeProfile(profile)
    local out = {}
    for k, v in pairs(profile) do
        if k ~= "passwordHash" then out[k] = v end
    end
    return out
end
function server.enableAuth(db, opts)
    assert(db, "server.enableAuth: db must be an Obsidian DB collection")
    opts = opts or {}
    _auth.db = db
    _auth.opts = opts
    _auth.enabled = true
    local minNameLen = opts.minNameLen or 3
    local maxNameLen = opts.maxNameLen or 16
    local minPwLen = opts.minPwLen or 4
    _handlers["REGISTER"] = function(clientId, data)
        local name = tostring(data.name or "")
        local passwordHash = tostring(data.passwordHash or "")
        local class = data.class
        if #name < minNameLen or #name > maxNameLen then
            server.send(clientId, "REGISTER_FAILED",
                { message = "Name must be " .. minNameLen .. "-" .. maxNameLen .. " characters." })
            return
        end
        if name:match("[^%w_%-]") then
            server.send(clientId, "REGISTER_FAILED",
                { message = "Name may only contain letters, numbers, - and _" })
            return
        end
        if #passwordHash == 0 then
            server.send(clientId, "REGISTER_FAILED",
                { message = "Password must be at least " .. minPwLen .. " characters." })
            return
        end
        if _auth.db:findOne({ name = name }) then
            server.send(clientId, "REGISTER_FAILED", { message = "Name already taken." })
            return
        end
        local profile = {
            cid = clientId,
            name = name,
            passwordHash = passwordHash,
            class = class,
        }
        if opts.buildProfile then
            local extra = opts.buildProfile(clientId, data) or {}
            for k, v in pairs(extra) do profile[k] = v end
        end
        _auth.db:insert(profile)
        _auth.sessions[clientId] = profile
        logger.info("Auth: '" .. name .. "' registered (client " .. clientId .. ")")
        _consolePush("Auth: '" .. name .. "' registered", "success")
        server.send(clientId, "REGISTER_SUCCESS", { profile = _safeProfile(profile) })
        if opts.onRegister then pcall(opts.onRegister, clientId, profile) end
    end
    _handlers["LOGIN_CHALLENGE_REQUEST"] = function(clientId, data)
        local now = os.epoch("utc") / 1000
        local att = _auth.attempts[clientId]
        if att and now < att.resetAt then
            server.send(clientId, "LOGIN_FAILED", { message = string.format(
                "Too many failed attempts. Try again in %ds.", math.ceil(att.resetAt - now)) })
            return
        end
        local name = tostring(data.name or "")
        math.randomseed(os.epoch("utc") + clientId)
        local nonce = tostring(math.random(10000000, 99999999)) .. tostring(os.epoch("utc") % 1000000)
        _auth.nonces[clientId] = { nonce = nonce, name = name, expireAt = now + 30 }
        server.send(clientId, "LOGIN_CHALLENGE", { nonce = nonce })
    end
    _handlers["LOGIN"] = function(clientId, data)
        local now = os.epoch("utc") / 1000
        local entry = _auth.nonces[clientId]
        local name = tostring(data.name or "")
        local response = tostring(data.response or "")
        if not entry or entry.name ~= name or now > entry.expireAt then
            _auth.nonces[clientId] = nil
            server.send(clientId, "LOGIN_FAILED", { message = "Challenge expired. Please try again." })
            return
        end
        _auth.nonces[clientId] = nil
        local profile = _auth.db:findOne({ name = name })
        if not profile or _djb2(profile.passwordHash .. entry.nonce) ~= response then
            local att = _auth.attempts[clientId] or { count = 0, resetAt = 0 }
            att.count = att.count + 1
            if att.count >= 5 then
                att.resetAt = now + 60
                att.count   = 0
                _consolePush("Auth: Client #" .. clientId .. " rate-limited", "warn")
            end
            _auth.attempts[clientId] = att
            server.send(clientId, "LOGIN_FAILED", { message = "Wrong username or password." })
            _consolePush("Auth: Failed login for '" .. name .. "'", "warn")
            return
        end
        _auth.attempts[clientId] = nil
        if profile.cid ~= clientId then
            _auth.db:update({ name = name }, { cid = clientId })
            profile.cid = clientId
        end
        _auth.sessions[clientId] = profile
        logger.info("Auth: '" .. name .. "' logged in (client " .. clientId .. ")")
        _consolePush("Auth: '" .. name .. "' logged in", "success")
        server.send(clientId, "LOGIN_SUCCESS", { profile = _safeProfile(profile) })
        if opts.onLogin then pcall(opts.onLogin, clientId, profile) end
    end
    _handlers["LOGOUT"] = function(clientId)
        local profile = _auth.sessions[clientId]
        _auth.sessions[clientId] = nil
        if profile then
            logger.info("Auth: '" .. profile.name .. "' logged out (client " .. clientId .. ")")
            _consolePush("Auth: '" .. profile.name .. "' logged out", "info")
        end
        if opts.onLogout then pcall(opts.onLogout, clientId, profile) end
    end
end
server.auth = {
    isLoggedIn = function(clientId)
        return _auth.sessions[clientId] ~= nil
    end,
    getProfile = function(clientId)
        return _auth.sessions[clientId]
    end,
    logout = function(clientId)
        _auth.sessions[clientId] = nil
    end,
    require = function(clientId)
        if not _auth.sessions[clientId] then
            server.send(clientId, "AUTH_REQUIRED", { message = "Please log in first." })
            return false
        end
        return true
    end,
}
function server.onTick(fn)
    _tickCbs[#_tickCbs + 1] = fn
end
function server.setTickRate(n)
    _tickRate = math.max(1, n)
end
function server.setTimeout(seconds)
    _timeout = seconds
end
function server.setHeartbeatInterval(seconds)
    _heartbeat = seconds
end
function server.enableSequencing()
    _seqEnabled = true
end
function server.getPing(clientId)
    local c = _clients[clientId]
    return c and c.ping or nil
end
function server.sendToList(idList, msgType, data)
    if not network.isOpen then return end
    local pkt = makePacket(msgType, data)
    for _, id in ipairs(idList) do
        if _clients[id] then
            rednet.send(id, pkt, _protocol)
        end
    end
end
function server.init(protocol, hostname, side)
    _protocol = protocol
    if not network.open(side) then
        logger.error("Server: No modem found!")
        return false
    end
    if not network.host(protocol, hostname) then
        logger.error("Server: Failed to host protocol '" .. protocol .. "'")
        return false
    end
    _hostname = hostname
    logger.info(string.format("Server: Online | protocol='%s' hostname='%s' id=%d",
        protocol, hostname, os.getComputerID()))
    return true
end
function server.stop()
    if not _running then return end
    _running = false
    server.broadcast("SERVER_SHUTDOWN", { reason = "Server shutting down" })
    local toRemove = {}
    for id in pairs(_clients) do toRemove[#toRemove + 1] = id end
    for _, id in ipairs(toRemove) do _clients[id] = nil end
    _rooms = {}
    network.close()
    _consolePush("Server stopped.", "system")
    _consoleRender()
    server._emit("server.stopped")
    logger.info("Server: Stopped")
end
local function _handleRednet(senderId, pkt, proto)
    if proto ~= _protocol then return end
    if type(pkt) ~= "table" or not pkt.type then return end
    if type(pkt) == "table" and pkt.type == "DISCOVER" and pkt.hostname == _hostname then
        logger.info("Server: DISCOVER from " .. tostring(senderId) .. " — replying")
        rednet.send(senderId, { type = "DISCOVER_REPLY", hostname = _hostname,
                                serverId = os.getComputerID() }, proto)
        return
    end
    if _clients[senderId] then
        _clients[senderId].lastSeen = os.epoch("utc") / 1000
    end
    if pkt.type == "CONNECT_REQUEST" then
        _clients[senderId] = {
            id = senderId,
            meta = {},
            joinedAt = os.epoch("utc") / 1000,
            lastSeen = os.epoch("utc") / 1000,
            ping = nil,
            heartbeatSent = nil,
            lastSeq = -1,
        }
        rednet.send(senderId, makePacket("CONNECT_ACCEPT", {
            serverId = os.getComputerID(),
            serverTime = os.epoch("utc"),
        }), _protocol)
        if _onConnectCb then pcall(_onConnectCb, senderId) end
        server._emit("server.clientConnect", senderId)
        logger.info("Server: Client " .. senderId .. " connected")
        _consolePush("Client #" .. senderId .. " connected", "success")
        return
    end
    if pkt.type == "CLIENT_LEAVE" then
        _removeClient(senderId)
        return
    end
    if not _clients[senderId] then return end
    if pkt.type == "PING" then
        local pingTime = pkt.t or (type(pkt.data) == "table" and pkt.data.t)
        rednet.send(senderId, makePacket("PONG", { t=pingTime }), _protocol)
        return
    end
    if pkt.type == "PONG" then
        local c = _clients[senderId]
        if c and c.heartbeatSent then
            c.ping = math.floor((os.epoch("utc") - c.heartbeatSent))
            c.heartbeatSent = nil
        end
        return
    end
    if _seqEnabled and pkt.seq then
        local c = _clients[senderId]
        if pkt.seq <= c.lastSeq then return end
        c.lastSeq = pkt.seq
    end
    _dispatch(senderId, pkt)
end
local _tickTimer = nil
local _lastTick  = 0
local function _runTick()
    local now = os.epoch("utc") / 1000
    local dt = now - _lastTick
    _lastTick = now
    for id, info in pairs(_clients) do
        if _timeout > 0 and now - info.lastSeen > _timeout then
            logger.warn("Server: Client " .. id .. " timed out")
            _consolePush(string.format("Client #%d timed out", id), "warn")
            server.kick(id, "Timed out")
        elseif _heartbeat > 0 and not info.heartbeatSent and
               (now - info.lastSeen) >= _heartbeat then
            info.heartbeatSent = os.epoch("utc")
            rednet.send(id, makePacket("PING", { t = info.heartbeatSent }), _protocol)
        end
    end
    for _, fn in ipairs(_tickCbs) do
        local ok, err = pcall(fn, dt)
        if not ok then
            logger.error("Server tick error: " .. tostring(err))
            _consolePush("Tick error: " .. tostring(err), "error")
        end
    end
    _con.dirty = true
    _consoleRender()
    _tickTimer = os.startTimer(1 / _tickRate)
end
function server.processEvent(rawEvent)
    local evName = rawEvent[1]
    if evName == "rednet_message" then
        _handleRednet(rawEvent[2], rawEvent[3], rawEvent[4])
    elseif evName == "term_resize" then
        _con.dirty = true
    elseif evName == "timer" and rawEvent[2] == _tickTimer then
        _runTick()
    end
end
function server.start()
    if not _protocol then
        logger.error("Server: Call server.init() before server.start()")
        return false
    end
    _running = true
    _lastTick = os.epoch("utc") / 1000
    _con.startTime = _lastTick
    _tickTimer = os.startTimer(1 / _tickRate)
    server._emit("server.started")
    logger.info("Server: Running at " .. _tickRate .. " ticks/s")
    _consolePush("Server started on " .. (_protocol or "?"), "system")
    if _con.enabled then
        local sw, sh = term.getSize()
        _rebuildLines(sw)
        _con.lastWidth  = sw
        _con.lastHeight = sh
    end
    return true
end
function server.run()
    if not server.start() then return end
    while _running do
        local rawEvent = { os.pullEventRaw() }
        if rawEvent[1] == "terminate" then
            logger.info("Server: Terminate signal received")
            server.stop()
            break
        end
        server.processEvent(rawEvent)
    end
end
return server
]=]
paths["core.server"] = "core/server"
sources["core.storage"] = [=[

local storage = {}
local SAVE_DIR = "saves/"
function storage.setDir(path)
    SAVE_DIR = path
end
function storage.save(name, data)
    if not fs.exists(SAVE_DIR) then
        fs.makeDir(SAVE_DIR)
    end
    local path = fs.combine(SAVE_DIR, name .. ".dat")
    local file = fs.open(path, "w")
    if not file then return false, "Could not open file for writing: " .. path end
    local ok, err = pcall(function()
        file.write(textutils.serialize(data))
    end)
    file.close()
    return ok, err
end
function storage.load(name)
    local path = fs.combine(SAVE_DIR, name .. ".dat")
    if not fs.exists(path) then return nil, "Save file does not exist: " .. path end
    local file = fs.open(path, "r")
    if not file then return nil, "Could not open file for reading: " .. path end
    local raw = file.readAll()
    file.close()
    local ok, data = pcall(textutils.unserialize, raw)
    if not ok then return nil, "Failed to deserialize save data: " .. tostring(data) end
    return data, nil
end
function storage.delete(name)
    local path = fs.combine(SAVE_DIR, name .. ".dat")
    if fs.exists(path) then
        fs.delete(path)
        return true
    end
    return false
end
function storage.list()
    if not fs.exists(SAVE_DIR) then return {} end
    local names = {}
    for _, file in ipairs(fs.list(SAVE_DIR)) do
        if file:sub(-4) == ".dat" then
            names[#names + 1] = file:sub(1, -5)
        end
    end
    return names
end
return storage
]=]
paths["core.storage"] = "core/storage"
sources["core.thread"] = [=[

local require = ...
local logger = require("core.logger")
local ThreadModule = {}
ThreadModule.errorHandler = nil
local threads = {}
local nextId  = 1
local function tracebackHandler(e)
    local d = _G and _G.debug
    return (d and d.traceback) and d.traceback(tostring(e), 2) or tostring(e)
end
local thread = {}
function thread:stop()
    return ThreadModule.stop(self)
end
function thread:isAlive()
    local id = type(self) == "table" and self.id or nil
    if not id then return false end
    local entry = threads[id]
    return entry ~= nil and coroutine.status(entry.co) ~= "dead"
end
function thread:getStatus()
    local id = type(self) == "table" and self.id or nil
    if not id then return nil end
    local entry = threads[id]
    return entry and entry.status or nil
end
function thread:yield(eventFilter)
    return ThreadModule.yield(eventFilter)
end
local function createHandle(id)
    local h = { id = id }
    setmetatable(h, { __index = thread })
    return h
end
function ThreadModule.start(fn)
    local co = coroutine.create(function(...)
        local ok, err = xpcall(fn, tracebackHandler, ...)
        if not ok then
            if ThreadModule.errorHandler then
                ThreadModule.errorHandler(err)
            else
                logger.error("[Thread] Uncaught error: " .. tostring(err))
            end
        end
    end)
    local id = nextId
    nextId = nextId + 1
    local handle = createHandle(id)
    threads[id] = { id = id, co = co, status = "running", filter = nil, handle = handle }
    return handle
end
function ThreadModule.stop(idOrHandle)
    local id = idOrHandle
    if type(idOrHandle) == "table" and idOrHandle.id then id = idOrHandle.id end
    if id == nil then return false end
    if threads[id] then
        threads[id] = nil
        return true
    end
    return false
end
function ThreadModule.getAll()
    local copy = {}
    for id, t in pairs(threads) do copy[id] = t end
    return copy
end
function ThreadModule.count()
    local n = 0
    for _, t in pairs(threads) do
        if coroutine.status(t.co) ~= "dead" then n = n + 1 end
    end
    return n
end
function ThreadModule.reset()
    threads = {}
    nextId  = 1
end
function ThreadModule.yield(eventFilter)
    return coroutine.yield(eventFilter)
end
function ThreadModule.update(...)
    local event = { ... }
    local snapshot = {}
    for id, t in pairs(threads) do snapshot[id] = t end
    for id, t in pairs(snapshot) do
        if coroutine.status(t.co) ~= "dead" then
            if t.filter == event[1] or t.filter == nil then
                local ok, result = coroutine.resume(t.co, table.unpack(event))
                if not ok then
                    if ThreadModule.errorHandler then
                        ThreadModule.errorHandler(result)
                    else
                        logger.error("[Thread] Error in Thread " .. id .. ": " .. tostring(result))
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
return ThreadModule
]=]
paths["core.thread"] = "core/thread"
sources["core.tilemap"] = [=[

local require = ...
local loader  = require("core.loader")
local storage = require("core.storage")
local tilemap = {}
local TilemapModule = {}
function TilemapModule.new(opts)
    opts = opts or {}
    local self = {
        tileW = opts.tileW or 2,
        tileH = opts.tileH or 1,
        _defs = {},
        _layers = {},
        _layerMap = {},
        _sprites = {},
        _scene = nil,
    }
    setmetatable(self, { __index = tilemap })
    return self
end
function tilemap:defineTile(id, opts)
    assert(type(id) == "number" and id > 0, "tilemap:defineTile id must be a positive number")
    opts = opts or {}
    self._defs[id] = {
        spritePath = opts.spritePath,
        solid = opts.solid or false,
        type = opts.type,
        hL = opts.hL or 0,
        hR = opts.hR or 0,
    }
end
function tilemap:getTileDef(id)
    return self._defs[id]
end
function tilemap:addLayer(name, opts)
    assert(type(name) == "string", "layer name must be a string")
    assert(not self._layerMap[name], "layer '" .. name .. "' already exists")
    opts = opts or {}
    local layer = {
        name = name,
        z = opts.z or -100,
        collision = opts.collision or false,
        data = {},
    }
    table.insert(self._layers, layer)
    table.sort(self._layers, function(a, b) return a.z < b.z end)
    self._layerMap[name] = layer
    return layer
end
function tilemap:removeLayer(name)
    self._layerMap[name] = nil
    for i = #self._layers, 1, -1 do
        if self._layers[i].name == name then
            table.remove(self._layers, i)
            return true
        end
    end
    return false
end
function tilemap:getLayer(name)
    return self._layerMap[name]
end
function tilemap:setTile(layerName, tx, ty, tileId)
    local layer = self._layerMap[layerName]
    assert(layer, "tilemap:setTile: unknown layer '" .. tostring(layerName) .. "'")
    if not layer.data[ty] then layer.data[ty] = {} end
    layer.data[ty][tx] = (tileId and tileId > 0) and tileId or nil
    self:_markDirty()
end
function tilemap:getTile(layerName, tx, ty)
    local layer = self._layerMap[layerName]
    if not layer then return nil end
    return layer.data[ty] and layer.data[ty][tx] or nil
end
function tilemap:fill(layerName, tileId, x1, y1, x2, y2)
    local layer = self._layerMap[layerName]
    assert(layer, "tilemap:fill: unknown layer '" .. tostring(layerName) .. "'")
    local val = (tileId and tileId > 0) and tileId or nil
    if not x1 then
        if val then
            error("tilemap:fill: provide x1,y1,x2,y2 when placing tiles (can't fill unbounded)")
        end
        layer.data = {}
    else
        for ty = y1, y2 do
            if not layer.data[ty] then layer.data[ty] = {} end
            for tx = x1, x2 do
                layer.data[ty][tx] = val
            end
        end
    end
    self:_markDirty()
end
function tilemap:copyRect(srcLayer, dstLayer, sx1, sy1, sx2, sy2, dx, dy)
    local src = self._layerMap[srcLayer]
    local dst = self._layerMap[dstLayer]
    assert(src, "copyRect: unknown source layer '" .. tostring(srcLayer) .. "'")
    assert(dst, "copyRect: unknown dest layer '"   .. tostring(dstLayer) .. "'")
    for oy = 0, sy2 - sy1 do
        local ty = sy1 + oy
        local dty = dy + oy
        if not dst.data[dty] then dst.data[dty] = {} end
        for ox = 0, sx2 - sx1 do
            local tx = sx1 + ox
            dst.data[dty][dx + ox] = src.data[ty] and src.data[ty][tx] or nil
        end
    end
    self:_markDirty()
end
function tilemap:worldToTile(wx, wy)
    return math.floor(wx / self.tileW) + 1,
           math.floor(wy / self.tileH) + 1
end
function tilemap:tileToWorld(tx, ty)
    return (tx - 1) * self.tileW,
           (ty - 1) * self.tileH
end
function tilemap:forArea(wx1, wy1, wx2, wy2, fn)
    local startX = math.floor(wx1 / self.tileW) + 1
    local startY = math.floor(wy1 / self.tileH) + 1
    local endX   = math.floor(wx2 / self.tileW) + 1
    local endY   = math.floor(wy2 / self.tileH) + 1
    for _, layer in ipairs(self._layers) do
        for ty = startY, endY do
            if layer.data[ty] then
                for tx = startX, endX do
                    local id = layer.data[ty][tx]
                    if id then fn(layer.name, tx, ty, id) end
                end
            end
        end
    end
end
function tilemap:getNeighbors(layerName, tx, ty)
    local layer = self._layerMap[layerName]
    if not layer then return {} end
    local dirs = { {0,-1},{0,1},{-1,0},{1,0} }
    local result = {}
    for _, d in ipairs(dirs) do
        local nx, ny = tx + d[1], ty + d[2]
        local id = layer.data[ny] and layer.data[ny][nx] or nil
        table.insert(result, { tx = nx, ty = ny, tileId = id })
    end
    return result
end
function tilemap:attach(scene)
    self._scene = scene
    for _, def in pairs(self._defs) do
        if def.spritePath and not self._sprites[def.spritePath] then
            local spr = loader.loadSprite(def.spritePath)
            if spr then
                self._sprites[def.spritePath] = spr
            end
        end
    end
    self:_buildSceneTilemap(scene)
end
function tilemap:detach()
    if self._scene then
        self._scene.tilemap = nil
        self._scene._staticDirty = true
        self._scene = nil
    end
end
function tilemap:save(name)
    local payload = {
        tileW  = self.tileW,
        tileH  = self.tileH,
        defs   = {},
        layers = {},
    }
    for id, def in pairs(self._defs) do
        payload.defs[id] = {
            spritePath = def.spritePath,
            solid      = def.solid,
            type       = def.type,
            hL         = def.hL,
            hR         = def.hR,
        }
    end
    for _, layer in ipairs(self._layers) do
        table.insert(payload.layers, {
            name      = layer.name,
            z         = layer.z,
            collision = layer.collision,
            data      = layer.data,
        })
    end
    storage.save(name, payload)
end
function tilemap:load(name)
    local payload = storage.load(name)
    if not payload then return nil, "tilemap: no saved data for key '" .. name .. "'" end
    self.tileW = payload.tileW or self.tileW
    self.tileH = payload.tileH or self.tileH
    for id, def in pairs(payload.defs or {}) do
        self._defs[tonumber(id)] = def
    end
    self._layers   = {}
    self._layerMap = {}
    for _, saved in ipairs(payload.layers or {}) do
        local layer = {
            name      = saved.name,
            z         = saved.z,
            collision = saved.collision,
            data      = saved.data or {},
        }
        table.insert(self._layers, layer)
        self._layerMap[saved.name] = layer
    end
    table.sort(self._layers, function(a, b) return a.z < b.z end)
    return self
end
function tilemap:_markDirty()
    if self._scene then
        self:_buildSceneTilemap(self._scene)
        self._scene._staticDirty = true
    end
end
function tilemap:_buildSceneTilemap(scene)
    local spriteTable = {}
    local solidTiles = {}
    local tileProperties = {}
    for id, def in pairs(self._defs) do
        if def.spritePath then
            local spr = self._sprites[def.spritePath]
            if spr then
                spriteTable[id] = spr
            end
        end
        if def.solid then
            solidTiles[id] = true
        end
        if def.type then
            tileProperties[id] = {
                type = def.type,
                hL = def.hL or 0,
                hR = def.hR or 0,
            }
        end
    end
    local collisionData = {}
    for _, layer in ipairs(self._layers) do
        if layer.collision then
            collisionData = layer.data
            break
        end
    end
    scene.tilemap = {
        layers = self._layers,
        data = collisionData,
        sprite = spriteTable,
        solidTiles = solidTiles,
        tileProperties = tileProperties,
        tileW = self.tileW,
        tileH = self.tileH,
        _map = self,
    }
end
return TilemapModule
]=]
paths["core.tilemap"] = "core/tilemap"
sources["core.timer"] = [=[

local require = ...
local logger = require("core.logger")
local TimerModule = {
    _active = {}
}
local function createHandle()
    local handle = {}
    local methods = {
        cancel = function(self) return TimerModule.cancel(self) end,
        pause = function(self) return TimerModule.pause(self) end,
        resume = function(self) return TimerModule.resume(self) end,
        isActive = function(self) return TimerModule.isActive(self) end,
        getRemaining = function(self) return TimerModule.getRemaining(self) end,
        getFiredCount = function(self) return TimerModule.getFiredCount(self) end,
    }
    return setmetatable(handle, { __index = methods })
end
function TimerModule.after(delay, callback)
    if type(delay) ~= "number" or delay < 0 then
        logger.error("Timer: Invalid delay (must be non-negative number)")
        return createHandle()
    end
    if type(callback) ~= "function" then
        logger.error("Timer: Invalid callback (must be function)")
        return createHandle()
    end
    local handle = createHandle()
    table.insert(TimerModule._active, {
        handle = handle,
        elapsed = 0,
        interval = delay,
        callback = callback,
        repeating = false,
        maxTimes = 1,
        firedCount = 0,
        paused = false,
    })
    return handle
end
function TimerModule.every(interval, callback, maxTimes)
    if type(interval) ~= "number" or interval <= 0 then
        logger.error("Timer: Invalid interval (must be positive number)")
        return createHandle()
    end
    if type(callback) ~= "function" then
        logger.error("Timer: Invalid callback (must be function)")
        return createHandle()
    end
    local handle = createHandle()
    table.insert(TimerModule._active, {
        handle = handle,
        elapsed = 0,
        interval = interval,
        callback = callback,
        repeating = true,
        maxTimes = maxTimes or math.huge,
        firedCount = 0,
        paused = false,
    })
    return handle
end
function TimerModule.nextFrame(callback)
    return TimerModule.after(0, callback)
end
function TimerModule.cancel(handle)
    for i = #TimerModule._active, 1, -1 do
        if TimerModule._active[i].handle == handle then
            table.remove(TimerModule._active, i)
            return true
        end
    end
    return false
end
function TimerModule.pause(handle)
    for _, timer in ipairs(TimerModule._active) do
        if timer.handle == handle then
            timer.paused = true
            return true
        end
    end
    return false
end
function TimerModule.resume(handle)
    for _, timer in ipairs(TimerModule._active) do
        if timer.handle == handle then
            timer.paused = false
            return true
        end
    end
    return false
end
function TimerModule.pauseAll()
    for _, timer in ipairs(TimerModule._active) do timer.paused = true end
end
function TimerModule.resumeAll()
    for _, timer in ipairs(TimerModule._active) do timer.paused = false end
end
function TimerModule.cancelAll()
    TimerModule._active = {}
end
function TimerModule.isActive(handle)
    for _, timer in ipairs(TimerModule._active) do
        if timer.handle == handle then
            return true
        end
    end
    return false
end
function TimerModule.count()
    return #TimerModule._active
end
function TimerModule.getRemaining(handle)
    for _, timer in ipairs(TimerModule._active) do
        if timer.handle == handle then
            return math.max(0, timer.interval - timer.elapsed)
        end
    end
    return nil
end
function TimerModule.getFiredCount(handle)
    for _, timer in ipairs(TimerModule._active) do
        if timer.handle == handle then
            return timer.firedCount
        end
    end
    return nil
end
function TimerModule.update(dt)
    for i = #TimerModule._active, 1, -1 do
        local timer = TimerModule._active[i]
        timer.elapsed = timer.elapsed + dt
        if not timer.paused then
            if timer.elapsed >= timer.interval then
                timer.elapsed = timer.elapsed - timer.interval
                timer.firedCount = timer.firedCount + 1
                local ok, err = pcall(timer.callback)
                if not ok then
                    logger.error("Timer: Callback error - " .. tostring(err))
                    table.remove(TimerModule._active, i)
                elseif not timer.repeating or
                       (timer.maxTimes ~= math.huge and timer.firedCount >= timer.maxTimes) then
                    table.remove(TimerModule._active, i)
                end
            end
        end
    end
end
function TimerModule.getDebugInfo()
    local info = {}
    for _, timer in ipairs(TimerModule._active) do
        table.insert(info, {
            remaining = timer.interval - timer.elapsed,
            interval = timer.interval,
            repeating = timer.repeating,
            firedCount = timer.firedCount,
            maxTimes = timer.maxTimes,
        })
    end
    return info
end
return TimerModule
]=]
paths["core.timer"] = "core/timer"
sources["core.tween"] = [=[

local require = ...
local logger = require("core.logger")
local TweenModule = {
    _active = {},
    easing = {}
}
TweenModule.easing.linear = function(t) return t end
TweenModule.easing.quadIn = function(t)
    return t * t
end
TweenModule.easing.quadInOut = function(t)
    return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end
TweenModule.easing.sineIn = function(t)
    return 1 - math.cos((t * math.pi) / 2)
end
TweenModule.easing.sineOut = function(t)
    return math.sin((t * math.pi) / 2)
end
TweenModule.easing.sineInOut = function(t)
    return -(math.cos(math.pi * t) - 1) / 2
end
TweenModule.easing.cubicIn = function(t)
    return t * t * t
end
TweenModule.easing.cubicOut = function(t)
    local u = t - 1
    return u * u * u + 1
end
TweenModule.easing.cubicInOut = function(t)
    return t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2) ^ 3 / 2
end
TweenModule.easing.expoIn = function(t)
    return t == 0 and 0 or 2 ^ (10 * t - 10)
end
TweenModule.easing.expoOut = function(t)
    return t == 1 and 1 or 1 - 2 ^ (-10 * t)
end
TweenModule.easing.expoInOut = function(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return t < 0.5 and 2 ^ (20 * t - 10) / 2 or (2 - 2 ^ (-20 * t + 10)) / 2
end
TweenModule.easing.backIn = function(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return c3 * t * t * t - c1 * t * t
end
TweenModule.easing.backOut = function(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end
TweenModule.easing.backInOut = function(t)
    local c1 = 1.70158
    local c2 = c1 * 1.525
    return t < 0.5
        and (2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2) / 2
        or ((2 * t - 2) ^ 2 * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
end
TweenModule.easing.elasticIn = function(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return -(2 ^ (10 * t - 10)) * math.sin((t * 10 - 10.75) * c4)
end
TweenModule.easing.elasticOut = function(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end
TweenModule.easing.elasticInOut = function(t)
    local c5 = (2 * math.pi) / 4.5
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return t < 0.5
        and -(2 ^ (20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
        or (2 ^ (-20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1
end
TweenModule.easing.bounceOut = function(t)
    local n1, d1 = 7.5625, 2.75
    if t < 1 / d1 then
        return n1 * t * t
    elseif t < 2 / d1 then
        t = t - 1.5 / d1
        return n1 * t * t + 0.75
    elseif t < 2.5 / d1 then
        t = t - 2.25 / d1
        return n1 * t * t + 0.9375
    else
        t = t - 2.625 / d1
        return n1 * t * t + 0.984375
    end
end
TweenModule.easing.bounceIn = function(t)
    return 1 - TweenModule.easing.bounceOut(1 - t)
end
TweenModule.easing.bounceInOut = function(t)
    return t < 0.5
        and (1 - TweenModule.easing.bounceOut(1 - 2 * t)) / 2
        or (1 + TweenModule.easing.bounceOut(2 * t - 1)) / 2
end
local function findTweenByHandle(handle)
    for _, tween in ipairs(TweenModule._active) do
        if tween.handle == handle then
            return tween
        end
    end
    return nil
end
local handle_methods = {}
function handle_methods:pause()
    return TweenModule.pause(self)
end
function handle_methods:resume()
    return TweenModule.resume(self)
end
function handle_methods:cancel()
    return TweenModule.cancel(self)
end
function handle_methods:complete()
    return TweenModule.complete(self)
end
function handle_methods:isActive()
    return TweenModule.isActive(self)
end
function handle_methods:isPaused()
    return TweenModule.isPaused(self)
end
function handle_methods:getProgress()
    return TweenModule.getProgress(self)
end
function handle_methods:seek(progress)
    if type(progress) ~= "number" then return false end
    local tween = findTweenByHandle(self)
    if not tween then return false end
    progress = math.max(0, math.min(1, progress))
    tween.elapsed = tween.delay + progress * tween.duration
    local effectiveElapsed = math.max(0, tween.elapsed - tween.delay)
    local p = math.min(1, effectiveElapsed / tween.duration)
    local alpha = tween.easing(p)
    for key, endValue in pairs(tween.endValues) do
        if tween.startValues[key] then
            tween.target[key] = tween.startValues[key] + (endValue - tween.startValues[key]) * alpha
        end
    end
    return true
end
local function createHandle()
    local h = {}
    setmetatable(h, { __index = handle_methods })
    return h
end
function TweenModule.to(target, duration, properties, easingFunc, onComplete)
    if type(target) ~= "table" then
        logger.error("Tween: Target must be a table")
        return createHandle()
    end
    if type(properties) ~= "table" then
        logger.error("Tween: Properties must be a table")
        return createHandle()
    end
    local options = type(easingFunc) == "table" and easingFunc or {
        easing = easingFunc,
        onComplete = onComplete
    }
    local handle = createHandle()
    local startValues = {}
    for key, endValue in pairs(properties) do
        if type(target[key]) == "number" then
            startValues[key] = target[key]
        else
            logger.warn("Tween: Property '" .. tostring(key) .. "' is not a number, skipping")
        end
    end
    local tween = {
        handle = handle,
        target = target,
        duration = math.max(0.001, duration),
        elapsed = 0,
        startValues = startValues,
        endValues = properties,
        easing = options.easing or TweenModule.easing.linear,
        onComplete = options.onComplete,
        delay = options.delay or 0,
        loop = options.loop or false,
        pingpong = options.pingpong or false,
        paused = false,
        _isReversing = false,
    }
    table.insert(TweenModule._active, tween)
    return handle
end
function TweenModule.from(target, duration, fromProperties, options)
    options = options or {}
    local currentValues = {}
    for key, startValue in pairs(fromProperties) do
        currentValues[key] = target[key]
        target[key] = startValue
    end
    return TweenModule.to(target, duration, currentValues, options)
end
function TweenModule.pause(handle)
    for _, tween in ipairs(TweenModule._active) do
        if tween.handle == handle then
            tween.paused = true
            return true
        end
    end
    return false
end
function TweenModule.resume(handle)
    for _, tween in ipairs(TweenModule._active) do
        if tween.handle == handle then
            tween.paused = false
            return true
        end
    end
    return false
end
function TweenModule.cancel(handle)
    for i = #TweenModule._active, 1, -1 do
        if TweenModule._active[i].handle == handle then
            table.remove(TweenModule._active, i)
            return true
        end
    end
    return false
end
function TweenModule.stop(target)
    local removed = 0
    for i = #TweenModule._active, 1, -1 do
        if TweenModule._active[i].target == target then
            table.remove(TweenModule._active, i)
            removed = removed + 1
        end
    end
    return removed
end
function TweenModule.stopAll()
    TweenModule._active = {}
end
function TweenModule.complete(handle)
    for i = #TweenModule._active, 1, -1 do
        local tween = TweenModule._active[i]
        if tween.handle == handle then
            for key, endValue in pairs(tween.endValues) do
                tween.target[key] = endValue
            end
            local callback = tween.onComplete
            table.remove(TweenModule._active, i)
            if callback then
                callback()
            end
            return true
        end
    end
    return false
end
function TweenModule.seek(handle, progress)
    local tween = findTweenByHandle(handle)
    if not tween or type(progress) ~= "number" then return false end
    progress = math.max(0, math.min(1, progress))
    tween.elapsed = tween.delay + progress * tween.duration
    local effectiveElapsed = math.max(0, tween.elapsed - tween.delay)
    local p = math.min(1, effectiveElapsed / tween.duration)
    local alpha = tween.easing(p)
    for key, endValue in pairs(tween.endValues) do
        if tween.startValues[key] then
            tween.target[key] = tween.startValues[key] + (endValue - tween.startValues[key]) * alpha
        end
    end
    return true
end
function TweenModule.getTweensForTarget(target)
    local out = {}
    for _, tween in ipairs(TweenModule._active) do
        if tween.target == target then
            table.insert(out, tween.handle)
        end
    end
    return out
end
function TweenModule.count()
    return #TweenModule._active
end
function TweenModule.isActive(handle)
    for _, tween in ipairs(TweenModule._active) do
        if tween.handle == handle then
            return true
        end
    end
    return false
end
function TweenModule.isPaused(handle)
    for _, tween in ipairs(TweenModule._active) do
        if tween.handle == handle then
            return tween.paused
        end
    end
    return false
end
function TweenModule.getProgress(handle)
    for _, tween in ipairs(TweenModule._active) do
        if tween.handle == handle then
            local effectiveElapsed = math.max(0, tween.elapsed - tween.delay)
            return math.min(1, effectiveElapsed / tween.duration)
        end
    end
    return nil
end
function TweenModule.update(dt)
    for i = #TweenModule._active, 1, -1 do
        local tween = TweenModule._active[i]
        tween.elapsed = tween.elapsed + dt
        if not tween.paused then
            local effectiveElapsed = tween.elapsed - tween.delay
            if effectiveElapsed >= 0 then
                local progress = math.min(1, effectiveElapsed / tween.duration)
                local alpha = tween.easing(progress)
                for key, endValue in pairs(tween.endValues) do
                    if tween.startValues[key] then
                        tween.target[key] = tween.startValues[key] +
                                           (endValue - tween.startValues[key]) * alpha
                    end
                end
                if progress >= 1 then
                    if tween.pingpong then
                        for key, endValue in pairs(tween.endValues) do
                            local startValue = tween.startValues[key]
                            tween.startValues[key] = endValue
                            tween.endValues[key] = startValue
                        end
                        tween.elapsed = tween.delay
                        tween._isReversing = not tween._isReversing
                    elseif tween.loop then
                        tween.elapsed = tween.delay
                    else
                        local callback = tween.onComplete
                        table.remove(TweenModule._active, i)
                        if callback then
                            callback()
                        end
                    end
                end
            end
        end
    end
end
function TweenModule.getDebugInfo()
    local info = {}
    for _, tween in ipairs(TweenModule._active) do
        local effectiveElapsed = math.max(0, tween.elapsed - tween.delay)
        table.insert(info, {
            target = tostring(tween.target),
            progress = math.min(1, effectiveElapsed / tween.duration),
            duration = tween.duration,
            paused = tween.paused,
            loop = tween.loop,
            pingpong = tween.pingpong,
        })
    end
    return info
end
return TweenModule
]=]
paths["core.tween"] = "core/tween"
sources["core.ui.element"] = [=[

local M = {}
M.ELEMENT_FIELDS = {
    x=true, y=true, z=true, w=true, h=true,
    visible=true, sprite=true, disabled=true,
    fore=true, back=true, borderColor=true, anchor=true, interactive=true,
    borderTop=true, borderBottom=true, borderLeft=true, borderRight=true,
}
M.DIRTY_FIELDS = { z=true, sprite=true, w=true, h=true }
function M.wrapText(text, maxW)
    local lines = {}
    for para in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        if #para == 0 then
            table.insert(lines, "")
        elseif maxW <= 0 or #para <= maxW then
            table.insert(lines, para)
        else
            local words = {}
            for w in para:gmatch("%S+") do table.insert(words, w) end
            local cur = ""
            for _, word in ipairs(words) do
                if #cur == 0 then
                    cur = word
                elseif #cur + 1 + #word <= maxW then
                    cur = cur .. " " .. word
                else
                    table.insert(lines, cur)
                    cur = word
                end
            end
            if #cur > 0 then table.insert(lines, cur) end
        end
    end
    return lines
end
local function resolveBorders(cfg)
    local def = cfg.border ~= false
    return
        cfg.borderTop    ~= nil and cfg.borderTop    or def,
        cfg.borderBottom ~= nil and cfg.borderBottom or def,
        cfg.borderLeft   ~= nil and cfg.borderLeft   or def,
        cfg.borderRight  ~= nil and cfg.borderRight  or def
end
function M.make(name, type_, x, y, config)
    local cfg = config or {}
    local bTop, bBot, bLeft, bRight = resolveBorders(cfg)
    local el = {
        name        = name,
        type        = type_,
        x           = x,
        y           = y,
        w           = cfg.w or (cfg.text and #cfg.text or 0),
        h           = cfg.h or 1,
        z           = cfg.z or 0,
        config      = cfg,
        visible     = (cfg.visible ~= false) and (cfg.hidden ~= true),
        anchor      = cfg.anchor or "top-left",
        interactive = (type_ ~= "text" and type_ ~= "rect" and type_ ~= "sprite"
                        and type_ ~= "multiline")
                      or (cfg.interactive == true)
                      or (cfg.onClick ~= nil),
        sprite      = cfg.sprite,
        borderTop    = bTop,
        borderBottom = bBot,
        borderLeft   = bLeft,
        borderRight  = bRight,
        fore        = cfg.fore or "0",
        back        = cfg.back or "7",
        borderColor = cfg.borderColor or "8",
        disabled    = cfg.disabled == true,
    }
    if cfg.sprite then
        el.w = cfg.sprite.width
        el.h = cfg.sprite.height
    end
    if type_ == "multiline" and not cfg.h then
        el.h = #M.wrapText(cfg.text or "", el.w)
    end
    return el
end
function M.makeContainer(name, x, y, w, h, config)
    local cfg = config or {}
    local bTop, bBot, bLeft, bRight = resolveBorders(cfg)
    return {
        name    = name,
        type    = "container",
        x       = x,
        y       = y,
        w       = w,
        h       = h,
        z           = cfg.z or 0,
        config      = cfg,
        visible     = (cfg.visible ~= false) and (cfg.hidden ~= true),
        anchor      = cfg.anchor or "top-left",
        interactive = true,
        fore        = cfg.fore or "0",
        back        = cfg.back or "7",
        borderColor = cfg.borderColor or "8",
        borderTop    = bTop,
        borderBottom = bBot,
        borderLeft   = bLeft,
        borderRight  = bRight,
        disabled       = cfg.disabled == true,
        children       = {},
        sortedChildren = {},
        childrenDirty  = true,
        scrollOffset   = 0,
    }
end
return M
]=]
paths["core.ui.element"] = "core/ui/element"
sources["core.ui.events"] = [=[

local events = {}
local function sliderValue(el, mx, ex)
    local relX = math.max(0, math.min(el.w - 1, mx - ex))
    local sMin = el.config.min  or 0
    local sMax = el.config.max  or 100
    local step = el.config.step or 1
    local raw  = sMin + (relX / math.max(1, el.w - 1)) * (sMax - sMin)
    local val  = math.floor(raw / step + 0.5) * step
    return math.max(sMin, math.min(sMax, val))
end
local function hitTest(ctx, mx, my, ox, oy)
    for i = #ctx.sorted, 1, -1 do
        local el = ctx.sorted[i]
        if not el.visible then goto next end
        local ex, ey = ctx:getAbsolutePos(el, ox, oy)
        if el.type == "container" then
            if mx >= ex and mx < ex + el.w and my >= ey and my < ey + el.h then
                if el.childrenDirty then
                    el.sortedChildren = {}
                    for _, c in pairs(el.children) do table.insert(el.sortedChildren, c) end
                    table.sort(el.sortedChildren, function(a, b) return a.z < b.z end)
                    el.childrenDirty = false
                end
                local contentX = ex + (el.borderLeft and 1 or 0)
                local contentY = ey + (el.borderTop  and 1 or 0)
                local contentH = el.h - (el.borderTop  and 1 or 0) - (el.borderBottom and 1 or 0)
                local scrollY  = el.scrollOffset or 0
                for j = #el.sortedChildren, 1, -1 do
                    local child = el.sortedChildren[j]
                    if child.visible then
                        local crx = contentX + child.x
                        local cry = contentY + child.y - scrollY
                        if cry + child.h > contentY and cry < contentY + contentH then
                            local childH = (child.type == "dropdown" and child.isOpen
                                            and child.config.options)
                                           and (child.h + #child.config.options) or child.h
                            if mx >= crx and mx < crx + child.w
                            and my >= cry and my < cry + childH then
                                return child, crx, cry
                            end
                        end
                    end
                end
                if el.config.onClick then
                    return el, ex, ey
                end
                return nil, 0, 0
            end
        else
            local elH = (el.type == "dropdown" and el.isOpen and el.config.options)
                        and (el.h + #el.config.options) or el.h
            if mx >= ex and mx < ex + el.w and my >= ey and my < ey + elH then
                return el, ex, ey
            end
        end
        ::next::
    end
    return nil, 0, 0
end
function events.handle(ctx, buf, event, ox, oy)
    local eventType = event[1]
    if eventType == "mouse_click" or eventType == "mouse_drag" then
        local mx, my = event[3], event[4]
        if ctx.dirty then ctx:_sort() end
        local hit, hitAbsX, hitAbsY = hitTest(ctx, mx, my, ox, oy)
        if eventType == "mouse_click" then
            ctx.focusedElement = (hit and hit.type == "input") and hit or nil
            for _, el in pairs(ctx.elements) do
                if el.type == "dropdown" and el ~= hit then el.isOpen = false end
                if el.type == "container" then
                    for _, child in pairs(el.children) do
                        if child.type == "dropdown" and child ~= hit then child.isOpen = false end
                    end
                end
            end
            if hit and hit.interactive and not hit.disabled then
                if hit.type == "checkbox" then
                    hit.config.checked = not hit.config.checked
                    if hit.config.onChanged then hit.config.onChanged(hit.config.checked) end
                    return true
                end
                if hit.type == "dropdown" then
                    if hit.isOpen then
                        local relY = my - hitAbsY - hit.h
                        if relY >= 0 and hit.config.options and relY < #hit.config.options then
                            hit.config.selectedIndex = relY + 1
                            if hit.config.onChanged then
                                hit.config.onChanged(hit.config.selectedIndex,
                                                     hit.config.options[hit.config.selectedIndex])
                            end
                        end
                        hit.isOpen = false
                    else
                        hit.isOpen = true
                    end
                    return true
                end
                if hit.type == "list" then
                    local relY    = my - hitAbsY
                    local itemIdx = (hit.config.scrollOffset or 0) + relY + 1
                    if hit.config.options and itemIdx >= 1 and itemIdx <= #hit.config.options then
                        hit.config.selectedIndex = itemIdx
                        if hit.config.onChanged then
                            hit.config.onChanged(itemIdx, hit.config.options[itemIdx])
                        end
                    end
                    return true
                end
                if hit.type == "slider" then
                    local val = sliderValue(hit, mx, hitAbsX)
                    hit.config.value = val
                    if hit.config.onChanged then hit.config.onChanged(val) end
                end
                ctx.pressedElement = hit
                ctx.pressedAbsX    = hitAbsX
                ctx.pressedAbsY    = hitAbsY
                return true
            end
        elseif eventType == "mouse_drag" then
            if ctx.pressedElement and ctx.pressedElement.type == "slider" then
                local el  = ctx.pressedElement
                local val = sliderValue(el, mx, ctx.pressedAbsX or 0)
                el.config.value = val
                if el.config.onChanged then el.config.onChanged(val) end
                return true
            end
        end
    elseif eventType == "mouse_up" then
        if ctx.pressedElement then
            local el     = ctx.pressedElement
            local ex, ey = ctx.pressedAbsX or 0, ctx.pressedAbsY or 0
            local mx, my = event[3], event[4]
            if el.type == "slider" then
                local val = sliderValue(el, mx, ex)
                el.config.value = val
                if el.config.onChanged then el.config.onChanged(val) end
            elseif mx >= ex and mx < ex + el.w and my >= ey and my < ey + el.h then
                if el.config.onClick then
                    el.config.onClick(event[2])
                end
            end
            ctx.pressedElement = nil
            ctx.pressedAbsX    = nil
            ctx.pressedAbsY    = nil
            return true
        end
    elseif eventType == "char" then
        if ctx.focusedElement and ctx.focusedElement.type == "input" then
            local el = ctx.focusedElement
            el.config.text = (el.config.text or "") .. event[2]
            if el.config.onChange then el.config.onChange(el.config.text) end
            return true
        end
    elseif eventType == "key" then
        if ctx.focusedElement and ctx.focusedElement.type == "input" then
            local el  = ctx.focusedElement
            local key = event[2]
            if key == keys.backspace then
                el.config.text = (el.config.text or ""):sub(1, -2)
                if el.config.onChange then el.config.onChange(el.config.text) end
            elseif key == keys.enter then
                ctx.focusedElement = nil
                if el.config.onConfirm then el.config.onConfirm(el.config.text) end
            end
            return true
        end
    elseif eventType == "mouse_scroll" then
        local dir, mx, my = event[2], event[3], event[4]
        if ctx.dirty then ctx:_sort() end
        for i = #ctx.sorted, 1, -1 do
            local el = ctx.sorted[i]
            if el.visible and not el.disabled then
                local ex, ey = ctx:getAbsolutePos(el, ox, oy)
                if mx >= ex and mx < ex + el.w and my >= ey and my < ey + el.h then
                    if el.type == "list" then
                        local maxScroll = math.max(0, #(el.config.options or {}) - el.h)
                        el.config.scrollOffset = math.max(0,
                            math.min(maxScroll, (el.config.scrollOffset or 0) + dir))
                        return true
                    elseif el.type == "slider" then
                        local sMin = el.config.min  or 0
                        local sMax = el.config.max  or 100
                        local step = el.config.step or 1
                        local val  = math.max(sMin, math.min(sMax,
                                         (el.config.value or sMin) - dir * step))
                        el.config.value = val
                        if el.config.onChanged then el.config.onChanged(val) end
                        return true
                    elseif el.type == "container" and el.config.scrollable ~= false then
                        local contentH = el.h
                            - (el.borderTop    and 1 or 0)
                            - (el.borderBottom and 1 or 0)
                        local maxChildBottom = 0
                        for _, child in pairs(el.children) do
                            local b = child.y + child.h
                            if b > maxChildBottom then maxChildBottom = b end
                        end
                        local maxScroll = math.max(0, maxChildBottom - contentH)
                        el.scrollOffset = math.max(0, math.min(maxScroll, el.scrollOffset + dir))
                        return true
                    end
                end
            end
        end
    end
    return false
end
return events
]=]
paths["core.ui.events"] = "core/ui/events"
sources["core.ui"] = [=[

local require = ...
local element = require("core.ui.element")
local render  = require("core.ui.render")
local events  = require("core.ui.events")
local UI = {}
function UI.new(buf)
    assert(buf, "UI.new: a Buffer instance is required")
    local ctx = {
        buf            = buf,
        elements       = {},
        sorted         = {},
        dirty          = true,
        pressedElement = nil,
        pressedAbsX    = nil,
        pressedAbsY    = nil,
        focusedElement = nil,
    }
    function ctx:_sort()
        self.sorted = {}
        for _, el in pairs(self.elements) do table.insert(self.sorted, el) end
        table.sort(self.sorted, function(a, b) return a.z < b.z end)
        self.dirty = false
    end
    function ctx:_insert(el)
        self.elements[el.name] = el
        self.dirty = true
        return el
    end
    function ctx:add(name, type_, x, y, config)
        return self:_insert(element.make(name, type_, x, y, config))
    end
    function ctx:button(name, x, y, config)   return self:add(name, "button",   x, y, config) end
    function ctx:text(name, x, y, config)     return self:add(name, "text",     x, y, config) end
    function ctx:input(name, x, y, config)    return self:add(name, "input",    x, y, config) end
    function ctx:checkbox(name, x, y, config) return self:add(name, "checkbox", x, y, config) end
    function ctx:dropdown(name, x, y, config) return self:add(name, "dropdown", x, y, config) end
    function ctx:progress(name, x, y, config) return self:add(name, "progress", x, y, config) end
    function ctx:slider(name, x, y, config)    return self:add(name, "slider",    x, y, config) end
    function ctx:list(name, x, y, config)      return self:add(name, "list",      x, y, config) end
    function ctx:rect(name, x, y, config)      return self:add(name, "rect",      x, y, config) end
    function ctx:sprite(name, x, y, config)    return self:add(name, "sprite",    x, y, config) end
    function ctx:multiline(name, x, y, config) return self:add(name, "multiline", x, y, config) end
    function ctx:label(name, x, y, config)     return self:multiline(name, x, y, config) end
    function ctx:container(name, x, y, w, h, config)
        return self:_insert(element.makeContainer(name, x, y, w, h, config))
    end
    function ctx:remove(name)
        if self.elements[name] then
            self.elements[name] = nil
            self.dirty = true
        end
    end
    function ctx:addToContainer(containerName, childName, childType, x, y, config)
        local con = self.elements[containerName]
        if not con or con.type ~= "container" then return nil end
        local child = element.make(childName, childType, x, y, config or {})
        con.children[childName] = child
        con.childrenDirty = true
        return child
    end
    function ctx:removeFromContainer(containerName, childName)
        local con = self.elements[containerName]
        if con and con.type == "container" then
            con.children[childName] = nil
            con.childrenDirty = true
        end
    end
    function ctx:update(name, config)
        local el = self.elements[name]
        if not el then return end
        for k, v in pairs(config) do
            if element.ELEMENT_FIELDS[k] then
                el[k] = v
                if element.DIRTY_FIELDS[k] then self.dirty = true end
            else
                el.config[k] = v
            end
        end
        if el.type == "text" and config.text then el.w = #config.text end
    end
    function ctx:updateInContainer(containerName, childName, config)
        local con = self.elements[containerName]
        if not con or con.type ~= "container" then return end
        local child = con.children[childName]
        if not child then return end
        for k, v in pairs(config) do
            if element.ELEMENT_FIELDS[k] then
                child[k] = v
                if element.DIRTY_FIELDS[k] then con.childrenDirty = true end
            else
                child.config[k] = v
            end
        end
        if child.type == "text" and config.text then child.w = #config.text end
    end
    function ctx:get(name)
        local el = self.elements[name]
        if not el then return nil end
        local t = el.type
        if t == "input" or t == "button" or t == "text" then
            return el.config.text
        elseif t == "checkbox" then
            return el.config.checked
        elseif t == "dropdown" or t == "list" then
            local idx = el.config.selectedIndex
            return idx, idx and el.config.options and el.config.options[idx]
        elseif t == "progress" then
            return el.config.progress
        elseif t == "slider" then
            return el.config.value or el.config.min or 0
        end
        return nil
    end
    function ctx:getAbsolutePos(el, ox, oy)
        local tw, th = self.buf:getSize()
        local rx, ry = el.x + ox, el.y + oy
        local cx = ox + math.floor((tw - ox * 2) / 2) - math.floor(el.w / 2) + el.x
        local cy = oy + math.floor((th - oy * 2) / 2) - math.floor(el.h / 2) + el.y
        local bx = (tw - ox) - el.w - el.x
        local by = (th - oy) - el.h - el.y
        local a  = el.anchor
        if     a == "top-center"    then rx = cx
        elseif a == "top-right"     then rx = bx
        elseif a == "center-left"   then ry = cy
        elseif a == "center"        then rx = cx ; ry = cy
        elseif a == "center-right"  then rx = bx ; ry = cy
        elseif a == "bottom-left"   then ry = by
        elseif a == "bottom-center" then rx = cx ; ry = by
        elseif a == "bottom-right"  then rx = bx ; ry = by
        end
        return rx, ry
    end
    function ctx:handleEvent(event, ox, oy)
        return events.handle(self, self.buf, event, ox or 0, oy or 0)
    end
    function ctx:draw(ox, oy, rowsToRestore)
        ox = ox or 0
        oy = oy or 0
        rowsToRestore = rowsToRestore or {}
        if self.dirty then self:_sort() end
        for _, el in ipairs(self.sorted) do
            if el.visible then
                local rx, ry = self:getAbsolutePos(el, ox, oy)
                if el.type == "container" then
                    render.drawContainer(self.buf, el, rx, ry, self, rowsToRestore)
                else
                    render.drawEl(self.buf, el, rx, ry,
                                  self.pressedElement, self.focusedElement, rowsToRestore)
                end
            end
        end
        return rowsToRestore
    end
    return ctx
end
UI.createContext = UI.new
return UI
]=]
paths["core.ui"] = "core/ui/init"
sources["core.ui.render"] = [=[

local require = ...
local render = {}
local function drawScrollbar(buf, x, topY, trackH, scrollOffset, totalRows, trackColor, thumbColor)
    if totalRows <= trackH then return end
    local thumbSize = math.max(1, math.floor(trackH * trackH / totalRows))
    local maxScroll = totalRows - trackH
    local thumbPos  = math.floor((scrollOffset / maxScroll) * (trackH - thumbSize))
    for i = 0, trackH - 1 do
        local isThumb = (i >= thumbPos and i < thumbPos + thumbSize)
        buf:drawText(x, topY + i, " ", "0", isThumb and thumbColor or trackColor)
    end
end
local function drawBorder(buf, el, rx, ry, bc, bg)
    if el.borderTop    then buf:drawText(rx, ry,            ("\131"):rep(el.w), bc, bg) end
    if el.borderBottom then buf:drawText(rx, ry + el.h - 1, ("\143"):rep(el.w), bg, bc) end
    if el.borderLeft   then
        for i = 0, el.h - 1 do buf:drawText(rx,           ry + i, "\149", bc, bg) end
    end
    if el.borderRight  then
        for i = 0, el.h - 1 do buf:drawText(rx + el.w - 1, ry + i, "\149", bg, bc) end
    end
    if el.borderTop    and el.borderLeft  then buf:drawText(rx,           ry,           "\151", bc, bg) end
    if el.borderTop    and el.borderRight then buf:drawText(rx + el.w - 1, ry,           "\148", bg, bc) end
    if el.borderBottom and el.borderLeft  then buf:drawText(rx,           ry + el.h - 1, "\138", bg, bc) end
    if el.borderBottom and el.borderRight then buf:drawText(rx + el.w - 1, ry + el.h - 1, "\133", bg, bc) end
end
function render.drawEl(buf, el, rx, ry, pressedEl, focusedEl, rowsToRestore)
    if el.sprite then
        local frame = el.sprite[el.config.frame or 1]
        if frame then
            buf:drawSprite(frame, rx, ry, 0, 0)
            for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
        end
        return
    end
    if el.type == "text" then
        buf:drawText(rx, ry, el.config.text or "", el.disabled and "8" or el.fore, el.back)
        rowsToRestore[ry] = true
        return
    end
    if el.type == "multiline" then
        local element = require("core.ui.element")
        local lines   = element.wrapText(el.config.text or "", el.w)
        local align   = el.config.align or "left"
        local fg      = el.disabled and "8" or el.fore
        buf:drawRect(rx, ry, el.w, el.h, " ", fg, el.back)
        for i, line in ipairs(lines) do
            local row = ry + i - 1
            if row >= ry + el.h then break end
            local tx = rx
            if align == "center" then
                tx = rx + math.floor((el.w - #line) / 2)
            elseif align == "right" then
                tx = rx + el.w - #line
            end
            if #line > 0 then buf:drawText(tx, row, line, fg, el.back) end
        end
        for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
        return
    end
    if el.type == "rect"   or el.type == "button" or el.type == "input"
    or el.type == "checkbox" or el.type == "dropdown" or el.type == "progress" then
        local isPressed = (pressedEl == el)
        local isFocused = (focusedEl == el)
        local bg = el.disabled and "8" or (isPressed and el.borderColor or el.back)
        local fg = el.disabled and "7" or (isPressed and el.back or el.fore)
        local bc = (isPressed or isFocused) and el.fore or el.borderColor
        buf:drawRect(rx, ry, el.w, el.h, el.config.char or " ", fg, bg)
        if el.type == "progress" then
            local progress = math.max(0, math.min(1, el.config.progress or 0))
            local fillCol  = el.config.fillColor or "d"
            local fillW    = math.floor(el.w * progress)
            local frac     = el.w * progress - fillW
            if fillW > 0 then
                buf:drawRect(rx, ry, fillW, el.h, el.config.fillChar or " ", fillCol, fillCol)
            end
            if frac >= 0.5 and fillW < el.w then
                for row = 0, el.h - 1 do
                    buf:drawText(rx + fillW, ry + row, "\149", fillCol, el.back)
                end
            end
        end
        drawBorder(buf, el, rx, ry, bc, bg)
        if el.type == "checkbox" then
            local mark = el.config.checked and "\7" or " "
            buf:drawText(rx + math.floor(el.w / 2), ry + math.floor(el.h / 2), mark, fg, bg)
        end
        if (el.type == "button" or el.type == "input") and el.config.text ~= nil then
            local text = el.config.text
            local ty   = ry + math.floor(el.h / 2)
            local tx
            if el.type == "input" then
                tx = rx + 1
                local cursor = isFocused and (math.floor(os.clock() * 2) % 2 == 0)
                if el.config.password then
                    text = string.rep("*", #text)
                end
                if cursor then text = text .. "_" end
                local maxW = math.max(1, el.w - 2)
                if #text > maxW then text = text:sub(#text - maxW + 1) end
            else
                tx = rx + math.floor((el.w - #text) / 2)
            end
            buf:drawText(tx, ty, text, fg, bg)
        end
        if el.type == "dropdown" then
            local selected    = el.config.selectedIndex
            local displayText = tostring(
                (selected and el.config.options and el.config.options[selected])
                or el.config.text or "")
            local maxW = math.max(1, el.w - 2)
            if #displayText > maxW then displayText = displayText:sub(1, maxW) end
            buf:drawText(rx + 1, ry + math.floor(el.h / 2), displayText, fg, bg)
            buf:drawText(rx + el.w - 1, ry + math.floor(el.h / 2),
                         el.isOpen and "\30" or "\31", fg, bg)
            if el.isOpen and el.config.options then
                for i, opt in ipairs(el.config.options) do
                    local optY  = ry + el.h - 1 + i
                    local optBg = (i == selected) and el.fore or el.back
                    local optFg = (i == selected) and el.back or el.fore
                    buf:drawRect(rx, optY, el.w, 1, " ", optFg, optBg)
                    local optText = tostring(opt)
                    if #optText > el.w - 1 then optText = optText:sub(1, el.w - 1) end
                    buf:drawText(rx + 1, optY, optText, optFg, optBg)
                    rowsToRestore[optY] = true
                end
            end
        end
        for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
        return
    end
    if el.type == "list" then
        local options       = el.config.options or {}
        local scrollOffset  = el.config.scrollOffset or 0
        local selectedIndex = el.config.selectedIndex
        local selFore    = el.config.selectedFore or el.back
        local selBack    = el.config.selectedBack or el.fore
        local needsBar   = #options > el.h
        local itemW      = needsBar and (el.w - 1) or el.w
        local trackColor = el.config.scrollTrack or "8"
        local thumbColor = el.config.scrollThumb or el.fore
        buf:drawRect(rx, ry, el.w, el.h, " ", el.fore, el.back)
        for row = 0, el.h - 1 do
            local itemIdx = scrollOffset + row + 1
            local opt = options[itemIdx]
            if opt then
                local isSelected = (itemIdx == selectedIndex)
                local fg = isSelected and selFore or el.fore
                local bg = isSelected and selBack or el.back
                local text = tostring(opt)
                if #text > itemW then text = text:sub(1, itemW) end
                buf:drawRect(rx, ry + row, itemW, 1, " ", fg, bg)
                buf:drawText(rx, ry + row, text, fg, bg)
            end
        end
        if needsBar then
            drawScrollbar(buf, rx + el.w - 1, ry, el.h, scrollOffset, #options, trackColor, thumbColor)
        end
        for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
        return
    end
    if el.type == "slider" then
        local sMin      = el.config.min or 0
        local sMax      = el.config.max or 100
        local value     = el.config.value or sMin
        local t         = (sMax > sMin) and math.max(0, math.min(1, (value - sMin) / (sMax - sMin))) or 0
        local thumbPos  = math.floor(t * (el.w - 1))
        local fillColor = el.disabled and "8" or (el.config.fillColor or "d")
        local trackBg   = el.disabled and "7" or el.back
        local thumbFore = el.config.thumbFore or el.back
        local thumbBack = el.config.thumbBack or (el.disabled and "8" or el.fore)
        local thumbChar = el.config.thumbChar or "\149"
        buf:drawRect(rx, ry, el.w, el.h, " ", el.fore, trackBg)
        if thumbPos > 0 then
            buf:drawRect(rx, ry, thumbPos, el.h, " ", fillColor, fillColor)
        end
        buf:drawText(rx + thumbPos, ry, thumbChar, thumbFore, thumbBack)
        if el.config.showValue then
            local label = tostring(math.floor(value))
            local lx = rx + math.floor((el.w - #label) / 2)
            if lx + #label - 1 ~= rx + thumbPos then
                buf:drawText(lx, ry, label, el.fore, trackBg)
            end
        end
        for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
    end
end
function render.drawContainer(buf, el, rx, ry, ctx, rowsToRestore)
    buf:drawRect(rx, ry, el.w, el.h, " ", el.fore, el.back)
    drawBorder(buf, el, rx, ry, el.borderColor, el.back)
    if el.config.title and el.borderTop then
        local t  = " " .. el.config.title .. " "
        local tx = rx + math.floor((el.w - #t) / 2)
        buf:drawText(tx, ry, t, el.borderColor, el.back)
    end
    for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
    if el.childrenDirty then
        el.sortedChildren = {}
        for _, child in pairs(el.children) do
            table.insert(el.sortedChildren, child)
        end
        table.sort(el.sortedChildren, function(a, b) return a.z < b.z end)
        el.childrenDirty = false
    end
    local contentX = rx + (el.borderLeft and 1 or 0)
    local contentY = ry + (el.borderTop  and 1 or 0)
    local contentH = el.h - (el.borderTop  and 1 or 0) - (el.borderBottom and 1 or 0)
    local contentW = el.w - (el.borderLeft and 1 or 0) - (el.borderRight  and 1 or 0)
    local scrollY  = el.scrollOffset or 0
    local maxChildBottom = 0
    for _, child in pairs(el.children) do
        local b = child.y + child.h
        if b > maxChildBottom then maxChildBottom = b end
    end
    local needsBar   = maxChildBottom > contentH
    local trackColor = el.config.scrollTrack or "8"
    local thumbColor = el.config.scrollThumb or el.fore
    for _, child in ipairs(el.sortedChildren) do
        if child.visible then
            local childRY = contentY + child.y - scrollY
            if childRY + child.h > contentY and childRY < contentY + contentH then
                buf:setClip(contentX, contentY, contentX + contentW - 1, contentY + contentH - 1)
                render.drawEl(buf, child, contentX + child.x, childRY,
                              ctx.pressedElement, ctx.focusedElement, rowsToRestore)
                buf:clearClip()
            end
        end
    end
    if needsBar then
        drawScrollbar(buf, contentX + contentW - 1, contentY, contentH,
                      scrollY, maxChildBottom, trackColor, thumbColor)
    end
end
return render
]=]
paths["core.ui.render"] = "core/ui/render"
local loaded = {}
local loading = {}
local function loader(name)
    local cached = loaded[name]
    if cached ~= nil then return cached end
    if loading[name] then
        error("Obsidian: circular require of " .. tostring(name), 0)
    end
    local source = sources[name]
        or error("Obsidian: module not bundled: " .. tostring(name), 0)
    local chunk = assert(load(source,
        "@obsidian/" .. (paths[name] or name) .. ".lua"))
    loading[name] = true
    local result = chunk(loader, name)
    loading[name] = nil
    loaded[name] = result == nil and true or result
    return loaded[name]
end

return loader("engine")