local Engine = require("../Obsidian/src")
local math = Engine.math
local Vec2 = math.vec2


print("Vec2:", Vec2 * Vec2_2) -- Vec2: (4, 6)

local network = Engine.network
network.onMessage(function(senderID, message, protocol)
    print("Received message from " .. tostring(senderID) .. ": " .. tostring(message))
end)

local particle = Engine.particles
local emitter = particle.createEmitter({
    spawnRate = 5,
    speedMin = 1,
    speedMax = 3,
    lifeMin = 2,
    lifeMax = 4,
    chars = {"*"},
    colors = {math.color(255, 0, 0)},
    bounce = true
})

local pathfinding = Engine.pathfinding
local scene = Engine.scene.new()
pathfinding.findPath(scene, Vec2(1, 1), Vec2(10, 10))

local physics = Engine.physics
local body = physics.createBody()
physics.system(scene, 4)

local scene = Engine.scene
local new = scene.new()
new:select("pos", "sprite")

local thread = Engine.thread
local t = thread.start(function()
    while true do
        print("Thread running...")
        thread.yield(1) -- Yield for 1 second
    end
end)

local tilemap = Engine.tilemap
local map = tilemap.new()
