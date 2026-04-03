local logger = require("core.logger")
local event = require("core.event")

local network = {
    modemSide = nil,
    isOpen = false,
    isHost = false,
    serverId = nil,
    clients = {},
    _connectCallback = nil,  -- pending callback from network.connect()
    _connecting = false,     -- true while a connect attempt is in-flight
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

--- Connect to a server.
--- Performs a modem check and auto-opens if needed.
--- @param protocol  string
--- @param hostname  string
--- @param callback  function|nil  Optional: function(ok, reason) called on success or failure.
---                               On success: ok=true,  reason=serverId
---                               On failure: ok=false, reason=error string
--- @param timeout   number|nil   Seconds to wait for CONNECT_ACCEPT after lookup (default 5)
--- @return ok      bool    false if a synchronous error occurred (no modem, already connecting)
--- @return reason  string  Error description if ok is false
function network.connect(protocol, hostname, callback, timeout)
    timeout = timeout or 5

    logger.info("Network: connect() called — protocol='" .. tostring(protocol) .. "' hostname='" .. tostring(hostname) .. "' timeout=" .. tostring(timeout))

    -- Auto-open modem if not already open
    if not network.isOpen then
        logger.info("Network: modem not open, attempting auto-open")
        local opened = network.open()
        if not opened then
            local err = "No modem found"
            logger.warn("Network: connect() failed — " .. err)
            if callback then callback(false, err) end
            return false, err
        end
    end

    -- Prevent duplicate simultaneous connect attempts
    if network._connecting then
        local err = "Already connecting"
        logger.warn("Network: connect() rejected — " .. err)
        if callback then callback(false, err) end
        return false, err
    end

    network._connecting = true
    network._connectCallback = callback
    logger.info("Network: starting connect thread")

    local function _cleanup(ok, reason)
        local cb = network._connectCallback
        network._connectCallback = nil
        network._connecting = false
        if cb then cb(ok, reason) end
    end

    local thread = require("core.thread")
    thread.start(function()
        -- Step 1: Try rednet.lookup (DNS-based)
        logger.info("Network: [thread] looking up '" .. tostring(hostname) .. "' on protocol '" .. tostring(protocol) .. "'")
        local lookupOk, id_or_err = pcall(network.lookup, protocol, hostname)
        local id = lookupOk and id_or_err or nil
        logger.info("Network: [thread] lookup result — ok=" .. tostring(lookupOk) .. " id=" .. tostring(id))

        -- Step 2: If DNS lookup failed, fall back to broadcast DISCOVER
        if not id then
            logger.info("Network: [thread] DNS lookup failed, trying broadcast DISCOVER")
            rednet.broadcast({ type = "DISCOVER", hostname = hostname }, protocol)
            local discoverTimer = os.startTimer(3)
            while true do
                local ev, p1, p2, p3 = os.pullEvent()
                if ev == "rednet_message" then
                    local msg, proto2 = p2, p3
                    if type(msg) == "table" and msg.type == "DISCOVER_REPLY"
                            and msg.hostname == hostname and proto2 == protocol then
                        id = p1
                        logger.info("Network: [thread] DISCOVER_REPLY from " .. tostring(id))
                        break
                    end
                elseif ev == "timer" and p1 == discoverTimer then
                    logger.warn("Network: [thread] broadcast discovery timed out")
                    break
                end
            end
        end

        -- Step 3: Give up if still no server found
        if not id then
            local err = (not lookupOk) and tostring(id_or_err) or "Server not found"
            logger.warn("Network: [thread] connect failed — " .. err)
            _cleanup(false, err)
            event.emit("onConnectionFailed", protocol, hostname)
            return
        end

        -- Step 4: Send CONNECT_REQUEST and wait for CONNECT_ACCEPT
        network.serverId = id
        logger.info("Network: [thread] sending CONNECT_REQUEST to server ID " .. tostring(id))
        network.send(id, { type = "CONNECT_REQUEST" }, protocol)

        -- _handleRawEvent fires the callback when CONNECT_ACCEPT arrives and
        -- clears _connecting.  We just watch for the timeout case.
        logger.info("Network: [thread] waiting up to " .. timeout .. "s for CONNECT_ACCEPT")
        local t = os.startTimer(timeout)
        while true do
            local ev, p1 = os.pullEvent()
            logger.info("Network: [thread] got event '" .. tostring(ev) .. "'")
            if ev == "timer" and p1 == t then
                if network._connecting then
                    logger.warn("Network: [thread] timed out waiting for CONNECT_ACCEPT")
                    _cleanup(false, "Connection timed out")
                    event.emit("onConnectionFailed", protocol, hostname)
                end
                break
            elseif not network._connecting then
                logger.info("Network: [thread] _connecting cleared externally, exiting wait")
                break
            end
        end
    end)
    return true
end

--- Cancel an in-flight connection attempt.
--- Fires the pending callback with the given reason (default "Cancelled").
--- @param reason  string|nil
function network.cancelConnect(reason)
    if not network._connecting then return end
    local cb = network._connectCallback
    network._connectCallback = nil
    network._connecting = false
    if cb then cb(false, reason or "Cancelled") end
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
        if not tostring(message.type) == "PING" then
            logger.info("Network: rednet_message from " .. tostring(senderID) .. " proto='" .. tostring(protocol) .. "' type=" .. (type(message) == "table" and tostring(message.type) or type(message)))
        end
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
                local cb = network._connectCallback
                network._connectCallback = nil
                network._connecting = false
                if cb then cb(true, senderID) end
                event.emit("onConnectedToServer", senderID)
                return
            elseif message.type == "PING" then
                network.send(senderID, { type = "PONG", t = message.t }, protocol)
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