local mathUtils = require("core.math")

local Pathfinding = {}

local function createHeap()
    local heap = {}
    function heap:push(node, priority)
        table.insert(self, {node = node, priority = priority})
        local idx = #self
        while idx > 1 do
            local parent = math.floor(idx / 2)
            if self[idx].priority < self[parent].priority then
                self[idx], self[parent] = self[parent], self[idx]
                idx = parent
            else break end
        end
    end
    function heap:pop()
        if #self == 0 then return nil end
        local root = self[1]
        self[1] = self[#self]
        table.remove(self)
        local idx = 1
        while true do
            local left = idx * 2
            local right = idx * 2 + 1
            local smallest = idx
            if left <= #self and self[left].priority < self[smallest].priority then smallest = left end
            if right <= #self and self[right].priority < self[smallest].priority then smallest = right end
            if smallest ~= idx then
                self[idx], self[smallest] = self[smallest], self[idx]
                idx = smallest
            else break end
        end
        return root.node
    end
    return heap
end

local function heuristic(a, b)
    local dx = math.abs(a.x - b.x)
    local dy = math.abs(a.y - b.y)
    local D = 1
    local D2 = 1.414
    return D * (dx + dy) + (D2 - 2 * D) * math.min(dx, dy)
end

local function nodeKey(node)
    return node.x .. "," .. node.y
end

local function isPathClear(scene, start, target, collider, ignoreId, layerMask)
    local p = 0.4
    local offsets = {
        {x = -p, y = -p},
        {x = collider.w + p, y = -p},
        {x = -p, y = collider.h + p},
        {x = collider.w + p, y = collider.h + p}
    }

    for _, o in ipairs(offsets) do
        local hit = scene:castRay(start.x + o.x, start.y + o.y, 
                                   target.x + o.x, target.y + o.y, 
                                   100, ignoreId, layerMask)
        if hit then return false end
    end

    return not scene:isAreaBlocked(target.x - p, target.y - p, collider.w + p*2, collider.h + p*2, ignoreId, layerMask)
end


function Pathfinding.findPath(scene, startPos, endPos, collider, ignoreId, layerMask)
    collider = collider or { w = 1, h = 1 }
    local startNode = { x = math.floor(startPos.x), y = math.floor(startPos.y) }
    local targetNode = { x = math.floor(endPos.x), y = math.floor(endPos.y) }

    local openSet = createHeap()
    local cameFrom = {}

    local gScore = {}
    local fScore = {}

    local startKey = nodeKey(startNode)
    gScore[startKey] = 0
    openSet:push(startNode, heuristic(startNode, targetNode))

    local closedSet = {}
    local iterations = 0
    local maxIterations = 1000

    while true do
        local current = openSet:pop()
        if not current then break end

        local currentKey = nodeKey(current)
        if closedSet[currentKey] then
            -- stale heap entry — a better path was already processed
        else
        iterations = iterations + 1
        if iterations >= maxIterations then break end

        if current.x == targetNode.x and current.y == targetNode.y then
            local path = { mathUtils.vec2(startNode.x, startNode.y) }
            local temp = current
            local tail = {}
            while cameFrom[nodeKey(temp)] do
                table.insert(tail, 1, mathUtils.vec2(temp.x, temp.y))
                temp = cameFrom[nodeKey(temp)]
            end
            for _, v in ipairs(tail) do table.insert(path, v) end

            if #path <= 2 then return path end
            local smoothed = { path[1] }
            local curr = 1
            while curr < #path do
                local furthestVisible = curr + 1
                for i = #path, curr + 2, -1 do
                    if isPathClear(scene, path[curr], path[i], collider, ignoreId, layerMask) then
                        furthestVisible = i
                        break
                    end
                end
                table.insert(smoothed, path[furthestVisible])
                curr = furthestVisible
            end
            return smoothed
        end

        closedSet[currentKey] = true

        local neighbors = {
            {x = current.x + 1, y = current.y, cost = 1},
            {x = current.x - 1, y = current.y, cost = 1},
            {x = current.x, y = current.y + 1, cost = 1},
            {x = current.x, y = current.y - 1, cost = 1},
            {x = current.x + 1, y = current.y + 1, cost = 1.414},
            {x = current.x - 1, y = current.y + 1, cost = 1.414},
            {x = current.x + 1, y = current.y - 1, cost = 1.414},
            {x = current.x - 1, y = current.y - 1, cost = 1.414},
        }

        for _, neighbor in ipairs(neighbors) do
            local nKey = nodeKey(neighbor)
            if not closedSet[nKey] then
                local p = 0.4
                if not scene:isAreaBlocked(neighbor.x - p, neighbor.y - p, collider.w + p*2, collider.h + p*2, ignoreId, layerMask) then
                    local isDiagonal = neighbor.x ~= current.x and neighbor.y ~= current.y
                    local canPass = true
                    if isDiagonal then
                        if scene:isAreaBlocked(neighbor.x - p, current.y - p, collider.w + p*2, collider.h + p*2, ignoreId, layerMask) or
                           scene:isAreaBlocked(current.x - p, neighbor.y - p, collider.w + p*2, collider.h + p*2, ignoreId, layerMask) then
                            canPass = false
                        end
                    end

                    if canPass then
                        local tentativeGScore = gScore[nodeKey(current)] + neighbor.cost
                        if not gScore[nKey] or tentativeGScore < gScore[nKey] then
                            cameFrom[nKey] = current
                            gScore[nKey] = tentativeGScore
                            openSet:push(neighbor, gScore[nKey] + heuristic(neighbor, targetNode))
                        end
                    end
                end
            end
        end
        end
    end

    return nil
end

return Pathfinding