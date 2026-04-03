--- Obsidian Camera
-- Instanced 2-D camera. Wraps scene.camera (the vec2 the engine reads for world offset).
--
-- Usage:
--   local cam = Engine.camera.new(scene)
--   cam:follow(playerId, { lerp = 0.12, deadzone = { w = 6, h = 3 } })
--   cam:setBounds(0, 0, worldPixelW, worldPixelH)
--   -- inside scene onUpdate:
--   cam:update(dt)

local camera = {}
camera.__index = camera

local buffer = require("core.buffer")
local debug  = require("core.debug")

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

--- Create a new camera bound to a scene.
--- @param scene  table  The scene whose .camera vec2 will be driven
--- @return Camera instance
function camera.new(scene)
    assert(scene and scene.camera, "camera.new: scene must have a .camera vec2")
    local self = setmetatable({}, camera)

    self._scene       = scene

    -- Target world position the camera wants to reach
    self._targetX     = scene.camera.x
    self._targetY     = scene.camera.y

    -- Lerp factor (0 = instant snap, 1 = never moves; typical: 0.08-0.15)
    self.lerpFactor   = 0.1

    -- Entity to follow (id + component name)
    self._followId    = nil
    self._followComp  = "pos"

    -- Deadzone (in world/character units).  Camera only moves when the target
    -- leaves this rectangle centred on the current camera centre.
    self._deadzone    = nil   -- { w, h } or nil

    -- World bounds clamping  (nil = unlimited)
    self._boundsX1    = nil
    self._boundsY1    = nil
    self._boundsX2    = nil
    self._boundsY2    = nil

    -- Offset applied on top of the followed position (for leading the camera)
    self.offsetX      = 0
    self.offsetY      = 0

    return self
end

-- ---------------------------------------------------------------------------
-- Configuration
-- ---------------------------------------------------------------------------

--- Follow an entity by its id.
--- @param id    any     Entity id (must have a `pos` component or the component named via `comp`)
--- @param opts  table|nil
---   opts.lerp     number   0-1 smoothing factor (default uses camera.lerpFactor)
---   opts.deadzone table    { w=number, h=number }  in world units
---   opts.comp     string   Component name that holds {x,y} (default "pos")
function camera:follow(id, opts)
    opts = opts or {}
    self._followId   = id
    self._followComp = opts.comp or "pos"
    if opts.lerp    ~= nil then self.lerpFactor = opts.lerp end
    if opts.deadzone       then self._deadzone  = opts.deadzone end
end

--- Stop following any entity.
function camera:unfollow()
    self._followId = nil
end

--- Clamp the camera so it never shows world area outside the given rectangle.
--- Pass nil values to remove clamping.
--- @param x1  number  Left bound in world units
--- @param y1  number  Top bound in world units
--- @param x2  number  Right bound in world units  (set to worldW - viewW for pixel-perfect)
--- @param y2  number  Bottom bound in world units
function camera:setBounds(x1, y1, x2, y2)
    self._boundsX1 = x1
    self._boundsY1 = y1
    self._boundsX2 = x2
    self._boundsY2 = y2
end

--- Remove world bounds.
function camera:clearBounds()
    self._boundsX1, self._boundsY1 = nil, nil
    self._boundsX2, self._boundsY2 = nil, nil
end

--- Set a camera lead offset (useful for making the camera look ahead of movement).
--- @param ox  number  Horizontal offset in world units
--- @param oy  number  Vertical offset in world units
function camera:setOffset(ox, oy)
    self.offsetX = ox or 0
    self.offsetY = oy or 0
end

-- ---------------------------------------------------------------------------
-- Immediate positioning
-- ---------------------------------------------------------------------------

--- Snap the camera to an exact world position (no lerp this frame).
--- @param wx  number  World X
--- @param wy  number  World Y
function camera:moveTo(wx, wy)
    self._targetX = wx + self.offsetX
    self._targetY = wy + self.offsetY
    self:_applyBounds()
    self._scene.camera.x = self._targetX
    self._scene.camera.y = self._targetY
end

--- Pan by a delta (adds to the current target position).
--- @param dx  number
--- @param dy  number
function camera:pan(dx, dy)
    self._targetX = self._targetX + (dx or 0)
    self._targetY = self._targetY + (dy or 0)
    self:_applyBounds()
    self._scene.camera.x = self._targetX
    self._scene.camera.y = self._targetY
end

-- ---------------------------------------------------------------------------
-- Per-frame update  (call inside scene:onUpdate or similar)
-- ---------------------------------------------------------------------------

--- Advance the camera each frame.
--- Reads the followed entity's pos, evaluates the deadzone, lerps, clamps to
--- bounds, and writes the result into scene.camera.
--- @param dt  number  Delta time in seconds
function camera:update(dt)
    local scene = self._scene

    -- Determine desired target from followed entity
    if self._followId then
        local comp = scene.components[self._followComp]
        local pos  = comp and comp[self._followId]
        if pos then
            local desiredX = pos.x + self.offsetX
            local desiredY = pos.y + self.offsetY

            -- Deadzone: only shift the target when entity left the deadzone rect
            if self._deadzone then
                local hw = self._deadzone.w * 0.5
                local hh = self._deadzone.h * 0.5
                local cx = self._targetX
                local cy = self._targetY
                if desiredX < cx - hw then
                    self._targetX = desiredX + hw
                elseif desiredX > cx + hw then
                    self._targetX = desiredX - hw
                end
                if desiredY < cy - hh then
                    self._targetY = desiredY + hh
                elseif desiredY > cy + hh then
                    self._targetY = desiredY - hh
                end
            else
                self._targetX = desiredX
                self._targetY = desiredY
            end
        end
    end

    -- Clamp target to bounds before lerping
    self:_applyBounds()

    -- Lerp scene.camera toward target
    local f = math.min(1, self.lerpFactor * (dt * 60))  -- frame-rate independent
    scene.camera.x = scene.camera.x + (self._targetX - scene.camera.x) * f
    scene.camera.y = scene.camera.y + (self._targetY - scene.camera.y) * f
end

-- ---------------------------------------------------------------------------
-- Coordinate helpers
-- ---------------------------------------------------------------------------

--- Convert a world position to screen (terminal character) position.
--- Accounts for the current camera and the engine's design-resolution letterbox offset.
--- @param wx  number  World X
--- @param wy  number  World Y
--- @return sx number, sy number  1-based screen character position
function camera:worldToScreen(wx, wy)
    local scene      = self._scene
    local termW, termH = buffer.getSize()
    local designW, designH = debug.designW, debug.designH
    local offsetX, offsetY = 0, 0
    if designW and designH then
        offsetX = math.max(0, math.floor((termW - designW) / 2))
        offsetY = math.max(0, math.floor((termH - designH) / 2))
    end
    local sx = math.floor(wx - scene.camera.x + offsetX) + 1
    local sy = math.floor(wy - scene.camera.y + offsetY) + 1
    return sx, sy
end

--- Convert a screen (terminal) position back to world coordinates.
--- @param sx  number  1-based screen X
--- @param sy  number  1-based screen Y
--- @return wx number, wy number
function camera:screenToWorld(sx, sy)
    local scene      = self._scene
    local termW, termH = buffer.getSize()
    local designW, designH = debug.designW, debug.designH
    local offsetX, offsetY = 0, 0
    if designW and designH then
        offsetX = math.max(0, math.floor((termW - designW) / 2))
        offsetY = math.max(0, math.floor((termH - designH) / 2))
    end
    local wx = (sx - 1) + scene.camera.x - offsetX
    local wy = (sy - 1) + scene.camera.y - offsetY
    return wx, wy
end

--- Read the camera's current world position (what the top-left corner maps to).
--- @return x number, y number
function camera:getPosition()
    return self._scene.camera.x, self._scene.camera.y
end

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

function camera:_applyBounds()
    if self._boundsX1 ~= nil and self._targetX < self._boundsX1 then
        self._targetX = self._boundsX1
    end
    if self._boundsY1 ~= nil and self._targetY < self._boundsY1 then
        self._targetY = self._boundsY1
    end
    if self._boundsX2 ~= nil and self._targetX > self._boundsX2 then
        self._targetX = self._boundsX2
    end
    if self._boundsY2 ~= nil and self._targetY > self._boundsY2 then
        self._targetY = self._boundsY2
    end
end

-- Module-level factory
return camera
