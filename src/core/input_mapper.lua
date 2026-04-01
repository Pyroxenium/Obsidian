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