local logger = require("core.logger")

local loader = {
    basePath = nil,
    spriteCache = {},
    uiCache = {},
    emitterCache = {}
}

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
                        if type(row[c]) ~= "string" or #row[c] ~= 1 then
                            local content = tostring(row[c])
                            return false, string.format("Frame %d, layer %d, row %d, column %d: '%s' is not a single character.", f, layer, r, c, content)
                        end
                    end
                end
            end
        end
    end
    return true
end

function loader.load(path)
    local fullPath = resolvePath(path)
    if loader.spriteCache[fullPath] then
        return loader.spriteCache[fullPath]
    end

    if not fs.exists(fullPath) then
        local err = "File not found: " .. fullPath
        logger.error("Loader: " .. err)
        return nil, err
    end

    local file = fs.open(fullPath, "r")
    if not file then
        local err = "Could not open file: " .. fullPath
        logger.error("Loader: " .. err)
        return nil, err
    end
    local ok, data = pcall(textutils.unserialize, file.readAll())
    file.close()

    if not ok or not data then
        local err = "Failed to unserialize OSF: " .. path
        logger.error("Loader: " .. err)
        return nil, err
    end

    local valid, verr = loader._validateSprite(path, data)
    if not valid then
        logger.error("Loader: Validation error in " .. path .. ": " .. verr)
        return nil, verr
    end

    loader._processSprite(data)

    data.path = path
    loader.spriteCache[fullPath] = data

    logger.info("Loader: Cached sprite: " .. fullPath)
    return data
end

function loader.loadUI(path)
    local fullPath = resolvePath(path)
    if loader.uiCache[fullPath] then
        return loader.uiCache[fullPath]
    end

    if not fs.exists(fullPath) then
        local err = "File not found: " .. fullPath
        logger.error("Loader: " .. err)
        return nil, err
    end

    local file = fs.open(fullPath, "r")
    if not file then
        local err = "Could not open file: " .. fullPath
        logger.error("Loader: " .. err)
        return nil, err
    end
    local ok, data = pcall(textutils.unserialize, file.readAll())
    file.close()

    if not ok or not data then
        local err = "Failed to parse UI file: " .. tostring(data)
        logger.error("Loader: " .. err)
        return nil, err
    end

    loader.uiCache[fullPath] = data
    return data
end

function loader.loadEmitter(path)
    local fullPath = resolvePath(path)
    if loader.emitterCache[fullPath] then
        return loader.emitterCache[fullPath]
    end

    if not fs.exists(fullPath) then
        local err = "File not found: " .. fullPath
        logger.error("Loader: " .. err)
        return nil, err
    end

    local file = fs.open(fullPath, "r")
    if not file then
        local err = "Could not open file: " .. fullPath
        logger.error("Loader: " .. err)
        return nil, err
    end
    local ok, data = pcall(textutils.unserialize, file.readAll())
    file.close()

    if not ok or not data then
        local err = "Failed to unserialize emitter: " .. path
        logger.error("Loader: " .. err)
        return nil, err
    end

    if data.sprite then loader._processSprite(data.sprite) end

    loader.emitterCache[fullPath] = data
    return data
end

function loader.unload(path)
    local fullPath = resolvePath(path)
    loader.spriteCache[fullPath]  = nil
    loader.uiCache[fullPath]      = nil
    loader.emitterCache[fullPath] = nil
    logger.info("Loader: Unloaded asset: " .. tostring(fullPath))
end

function loader.clearCache()
    loader.spriteCache = {}
    loader.uiCache = {}
    loader.emitterCache = {}
    logger.info("Loader: Asset cache cleared.")
end

return loader