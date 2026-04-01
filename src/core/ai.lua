local ai = {}

function ai.createBrain(definition, initialState)
    return {
        definition = definition,
        state = initialState,
        timer = 0,
        firstRun = true,
        memory = {}
    }
end

function ai.canSee(id, targetId, scene, maxDist, layerMask)
    local pos = scene.components.pos[id]
    local tPos = scene.components.pos[targetId]
    if not pos or not tPos then return false end

    if maxDist and pos:dist(tPos) > maxDist then return false end

    local hit, hx, hy, hitId = scene:castRay(pos.x, pos.y, tPos.x, tPos.y, maxDist or 100, id, layerMask)
    return (not hit) or (hitId == targetId)
end

function ai.system(scene)
    return function(dt, ids, components)
        local brains = components.brain
        if not brains then return end

        for _, id in ipairs(ids) do
            local brain = brains[id]
            local stateDef = brain.definition[brain.state]

            if stateDef then
                if brain.firstRun then
                    brain.firstRun = false
                    if stateDef.onEnter then stateDef.onEnter(id, brain, scene) end
                end

                brain.timer = brain.timer + dt

                if stateDef.onUpdate then
                    local nextState = stateDef.onUpdate(id, dt, brain, scene)

                    if nextState and nextState ~= brain.state then
                        if stateDef.onExit then stateDef.onExit(id, brain, scene) end

                        local oldState = brain.state
                        brain.previousState = oldState
                        brain.state = nextState
                        brain.timer = 0

                        local newStateDef = brain.definition[nextState]
                        if newStateDef and newStateDef.onEnter then
                            newStateDef.onEnter(id, brain, scene, oldState)
                        end
                    end
                end
            end
        end
    end
end

return ai