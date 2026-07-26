--- examples/ai_demo.lua
--- Minimal AI demo using `ai.Brain` and `ai.system`

local Engine = require("../Obsidian/src")
local ai = Engine.ai

Engine.showDebug(true)

local demo = Engine.scene.new()
demo.name = "AI Demo"

local buf = Engine.buffer

local function makeSprite(ch, fg, bg)
    local frame = { { { ch } }, { { fg or "7" } }, { { bg or "0" } } }
    return { width = 1, height = 1, [1] = frame }
end

demo.onLoad = function()
    local W, H = buf:getSize()
    if os.epoch then math.randomseed(os.epoch("utc") % 100000) end

    -- Spawn a player entity
    local player = demo:spawn()
    demo:attach(player, "pos", { x = math.floor(W/2), y = math.floor(H/2) })
    demo:attach(player, "sprite", makeSprite("@", "e", "0"))

    -- Spawn an NPC with a Brain
    local npc = demo:spawn()
    demo:attach(npc, "pos", { x = math.floor(W/2) - 10, y = math.floor(H/2) })
    demo:attach(npc, "sprite", makeSprite("n", "a", "0"))

    -- Define simple states: idle <-> patrol <-> chase
    local states = {
        idle = {
            onEnter = function(self, prev)
                Engine.logger.info("NPC: enter idle")
            end,
            onUpdate = function(self, dt)
                -- If player seen, switch to chase
                if ai.canSee(self.id, player, self.scene, 12) then
                    return "chase"
                end
                if self:timeInState() > 2 then
                    return "patrol"
                end
            end,
        },
        patrol = {
            onEnter = function(self, prev)
                Engine.logger.info("NPC: enter patrol")
                -- Demonstrate per-state repeating timer
                self:every(1, function(br) Engine.logger.info(string.format("NPC patrolling (t=%.2f)", br:timeInState())) end)
            end,
            onUpdate = function(self, dt)
                local pos = self.scene.components.pos[self.id]
                if pos then
                    pos.x = pos.x + (math.random() * 2 - 1) * 0.6
                    pos.y = pos.y + (math.random() * 2 - 1) * 0.2
                end
                -- If player seen, switch to chase
                if ai.canSee(self.id, player, self.scene, 12) then
                    return "chase"
                end
                if self:timeInState() > 3 then
                    return "idle"
                end
            end,
        },
        chase = {
            onEnter = function(self, prev)
                Engine.logger.info("NPC: enter chase")
            end,
            onUpdate = function(self, dt)
                local scene = self.scene
                local pos = scene.components.pos[self.id]
                local ppos = scene.components.pos[player]
                if not pos or not ppos then return "idle" end
                -- Move towards player
                local dx = ppos.x - pos.x
                local dy = ppos.y - pos.y
                local dist = math.sqrt((dx*dx) + (dy*dy))
                local speed = 6 -- world units/sec
                if dist > 0 then
                    pos.x = pos.x + (dx / dist) * speed * dt
                    pos.y = pos.y + (dy / dist) * speed * dt
                end
                -- Lose sight -> back to idle
                if not ai.canSee(self.id, player, scene, 14) then
                    return "idle"
                end
            end,
        },
    }

    demo:attach(npc, "brain", ai.Brain.new(states, "idle"))

    -- Register the AI system so all Brain components are updated each frame
    demo:addSystem({"brain"}, ai.system(demo))

    -- Simple HUD showing brain states
    demo.ui:text("ai_hud", 2, H, { text = "", z = 500 })
    local hud_bind = demo:bindHUD("ai_hud", function(scene, dt)
        local out = ""
        for id, br in pairs(scene.components.brain or {}) do
            out = out .. string.format("Ent %d: state=%s time=%.2f\n", id, tostring(br.current), br:timeInState())
        end
        scene.ui:update("ai_hud", { text = out })
    end)

    -- Basic controls: move player with A/D, quit with Q
    local hook_a = Engine.input.onKey("a", function()
        local p = demo.components.pos[player]
        if p then p.x = p.x - 1 end
    end, { repeatable = true, repeatDelay = 0.08, repeatInterval = 0.02 })

    local hook_d = Engine.input.onKey("d", function()
        local p = demo.components.pos[player]
        if p then p.x = p.x + 1 end
    end, { repeatable = true, repeatDelay = 0.08, repeatInterval = 0.02 })

    local hook_q = Engine.input.onKey("q", function() error("quit") end)

    -- Cleanup on scene unload
    demo.event:once("unload", function()
        if hook_a then Engine.input.offKey(hook_a) end
        if hook_d then Engine.input.offKey(hook_d) end
        if hook_q then Engine.input.offKey(hook_q) end
        if hud_bind then demo:unbindHUD(hud_bind) end
    end)
end

Engine.setScene(demo)
Engine.start()
