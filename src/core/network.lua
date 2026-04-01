local logger = require("core.logger")
local event = require("core.event")

local network = {
    modemSide = nil,
    isOpen = false,
    isHost = false,
    serverId = nil,
    clients = {}
}

function network.open(side)
    if side then
        if peripheral.getType(side) == "modem" then
            rednet.open(side)
            network.modemSide = side
            network.isOpen = true
            logger.info("Network: Modem opened on side " .. side .. " (ID: " .. os.getComputerID() .. ")")
            return true
        end
    else
        local modems = { peripheral.find("modem") }
        if #modems > 0 then
            for _, m in ipairs(modems) do
                local s = peripheral.getName(m)
                rednet.open(s)
                network.modemSide = s
            end
            network.isOpen = true
            logger.info("Network: " .. #modems .. " modem(s) opened. Local ID: " .. os.getComputerID())
            return true
        end
    end
    return false
end

function network.close()
    if network.isOpen then
        local modems = { peripheral.find("modem") }
        for _, m in ipairs(modems) do
            rednet.close(peripheral.getName(m))
        end
        network.isOpen = false
        logger.info("Network: All modems closed")
    end
end

function network.disconnect(protocol)
    if not network.isOpen then return end
    if network.isHost then
        network.broadcast({ type = "SERVER_SHUTDOWN" }, protocol)
    elseif network.serverId then
        network.send(network.serverId, { type = "CLIENT_LEAVE" }, protocol)
    end
    network.close()
end

function network.send(targetId, message, protocol)
    if not network.isOpen then return false end
    rednet.send(targetId, message, protocol)
    return true
end

function network.broadcast(message, protocol)
    if not network.isOpen then return false end
    rednet.broadcast(message, protocol)
    return true
end

function network.connect(protocol, hostname)
    if not network.isOpen then return false end
    local id = network.lookup(protocol, hostname)
    if id then
        network.serverId = id
        network.send(id, { type = "CONNECT_REQUEST" }, protocol)
        return id
    end
    return nil
end

function network.host(protocol, hostname)
    if not network.isOpen then return false end
    rednet.host(protocol, hostname)
    network.isHost = true
    logger.info("Network: Now hosting protocol '" .. protocol .. "' as '" .. hostname .. "'")
    return true
end

function network.lookup(protocol, hostname)
    if not network.isOpen then return nil end
    return rednet.lookup(protocol, hostname)
end

function network._handleRawEvent(eventData)
    if eventData[1] == "rednet_message" then
        local senderID, message, protocol = eventData[2], eventData[3], eventData[4]

        if type(message) == "table" then
            if message.type == "CONNECT_REQUEST" and network.isHost then
                logger.info("Network: Received CONNECT_REQUEST from ID " .. senderID)
                network.clients[senderID] = true
                network.send(senderID, { type = "CONNECT_ACCEPT" }, protocol)
                event.emit("onClientConnect", senderID)
                return
            elseif message.type == "CONNECT_ACCEPT" then
                logger.info("Network: Connection accepted by server " .. senderID)
                network.serverId = senderID
                event.emit("onConnectedToServer", senderID)
                return
            elseif message.type == "CLIENT_LEAVE" and network.isHost then
                network.clients[senderID] = nil
                event.emit("onClientDisconnect", senderID)
                return
            elseif message.type == "SERVER_SHUTDOWN" and not network.isHost then
                event.emit("onServerShutdown", senderID)
                return
            end
        end

        event.emit("onNetworkMessage", senderID, message, protocol)
    end
end

return network