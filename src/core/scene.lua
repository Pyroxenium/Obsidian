local Scene = {}
local ecs         = require("core.ecs")
local buffer      = require("core.buffer")
local debug       = require("core.debug")
local logger      = require("core.logger")
local loader      = require("core.loader")
local mathUtils   = require("core.math")
local uiModule    = require("core.ui")
local errorModule = require("core.error")

-- Capture Lua's native debug library before the local `debug` variable above shadows it
local _luaDebug = _G and _G.debug

local function tracebackHandler(e)
    return (_luaDebug and _luaDebug.traceback)
        and _luaDebug.traceback(tostring(e), 2)
        or  tostring(e)
end

local function deepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = deepCopy(v)
        end
        setmetatable(copy, getmetatable(orig))
    else
        copy = orig
    end
    return copy
end

function Scene.new()
    local self = ecs.createRegistry()

    self.name   = ""
    self.camera = mathUtils.vec2(0, 0)
    self.lastCam = mathUtils.vec2(0, 0)
    self.staticElements = {}
    self.memory = {} -- Globaler Speicher für szenenweite Daten (Score, Timer, etc.)
    self.staticCache = { t = {}, f = {}, b = {} }
    self.foregroundElements = {}
    self.ui = uiModule.createContext()
    self.staticDirty = true
    self.staticsSortDirty = false
    self.foregroundSortDirty = false
    self.rowsToRestore = {}
    self.sortedIds = {}
    self.triggers = {}
    self.zDirty = true

    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.shakeDurationMax = 0

    self.flashColor = "0"
    self.flashDuration = 0

    self.cellSize = 10
    self.spatialGrid = {}
    self.activeDynamicCells = {}
    self.onUpdate = nil
    self.onEvent = nil
    self.onLoad = nil
    self.onUnload = nil
    self.tilemap = nil

    function self:setTilemap(sprite, data, solidTiles, tileProperties, spritePath)
        self.tilemap = {
            sprite = sprite,
            spritePath = spritePath,
            data = data,
            solidTiles = solidTiles or {},
            tileProperties = tileProperties or {},
            tileW = sprite and sprite.width or 1,
            tileH = sprite and sprite.height or 1
        }
        self.staticDirty = true
    end

    function self:instantiate(template, x, y)
        local id = self:createEntity()
        for compName, data in pairs(template) do
            self:setComponent(id, compName, deepCopy(data))
        end
        if x and y then
            if self.components.pos and self.components.pos[id] then
                self.components.pos[id]:set(x, y)
            else
                self:setComponent(id, "pos", mathUtils.vec2(x, y))
            end
        end
        return id
    end

    -- Bindet eine Entity an eine andere (mit optionalem Offset)
    function self:setParent(childId, parentId, offsetX, offsetY)
        self:setComponent(childId, "parent", { id = parentId, offset = mathUtils.vec2(offsetX or 0, offsetY or 0) })
    end

    function self:addStatic(sprite, x, y, z, collider, layer, spritePath)
        if not sprite and not collider then
            logger.warn(string.format("Scene: addStatic at (%.1f, %.1f) called with nil sprite and no collider. Check asset paths!", x or 0, y or 0))
        end
        local item = {
            sprite = sprite,
            spritePath = spritePath or (sprite and sprite.path),
            x = x,
            y = y,
            z = z or -100,
            w = sprite and sprite.width or (collider and collider.w or 0),
            h = sprite and sprite.height or (collider and collider.h or 0),
            collider = collider,
            layer = layer or 1,
            oneWay = oneWay or false
        }
        table.insert(self.staticElements, item)
        self.staticsSortDirty = true
        self.staticDirty = true

        self:addToGrid(item, true)
    end

    function self:addToGrid(obj, isStatic, id)
        if obj.collider == false then return end
        local col = obj.collider or { x = 0, y = 0, w = obj.w, h = obj.h }
        local x1 = math.floor((obj.x + col.x) / self.cellSize)
        local y1 = math.floor((obj.y + col.y) / self.cellSize)
        local x2 = math.floor((obj.x + col.x + col.w - 0.001) / self.cellSize)
        local y2 = math.floor((obj.y + col.y + col.h - 0.001) / self.cellSize)

        for cx = x1, x2 do
            for cy = y1, y2 do
                self.spatialGrid[cx] = self.spatialGrid[cx] or {}
                self.spatialGrid[cx][cy] = self.spatialGrid[cx][cy] or { static = {}, dynamic = {} }
                local cell = self.spatialGrid[cx][cy]
                obj.layer = obj.layer or 1
                if isStatic then
                    table.insert(cell.static, obj)
                else
                    if not next(cell.dynamic) then table.insert(self.activeDynamicCells, cell) end
                    cell.dynamic[id] = obj
                end
            end
        end
    end

    function self:getDistance(id1, id2)
        local p1, p2 = self.components.pos[id1], self.components.pos[id2]
        if not p1 or not p2 then return 9999 end
        return mathUtils.dist(p1.x, p1.y, p2.x, p2.y)
    end

    function self:getEntityAt(worldX, worldY, ignoreId)
        local x1 = math.floor(worldX / self.cellSize)
        local y1 = math.floor(worldY / self.cellSize)
        local cell = self.spatialGrid[x1] and self.spatialGrid[x1][y1]

        if cell then
            for id, obj in pairs(cell.dynamic) do
                if id ~= ignoreId then
                    local col = obj.collider
                    local icx, icy = obj.x + col.x, obj.y + col.y
                    if worldX >= icx and worldX < icx + col.w and
                       worldY >= icy and worldY < icy + col.h then
                        return id
                    end
                end
            end
        end
        return nil
    end

    function self:castRay(startX, startY, targetX, targetY, maxDist, ignoreId, layerMask)
        local stepX, stepY, dist = mathUtils.normalize(targetX - startX, targetY - startY)

        if dist == 0 then return false, startX, startY end

        local checkDist = math.min(dist, maxDist or 100)

        for d = 0, checkDist, 0.5 do
            local curX = startX + stepX * d
            local curY = startY + stepY * d

            local x1 = math.floor(curX / self.cellSize)
            local y1 = math.floor(curY / self.cellSize)
            local cell = self.spatialGrid[x1] and self.spatialGrid[x1][y1]

            if cell then
                for id, obj in pairs(cell.dynamic) do
                    if id ~= ignoreId and (not layerMask or bit.band(obj.layer or 1, layerMask) > 0) then
                        local c = obj.collider
                        if curX >= (obj.x or 0) + (c.x or 0) and curX < (obj.x or 0) + (c.x or 0) + (c.w or 0) and
                           curY >= (obj.y or 0) + (c.y or 0) and curY < (obj.y or 0) + (c.y or 0) + (c.h or 0) then
                            return true, curX, curY, id
                        end
                    end
                end

                for _, item in ipairs(cell.static) do
                    if item.collider ~= false and (not layerMask or bit.band(item.layer or 1, layerMask) > 0) then
                    local col = item.collider
                    local scx, scy, scw, sch = (item.x or 0) + (col and col.x or 0), (item.y or 0) + (col and col.y or 0), (col and col.w or item.w or 0), (col and col.h or item.h or 0)
                    if curX >= scx and curX < scx + (scw or 0) and curY >= scy and curY < scy + (sch or 0) then
                        return true, curX, curY, nil
                    end
                    end
                end
            end
        end

        return false, startX + stepX * checkDist, startY + stepY * checkDist
    end

    function self:queryRect(x, y, w, h, layerMask)
        local results = {}
        local x1, y1 = math.floor(x / self.cellSize), math.floor(y / self.cellSize)
        local x2, y2 = math.floor((x + w) / self.cellSize), math.floor((y + h) / self.cellSize)

        for cx = x1, x2 do
            if self.spatialGrid[cx] then
                for cy = y1, y2 do
                    local cell = self.spatialGrid[cx][cy]
                    if cell then
                        for id, obj in pairs(cell.dynamic) do
                            if not layerMask or bit.band(obj.layer or 1, layerMask) > 0 then
                                local c = obj.collider
                                local icx, icy = obj.x + c.x, obj.y + c.y
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

    function self:getUIAt(screenX, screenY)
        local ox, oy = 0, 0
        if debug.designW and debug.designH then
            local tw, th = buffer.getSize()
            ox = math.floor((tw - debug.designW) / 2)
            oy = math.floor((th - debug.designH) / 2)
        end
        for i = #self.ui.sorted, 1, -1 do
            local el = self.ui.sorted[i]
            local ex, ey = self.ui:getAbsolutePos(el, ox, oy)
            if screenX >= ex and screenX < ex + el.w and screenY >= ey and screenY < ey + el.h then
                return el.name
            end
        end
        return nil
    end

    function self:updateDynamicGrid()
        for i = 1, #self.activeDynamicCells do
            self.activeDynamicCells[i].dynamic = {}
        end
        self.activeDynamicCells = {}

        local ids = self:query("pos", "collider")
        local layerComp = self.components.layer
        for _, id in ipairs(ids) do
            local p = self.components.pos[id]
            local c = self.components.collider[id]
            local l = layerComp and layerComp[id] or 1
            self:addToGrid({ x = p.x, y = p.y, w = c.w, h = c.h, collider = c, layer = l }, false, id)
        end
    end

    function self:addForeground(sprite, x, y, z)
        table.insert(self.foregroundElements, {
            sprite = sprite,
            x = x,
            y = y,
            z = z or 100,
            w = sprite.width,
            h = sprite.height
        })
        self.foregroundSortDirty = true
    end

    function self:isAreaBlocked(x, y, w, h, ignoreId, layerMask)
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
                                local vel = self.components.velocity and self.components.velocity[ignoreId]
                                if vel and vel.y > 0 and (y + h - vel.y * 0.1) <= platformY then
                                    if y + h > platformY then
                                        bestSlopeY = platformY
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

        if bestSlopeY then return true, "tile", bestSlopeY end

        local x1, y1 = math.floor(x / self.cellSize), math.floor(y / self.cellSize)
        local x2, y2 = math.floor((x + w - 0.001) / self.cellSize), math.floor((y + h - 0.001) / self.cellSize)

        for cx = x1, x2 do
            if self.spatialGrid[cx] then
                for cy = y1, y2 do
                    local cell = self.spatialGrid[cx][cy]
                    if cell then
                        for _, item in ipairs(cell.static) do
                            if item.collider ~= false and (not layerMask or bit.band(item.layer or 1, layerMask) > 0) then
                            local col = item.collider
                            local cx, cy, cw, ch
                            if col then
                                cx, cy, cw, ch = item.x + (col.x or 0), item.y + (col.y or 0), (col.w or item.w or 0), (col.h or item.h or 0)
                            else
                                cx, cy, cw, ch = item.x or 0, item.y or 0, item.w or 0, item.h or 0
                            end

                            if x < cx + cw and x + w > cx and 
                               y < cy + ch and y + h > cy then
                                if item.oneWay then
                                    local vel = self.components.velocity and self.components.velocity[ignoreId]
                                    if vel and vel.y >= 0 and (y + h - vel.y * 0.1) <= cy then
                                        return true, "static"
                                    end
                                else
                                    return true, "static"
                                end
                            end
                            end
                        end
                        for id, obj in pairs(cell.dynamic) do
                            if id ~= ignoreId and (not layerMask or bit.band(obj.layer or 1, layerMask) > 0) then
                                local col = obj.collider
                                local icx, icy = (obj.x or 0) + (col.x or 0), (obj.y or 0) + (col.y or 0)
                                if x < icx + (col.w or 0) and x + w > icx and
                                   y < icy + col.h and y + h > icy then
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

    local originalSetComp = self.setComponent
    function self:setComponent(id, name, data)
        originalSetComp(self, id, name, data)
        if name == "z" or name == "sprite" then
            if name == "sprite" and data == nil then
                logger.warn("Scene: Sprite component set to nil for entity " .. tostring(id) .. ". Check asset paths!")
            end
            self.zDirty = true
        end
    end

    local originalDestroy = self.destroyEntity
    function self:destroyEntity(id)
        local p = self.components.pos and self.components.pos[id]
        local s = self.components.sprite and self.components.sprite[id]
        if p and s then
            local termW, termH = buffer.getSize()
            local designW, designH = debug.designW, debug.designH
            local offsetY = (designW and designH) and math.floor((termH - designH) / 2) or 0
            local totalCamY = self.camera.y - offsetY

            local sy = math.floor(p.y - totalCamY)
            for i = 0, s.height - 1 do
                local targetY = sy + i
                if targetY >= 1 and targetY <= termH then
                    self.rowsToRestore[targetY] = true
                end
            end
        end

        originalDestroy(self, id)
        self.zDirty = true
    end

    function self:shake(intensity, duration)
        self.shakeIntensity = intensity or 1
        self.shakeDuration = duration or 0.5
        self.shakeDurationMax = self.shakeDuration
    end

    function self:addTrigger(x, y, w, h, onEnter, onExit)
        table.insert(self.triggers, {
            x = x, y = y, w = w, h = h,
            onEnter = onEnter,
            onExit = onExit,
            entitiesInside = {}
        })
    end

    function self:flash(color, duration)
        self.flashColor = color or "0"
        self.flashDuration = duration or 0.2
    end

    function self:loadUI(path, x, y)
        local uiData, err = loader.loadUI(path)
        if not uiData then
            logger.error("Failed to load OUI: " .. tostring(err))
            return
        end

        for name, el in pairs(uiData.elements) do
            self.ui:add(name, el.type, (x or 0) + (el.x or 0), (y or 0) + (el.y or 0), el)
        end
    end

    function self:unloadUI(path)
        local uiData = loader.loadUI(path)
        if uiData then
            for name, _ in pairs(uiData.elements) do
                self.ui:remove(name)
            end
        end
    end

    function self:addUI(name, type, x, y, config)
        return self.ui:add(name, type, x, y, config)
    end

    function self:updateUI(name, config)
        self.ui:update(name, config)
    end

    self.systems = {
        update = {},
        render = {}
    }

    function self:addSystem(filter, fn)
        table.insert(self.systems.update, {filter = filter, update = fn})
    end

    function self:update(dt)
        self:updateDynamicGrid()

        -- 1. Parenting System: Kind-Positionen basierend auf Eltern berechnen
        local children = self:query("pos", "parent")
        for _, id in ipairs(children) do
            local pData = self.components.parent[id]
            local parentPos = self.components.pos[pData.id]
            local childPos = self.components.pos[id]
            if parentPos and childPos then
                childPos:set(parentPos.x + pData.offset.x, parentPos.y + pData.offset.y)
            end
        end

        if self.shakeDuration > 0 then
            self.shakeDuration = self.shakeDuration - dt
            if self.shakeDuration <= 0 then 
                self.shakeIntensity = 0 
                self.shakeDurationMax = 0
                self.staticDirty = true
            end
        end

        if (self.flashDuration or 0) > 0 then
            self.flashDuration = self.flashDuration - dt
        end

        for _, system in ipairs(self.systems.update) do
            local ids = self:query(table.unpack(system.filter))
            local ok, err = xpcall(function()
                system.update(dt, ids, self.components)
            end, tracebackHandler)
            if not ok then
                local filterStr = "[" .. table.concat(system.filter, ", ") .. "]"
                errorModule.report("System " .. filterStr .. ":\n" .. err)
                return
            end
        end

        for _, t in ipairs(self.triggers) do
            local ids = self:queryRect(t.x, t.y, t.w, t.h)
            local idMap = {}
            for _, id in ipairs(ids) do idMap[id] = true end

            for id, _ in pairs(t.entitiesInside) do
                if not idMap[id] then
                    if t.onExit then t.onExit(id) end
                    t.entitiesInside[id] = nil
                end
            end

            for _, id in ipairs(ids) do
                if not t.entitiesInside[id] then
                    if t.onEnter then t.onEnter(id) end
                    t.entitiesInside[id] = true
                end
            end
        end

        if self.onUpdate then
            local ok, err = xpcall(self.onUpdate, tracebackHandler, dt)
            if not ok then
                errorModule.report("Scene.onUpdate:\n" .. err)
                return
            end
        end
    end

    function self:draw()
        local camMoved = self.camera.x ~= self.lastCam.x or self.camera.y ~= self.lastCam.y
        local termW, termH = buffer.getSize()

        local designW, designH = debug.designW, debug.designH
        local offsetX, offsetY = 0, 0
        if designW and designH then
            offsetX = math.max(0, math.floor((termW - designW) / 2))
            offsetY = math.max(0, math.floor((termH - designH) / 2))
        end

        local shakeX, shakeY = 0, 0
        if (self.shakeDuration or 0) > 0 then
            local falloff = self.shakeDuration / self.shakeDurationMax
            local currentIntensity = self.shakeIntensity * falloff

            shakeX = (math.random() - 0.5) * 2 * currentIntensity
            shakeY = (math.random() - 0.5) * 2 * currentIntensity
        end

        local totalCamX = self.camera.x - offsetX + shakeX
        local totalCamY = self.camera.y - offsetY + shakeY

        if self.staticsSortDirty then
            table.sort(self.staticElements, function(a, b) return a.z < b.z end)
            self.staticsSortDirty = false
        end
        if self.foregroundSortDirty then
            table.sort(self.foregroundElements, function(a, b) return a.z < b.z end)
            self.foregroundSortDirty = false
        end

        if self.staticDirty or camMoved or (self.shakeDuration or 0) > 0 then
            -- Hintergrund muss neu generiert werden
            buffer.clear()

            if self.tilemap then
                local tm = self.tilemap
                local startX = math.max(1, math.floor(totalCamX / tm.tileW) + 1)
                local startY = math.max(1, math.floor(totalCamY / tm.tileH) + 1)
                local endX = math.floor((totalCamX + termW) / tm.tileW) + 1
                local endY = math.floor((totalCamY + termH) / tm.tileH) + 1

                for ty = startY, endY do
                    if tm.data[ty] then
                        for tx = startX, endX do
                            local tid = tm.data[ty][tx]
                            if tid and tid > 0 and tm.sprite[tid] then
                                buffer.drawSprite(tm.sprite[tid], (tx-1)*tm.tileW, (ty-1)*tm.tileH, totalCamX, totalCamY)
                            end
                        end
                    end
                end
            end

            for _, item in ipairs(self.staticElements) do
                local s = item.sprite
                local sx = math.floor(item.x - totalCamX)
                local sy = math.floor(item.y - totalCamY)

                if s and sx + s.width >= 1 and sx <= termW and 
                   sy + s.height >= 1 and sy <= termH and 
                   s[1] then
                    buffer.drawSprite(s[1], item.x, item.y, totalCamX, totalCamY)
                end
            end
            buffer.copyTo(self.staticCache)
            self.staticDirty = false
            self.rowsToRestore = {}
            self.lastCam.x, self.lastCam.y = self.camera.x, self.camera.y
        else
            for y, _ in pairs(self.rowsToRestore) do
                buffer.restoreLine(y, self.staticCache)
            end
            self.rowsToRestore = {}
        end

        local comps = self.components
        local zComp = comps.z
        local posComp = comps.pos
        local spriteComp = comps.sprite
        local animComp = comps.animation

        if self.zDirty then
            self.sortedIds = self:query("pos", "sprite")
            table.sort(self.sortedIds, function(a, b)
                local za = zComp and zComp[a] or 0
                local zb = zComp and zComp[b] or 0
                return za < zb
            end)
            self.zDirty = false
        end

        debug.dynamicCount = #self.sortedIds

        for _, id in ipairs(self.sortedIds) do
            local p = posComp[id]
            local s = spriteComp[id]

            local anim = animComp and animComp[id]
            local seq = (anim and anim.sequences and anim.state) and anim.sequences[anim.state]
            local frameIdx = seq and seq[anim.currentFrame or 1] or (anim and anim.currentFrame or 1)
            local currentFrame = s and s[frameIdx]

            if currentFrame then
                local sy = math.floor(p.y - totalCamY)
                local sx = math.floor(p.x - totalCamX)
                local frameHeight = s.height or 0
                local frameWidth = s.width or 0

                if sx + frameWidth >= 1 and sx <= termW and sy + frameHeight >= 1 and sy <= termH then
                    local cOver = comps.colorOverride and comps.colorOverride[id]
                    local charOver = comps.charOverride and comps.charOverride[id]

                    if cOver or charOver then
                        buffer.drawRect(p.x - totalCamX, p.y - totalCamY, frameWidth, frameHeight, charOver, cOver)
                    else
                        buffer.drawSprite(currentFrame, p.x, p.y, totalCamX, totalCamY)
                    end

                    for i = 0, frameHeight - 1 do
                        local targetY = sy + i
                        if targetY >= 1 and targetY <= termH then
                            self.rowsToRestore[targetY] = true
                        end
                    end
                end
            end
        end

        for _, item in ipairs(self.foregroundElements) do
            local s = item.sprite
            local sx = math.floor(item.x - totalCamX)
            local sy = math.floor(item.y - totalCamY)

            if s and sx + s.width >= 1 and sx <= termW and 
               sy + s.height >= 1 and sy <= termH and 
               s[1] then
                buffer.drawSprite(s[1], item.x, item.y, totalCamX, totalCamY)
                for i = 0, s.height - 1 do
                    self.rowsToRestore[sy + i] = true
                end
            end
        end

        if not debug.unsupportedResolution then
            self.ui:draw(offsetX, offsetY, self.rowsToRestore)
        end

        if (self.flashDuration or 0) > 0 then
            buffer.drawRect(1, 1, termW, termH, " ", self.flashColor, self.flashColor)
        end

        if debug.enabled then
            local stats = string.format("FPS: %d | Upd: %dms | Draw: %dms", debug.fps, debug.updateTime, debug.drawTime)
            local entInfo = string.format("Entities: %d (Dyn) | %d (Stat)", debug.dynamicCount, #self.staticElements)
            buffer.drawText(1, 1, stats, "0", "f")
            buffer.drawText(1, 2, entInfo, "7", "f")
            self.rowsToRestore[1], self.rowsToRestore[2] = true, true

            if debug.showLogs then
                local history = logger.getHistory()
                for i, entry in ipairs(history) do
                    buffer.drawText(1, 3 + i, entry.text, entry.color, "f")
                    self.rowsToRestore[3 + i] = true
                end
            end
        end
    end

    return self
end

return Scene