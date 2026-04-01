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

    -- Fields that live directly on the element table (not in config)
    local ELEMENT_FIELDS = {
        x=true, y=true, z=true, w=true, h=true,
        visible=true, sprite=true, disabled=true,
        fore=true, back=true, borderColor=true, anchor=true, interactive=true,
        borderTop=true, borderBottom=true, borderLeft=true, borderRight=true,
    }
    local DIRTY_FIELDS = { z=true, sprite=true, w=true, h=true }

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
        if     el.anchor == "top-left"     then -- default, rx/ry already set
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
            for i = #self.sorted, 1, -1 do
                local el = self.sorted[i]
                if el.visible then
                    local ex, ey = self:getAbsolutePos(el, ox, oy)
                    local elH = (el.type == "dropdown" and el.isOpen and el.config.options)
                                and (el.h + #el.config.options) or el.h
                    if mx >= ex and mx < ex + el.w and my >= ey and my < ey + elH then
                        hit = el
                        break
                    end
                end
            end

            if eventType == "mouse_click" then
                self.focusedElement = (hit and hit.type == "input") and hit or nil
                -- Close any open dropdown unless we clicked on it
                for _, el in pairs(self.elements) do
                    if el.type == "dropdown" and el ~= hit then el.isOpen = false end
                end
                if hit and hit.interactive and not hit.disabled then
                    if hit.type == "checkbox" then
                        hit.config.checked = not hit.config.checked
                        if hit.config.onChanged then hit.config.onChanged(hit.config.checked) end
                        return true
                    end

                    if hit.type == "dropdown" then
                        if hit.isOpen then
                            local hx, hy = self:getAbsolutePos(hit, ox, oy)
                            local relY = my - hy - hit.h
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

                    self.pressedElement = hit
                    return true
                end
            end
        elseif eventType == "mouse_up" then
            local button, mx, my = event[2], event[3], event[4]
            if self.pressedElement then
                local el = self.pressedElement
                local ex, ey = self:getAbsolutePos(el, ox, oy)

                if mx >= ex and mx < ex + el.w and my >= ey and my < ey + el.h then
                    if el.type == "button" and el.config.onClick then
                        el.config.onClick(button)
                    end
                end
                self.pressedElement = nil
                return true
            end
        elseif eventType == "char" then
            if self.focusedElement and self.focusedElement.type == "input" then
                local el = self.focusedElement
                el.config.text = (el.config.text or "") .. event[2]
                if el.config.onChange then el.config.onChange(el.config.text) end
                return true -- Konsumiert das Zeichen
            end
        elseif eventType == "key" then
            if self.focusedElement and self.focusedElement.type == "input" then
                local el = self.focusedElement
                local key = event[2]
                if key == keys.backspace then
                    el.config.text = (el.config.text or ""):sub(1, -2)
                    if el.config.onChange then el.config.onChange(el.config.text) end
                elseif key == keys.enter then
                    self.focusedElement = nil -- Fokus verlieren bei Enter
                    if el.config.onConfirm then el.config.onConfirm(el.config.text) end
                end
                return true -- Konsumiert den Tastendruck
            end
        end
        return false
    end

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
                    local isPressed = (self.pressedElement == el)
                    local isFocused = (self.focusedElement == el)

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
                        -- Halbblock (\149 = links gefüllt) für doppelte Auflösung
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

                    if el.borderTop and el.borderLeft then buffer.drawText(rx, ry, "\151", bc, bg) end
                    if el.borderTop and el.borderRight then buffer.drawText(rx + el.w - 1, ry, "\148", bg, bc) end
                    if el.borderBottom and el.borderLeft then buffer.drawText(rx, ry + el.h - 1, "\138", bg, bc) end
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
                end
            end
        end
    end

    return self
end

return UI