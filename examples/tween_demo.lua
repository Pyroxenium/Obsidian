--- examples/tween_demo.lua
---
--- Demonstrates the Tween module.
---
---   • Jede Zeile zeigt eine Box die mit einem anderen Easing interpoliert
---   • Die Box bewegt sich von links nach rechts (ping-pong)
---   • Unten: eine Box die beim Start eine Sequenz (chain) abläuft
---   • Q — beenden

local Engine = require("../Obsidian/src")
local Tween  = Engine.tween
local buf    = Engine.buffer

local demo = Engine.scene.new()
demo.name  = "TweenDemo"

-- ── Konfiguration ─────────────────────────────────────────────────────────────

local EASINGS = {
    { name = "linear",     fn = Tween.easing.linear     },
    { name = "quadIn",     fn = Tween.easing.quadIn     },
    { name = "quadOut",    fn = Tween.easing.quadOut    },
    { name = "quadInOut",  fn = Tween.easing.quadInOut  },
    { name = "cubicInOut", fn = Tween.easing.cubicInOut },
    { name = "sineOut",    fn = Tween.easing.sineOut    },
    { name = "expoOut",    fn = Tween.easing.expoOut    },
    { name = "elasticOut", fn = Tween.easing.elasticOut },
    { name = "bounceOut",  fn = Tween.easing.bounceOut  },
    { name = "backOut",    fn = Tween.easing.backOut    },
}

local COLORS = { "1","2","3","4","5","6","7","9","a","b","c","d","e" }

local W, H
local LABEL_W  = 12   -- width reserved for name on the left
local TRAVEL   = 0    -- set in onLoad: screen width minus margins
local DURATION = 1.5

-- State: one moving object per easing row
local boxes = {}

-- Chain demo (bottom row): a box that sequences through 3 tweens
local chain = { x = 0, color = "b" }

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function startChain()
    chain.x = LABEL_W + 1
    -- Ensure any existing chain tweens are stopped
    Tween.stop(chain)
    if chain.handle and type(chain.handle.cancel) == "function" then
        pcall(function() chain.handle:cancel() end)
    end

    chain.handle = Tween.to(chain, 0.6, { x = LABEL_W + TRAVEL * 0.5 }, {
        easing = Tween.easing.cubicOut,
        onComplete = function()
            chain.handle = Tween.to(chain, 0.4, { x = LABEL_W + TRAVEL * 0.25 }, {
                easing = Tween.easing.bounceOut,
                onComplete = function()
                    chain.handle = Tween.to(chain, 0.8, { x = LABEL_W + TRAVEL }, {
                        easing = Tween.easing.elasticOut,
                        onComplete = startChain,
                    })
                end
            })
        end
    })
end

-- ── Scene lifecycle ───────────────────────────────────────────────────────────

demo.onLoad = function()
    W, H = buf:getSize()
    TRAVEL = W - LABEL_W - 3

    -- One ping-pong box per easing
    for i, entry in ipairs(EASINGS) do
        local obj = { x = LABEL_W + 1 }
        boxes[i] = { obj = obj, name = entry.name, color = COLORS[((i-1) % #COLORS) + 1] }

        -- Store handle so demo can control the tween via the handle API
        boxes[i].handle = Tween.to(obj, DURATION, { x = LABEL_W + TRAVEL }, {
            easing    = entry.fn,
            pingpong  = true,
            delay     = (i - 1) * 0.08,   -- stagger so they don't all start identically
        })
    end

    startChain()
end

demo.onUpdate = function(dt)
    -- Tween.update is called by the engine; nothing else to update here
end

demo.onDraw = function()
    buf:drawRect(1, 1, W, H, " ", "f", "f")

    -- Title
    buf:drawText(1, 1, "Tween Demo — ping-pong easings          Q=Quit", "7", "f")

    -- Easing rows
    for i, box in ipairs(boxes) do
        local y = i + 2
        -- Label
        buf:drawText(1, y, string.format("%-11s", box.name), "8", "f")
        -- Track
        buf:drawText(LABEL_W + 1, y, string.rep("-", TRAVEL), "0", "f")
        -- Box
        local bx = math.floor(box.obj.x + 0.5)
        buf:drawText(bx, y, "\x07", box.color, "f")
    end

    -- Chain row label + track
    local chainY = #EASINGS + 4
    buf:drawText(1, chainY - 1, "chain:", "7", "f")
    buf:drawText(LABEL_W + 1, chainY, string.rep("-", TRAVEL), "0", "f")
    local cx = math.floor(chain.x + 0.5)
    buf:drawText(cx, chainY, "\x07", chain.color, "f")
    buf:drawText(1, chainY, string.format("%-11s", "sequence"), "8", "f")

    -- Footer
    buf:drawText(1, H, "Q=Quit", "8", "f")
end

demo.onEvent = function(event)
    local etype = event[1]
    Engine.input.processEvent(etype, event[2], event[3], event[4])
    if etype == "key" and event[2] == keys.q then
        error("quit")
    end
end

demo.onUnload = function()
    -- Cancel individual tweens via handles if present
    for _, b in ipairs(boxes) do
        if b and b.handle and type(b.handle.cancel) == "function" then
            pcall(function() b.handle:cancel() end)
        end
    end
    if chain and chain.handle and type(chain.handle.cancel) == "function" then
        pcall(function() chain.handle:cancel() end)
    end

    -- Fallback: ensure any remaining tweens are stopped
    Tween.stopAll()
    boxes = {}
end

-- ── Boot ──────────────────────────────────────────────────────────────────────

Engine.setScene(demo)
Engine.start()
