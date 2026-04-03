-- Obsidian Engine: Server Module
-- High-level server abstraction built on top of network.lua
-- Greatly simplifies building dedicated servers with Obsidian.

local logger  = require("core.logger")
local event   = require("core.event")
local network = require("core.network")
local buffer  = require("core.buffer")

local server = {}

-- ─── Internal State ───────────────────────────────────────────────────────────

local _clients     = {}   -- [id] = { id, meta, joinedAt, lastSeen, ping, heartbeatSent, lastSeq }
local _rooms       = {}   -- [roomName] = { [clientId] = true }
local _handlers    = {}   -- [msgType]  = fn(clientId, data, packet)
local _middleware  = {}   -- list of fn(clientId, packet, next)
local _tickCbs     = {}   -- list of fn(dt)
local _onConnectCb    = nil
local _onDisconnectCb = nil
local _running     = false
local _protocol    = nil
local _hostname    = nil
local _tickRate    = 20
local _timeout     = 30   -- seconds until a client is considered timed out (0 = off)
local _heartbeat   = 5    -- send a PING every N seconds (0 = off)
local _seqEnabled  = false -- enable per-client sequence number dedup

-- ─── Server Console ───────────────────────────────────────────────────────────

local _con = {
    enabled    = false,
    title      = "Obsidian Server",
    maxEntries = 200,
    log        = {},
    lines      = {},
    lastWidth  = 0,
    lastHeight = 0,
    startTime  = nil,
    dirty      = true,
}

-- Colour palette for log levels
local CON_LEVEL = {
    info    = { fore = "0", prefix = "[INFO ] " },
    warn    = { fore = "1", prefix = "[WARN ] " },
    error   = { fore = "e", prefix = "[ERROR] " },
    success = { fore = "d", prefix = "[OK   ] " },
    system  = { fore = "b", prefix = "[SYS  ] " },
}

-- Continuation lines start at column 1 (no indent)
local CON_PREFIX_W = 0

local function _conTimestamp()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

-- Word-wrap a single string to `width` columns.
-- Continuation lines are indented by `indentW` spaces.
local function _wrapText(fullLine, width, indentW)
    if width <= 0 or #fullLine <= width then return { fullLine } end
    local result  = {}
    local indent  = string.rep(" ", indentW)
    local remaining = fullLine
    while #remaining > width do
        local cut = width
        -- search backwards for a space to soft-break at
        for i = width, indentW + 1, -1 do
            if remaining:sub(i, i) == " " then
                cut = i - 1
                break
            end
        end
        result[#result + 1] = remaining:sub(1, cut)
        local rest = remaining:sub(cut + 1):match("^%s*(.*)")
        remaining = (#rest > 0) and (indent .. rest) or ""
    end
    if #remaining > 0 then
        result[#result + 1] = remaining
    end
    return result
end

-- Rebuild all wrapped display lines from the raw log at the given width.
local function _rebuildLines(width)
    _con.lines = {}
    for _, entry in ipairs(_con.log) do
        local full = entry.ts .. "  " .. entry.prefix .. entry.raw
        for _, wl in ipairs(_wrapText(full, width, CON_PREFIX_W)) do
            _con.lines[#_con.lines + 1] = { text = wl, fore = entry.fore }
        end
    end
    _con.lastWidth = width
end

local function _conPush(text, level)
    level = CON_LEVEL[level] or CON_LEVEL.info
    local entry = {
        ts     = _conTimestamp(),
        prefix = level.prefix,
        raw    = tostring(text),
        fore   = level.fore,
    }
    table.insert(_con.log, entry)
    if #_con.log > _con.maxEntries then
        table.remove(_con.log, 1)
        -- full rebuild needed since we dropped the oldest entry
        if _con.lastWidth > 0 then
            _rebuildLines(_con.lastWidth)
        end
    else
        -- incremental: just append the new wrapped lines
        if _con.lastWidth > 0 then
            local full = entry.ts .. "  " .. entry.prefix .. entry.raw
            for _, wl in ipairs(_wrapText(full, _con.lastWidth, CON_PREFIX_W)) do
                _con.lines[#_con.lines + 1] = { text = wl, fore = entry.fore }
            end
        end
    end
    _con.dirty = true
end

local function _conRender()
    if not _con.enabled or not _con.dirty then return end
    _con.dirty = false

    local sw, sh = term.getSize()
    if sw == 0 or sh == 0 then return end

    -- Rebuild wrap table whenever terminal width changes
    if sw ~= _con.lastWidth then
        _rebuildLines(sw)
        _con.lastWidth  = sw
        _con.lastHeight = sh
    end

    -- Draw directly to the terminal — no buffer cache, so resize always gives
    -- a clean full redraw without dirty-check mismatches.

    -- Helper: write a full-width line at row y
    local function drawLine(y, text, fore, back)
        -- pad / truncate to exact terminal width
        if #text < sw then
            text = text .. string.rep(" ", sw - #text)
        elseif #text > sw then
            text = text:sub(1, sw)
        end
        local f = string.rep(fore, sw)
        local b = string.rep(back, sw)
        term.setCursorPos(1, y)
        term.blit(text, f, b)
    end

    -- Header (row 1)
    local uptime = ""
    if _con.startTime then
        local secs = math.floor(os.epoch("utc") / 1000 - _con.startTime)
        local m    = math.floor(secs / 60)
        local s    = secs % 60
        uptime = string.format("up %dm%02ds", m, s)
    end
    local right  = string.format("ID:%-3d  %s ", os.getComputerID(), uptime)
    local header = (" " .. _con.title .. string.rep(" ", sw)):sub(1, sw - #right) .. right
    drawLine(1, header, "f", "5")

    -- Status bar (last row)
    local proto    = _protocol or "(no protocol)"
    local nClients = 0
    for _ in pairs(_clients) do nClients = nClients + 1 end
    local status = string.format(" proto: %-20s  clients: %d", proto, nClients)
    drawLine(sh, status, "0", "8")

    -- Log area (rows 2 .. sh-1)
    local logH     = sh - 2
    local startIdx = math.max(1, #_con.lines - logH + 1)
    local row      = 2

    -- Render visible log lines
    for i = startIdx, math.min(startIdx + logH - 1, #_con.lines) do
        local line = _con.lines[i]
        drawLine(row, line.text, line.fore, "f")
        row = row + 1
    end

    -- Fill remaining empty log rows with blanks
    while row < sh do
        drawLine(row, "", "f", "f")
        row = row + 1
    end
end

--- Enable the server console. Call before server.run().
-- @param title  Optional title string shown in the header.
function server.showConsole(title)
    _con.enabled = true
    if title then _con.title = title end
end

--- Write a line to the server console.
-- @param text   Message string.
-- @param level  One of: "info", "warn", "error", "success", "system" (default: "info")
function server.print(text, level)
    _conPush(tostring(text), level or "info")
end

-- ─── Packet Helpers ───────────────────────────────────────────────────────────

local function makePacket(msgType, data)
    return {
        type      = msgType,
        data      = data or {},
        sender    = os.getComputerID(),
        timestamp = os.epoch("utc"),
    }
end

-- ─── Client Management ────────────────────────────────────────────────────────

--- Returns all currently connected client IDs as a list.
function server.getClients()
    local list = {}
    for id in pairs(_clients) do
        list[#list + 1] = id
    end
    return list
end

--- Returns the number of connected clients.
function server.clientCount()
    local n = 0
    for _ in pairs(_clients) do n = n + 1 end
    return n
end

--- Returns true if the given client ID is connected.
function server.isConnected(clientId)
    return _clients[clientId] ~= nil
end

--- Store arbitrary key/value metadata on a connected client.
function server.setMeta(clientId, key, value)
    if _clients[clientId] then
        _clients[clientId].meta[key] = value
    end
end

--- Retrieve metadata from a connected client. Returns nil if not found.
function server.getMeta(clientId, key)
    if _clients[clientId] then
        return _clients[clientId].meta[key]
    end
    return nil
end

-- Internal: remove client and clean up rooms
local function _removeClient(clientId)
    if not _clients[clientId] then return end
    _clients[clientId] = nil

    for roomName, members in pairs(_rooms) do
        members[clientId] = nil
        -- prune empty rooms
        local count = 0
        for _ in pairs(members) do count = count + 1 end
        if count == 0 then _rooms[roomName] = nil end
    end

    if _onDisconnectCb then
        pcall(_onDisconnectCb, clientId)
    end
    event.emit("server.clientDisconnect", clientId)
    logger.info("Server: Client " .. clientId .. " disconnected")
    _conPush("Client #" .. clientId .. " disconnected", "warn")
end

--- Kick a client from the server with an optional reason string.
function server.kick(clientId, reason)
    if not _clients[clientId] then return end
    server.send(clientId, "SERVER_KICK", { reason = reason or "Kicked by server" })
    _removeClient(clientId)
end


-- ─── Rooms ────────────────────────────────────────────────────────────────────

--- Add a client to a named room (creates it if it doesn't exist).
function server.joinRoom(clientId, roomName)
    if not _clients[clientId] then return end
    if not _rooms[roomName] then _rooms[roomName] = {} end
    _rooms[roomName][clientId] = true
end

--- Remove a client from a named room.
function server.leaveRoom(clientId, roomName)
    if _rooms[roomName] then
        _rooms[roomName][clientId] = nil
    end
end

--- Returns a list of client IDs currently in the given room.
function server.getRoomClients(roomName)
    local list = {}
    if _rooms[roomName] then
        for id in pairs(_rooms[roomName]) do
            list[#list + 1] = id
        end
    end
    return list
end

--- Returns a list of room names the given client is a member of.
function server.getClientRooms(clientId)
    local list = {}
    for roomName, members in pairs(_rooms) do
        if members[clientId] then
            list[#list + 1] = roomName
        end
    end
    return list
end

-- ─── Messaging ────────────────────────────────────────────────────────────────

--- Send a typed message to a specific client.
function server.send(clientId, msgType, data)
    if not network.isOpen then return false end
    local pkt = makePacket(msgType, data)
    rednet.send(clientId, pkt, _protocol)
    return true
end

--- Broadcast a typed message to all connected clients.
-- @param exceptId  optional client ID to skip
function server.broadcast(msgType, data, exceptId)
    if not network.isOpen then return end
    local pkt = makePacket(msgType, data)
    for id in pairs(_clients) do
        if id ~= exceptId then
            rednet.send(id, pkt, _protocol)
        end
    end
end

--- Broadcast a message to all clients in a specific room.
-- @param exceptId  optional client ID to skip
function server.broadcastRoom(roomName, msgType, data, exceptId)
    if not _rooms[roomName] then return end
    local pkt = makePacket(msgType, data)
    for id in pairs(_rooms[roomName]) do
        if id ~= exceptId and _clients[id] then
            rednet.send(id, pkt, _protocol)
        end
    end
end

-- ─── Handlers & Middleware ────────────────────────────────────────────────────

--- Register a handler for a specific message type.
-- Handler signature: fn(clientId, data, packet)
function server.on(msgType, fn)
    server.print(string.format("Registered handler for message type: %s", msgType), "debug")
    _handlers[msgType] = fn
end

--- Remove a message type handler.
function server.off(msgType)
    _handlers[msgType] = nil
end

--- Add middleware that runs before every message handler.
-- Middleware signature: fn(clientId, packet, next)
-- Call next() to pass to the next middleware / handler.
-- Omitting next() stops further processing.
function server.use(fn)
    _middleware[#_middleware + 1] = fn
end

-- Internal: run the middleware chain then dispatch to handler
local function _dispatch(clientId, packet)
    local i = 0
    server.print(string.format("Dispatching packet type '%s' from client #%d", tostring(packet.type), clientId), "debug")
    local function next()
        i = i + 1
        if i <= #_middleware then
            local ok, err = pcall(_middleware[i], clientId, packet, next)
            if not ok then
                logger.error("Server middleware error: " .. tostring(err))
            end
        else
            local handler = _handlers[packet.type]
            if handler then
                local ok, err = pcall(handler, clientId, packet.data or {}, packet)
                if not ok then
                    logger.error("Server handler error [" .. tostring(packet.type) .. "]: " .. tostring(err))
                end
            end
        end
    end
    next()
end

-- ─── Connection Callbacks ─────────────────────────────────────────────────────

--- Called when a new client connects. fn(clientId)
function server.onConnect(fn)
    _onConnectCb = fn
end

--- Called when a client disconnects. fn(clientId)
function server.onDisconnect(fn)
    _onDisconnectCb = fn
end

-- ─── Built-in Auth System ─────────────────────────────────────────────────────
--
-- Opt-in auth layer. Activate with server.enableAuth(db, opts).
-- Once enabled, the server automatically handles LOGIN, REGISTER, and LOGOUT
-- messages and exposes server.auth.* helpers for game code.
--
-- Usage:
--   local players = Engine.db.open("players", { autosave = true })
--   server.enableAuth(players, {
--       minNameLen  = 3,   -- default 3
--       maxNameLen  = 16,  -- default 16
--       minPwLen    = 4,   -- default 4
--       onLogin     = function(clientId, profile) end,   -- optional
--       onRegister  = function(clientId, profile) end,   -- optional
--       onLogout    = function(clientId, profile) end,   -- optional
--   })
--
-- After login/register, game handlers can guard with:
--   if not server.auth.isLoggedIn(clientId) then
--       server.send(clientId, "AUTH_REQUIRED", {}); return
--   end

local _auth = {
    enabled  = false,
    db       = nil,
    sessions = {},    -- [clientId] = profile
    nonces   = {},    -- [clientId] = { nonce, name, expireAt }
    attempts = {},    -- [clientId] = { count, resetAt }
    opts     = {},
}

-- djb2 hash — lightweight, deterministic, no external deps.
local function _djb2(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + string.byte(str, i)) % 2147483647
    end
    return tostring(h)
end

-- Strip the passwordHash field before sending a profile to a client.
local function _safeProfile(profile)
    local out = {}
    for k, v in pairs(profile) do
        if k ~= "passwordHash" then out[k] = v end
    end
    return out
end

--- Enable the built-in auth system.
-- @param db    An Obsidian DB collection (from Engine.db.open)
-- @param opts  Optional configuration table (see module header)
function server.enableAuth(db, opts)
    assert(db, "server.enableAuth: db must be an Obsidian DB collection")
    opts = opts or {}
    _auth.db      = db
    _auth.opts    = opts
    _auth.enabled = true

    local minNameLen = opts.minNameLen or 3
    local maxNameLen = opts.maxNameLen or 16
    local minPwLen   = opts.minPwLen   or 4

    -- ── REGISTER handler ────────────────────────────────────────────────────
    -- Client sends djb2(password) — plaintext never leaves the client.
    _handlers["REGISTER"] = function(clientId, data)
        local name         = tostring(data.name or "")
        local passwordHash = tostring(data.passwordHash or "")  -- pre-hashed by client
        local class        = data.class  -- optional, game-specific

        if #name < minNameLen or #name > maxNameLen then
            server.send(clientId, "REGISTER_FAILED",
                { message = "Name must be " .. minNameLen .. "-" .. maxNameLen .. " characters." })
            return
        end
        if name:match("[^%w_%-]") then
            server.send(clientId, "REGISTER_FAILED",
                { message = "Name may only contain letters, numbers, - and _" })
            return
        end
        if #passwordHash == 0 then
            server.send(clientId, "REGISTER_FAILED",
                { message = "Password must be at least " .. minPwLen .. " characters." })
            return
        end
        if _auth.db:findOne({ name = name }) then
            server.send(clientId, "REGISTER_FAILED", { message = "Name already taken." })
            return
        end

        local profile = {
            cid          = clientId,
            name         = name,
            passwordHash = passwordHash,  -- already hashed by client
            class        = class,
        }
        -- Merge any extra fields the game passed (e.g. starting stats)
        if opts.buildProfile then
            local extra = opts.buildProfile(clientId, data) or {}
            for k, v in pairs(extra) do profile[k] = v end
        end
        _auth.db:insert(profile)
        _auth.sessions[clientId] = profile
        logger.info("Auth: '" .. name .. "' registered (client " .. clientId .. ")")
        _conPush("Auth: '" .. name .. "' registered", "success")
        server.send(clientId, "REGISTER_SUCCESS", { profile = _safeProfile(profile) })
        if opts.onRegister then pcall(opts.onRegister, clientId, profile) end
    end

    -- ── LOGIN_CHALLENGE_REQUEST handler ─────────────────────────────────────
    -- Step 1: client sends username → server returns a one-time nonce.
    _handlers["LOGIN_CHALLENGE_REQUEST"] = function(clientId, data)
        local now = os.epoch("utc") / 1000
        local att = _auth.attempts[clientId]
        if att and now < att.resetAt then
            server.send(clientId, "LOGIN_FAILED", { message = string.format(
                "Too many failed attempts. Try again in %ds.", math.ceil(att.resetAt - now)) })
            return
        end
        local name = tostring(data.name or "")
        math.randomseed(os.epoch("utc") + clientId)
        local nonce = tostring(math.random(10000000, 99999999)) .. tostring(os.epoch("utc") % 1000000)
        _auth.nonces[clientId] = { nonce = nonce, name = name, expireAt = now + 30 }
        server.send(clientId, "LOGIN_CHALLENGE", { nonce = nonce })
    end

    -- ── LOGIN handler ────────────────────────────────────────────────────────
    -- Step 2: client replies with djb2(clientPasswordHash .. nonce).
    _handlers["LOGIN"] = function(clientId, data)
        local now      = os.epoch("utc") / 1000
        local entry    = _auth.nonces[clientId]
        local name     = tostring(data.name or "")
        local response = tostring(data.response or "")

        -- Validate nonce: must exist, match username, and not be expired
        if not entry or entry.name ~= name or now > entry.expireAt then
            _auth.nonces[clientId] = nil
            server.send(clientId, "LOGIN_FAILED", { message = "Challenge expired. Please try again." })
            return
        end
        _auth.nonces[clientId] = nil  -- one-time use

        local profile = _auth.db:findOne({ name = name })
        if not profile or _djb2(profile.passwordHash .. entry.nonce) ~= response then
            -- Track failed attempt for rate limiting
            local att = _auth.attempts[clientId] or { count = 0, resetAt = 0 }
            att.count = att.count + 1
            if att.count >= 5 then
                att.resetAt = now + 60
                att.count   = 0
                _conPush("Auth: Client #" .. clientId .. " rate-limited (5 failed attempts)", "warn")
            end
            _auth.attempts[clientId] = att
            server.send(clientId, "LOGIN_FAILED", { message = "Wrong username or password." })
            _conPush("Auth: Failed login for '" .. name .. "' (client " .. clientId .. ")", "warn")
            return
        end

        -- Success – clear rate limit counter
        _auth.attempts[clientId] = nil
        if profile.cid ~= clientId then
            _auth.db:update({ name = name }, { cid = clientId })
            profile.cid = clientId
        end
        _auth.sessions[clientId] = profile
        logger.info("Auth: '" .. name .. "' logged in (client " .. clientId .. ")")
        _conPush("Auth: '" .. name .. "' logged in", "success")
        server.send(clientId, "LOGIN_SUCCESS", { profile = _safeProfile(profile) })
        if opts.onLogin then pcall(opts.onLogin, clientId, profile) end
    end

    -- ── LOGOUT handler ───────────────────────────────────────────────────────
    _handlers["LOGOUT"] = function(clientId)
        local profile = _auth.sessions[clientId]
        _auth.sessions[clientId] = nil
        if profile then
            logger.info("Auth: '" .. profile.name .. "' logged out (client " .. clientId .. ")")
            _conPush("Auth: '" .. profile.name .. "' logged out", "info")
        end
        if opts.onLogout then pcall(opts.onLogout, clientId, profile) end
    end
end

--- Namespace exposed to game code after server.enableAuth() is called.
server.auth = {
    --- Returns true if the client has an active session.
    isLoggedIn = function(clientId)
        return _auth.sessions[clientId] ~= nil
    end,
    --- Returns the in-memory profile for a logged-in client, or nil.
    getProfile = function(clientId)
        return _auth.sessions[clientId]
    end,
    --- Manually clear a client's session (e.g. on disconnect).
    logout = function(clientId)
        _auth.sessions[clientId] = nil
    end,
    --- Convenience guard: sends AUTH_REQUIRED and returns false if not logged in.
    require = function(clientId)
        if not _auth.sessions[clientId] then
            server.send(clientId, "AUTH_REQUIRED", { message = "Please log in first." })
            return false
        end
        return true
    end,
}


-- ─── Tick System ─────────────────────────────────────────────────────────────

--- Register a callback to be called every server tick. fn(dt)
function server.onTick(fn)
    _tickCbs[#_tickCbs + 1] = fn
end

--- Set the server tick rate (ticks per second, default 20).
function server.setTickRate(n)
    _tickRate = math.max(1, n)
end

--- Set the client timeout in seconds (0 to disable). Default 30.
function server.setTimeout(seconds)
    _timeout = seconds
end

--- Set the heartbeat interval in seconds (0 to disable). Default 5.
-- The server sends a PING every N seconds; clients should reply with a PONG.
-- The round-trip time is stored as the client's ping in milliseconds.
function server.setHeartbeatInterval(seconds)
    _heartbeat = seconds
end

--- Enable per-client message sequence numbers.
-- When enabled, packets with a seq field lower than the last seen value
-- for that client are silently dropped (protects against replays / duplicates).
function server.enableSequencing()
    _seqEnabled = true
end

--- Returns the last measured ping (ms) for a client, or nil if unknown.
function server.getPing(clientId)
    local c = _clients[clientId]
    return c and c.ping or nil
end

--- Send a typed message to a list of specific client IDs.
function server.sendToList(idList, msgType, data)
    if not network.isOpen then return end
    local pkt = makePacket(msgType, data)
    for _, id in ipairs(idList) do
        if _clients[id] then
            rednet.send(id, pkt, _protocol)
        end
    end
end

-- ─── Init & Lifecycle ─────────────────────────────────────────────────────────

--- Initialise the server: open modem, host protocol.
-- @param protocol  Rednet protocol string (e.g. "myGame")
-- @param hostname  Rednet hostname (e.g. "server")
-- @param side      Optional modem side; auto-detected if nil
function server.init(protocol, hostname, side)
    _protocol = protocol

    if not network.open(side) then
        logger.error("Server: No modem found!")
        return false
    end

    if not network.host(protocol, hostname) then
        logger.error("Server: Failed to host protocol '" .. protocol .. "'")
        return false
    end

    _hostname = hostname
    logger.info(string.format("Server: Online | protocol='%s' hostname='%s' id=%d",
        protocol, hostname, os.getComputerID()))
    return true
end

--- Shut down the server, kick all clients, and close the modem.
function server.stop()
    if not _running then return end
    _running = false
    server.broadcast("SERVER_SHUTDOWN", { reason = "Server shutting down" })
    for id in pairs(_clients) do
        _clients[id] = nil
    end
    _rooms = {}
    network.close()
    _conPush("Server stopped.", "system")
    _conRender()
    event.emit("server.stopped")
    logger.info("Server: Stopped")
end

-- ─── Internal Event Processing ───────────────────────────────────────────────

local function _handleRednet(senderId, pkt, proto)
    if proto ~= _protocol then return end

    -- Respond to broadcast discovery (pre-handshake — no client record needed)
    if not pkt.type == "PONG" then
        server.print(string.format("Received rednet_message from %d: type=%s", senderId, tostring(pkt.type)), "debug")
    end
    if type(pkt) == "table" and pkt.type == "DISCOVER" and pkt.hostname == _hostname then
        logger.info("Server: DISCOVER from " .. tostring(senderId) .. " — replying")
        rednet.send(senderId, { type = "DISCOVER_REPLY", hostname = _hostname,
                                serverId = os.getComputerID() }, proto)
        return
    end

    -- update last-seen
    if _clients[senderId] then
        _clients[senderId].lastSeen = os.epoch("utc") / 1000
    end

    if type(pkt) ~= "table" or not pkt.type then return end

    -- Built-in: connection handshake
    if pkt.type == "CONNECT_REQUEST" then
        _clients[senderId] = {
            id            = senderId,
            meta          = {},
            joinedAt      = os.epoch("utc") / 1000,
            lastSeen      = os.epoch("utc") / 1000,
            ping          = nil,
            heartbeatSent = nil,
            lastSeq       = -1,
        }
        rednet.send(senderId, makePacket("CONNECT_ACCEPT", {
            serverId   = os.getComputerID(),
            serverTime = os.epoch("utc"),
        }), _protocol)

        if _onConnectCb then pcall(_onConnectCb, senderId) end
        event.emit("server.clientConnect", senderId)
        logger.info("Server: Client " .. senderId .. " connected")
        _conPush("Client #" .. senderId .. " connected  (total: " .. server.clientCount() .. ")", "success")
        return
    end

    -- Built-in: graceful leave
    if pkt.type == "CLIENT_LEAVE" then
        _removeClient(senderId)
        return
    end

    -- Ignore messages from unknown clients (not yet handshook)
    if not _clients[senderId] then return end

    -- Built-in: heartbeat reply
    if pkt.type == "PONG" then
        local c = _clients[senderId]
        if c and c.heartbeatSent then
            c.ping = math.floor((os.epoch("utc") - c.heartbeatSent))
            c.heartbeatSent = nil
        end
        return
    end

    -- Sequence dedup: drop replayed / out-of-order packets
    if _seqEnabled and pkt.seq then
        local c = _clients[senderId]
        if pkt.seq <= c.lastSeq then return end
        c.lastSeq = pkt.seq
    end

    _dispatch(senderId, pkt)
end

-- ─── Main Loop ────────────────────────────────────────────────────────────────

--- Run the server loop (blocking, typically called from the main script).
-- Handles network events, tick callbacks, and client timeouts in one loop.
function server.run()
    if not _protocol then
        logger.error("Server: Call server.init() before server.run()")
        return
    end

    _running = true
    _con.startTime = os.epoch("utc") / 1000
    event.emit("server.started")
    logger.info("Server: Running at " .. _tickRate .. " ticks/s")
    _conPush("Server started  |  protocol: " .. (_protocol or "?") .. "  |  " .. _tickRate .. " ticks/s", "system")

    if _con.enabled then
        local sw, sh = term.getSize()
        _con.lastWidth  = sw
        _con.lastHeight = sh
        _rebuildLines(sw)
    end

    local FRAME_TIME = 1 / _tickRate
    local lastTime   = os.epoch("utc") / 1000

    -- Start the first tick timer BEFORE entering the loop so pullEventRaw
    -- never blocks forever when there are no network events.
    local _tickTimer = os.startTimer(FRAME_TIME)

    while _running do
        local rawEvent = { os.pullEventRaw() }
        local evName   = rawEvent[1]

        -- Graceful quit
        if evName == "terminate" then
            logger.info("Server: Terminate signal received")
            server.stop()
            break
        end

        -- Incoming rednet message
        if evName == "rednet_message" then
            local senderId = rawEvent[2]
            local pkt      = rawEvent[3]
            local proto    = rawEvent[4]
            _handleRednet(senderId, pkt, proto)
        end

        -- Terminal resize: _conRender detects the size change and rebuilds wrapping
        if evName == "term_resize" then
            _con.dirty = true
        end

        -- Tick: only fires when OUR tick timer event arrives
        if evName == "timer" and rawEvent[2] == _tickTimer then
            local now = os.epoch("utc") / 1000
            local dt  = now - lastTime
            lastTime  = now

            -- Timeout + heartbeat check
            for id, info in pairs(_clients) do
                -- Timeout
                if _timeout > 0 and now - info.lastSeen > _timeout then
                    logger.warn("Server: Client " .. id .. " timed out")
                    _conPush(string.format("Client #%d timed out (no response for %ds)", id, _timeout), "warn")
                    server.kick(id, "Timed out")
                -- Heartbeat: send a PING if interval elapsed and no outstanding PING
                elseif _heartbeat > 0 and not info.heartbeatSent and
                       (now - info.lastSeen) >= _heartbeat then
                    info.heartbeatSent = os.epoch("utc")
                    rednet.send(id, makePacket("PING", { t = info.heartbeatSent }), _protocol)
                end
            end

            -- Fire tick callbacks
            for _, fn in ipairs(_tickCbs) do
                local ok, err = pcall(fn, dt)
                if not ok then
                    logger.error("Server tick error: " .. tostring(err))
                    _conPush("Tick error: " .. tostring(err), "error")
                end
            end

            -- Always redraw console so uptime/client count stay current
            _con.dirty = true
            _conRender()

            -- Schedule next tick
            _tickTimer = os.startTimer(FRAME_TIME)
        end
    end
end

return server