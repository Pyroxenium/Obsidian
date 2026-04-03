local buffer = require("core.buffer")

local UI = {}

function UI.createContext()
    local self = {
        elements = {},
        sorted = {},
        dirty = true,
        pressedElement = nil,
        focusedElement = nil
    }

    local ELEMENT_FIELDS = {
        x=true, y=true, z=true, w=true, h=true,
        visible=true, sprite=true, disabled=true,
        fore=true, back=true, borderColor=true, anchor=true, interactive=true,
        borderTop=true, borderBottom=true, borderLeft=true, borderRight=true,
    }
    local DIRTY_FIELDS = { z=true, sprite=true, w=true, h=true }

    function self:add(name, type, x, y, config)
        self.elements[name] = {
            name = name,
            type = type,
            x = x,
            y = y,
            w = config.w or (config.text and #config.text or 0),
            h = config.h or 1,
            z = config.z or 0,
            config = config,
            visible = (config.visible ~= false) and (config.hidden ~= true),
            anchor = config.anchor or "top-left",
            interactive = (type ~= "text" and type ~= "rect" and type ~= "sprite") or config.interactive,
            sprite = config.sprite,
            borderTop = config.borderTop ~= nil and config.borderTop or (config.border ~= false),
            borderBottom = config.borderBottom ~= nil and config.borderBottom or (config.border ~= false),
            borderLeft = config.borderLeft ~= nil and config.borderLeft or (config.border ~= false),
            borderRight = config.borderRight ~= nil and config.borderRight or (config.border ~= false),
            fore = config.fore or "0",
            back = config.back or "7",
            borderColor = config.borderColor or "8",
            disabled = config.disabled == true
        }

        if config.sprite then
            self.elements[name].w = config.sprite.width
            self.elements[name].h = config.sprite.height
        end

        self.dirty = true
        return self.elements[name]
    end

    function self:remove(name)
        if self.elements[name] then
            self.elements[name] = nil
            self.dirty = true
        end
    end

    -- -------------------------------------------------------------------------
    -- Container API
    -- -------------------------------------------------------------------------

    function self:addContainer(name, x, y, w, h, config)
        config = config or {}
        local el = {
            name = name,
            type = "container",
            x = x,
            y = y,
            w = w,
            h = h,
            z = config.z or 0,
            config = config,
            visible = (config.visible ~= false) and (config.hidden ~= true),
            anchor = config.anchor or "top-left",
            interactive = true,
            fore = config.fore or "0",
            back = config.back or "7",
            borderColor = config.borderColor or "8",
            borderTop    = config.borderTop    ~= nil and config.borderTop    or (config.border ~= false),
            borderBottom = config.borderBottom ~= nil and config.borderBottom or (config.border ~= false),
            borderLeft   = config.borderLeft   ~= nil and config.borderLeft   or (config.border ~= false),
            borderRight  = config.borderRight  ~= nil and config.borderRight  or (config.border ~= false),
            disabled = config.disabled == true,
            children = {},
            sortedChildren = {},
            childrenDirty = true,
            scrollOffset = 0,
        }
        self.elements[name] = el
        self.dirty = true
        return el
    end

    function self:addToContainer(containerName, childName, childType, x, y, config)
        local container = self.elements[containerName]
        if not container or container.type ~= "container" then return nil end
        config = config or {}
        local child = {
            name = childName,
            type = childType,
            x = x,
            y = y,
            w = config.w or (config.text and #config.text or 0),
            h = config.h or 1,
            z = config.z or 0,
            config = config,
            visible = (config.visible ~= false) and (config.hidden ~= true),
            anchor = "top-left",
            interactive = (childType ~= "text" and childType ~= "rect" and childType ~= "sprite") or config.interactive,
            sprite = config.sprite,
            borderTop    = config.borderTop    ~= nil and config.borderTop    or (config.border ~= false),
            borderBottom = config.borderBottom ~= nil and config.borderBottom or (config.border ~= false),
            borderLeft   = config.borderLeft   ~= nil and config.borderLeft   or (config.border ~= false),
            borderRight  = config.borderRight  ~= nil and config.borderRight  or (config.border ~= false),
            fore = config.fore or "0",
            back = config.back or "7",
            borderColor = config.borderColor or "8",
            disabled = config.disabled == true,
        }
        if config.sprite then
            child.w = config.sprite.width
            child.h = config.sprite.height
        end
        container.children[childName] = child
        container.childrenDirty = true
        return child
    end

    function self:removeFromContainer(containerName, childName)
        local container = self.elements[containerName]
        if container and container.type == "container" then
            container.children[childName] = nil
            container.childrenDirty = true
        end
    end

    function self:updateInContainer(containerName, childName, config)
        local container = self.elements[containerName]
        if not container or container.type ~= "container" then return end
        local child = container.children[childName]
        if not child then return end
        for k, v in pairs(config) do
            if ELEMENT_FIELDS[k] then
                child[k] = v
                if DIRTY_FIELDS[k] then container.childrenDirty = true end
            else
                child.config[k] = v
            end
        end
        if child.type == "text" and config.text then child.w = #config.text end
    end

    function self:update(name, config)
        local el = self.elements[name]
        if not el then return end
        for k, v in pairs(config) do
            if ELEMENT_FIELDS[k] then
                el[k] = v
                if DIRTY_FIELDS[k] then self.dirty = true end
            else
                el.config[k] = v
            end
        end
        if el.type == "text" and config.text then el.w = #config.text end
    end

    function self:get(name)
        local el = self.elements[name]
        if not el then return nil end
        if el.type == "input" or el.type == "button" or el.type == "text" then
            return el.config.text
        elseif el.type == "checkbox" then
            return el.config.checked
        elseif el.type == "dropdown" then
            local idx = el.config.selectedIndex
            return idx, idx and el.config.options and el.config.options[idx]
        elseif el.type == "progress" then
            return el.config.progress
        elseif el.type == "slider" then
            return el.config.value or el.config.min or 0
        elseif el.type == "list" then
            local idx = el.config.selectedIndex
            return idx, idx and el.config.options and el.config.options[idx]
        end
        return nil
    end

    function self:getAbsolutePos(el, ox, oy)
        local tw, th = buffer.getSize()
        local rx, ry = el.x + ox, el.y + oy
        local cx = ox + math.floor((tw - ox * 2) / 2) - math.floor(el.w / 2) + el.x
        local cy = oy + math.floor((th - oy * 2) / 2) - math.floor(el.h / 2) + el.y
        local bx = (tw - ox) - el.w - el.x
        local by = (th - oy) - el.h - el.y
        if     el.anchor == "top-left"     then
        elseif el.anchor == "top-center"   then rx = cx
        elseif el.anchor == "top-right"    then rx = bx
        elseif el.anchor == "center-left"  then ry = cy
        elseif el.anchor == "center"       then rx = cx ; ry = cy
        elseif el.anchor == "center-right" then rx = bx ; ry = cy
        elseif el.anchor == "bottom-left"  then ry = by
        elseif el.anchor == "bottom-center"then rx = cx ; ry = by
        elseif el.anchor == "bottom-right" then rx = bx ; ry = by
        end
        return rx, ry
    end

    function self:handleEvent(event, ox, oy)
        local eventType = event[1]
        if eventType == "mouse_click" or eventType == "mouse_drag" then
            local _, mx, my = event[2], event[3], event[4]
            local hit = nil
            local hitAbsX, hitAbsY = 0, 0

            local function sortContainerChildren(el)
                if el.childrenDirty then
                    el.sortedChildren = {}
                    for _, child in pairs(el.children) do
                        table.insert(el.sortedChildren, child)
                    end
                    table.sort(el.sortedChildren, function(a, b) return a.z < b.z end)
                    el.childrenDirty = false
                end
            end

            for i = #self.sorted, 1, -1 do
                local el = self.sorted[i]
                if el.visible then
                    local ex, ey = self:getAbsolutePos(el, ox, oy)
                    if el.type == "container" then
                        if mx >= ex and mx < ex + el.w and my >= ey and my < ey + el.h then
                            sortContainerChildren(el)
                            local contentX = ex + (el.borderLeft and 1 or 0)
                            local contentY = ey + (el.borderTop  and 1 or 0)
                            local contentH = el.h - (el.borderTop and 1 or 0) - (el.borderBottom and 1 or 0)
                            local scrollY  = el.scrollOffset or 0
                            for j = #el.sortedChildren, 1, -1 do
                                local child = el.sortedChildren[j]
                                if child.visible then
                                    local crx = contentX + child.x
                                    local cry = contentY + child.y - scrollY
                                    -- skip children scrolled out of view
                                    if cry + child.h > contentY and cry < contentY + contentH then
                                        local childH = (child.type == "dropdown" and child.isOpen and child.config.options)
                                                       and (child.h + #child.config.options) or child.h
                                        if mx >= crx and mx < crx + child.w and my >= cry and my < cry + childH then
                                            hit = child
                                            hitAbsX, hitAbsY = crx, cry
                                            break
                                        end
                                    end
                                end
                            end
                            break
                        end
                    else
                        local elH = (el.type == "dropdown" and el.isOpen and el.config.options)
                                    and (el.h + #el.config.options) or el.h
                        if mx >= ex and mx < ex + el.w and my >= ey and my < ey + elH then
                            hit = el
                            hitAbsX, hitAbsY = ex, ey
                            break
                        end
                    end
                end
            end

            if eventType == "mouse_click" then
                self.focusedElement = (hit and hit.type == "input") and hit or nil
                for _, el in pairs(self.elements) do
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
                                if hit.config.onChanged then hit.config.onChanged(hit.config.selectedIndex, hit.config.options[hit.config.selectedIndex]) end
                            end
                            hit.isOpen = false
                        else
                            hit.isOpen = true
                        end
                        return true
                    end

                    if hit.type == "list" then
                        local relY = my - hitAbsY
                        local itemIdx = (hit.config.scrollOffset or 0) + relY + 1
                        if hit.config.options and itemIdx >= 1 and itemIdx <= #hit.config.options then
                            hit.config.selectedIndex = itemIdx
                            if hit.config.onChanged then hit.config.onChanged(itemIdx, hit.config.options[itemIdx]) end
                        end
                        return true
                    end

                    if hit.type == "slider" then
                        local relX = math.max(0, math.min(hit.w - 1, mx - hitAbsX))
                        local sMin = hit.config.min or 0
                        local sMax = hit.config.max or 100
                        local step = hit.config.step or 1
                        local rawVal = sMin + (relX / math.max(1, hit.w - 1)) * (sMax - sMin)
                        local val = math.floor(rawVal / step + 0.5) * step
                        val = math.max(sMin, math.min(sMax, val))
                        hit.config.value = val
                        if hit.config.onChanged then hit.config.onChanged(val) end
                    end

                    self.pressedElement = hit
                    self.pressedAbsX = hitAbsX
                    self.pressedAbsY = hitAbsY
                    return true
                end
            elseif eventType == "mouse_drag" then
                if self.pressedElement and self.pressedElement.type == "slider" then
                    local el = self.pressedElement
                    local ex = self.pressedAbsX or 0
                    local relX = math.max(0, math.min(el.w - 1, mx - ex))
                    local sMin = el.config.min or 0
                    local sMax = el.config.max or 100
                    local step = el.config.step or 1
                    local rawVal = sMin + (relX / math.max(1, el.w - 1)) * (sMax - sMin)
                    local val = math.floor(rawVal / step + 0.5) * step
                    val = math.max(sMin, math.min(sMax, val))
                    el.config.value = val
                    if el.config.onChanged then el.config.onChanged(val) end
                    return true
                end
            end
        elseif eventType == "mouse_up" then
            local button, mx, my = event[2], event[3], event[4]
            if self.pressedElement then
                local el = self.pressedElement
                local ex = self.pressedAbsX or 0
                local ey = self.pressedAbsY or 0

                if el.type == "slider" then
                    local relX = math.max(0, math.min(el.w - 1, mx - ex))
                    local sMin = el.config.min or 0
                    local sMax = el.config.max or 100
                    local step = el.config.step or 1
                    local rawVal = sMin + (relX / math.max(1, el.w - 1)) * (sMax - sMin)
                    local val = math.floor(rawVal / step + 0.5) * step
                    val = math.max(sMin, math.min(sMax, val))
                    el.config.value = val
                    if el.config.onChanged then el.config.onChanged(val) end
                elseif mx >= ex and mx < ex + el.w and my >= ey and my < ey + el.h then
                    if el.type == "button" and el.config.onClick then
                        el.config.onClick(button)
                    end
                end
                self.pressedElement = nil
                self.pressedAbsX = nil
                self.pressedAbsY = nil
                return true
            end
        elseif eventType == "char" then
            if self.focusedElement and self.focusedElement.type == "input" then
                local el = self.focusedElement
                el.config.text = (el.config.text or "") .. event[2]
                if el.config.onChange then el.config.onChange(el.config.text) end
                return true
            end
        elseif eventType == "key" then
            if self.focusedElement and self.focusedElement.type == "input" then
                local el = self.focusedElement
                local key = event[2]
                if key == keys.backspace then
                    el.config.text = (el.config.text or ""):sub(1, -2)
                    if el.config.onChange then el.config.onChange(el.config.text) end
                elseif key == keys.enter then
                    self.focusedElement = nil
                    if el.config.onConfirm then el.config.onConfirm(el.config.text) end
                end
                return true
            end
        elseif eventType == "mouse_scroll" then
            local dir, mx, my = event[2], event[3], event[4]
            for i = #self.sorted, 1, -1 do
                local el = self.sorted[i]
                if el.visible and not el.disabled then
                    local ex, ey = self:getAbsolutePos(el, ox, oy)
                    if mx >= ex and mx < ex + el.w and my >= ey and my < ey + el.h then
                        if el.type == "list" then
                            local maxScroll = math.max(0, #(el.config.options or {}) - el.h)
                            el.config.scrollOffset = math.max(0, math.min(maxScroll, (el.config.scrollOffset or 0) + dir))
                            return true
                        elseif el.type == "slider" then
                            local sMin = el.config.min or 0
                            local sMax = el.config.max or 100
                            local step = el.config.step or 1
                            local val = math.max(sMin, math.min(sMax, (el.config.value or sMin) - dir * step))
                            el.config.value = val
                            if el.config.onChanged then el.config.onChanged(val) end
                            return true
                        elseif el.type == "container" and el.config.scrollable ~= false then
                            -- compute max scrollOffset from deepest child bottom
                            local contentH = el.h - (el.borderTop and 1 or 0) - (el.borderBottom and 1 or 0)
                            local maxChildBottom = 0
                            for _, child in pairs(el.children) do
                                local bottom = child.y + child.h
                                if bottom > maxChildBottom then maxChildBottom = bottom end
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

    -- Draws a proportional scrollbar at column x, from topY, over trackH rows.
    -- scrollOffset = current scroll position, totalRows = total content rows.
    local function drawScrollbar(x, topY, trackH, scrollOffset, totalRows, trackColor, thumbColor)
        if totalRows <= trackH then return end
        local thumbSize = math.max(1, math.floor(trackH * trackH / totalRows))
        local maxScroll = totalRows - trackH
        local thumbPos  = math.floor((scrollOffset / maxScroll) * (trackH - thumbSize))
        for i = 0, trackH - 1 do
            local isThumb = (i >= thumbPos and i < thumbPos + thumbSize)
            buffer.drawText(x, topY + i, " ", "0", isThumb and thumbColor or trackColor)
        end
    end

    -- Draws a single non-container element at the given absolute pixel position.
    local function drawEl(el, rx, ry, pressedEl, focusedEl, rowsToRestore)
        if el.sprite then
            local frame = el.sprite[el.config.frame or 1]
            if frame then
                buffer.drawSprite(frame, rx, ry, 0, 0)
                for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
            end
        elseif el.type == "text" then
            local color = el.disabled and "8" or el.fore
            buffer.drawText(rx, ry, el.config.text, color, el.back)
            rowsToRestore[ry] = true
        elseif el.type == "rect" or el.type == "button" or el.type == "input" or el.type == "checkbox" or el.type == "dropdown" or el.type == "progress" then
            local isPressed = (pressedEl == el)
            local isFocused = (focusedEl == el)

            local bg = el.disabled and "8" or (isPressed and el.borderColor or el.back)
            local fg = el.disabled and "7" or (isPressed and el.back or el.fore)
            local bc = (isPressed or isFocused) and el.fore or el.borderColor

            buffer.drawRect(rx, ry, el.w, el.h, el.config.char or " ", fg, bg)

            if el.type == "progress" then
                local progress = math.max(0, math.min(1, el.config.progress or 0))
                local fillCol = el.config.fillColor or "d"
                local fillW = math.floor(el.w * progress)
                local frac = el.w * progress - fillW
                if fillW > 0 then
                    buffer.drawRect(rx, ry, fillW, el.h, el.config.fillChar or " ", fillCol, fillCol)
                end
                if frac >= 0.5 and fillW < el.w then
                    for row = 0, el.h - 1 do
                        buffer.drawText(rx + fillW, ry + row, "\149", fillCol, el.back)
                    end
                end
            end

            if el.borderTop then
                buffer.drawText(rx, ry, ("\131"):rep(el.w), bc, bg)
            end
            if el.borderBottom then
                buffer.drawText(rx, ry + el.h - 1, ("\143"):rep(el.w), bg, bc)
            end
            if el.borderLeft then
                for i = 0, el.h - 1 do
                    buffer.drawText(rx, ry + i, "\149", bc, bg)
                end
            end
            if el.borderRight then
                for i = 0, el.h - 1 do
                    buffer.drawText(rx + el.w - 1, ry + i, "\149", bg, bc)
                end
            end

            if el.borderTop and el.borderLeft  then buffer.drawText(rx, ry, "\151", bc, bg) end
            if el.borderTop and el.borderRight  then buffer.drawText(rx + el.w - 1, ry, "\148", bg, bc) end
            if el.borderBottom and el.borderLeft  then buffer.drawText(rx, ry + el.h - 1, "\138", bg, bc) end
            if el.borderBottom and el.borderRight then buffer.drawText(rx + el.w - 1, ry + el.h - 1, "\133", bg, bc) end

            if el.type == "checkbox" then
                local mark = el.config.checked and "\7" or " "
                buffer.drawText(rx + math.floor(el.w / 2), ry + math.floor(el.h / 2), mark, fg, bg)
            end

            if (el.type == "button" or el.type == "input") and el.config.text then
                local tx = el.type == "input" and (rx + 1) or (rx + math.floor((el.w - #el.config.text) / 2))
                local ty = ry + math.floor(el.h / 2)
                local text = el.config.text
                if isFocused and (math.floor(os.clock() * 2) % 2 == 0) then text = text .. "_" end

                if el.type == "input" then
                    if el.config.password then
                        local cursor = isFocused and (math.floor(os.clock() * 2) % 2 == 0)
                        local masked = string.rep("*", #el.config.text)
                        text = cursor and (masked .. "_") or masked
                    end
                    local maxW = math.max(1, el.w - 2)
                    if #text > maxW then
                        text = text:sub(#text - maxW + 1)
                    end
                end

                buffer.drawText(tx, ty, text, fg, bg)
            end

            if el.type == "dropdown" then
                local selected = el.config.selectedIndex
                local displayText = tostring((selected and el.config.options and el.config.options[selected]) or el.config.text or "")
                local maxW = math.max(1, el.w - 2)
                if #displayText > maxW then displayText = displayText:sub(1, maxW) end
                buffer.drawText(rx + 1, ry + math.floor(el.h / 2), displayText, fg, bg)
                buffer.drawText(rx + el.w - 1, ry + math.floor(el.h / 2), el.isOpen and "\30" or "\31", fg, bg)

                if el.isOpen and el.config.options then
                    for i, opt in ipairs(el.config.options) do
                        local optY = ry + el.h - 1 + i
                        local optBg = (i == selected) and el.fore or el.back
                        local optFg = (i == selected) and el.back or el.fore
                        buffer.drawRect(rx, optY, el.w, 1, " ", optFg, optBg)
                        local optText = tostring(opt)
                        if #optText > el.w - 1 then optText = optText:sub(1, el.w - 1) end
                        buffer.drawText(rx + 1, optY, optText, optFg, optBg)
                        rowsToRestore[optY] = true
                    end
                end
            end

            for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
        elseif el.type == "list" then
            local options = el.config.options or {}
            local scrollOffset = el.config.scrollOffset or 0
            local selectedIndex = el.config.selectedIndex
            local selFore = el.config.selectedFore or el.back
            local selBack = el.config.selectedBack or el.fore
            local needsBar = #options > el.h
            local itemW = needsBar and (el.w - 1) or el.w
            local trackColor = el.config.scrollTrack or "8"
            local thumbColor = el.config.scrollThumb or el.fore
            buffer.drawRect(rx, ry, el.w, el.h, " ", el.fore, el.back)
            for row = 0, el.h - 1 do
                local itemIdx = scrollOffset + row + 1
                local opt = options[itemIdx]
                if opt then
                    local isSelected = (itemIdx == selectedIndex)
                    local fg = isSelected and selFore or el.fore
                    local bg = isSelected and selBack or el.back
                    local text = tostring(opt)
                    if #text > itemW then text = text:sub(1, itemW) end
                    buffer.drawRect(rx, ry + row, itemW, 1, " ", fg, bg)
                    buffer.drawText(rx, ry + row, text, fg, bg)
                end
            end
            if needsBar then
                drawScrollbar(rx + el.w - 1, ry, el.h, scrollOffset, #options, trackColor, thumbColor)
            end
            for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
        elseif el.type == "slider" then
            local sMin = el.config.min or 0
            local sMax = el.config.max or 100
            local value = el.config.value or sMin
            local t = (sMax > sMin) and math.max(0, math.min(1, (value - sMin) / (sMax - sMin))) or 0
            local thumbPos = math.floor(t * (el.w - 1))
            local fillColor = el.disabled and "8" or (el.config.fillColor or "d")
            local trackBg  = el.disabled and "7" or el.back
            local thumbFore = el.config.thumbFore or el.back
            local thumbBack = el.config.thumbBack or (el.disabled and "8" or el.fore)
            local thumbChar = el.config.thumbChar or "\149"
            -- draw empty track
            buffer.drawRect(rx, ry, el.w, el.h, " ", el.fore, trackBg)
            -- draw filled portion
            if thumbPos > 0 then
                buffer.drawRect(rx, ry, thumbPos, el.h, " ", fillColor, fillColor)
            end
            -- draw thumb handle
            buffer.drawText(rx + thumbPos, ry, thumbChar, thumbFore, thumbBack)
            -- optional label
            if el.config.showValue then
                local label = tostring(math.floor(value))
                local lx = rx + math.floor((el.w - #label) / 2)
                if lx + #label - 1 ~= rx + thumbPos then
                    buffer.drawText(lx, ry, label, el.fore, trackBg)
                end
            end
            rowsToRestore[ry] = true
        end
    end  -- drawEl

    function self:draw(ox, oy, rowsToRestore)
        if self.dirty then
            self.sorted = {}
            for _, el in pairs(self.elements) do
                table.insert(self.sorted, el)
            end
            table.sort(self.sorted, function(a, b) return a.z < b.z end)
            self.dirty = false
        end
        for _, el in ipairs(self.sorted) do
            if el.visible then
                local rx, ry = self:getAbsolutePos(el, ox, oy)

                if el.type == "container" then
                    -- Background
                    buffer.drawRect(rx, ry, el.w, el.h, " ", el.fore, el.back)
                    -- Borders
                    local bg = el.back
                    local bc = el.borderColor
                    if el.borderTop    then buffer.drawText(rx, ry, ("\131"):rep(el.w), bc, bg) end
                    if el.borderBottom then buffer.drawText(rx, ry + el.h - 1, ("\143"):rep(el.w), bg, bc) end
                    if el.borderLeft   then for i = 0, el.h - 1 do buffer.drawText(rx, ry + i, "\149", bc, bg) end end
                    if el.borderRight  then for i = 0, el.h - 1 do buffer.drawText(rx + el.w - 1, ry + i, "\149", bg, bc) end end
                    if el.borderTop    and el.borderLeft  then buffer.drawText(rx, ry, "\151", bc, bg) end
                    if el.borderTop    and el.borderRight then buffer.drawText(rx + el.w - 1, ry, "\148", bg, bc) end
                    if el.borderBottom and el.borderLeft  then buffer.drawText(rx, ry + el.h - 1, "\138", bg, bc) end
                    if el.borderBottom and el.borderRight then buffer.drawText(rx + el.w - 1, ry + el.h - 1, "\133", bg, bc) end
                    -- Optional title in top border
                    if el.config.title then
                        local t = " " .. el.config.title .. " "
                        local tx = rx + math.floor((el.w - #t) / 2)
                        buffer.drawText(tx, ry, t, bc, bg)
                    end
                    for i = 0, el.h - 1 do rowsToRestore[ry + i] = true end
                    -- Sort children if needed
                    if el.childrenDirty then
                        el.sortedChildren = {}
                        for _, child in pairs(el.children) do
                            table.insert(el.sortedChildren, child)
                        end
                        table.sort(el.sortedChildren, function(a, b) return a.z < b.z end)
                        el.childrenDirty = false
                    end
                    -- Draw children relative to content area, with scroll offset and clipping
                    local contentX = rx + (el.borderLeft and 1 or 0)
                    local contentY = ry + (el.borderTop  and 1 or 0)
                    local contentH = el.h - (el.borderTop and 1 or 0) - (el.borderBottom and 1 or 0)
                    local contentW = el.w - (el.borderLeft and 1 or 0) - (el.borderRight and 1 or 0)
                    local scrollY  = el.scrollOffset or 0
                    -- compute total content height for scrollbar
                    local maxChildBottom = 0
                    for _, child in pairs(el.children) do
                        local b = child.y + child.h
                        if b > maxChildBottom then maxChildBottom = b end
                    end
                    local needsBar = maxChildBottom > contentH
                    local trackColor = el.config.scrollTrack or "8"
                    local thumbColor = el.config.scrollThumb or el.fore
                    for _, child in ipairs(el.sortedChildren) do
                        if child.visible then
                            local childRY = contentY + child.y - scrollY
                            if childRY + child.h > contentY and childRY < contentY + contentH then
                                drawEl(child, contentX + child.x, childRY,
                                       self.pressedElement, self.focusedElement, rowsToRestore)
                            end
                        end
                    end
                    -- draw scrollbar inside the content area on the last content column
                    if needsBar then
                        local barX = contentX + contentW - 1
                        drawScrollbar(barX, contentY, contentH, scrollY, maxChildBottom, trackColor, thumbColor)
                    end
                else
                    drawEl(el, rx, ry, self.pressedElement, self.focusedElement, rowsToRestore)
                end
            end
        end
    end

    return self
end

return UI