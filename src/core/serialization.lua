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

    for _, item in ipairs(scene.staticElements) do
        table.insert(data.statics, {
            spritePath = item.spritePath,
            x = item.x,
            y = item.y,
            z = item.z,
            collider = item.collider,
            layer = item.layer
        })
    end

    for id, _ in pairs(scene.entities) do
        local entData = { id = id, components = {} }
        local signature = scene.signatures[id]

        for compName, _ in pairs(signature) do
            local comp = scene.components[compName][id]
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
    if file then
        file.write(textutils.serialize(data))
        file.close()
        logger.info("Scene serialized to " .. path)
        return true
    end
    return false
end

function Serialization.apply(scene, data)
    local toDestroy = {}
    for id in pairs(scene.entities) do
        toDestroy[#toDestroy + 1] = id
    end
    for _, id in ipairs(toDestroy) do
        scene:destroyEntity(id)
    end

    scene.staticElements = {}
    scene.foregroundElements = {}
    scene.tilemap = nil
    scene.spatialGrid = {}
    scene.activeDynamicCells = {}
    scene.staticDirty = true

    scene.name = data.name
    scene.camera:set(data.camera.x, data.camera.y)

    if data.tilemap and data.tilemap.spritePath then
        local sprite = loader.load(data.tilemap.spritePath)
        scene:setTilemap(sprite, data.tilemap.data, data.tilemap.solidTiles, data.tilemap.tileProperties)
        scene.tilemap.spritePath = data.tilemap.spritePath
    end

    for _, s in ipairs(data.statics) do
        local sprite = s.spritePath and loader.load(s.spritePath) or nil
        scene:addStatic(sprite, s.x, s.y, s.z, s.collider, s.layer)
        scene.staticElements[#scene.staticElements].spritePath = s.spritePath
    end

    for _, entData in ipairs(data.entities) do
        local id = scene:createEntity()
        for compName, compData in pairs(entData.components) do
            if compName == "sprite" then
                local s = loader.load(compData.spritePath)
                scene:setComponent(id, "sprite", s)
            elseif type(compData) == "table" and compData.__type == "vec2" then
                scene:setComponent(id, compName, mathUtils.vec2(compData.x, compData.y))
            elseif compName == "pos" then
                scene:setComponent(id, "pos", mathUtils.vec2(compData.x or 0, compData.y or 0))
            else
                scene:setComponent(id, compName, compData)
            end
        end
    end
end

return Serialization