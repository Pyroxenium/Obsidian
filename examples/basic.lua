-- A small Obsidian starter project.
-- Put obsidian.lua next to this file, then run it in CraftOS.

local Engine = require("obsidian")
local game = Engine.scene.new()
local player

game.name = "My first Obsidian game"

local function sprite(character, foreground, background)
    return {
        width = 1,
        height = 1,
        [1] = {
            { { character } },
            { { foreground or "0" } },
            { { background or "f" } },
        },
    }
end

game.onLoad = function()
    local width, height = Engine.buffer:getSize()

    player = game:spawn()
    game:attach(player, "pos", Engine.math.vec2(
        math.floor(width / 2),
        math.floor(height / 2)
    ))
    game:attach(player, "sprite", sprite("@", "9", "f"))

    game.ui:text("title", 2, 2, {
        text = "My first Obsidian game",
        fore = "a",
        back = "f",
        z = 100,
    })
    game.ui:text("help", 2, height, {
        text = "Arrow keys / WASD to move - Q to quit",
        fore = "8",
        back = "f",
        z = 100,
    })
end

game.onEvent = function(event)
    if event[1] ~= "key" then return end

    local pos = game:get(player, "pos")
    local key = event[2]

    if key == keys.left or key == keys.a then
        pos.x = pos.x - 1
    elseif key == keys.right or key == keys.d then
        pos.x = pos.x + 1
    elseif key == keys.up or key == keys.w then
        pos.y = pos.y - 1
    elseif key == keys.down or key == keys.s then
        pos.y = pos.y + 1
    elseif key == keys.q then
        Engine.stop()
    end
end

Engine.setScene(game)
Engine.start()
