local ECS = {}

function ECS.createRegistry()
    local world = {
        nextEntityId = 1,
        entities = {},
        components = {},
        signatures = {},
        componentIndex = {},
    }

    function world:createEntity()
        local id = self.nextEntityId
        self.nextEntityId = id + 1
        self.entities[id] = true
        self.signatures[id] = {}
        return id
    end

    function world:destroyEntity(id)
        self.entities[id] = nil
        self.signatures[id] = nil
        for compType, storage in pairs(self.components) do
            storage[id] = nil
            if self.componentIndex[compType] then
                self.componentIndex[compType][id] = nil
            end
        end
    end

    function world:registerComponent(name)
        self.components[name] = {}
    end

    function world:setComponent(id, name, data)
        if not self.components[name] then self:registerComponent(name) end
        if not self.componentIndex[name] then self.componentIndex[name] = {} end

        if data == nil then
            self.components[name][id] = nil
            self.signatures[id][name] = nil
            self.componentIndex[name][id] = nil
        else
            self.components[name][id] = data
            self.signatures[id][name] = true
            self.componentIndex[name][id] = true
        end
    end


    function world:query(...)
        local types = {...}
        if #types == 0 then return {} end

        local smallestIdx = types[1]

        local source = self.componentIndex[smallestIdx] or {}
        local results = {}

        for id in pairs(source) do
            local match = true
            local sig = self.signatures[id]
            for i = 2, #types do
                if not sig[types[i]] then
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

    function world:getComponent(id, name)
        local storage = self.components[name]
        return storage and storage[id]
    end

    function world:hasComponent(id, name)
        return self.signatures[id] ~= nil and self.signatures[id][name] == true
    end

    return world
end

return ECS