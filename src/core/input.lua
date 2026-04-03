local input = {
    keysDown         = {},
    keysDownPrevious = {},
    mouseDown         = {},
    mouseDownPrevious = {},
    mouseX = 0,
    mouseY = 0
}

function input._update(event, p1, p2, p3)
    if event == "key" then
        input.keysDown[p1] = true
    elseif event == "key_up" then
        input.keysDown[p1] = false

    elseif event == "mouse_click" or event == "mouse_drag" then
        input.mouseDown[p1] = true
        input.mouseX = p2
        input.mouseY = p3
    elseif event == "mouse_up" then
        input.mouseDown[p1] = false
        input.mouseX = p2
        input.mouseY = p3

    elseif event == "mouse_scroll" then
        input.mouseX = p2
        input.mouseY = p3
    elseif event == "mouse_move" then
        input.mouseX = p1
        input.mouseY = p2
    end
end

function input._endFrame()
    for k, v in pairs(input.keysDown)  do input.keysDownPrevious[k]  = v end
    for k, v in pairs(input.mouseDown) do input.mouseDownPrevious[k] = v end
    for k in pairs(input.keysDownPrevious) do
        if not input.keysDown[k] then input.keysDownPrevious[k] = nil end
    end
    for k in pairs(input.mouseDownPrevious) do
        if not input.mouseDown[k] then input.mouseDownPrevious[k] = nil end
    end
end

function input.clear()
    input.keysDown         = {}
    input.keysDownPrevious = {}
    input.mouseDown         = {}
    input.mouseDownPrevious = {}
end

function input.isKeyDown(key)
    if type(key) == "string" then key = keys[key] end
    return input.keysDown[key] == true
end

function input.isJustPressed(key)
    if type(key) == "string" then key = keys[key] end
    return input.keysDown[key] == true and not (input.keysDownPrevious[key] == true)
end

function input.isJustReleased(key)
    if type(key) == "string" then key = keys[key] end
    return not (input.keysDown[key] == true) and input.keysDownPrevious[key] == true
end

function input.isMouseDown(button)
    return input.mouseDown[button] == true
end

function input.isMouseJustPressed(button)
    return input.mouseDown[button] == true and not (input.mouseDownPrevious[button] == true)
end

function input.isMouseJustReleased(button)
    return not (input.mouseDown[button] == true) and input.mouseDownPrevious[button] == true
end

function input.getMousePos()
    return input.mouseX, input.mouseY
end

return input