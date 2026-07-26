--- examples/ecs_example.lua
--- Simple ECS example demonstrating `Engine.ecs` (World)

local Engine = require("../Obsidian/src")
local World  = Engine.ecs
Engine.showDebug(true)

local demo = Engine.scene.new()
demo.name = "ECS Example"

-- Use the scene instance as the world so the engine's debug overlay
-- and rendering pipeline reflect these entities.
local world = demo
local buf = Engine.buffer
local hook_spawn_s, hook_combo_clear, hook_q, hook_space, hook_c, hud_bind

local function spawnEntity(x, y, vx, vy, label)
	local id = world:spawn()
	world:attach(id, "pos", { x = x, y = y })
	world:attach(id, "vel", { x = vx or 0, y = vy or 0 })
	-- Minimal 1x1 sprite so Scene can render and count the entity as dynamic
	local ch = (label or "*")
	local frame = {
		{ { ch } }, -- chars (rows)
		{ { "f" } }, -- foreground color per cell
		{ { "0" } }  -- background color per cell
	}
	world:attach(id, "sprite", { width = 1, height = 1, [1] = frame })
	Engine.logger.info("ECS: Spawned entity " .. tostring(id))
	return id
end

demo.onLoad = function()
	-- Seed randomness and spawn some initial entities
	if os.epoch then math.randomseed(os.epoch("utc") % 100000) end

	local W, H = buf:getSize()
	for i = 1, 8 do
		local x = math.random(2, W - 1)
		local y = math.random(2, H - 2)
		local vx = (math.random() * 2 - 1) * 6
		local vy = (math.random() * 2 - 1) * 6
		spawnEntity(x, y, vx, vy, "*")
	end

	-- Add HUD as a UI text element so it uses the scene's UI system
	demo.ui:text("hud", 2, H, { text = "", z = 500 })

	-- Official HUD binding: update UI outside of ECS systems
	hud_bind = demo:bindHUD("hud", function(scene, dt)
		local stats = world:stats()
		scene.ui:update("hud", { text = string.format("Entities: %d  Space=Spawn  C=Clear  Q=Quit", stats.entities) })
	end)

	-- Example: register key and combo hooks using the Input hook API
	-- Press `s` to spawn a special entity labeled 'S'
	hook_spawn_s = Engine.input.onKey("s", function()
		local W, H = buf:getSize()
		spawnEntity(math.random(2, W - 1), math.random(2, H - 2), (math.random() * 2 - 1) * 8, (math.random() * 2 - 1) * 8, "S")
	end, { repeatable = true, repeatDelay = 0.4, repeatInterval = 0 })

	-- Combo: press Space + C simultaneously to clear the world
	hook_combo_clear = Engine.input.onCombo({ keys.space, keys.c }, function()
		world:clear()
		Engine.logger.info("ECS: Cleared via combo (Space+C)")
	end)

	-- Register simple key hooks: q=quit, space=spawn, c=clear
	hook_q = Engine.input.onKey("q", function() error("quit") end)
	hook_space = Engine.input.onKey("space", function()
		local W, H = buf:getSize()
		spawnEntity(math.random(2, W - 1), math.random(2, H - 2), (math.random() * 2 - 1) * 8, (math.random() * 2 - 1) * 8, "*")
	end, { repeatable = true, repeatDelay = 0.5, repeatInterval = 0 })
	hook_c = Engine.input.onKey("c", function()
		world:clear()
		Engine.logger.info("ECS: World cleared")
	end)

	-- Clean up hooks/UI on scene unload (no need to override onUnload)
	demo.event:once("unload", function()
		world:clear()
		if hook_spawn_s then Engine.input.offKey(hook_spawn_s) end
		if hook_combo_clear then Engine.input.offCombo(hook_combo_clear) end
		if hook_q then Engine.input.offKey(hook_q) end
		if hook_space then Engine.input.offKey(hook_space) end
		if hook_c then Engine.input.offKey(hook_c) end
		if hud_bind then demo:unbindHUD(hud_bind) end
	end)

end
-- Physics system: integrate velocity into position
demo:addSystem({"pos", "vel"}, function(dt, entities, comps)
	for _, id in ipairs(entities) do
		local p = comps.pos[id]
		local v = comps.vel[id]
		if p and v then
			p.x = p.x + v.x * dt
			p.y = p.y + v.y * dt

			-- Wrap around the viewport
			local W, H = buf:getSize()
			if p.x < 1 then p.x = W end
			if p.x > W then p.x = 1 end
			if p.y < 1 then p.y = H - 1 end
			if p.y > H - 1 then p.y = 1 end
		end
	end
end)

-- HUD update system: refresh UI text each frame
-- (HUD is now updated via Scene:bindHUD and not via an ECS system)

-- Input system: poll `Engine.input` to handle key presses (avoids onEvent hook)
-- Input handled via `Engine.input` hooks (registered in demo.onLoad)



Engine.setScene(demo)
Engine.start()

