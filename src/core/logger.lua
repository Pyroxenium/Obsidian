local logger = {
    history = {},
    maxHistory = 8,
    logFile = "obsidian.log",
    _fileInitialized = false
}

local colors = {
    INFO = "0",
    WARN = "1",
    ERROR = "e"
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
end

function logger.info(msg) logger._add("INFO", msg) end
function logger.warn(msg) logger._add("WARN", msg) end
function logger.error(msg) logger._add("ERROR", msg) end
function logger.getHistory() return logger.history end

return logger