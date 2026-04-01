local Buffer = {}
local w, h = 0, 0

local screenT, screenF, screenB = {}, {}, {}
local lastT, lastF, lastB = {}, {}, {}

function Buffer.clear()
    for i = 1, h do
        if not screenT[i] then
            screenT[i], screenF[i], screenB[i] = {}, {}, {}
            lastT[i], lastF[i], lastB[i] = "", "", ""
        end

        for x = 1, w do
            screenT[i][x] = " "
            screenF[i][x] = "0"
            screenB[i][x] = "f"
        end
    end
end

function Buffer.setSize(newW, newH)
    w, h = newW, newH
    screenT, screenF, screenB = {}, {}, {}
    lastT, lastF, lastB = {}, {}, {}
    Buffer.clear()
end

function Buffer.getSize()
    return w, h
end

function Buffer.copyTo(target)
    for i = 1, h do
        if not target.t[i] then 
            target.t[i], target.f[i], target.b[i] = {}, {}, {}
        end
        table.move(screenT[i], 1, w, 1, target.t[i])
        table.move(screenF[i], 1, w, 1, target.f[i])
        table.move(screenB[i], 1, w, 1, target.b[i])
    end
end

function Buffer.restoreLine(y, source)
    if y < 1 or y > h or not source.t[y] then return end
    table.move(source.t[y], 1, w, 1, screenT[y])
    table.move(source.f[y], 1, w, 1, screenF[y])
    table.move(source.b[y], 1, w, 1, screenB[y])
end

function Buffer.copyFrom(source)
    for i = 1, h do
        if source.t[i] then
            table.move(source.t[i], 1, w, 1, screenT[i])
            table.move(source.f[i], 1, w, 1, screenF[i])
            table.move(source.b[i], 1, w, 1, screenB[i])
        end
    end
end

function Buffer.drawRect(x, y, rectW, rectH, char, fore, back)
    x, y, rectW, rectH = math.floor(x), math.floor(y), math.floor(rectW), math.floor(rectH)
    for i = 0, rectH - 1 do
        local targetY = y + i
        if targetY >= 1 and targetY <= h then
            Buffer.drawText(x, targetY, string.rep(char or " ", rectW), fore, back)
        end
    end
end

function Buffer.drawText(x, y, text, fore, back)
    x, y = math.floor(x), math.floor(y)
    if y < 1 or y > h or not screenT[y] then return end

    for i = 1, #text do
        local targetX = x + i - 1
        if targetX >= 1 and targetX <= w then
            screenT[y][targetX] = text:sub(i, i)
            screenF[y][targetX] = fore or "0"
            screenB[y][targetX] = back or "f"
        end
    end
end

function Buffer.drawSprite(frame, x, y, camX, camY)
    if not frame or not frame[1] or not frame[2] or not frame[3] then return end

    local sx = math.floor(x - (camX or 0))
    local sy = math.floor(y - (camY or 0))
    local rows = #frame[1]

    for i = 1, rows do
        local targetY = sy + i - 1
        if targetY >= 1 and targetY <= h then
            local rowT, rowF, rowB = frame[1][i], frame[2][i], frame[3][i]
            local rowLen = #rowT

            for charPos = 1, rowLen do
                local targetX = sx + charPos - 1
                if targetX >= 1 and targetX <= w then
                    local char = rowT[charPos]
                    local fore = rowF[charPos]
                    local back = rowB[charPos]

                    if char and char ~= " " then 
                        screenT[targetY][targetX] = char
                    end
                    if fore and fore ~= " " then 
                        screenF[targetY][targetX] = fore
                    end
                    if back and back ~= " " then 
                        screenB[targetY][targetX] = back
                    end
                end
            end
        end
    end
end

function Buffer.present()
    for i = 1, h do
        local sT = table.concat(screenT[i])
        local sF = table.concat(screenF[i])
        local sB = table.concat(screenB[i])

        if sT ~= lastT[i] or sF ~= lastF[i] or sB ~= lastB[i] then
            term.setCursorPos(1, i)
            term.blit(sT, sF, sB)
            lastT[i], lastF[i], lastB[i] = sT, sF, sB
        end
    end
end

local tw, th = term.getSize()
Buffer.setSize(tw, th)

return Buffer