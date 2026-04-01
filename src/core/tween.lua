local tween = {
    activeTweens = {},
    easing = {}
}

tween.easing.linear = function(t) return t end
tween.easing.quadIn = function(t) return t * t end
tween.easing.quadOut = function(t) return t * (2 - t) end
tween.easing.quadInOut = function(t)
    return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end

tween.easing.sineIn = function(t) return 1 - math.cos((t * math.pi) / 2) end
tween.easing.sineOut = function(t) return math.sin((t * math.pi) / 2) end
tween.easing.backOut = function(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

function tween.to(target, duration, properties, easingFunc, onComplete)
    local opt = type(easingFunc) == "table" and easingFunc or { easing = easingFunc, onComplete = onComplete }

    local t = {
        target = target,
        duration = math.max(0.001, duration),
        elapsed = 0,
        startValues = {},
        endValues = properties,
        easing = opt.easing or tween.easing.linear,
        onComplete = opt.onComplete,
        delay = opt.delay or 0,
        loop = opt.loop or false,
        pingpong = opt.pingpong or false,
        isReversing = false,
        id = {}
    }

    for k, v in pairs(properties) do
        if type(target[k]) == "number" then
            t.startValues[k] = target[k]
        end
    end

    table.insert(tween.activeTweens, t)
    return t.id
end

function tween.stop(target)
    for i = #tween.activeTweens, 1, -1 do
        if tween.activeTweens[i].target == target then
            table.remove(tween.activeTweens, i)
        end
    end
end

function tween.cancel(id)
    for i = #tween.activeTweens, 1, -1 do
        if tween.activeTweens[i].id == id then
            table.remove(tween.activeTweens, i)
            return
        end
    end
end

function tween.update(dt)
    for i = #tween.activeTweens, 1, -1 do
        local t = tween.activeTweens[i]
        t.elapsed = t.elapsed + dt

        local effectiveElapsed = t.elapsed - t.delay
        if effectiveElapsed < 0 then goto continue end

        local progress = math.min(1, effectiveElapsed / t.duration)
        local alpha = t.easing(progress)

        for k, v in pairs(t.endValues) do
            if t.startValues[k] then
                t.target[k] = t.startValues[k] + (v - t.startValues[k]) * alpha
            end
        end

        if progress >= 1 then
            if t.pingpong then
                for k, v in pairs(t.endValues) do
                    local start = t.startValues[k]
                    t.startValues[k] = v
                    t.endValues[k] = start
                end
                t.elapsed = t.delay
                t.isReversing = not t.isReversing
            elseif t.loop then
                t.elapsed = t.delay
            else
                local callback = t.onComplete
                table.remove(tween.activeTweens, i)
                if callback then callback() end
            end
        end
        ::continue::
    end
end

function tween.stopAll()
    tween.activeTweens = {}
end

return tween