local storage = {}
local SAVE_DIR = "saves/"

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
    if not fs.exists(path) then return nil end

    local file = fs.open(path, "r")
    if not file then return nil, "Could not open file for reading: " .. path end
    local raw = file.readAll()
    file.close()
    local ok, data = pcall(textutils.unserialize, raw)
    if not ok then return nil, "Failed to deserialize save data: " .. tostring(data) end
    return data
end

function storage.delete(name)
    local path = fs.combine(SAVE_DIR, name .. ".dat")
    if fs.exists(path) then
        fs.delete(path)
        return true
    end
    return false
end

return storage