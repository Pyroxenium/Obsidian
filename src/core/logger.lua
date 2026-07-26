--- Obsidian Logger Module
--- Provides logging functionality with different levels (info, warn, error, debug).

---@diagnostic disable: undefined-global

--- This is the main logger module for Obsidian. It buffers log entries in memory and also writes them to a log file. The logger supports different log levels (info, warn, error, debug) and can be extended with a console hook to forward log lines to an in-game console overlay.
---@alias LogLevel "debug"|"info"|"warn"|"error"|"off"

---@class LoggerModule
---@field history table<number, { level:string, text:string, color:string }> Buffered log history entries
---@field maxHistory number Maximum number of log entries to keep in history
---@field logFile string Path to the log file
---@field level LogLevel Lowest level that is recorded; "off" silences the logger
---@field fileEnabled boolean Whether entries are also written to `logFile`
---@field _fileInitialized boolean Internal flag to track if the log file has been initialized
---@field _consoleHook any|nil Optional hook function to forward log lines to the console
local logger = {
    history = {},
    maxHistory = 8,
    logFile = "obsidian.log",
    level = "info",
    fileEnabled = true,
    _fileInitialized = false,
    --- Optional hook: set by engine to forward log lines to the console.
    --- Signature: function(text, colorChar)
    _consoleHook = nil,
}

local colors = {
    INFO = "0",
    WARN = "1",
    ERROR = "e",
    DEBUG = "7"
}

-- Ordered so that a configured level admits everything at or above it.
local severity = {
    debug = 1, DEBUG = 1,
    info  = 2, INFO  = 2,
    warn  = 3, WARN  = 3,
    error = 4, ERROR = 4,
    off   = 5,
}

--- Set the lowest level that is recorded.
---@param level LogLevel "debug", "info", "warn", "error", or "off"
function logger.setLevel(level)
    if severity[level] == nil then
        error("Obsidian logger: unknown level " .. tostring(level), 2)
    end
    logger.level = level
end

--- Enable or disable writing entries to the log file. History and the console
--- hook are unaffected.
---@param enabled boolean
function logger.setFileEnabled(enabled)
    logger.fileEnabled = enabled ~= false
end

--- Add a log entry to history and, unless disabled, the log file.
--- Entries below the configured level are dropped before any work is done.
---@param level string
---@param msg any
function logger._add(level, msg)
    local threshold = severity[logger.level] or severity.info
    if (severity[level] or severity.info) < threshold then return end

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

    -- Reopened per entry on purpose: a crash must not lose the lines written
    -- just before it, which is exactly when the log matters most.
    if logger.fileEnabled then
        local mode = logger._fileInitialized and "a" or "w"
        local f = fs.open(logger.logFile, mode)
        if f then
            logger._fileInitialized = true
            f.writeLine(logLine)
            f.close()
        end
    end

    if logger._consoleHook then
        logger._consoleHook(logLine, colors[level] or "0")
    end
end

--- Log an info-level message.
---@param msg any
function logger.info(msg) logger._add("INFO", msg) end

--- Log a warn-level message.
---@param msg any
function logger.warn(msg) logger._add("WARN", msg) end

--- Log an error-level message.
---@param msg any
function logger.error(msg) logger._add("ERROR", msg) end

--- Log a debug-level message.
---@param msg any
function logger.debug(msg) logger._add("DEBUG", msg) end

--- Return the buffered log history.
---@return table
function logger.getHistory() return logger.history end

return logger