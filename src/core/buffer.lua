-- Obsidian Engine: Buffer Module
-- Instanced double-buffered renderer. Draw into the buffer, call :present()
-- to flush only changed rows to the terminal.

---@diagnostic disable: undefined-global

---@alias BlitChar string A single hex character "0"-"f"
---@alias BlitRow string[] An array of single characters
---@class BufferModule
local buffer = {}

---@class BufferInstance
---@field _w number Current width
---@field _h number Current height
---@field _screenT table<number, BlitRow> Text layers (indexed by Y)
---@field _screenF table<number, BlitRow> Foreground color layers
---@field _screenB table<number, BlitRow> Background color layers
---@field _lastT table<number, string> Cached text strings for diffing
---@field _lastF table<number, string> Cached fore strings for diffing
---@field _lastB table<number, string> Cached back strings for diffing
---@field _dirty table<number, boolean> Flags for rows that changed since last draw
---@field _clipX1 number|nil Clipping boundary
---@field _clipY1 number|nil Clipping boundary
---@field _clipX2 number|nil Clipping boundary
---@field _clipY2 number|nil Clipping boundary
---@field BufferModule BufferModule Reference to the parent module
local Buffer = {}
Buffer.__index = Buffer

-- ─── Constructor ──────────────────────────────────────────────────────────────

--- Create a new Buffer instance.
--- @param width? number Optional width (defaults to terminal width)
--- @param height? number Optional height (defaults to terminal height)
--- @return BufferInstance
function buffer.new(width, height)
    local self = setmetatable({}, Buffer)
    local tw, th = term.getSize()
    self._w = 0
    self._h = 0
    self._screenT = {}
    self._screenF = {}
    self._screenB = {}
    self._lastT = {}
    self._lastF = {}
    self._lastB = {}
    self._dirty = {}
    self._clipX1 = nil
    self._clipY1 = nil
    self._clipX2 = nil
    self._clipY2 = nil
    self.BufferModule = buffer
    self:setSize(width or tw, height or th)
    return self
end

-- ─── Size ─────────────────────────────────────────────────────────────────────

--- Resize the buffer, discarding all content.
--- @param self BufferInstance The buffer instance
--- @param width number New width
--- @param height number New height
function Buffer:setSize(width, height)
    self._w = width
    self._h = height
    self._screenT = {}
    self._screenF = {}
    self._screenB = {}
    self._lastT = {}
    self._lastF = {}
    self._lastB = {}
    self._dirty = {}
    self:clear()
end

--- Returns current width, height.
--- @param self BufferInstance The buffer instance
--- @return number width The buffer width
--- @return number height The buffer height
function Buffer:getSize()
    return self._w, self._h
end

-- ─── Clipping ─────────────────────────────────────────────────────────────────

--- Set the active clipping rectangle for draw operations.
--- @param self BufferInstance The buffer instance
--- @param x1 number|nil Left boundary (inclusive)
--- @param y1 number|nil Top boundary (inclusive)
--- @param x2 number|nil Right boundary (inclusive)
--- @param y2 number|nil Bottom boundary (inclusive)
function Buffer:setClip(x1, y1, x2, y2)
    self._clipX1, self._clipY1, self._clipX2, self._clipY2 = x1, y1, x2, y2
end

--- Clear any active clipping rectangle.
--- @param self BufferInstance The buffer instance
function Buffer:clearClip()
    self._clipX1, self._clipY1, self._clipX2, self._clipY2 = nil, nil, nil, nil
end

-- ─── Clear ────────────────────────────────────────────────────────────────────

--- Fill the buffer with spaces (fore="0", back="f") and invalidate the
-- dirty cache so the next :present() redraws every changed row.
--- @param self BufferInstance The buffer instance
function Buffer:clear()
    local w, h = self._w, self._h
    self._lastT = {}
    self._lastF = {}
    self._lastB = {}
    for y = 1, h do
        self._dirty[y] = true
        local rowT = {}
        local rowF = {}
        local rowB = {}
        for x = 1, w do
            rowT[x] = " "
            rowF[x] = "0"
            rowB[x] = "f"
        end
        self._screenT[y] = rowT
        self._screenF[y] = rowF
        self._screenB[y] = rowB
    end
end

-- ─── Draw Primitives ──────────────────────────────────────────────────────────

--- Write a single-colour full-row line. Faster than drawText for cases
-- where fore and back are uniform across the entire row.
--- @param self BufferInstance The buffer instance
--- @param y number Row number (1-based)
--- @param text string Text to draw (will be padded or truncated to fit)
--- @param fore? BlitChar Blit hex character (default "0")
--- @param back? BlitChar Blit hex character (default "f")
function Buffer:drawLine(y, text, fore, back)
    if y < 1 or y > self._h then return end

    local width = self._w
    local len = #text
    if len < width then
        text = text .. string.rep(" ", width - len)
    elseif len > width then
        text = text:sub(1, width)
    end

    local f    = fore or "0"
    local b    = back or "f"
    self._dirty[y] = true
    local rowT = self._screenT[y]
    local rowF = self._screenF[y]
    local rowB = self._screenB[y]
    for x = 1, width do
        rowT[x] = text:sub(x, x)
        rowF[x] = f
        rowB[x] = b
    end
end

--- Write text at (x, y). fore and back are single blit chars.
--- @param self BufferInstance The buffer instance
--- @param x number Column number (1-based)
--- @param y number Row number (1-based)
--- @param text string Text to draw
--- @param fore? BlitChar Blit hex character (default "0")
--- @param back? BlitChar Blit hex character (default "f")
function Buffer:drawText(x, y, text, fore, back)
    x, y = math.floor(x), math.floor(y)
    local w = self._w
    if y < 1 or y > self._h or not self._screenT[y] then return end
    local clipY1, clipY2 = self._clipY1, self._clipY2
    if clipY1 and (y < clipY1 or y > clipY2) then return end

    self._dirty[y] = true
    local rowT   = self._screenT[y]
    local rowF   = self._screenF[y]
    local rowB   = self._screenB[y]
    local f      = fore or "0"
    local b      = back or "f"
    local clipX1 = self._clipX1
    local clipX2 = self._clipX2

    for i = 1, #text do
        local tx = x + i - 1
        if tx >= 1 and tx <= w then
            if not clipX1 or (tx >= clipX1 and tx <= clipX2) then
                rowT[tx] = text:sub(i, i)
                rowF[tx] = f
                rowB[tx] = b
            end
        end
    end
end

--- Fill a rectangle with a character.
--- @param self BufferInstance The buffer instance
--- @param x number Column number (1-based)
--- @param y number Row number (1-based)
--- @param rectW number Width of the rectangle
--- @param rectH number Height of the rectangle
--- @param char? string Single character to fill the rectangle
--- @param fore? BlitChar Foreground color (default "0")
--- @param back? BlitChar Background color (default "f")
function Buffer:drawRect(x, y, rectW, rectH, char, fore, back)
    x, y         = math.floor(x), math.floor(y)
    rectW, rectH = math.floor(rectW), math.floor(rectH)
    -- Build the fill string once, reuse for every row
    local row = string.rep(char or " ", rectW)
    for i = 0, rectH - 1 do
        local ty = y + i
        if ty >= 1 and ty <= self._h then
            self:drawText(x, ty, row, fore, back)
        end
    end
end

--- Draw a pre-parsed sprite frame at world position (x, y) offset by camera.
-- Transparent cells (char == " ") are skipped.
--- @param self BufferInstance The buffer instance
--- @param frame SpriteFrame Pre-parsed sprite frame with { [1]=Chars, [2]=Fore, [3]=Back }
--- @param x number World X coordinate (1-based)
--- @param y number World Y coordinate (1-based)
--- @param camX? number Camera X offset (default 0)
--- @param camY? number Camera Y offset (default 0)
function Buffer:drawSprite(frame, x, y, camX, camY)
    if not frame or not frame[1] or not frame[2] or not frame[3] then return end

    local sx = math.floor(x - (camX or 0))
    local sy = math.floor(y - (camY or 0))
    local w, h = self._w, self._h

    for i = 1, #frame[1] do
        local ty = sy + i - 1
        if ty >= 1 and ty <= h then
            self._dirty[ty] = true
            local sT = self._screenT[ty]
            local sF = self._screenF[ty]
            local sB = self._screenB[ty]
            local fT = frame[1][i]
            local fF = frame[2][i]
            local fB = frame[3][i]
            local rowLen = #fT
            for charPos = 1, rowLen do
                local tx = sx + charPos - 1
                if tx >= 1 and tx <= w then
                    local c  = fT[charPos]
                    local fc = fF[charPos]
                    local bc = fB[charPos]
                    if c  and c  ~= " " then sT[tx] = c  end
                    if fc and fc ~= " " then sF[tx] = fc end
                    if bc and bc ~= " " then sB[tx] = bc end
                end
            end
        end
    end
end

-- ─── Snapshot / Restore ───────────────────────────────────────────────────────

--- Copy the current screen content into a snapshot table.
--- @param self BufferInstance The buffer instance
--- @param target table Snapshot table with { t, f, b } keys
function Buffer:copyTo(target)
    local width = self._w
    for i = 1, self._h do
        if not target.t[i] then
            target.t[i], target.f[i], target.b[i] = {}, {}, {}
        end
        table.move(self._screenT[i], 1, width, 1, target.t[i])
        table.move(self._screenF[i], 1, width, 1, target.f[i])
        table.move(self._screenB[i], 1, width, 1, target.b[i])
    end
end

--- Restore all rows from a snapshot table.
--- @param self BufferInstance The buffer instance
--- @param source table Snapshot table with { t, f, b } keys
function Buffer:copyFrom(source)
    local width = self._w
    for i = 1, self._h do
        if source.t[i] then
            table.move(source.t[i], 1, width, 1, self._screenT[i])
            table.move(source.f[i], 1, width, 1, self._screenF[i])
            table.move(source.b[i], 1, width, 1, self._screenB[i])
            self._dirty[i] = true
        end
    end
end

--- Restore a single row from a snapshot table.
--- @param self BufferInstance The buffer instance
--- @param y number Row number (1-based)
--- @param source table Snapshot table with { t, f, b } keys
function Buffer:restoreLine(y, source)
    if y < 1 or y > self._h or not source.t[y] then return end
    local width = self._w
    table.move(source.t[y], 1, width, 1, self._screenT[y])
    table.move(source.f[y], 1, width, 1, self._screenF[y])
    table.move(source.b[y], 1, width, 1, self._screenB[y])
    self._dirty[y] = true
end

-- ─── Present ──────────────────────────────────────────────────────────────────

--- Flush changed rows to the terminal (dirty-row diffing).
--- @param self BufferInstance The buffer instance
function Buffer:present()
    for i = 1, self._h do
        if self._dirty[i] then
            local sT = table.concat(self._screenT[i])
            local sF = table.concat(self._screenF[i])
            local sB = table.concat(self._screenB[i])
            if sT ~= self._lastT[i] or sF ~= self._lastF[i] or sB ~= self._lastB[i] then
                term.setCursorPos(1, i)
                term.blit(sT, sF, sB)
                self._lastT[i] = sT
                self._lastF[i] = sF
                self._lastB[i] = sB
            end
            self._dirty[i] = false
        end
    end
end

return buffer