# server

Obsidian Engine: Server Module
High-level server abstraction built on top of network.lua
Greatly simplifies building dedicated servers with Obsidian.
Injected by the bundler / init.lua loader; see src/init.lua.

## Types

### `NetworkPacket`

Network packet structure

| Field | Type | Description |
| --- | --- | --- |
| type | `string` | Message type identifier |
| data | `table` | Arbitrary message data payload |
| sender | `number` | Computer ID of the sender |
| timestamp | `number` | Epoch time in milliseconds when the packet was sent |

### `ServerProfile`

Server profile object structure

| Field | Type | Description |
| --- | --- | --- |
| cid | `number` | Client ID |
| name | `string` | Player name |
| passwordHash | `string` | DJB2 hash of the player's password (stored but never sent to clients) |
| class | `string\|nil` | Optional player class/type for game-specific logic |

### `ServerModule`

This module provides a high-level server abstraction built on top of network.lua, making it easy to build dedicated servers with Obsidian. It includes client management, message handling, rooms, a built-in auth system, and an optional server console for logging and monitoring.

### `AuthOptions`

Auth config structure

| Field | Type | Description |
| --- | --- | --- |
| minNameLen *(optional)* | `number` | Minimum allowed username length (default 3) |
| maxNameLen *(optional)* | `number` | Maximum allowed username length (default 16) |
| onLogin *(optional)* | `fun(clientId: number, profile: ServerProfile)` | Optional callback fired after successful login |
| onRegister *(optional)* | `fun(clientId: number, profile: ServerProfile)` | Optional callback fired after successful registration |
| onLogout *(optional)* | `fun(clientId: number, profile: ServerProfile)` | Optional callback fired after logout |
| buildProfile *(optional)* | `fun(clientId: number, data: table): table` | Optional function to build a complete profile on registration. Receives the client ID and original registration data, should return a table of additional profile fields to merge into the stored profile (e.g. starting stats or inventory). |

## Methods

### server.showConsole(title)

Enable the server console. Call before server.run().

- **title** (`string`, optional) Optional title string shown in the header.

### server.log(text, level)

Write a line to the server console.

- **text** (`any`) Message to log.
- **level** (`"info"|"warn"|"error"|"success"|"system"|"debug"`, optional) 

### server.getClients()

Returns all currently connected client IDs as a list.

- **returns** **list** (`number[]`) List of connected client IDs

### server.clientCount()

Returns the number of connected clients.

- **returns** **count** (`number`) Count of connected clients

### server.isConnected(clientId)

Returns true if the given client ID is connected.

- **clientId** (`number`) Client ID to check

- **returns** **isConnected** (`boolean`) True if the client is currently connected, false otherwise

### server.setMeta(clientId, key, value)

Store arbitrary key/value metadata on a connected client.

- **clientId** (`number`) Client ID of the client
- **key** (`string`) Metadata key
- **value** (`any`) Metadata value

### server.getMeta(clientId, key)

Retrieve metadata from a connected client. Returns nil if not found.

- **clientId** (`number`) Client ID of the client
- **key** (`string`) Metadata key

- **returns** **data** (`any|nil`) Metadata value or nil if not found

### server.kick(clientId, reason)

Kick a client from the server with an optional reason string.

- **clientId** (`number`) Client ID to kick
- **reason** (`string`, optional) Optional reason for the kick, sent to the client before disconnecting

### server.joinRoom(clientId, roomName)

Add a client to a named room (creates it if it doesn't exist).

- **clientId** (`number`) Client ID to add to the room
- **roomName** (`string`) Name of the room to join

### server.leaveRoom(clientId, roomName)

Remove a client from a named room.

- **clientId** (`number`) Client ID to remove from the room
- **roomName** (`string`) Name of the room to leave

### server.getRoomClients(roomName)

Returns a list of client IDs currently in the given room.

- **roomName** (`string`) Name of the room to query

- **returns** **list** (`number[]`) List of client IDs in the room, or empty list if room doesn't exist

### server.getClientRooms(clientId)

Returns a list of room names the given client is a member of.

- **clientId** (`number`) Client ID to query

- **returns** **list** (`string[]`) List of room names the client is a member of

### server.send(clientId, msgType, data)

Send a typed message to a specific client.

- **clientId** (`number`) Client ID of the recipient
- **msgType** (`string`) Message type identifier
- **data** (`table`, optional) Optional message data payload

- **returns** **success** (`boolean`) True if the message was sent successfully, false if the client is not connected or network is closed

### server.broadcast(msgType, data, exceptId)

Broadcast a typed message to all connected clients.

- **msgType** (`string`) Message type identifier
- **data** (`table`, optional) Optional message data payload
- **exceptId** (`number`, optional) Optional client ID to skip

### server.broadcastRoom(roomName, msgType, data, exceptId)

Broadcast a message to all clients in a specific room.

- **roomName** (`string`) Name of the room to broadcast to
- **msgType** (`string`) Message type identifier
- **data** (`table`, optional) Optional message data payload
- **exceptId** (`number`, optional) Optional client ID to skip

### server.on(msgType, fn)

Register a handler for a specific message type.

- **msgType** (`string`) Message type identifier
- **fn** (`fun(clientId: number, data: table, packet: NetworkPacket)`) Handler function that processes incoming messages of the specified type. Receives the client ID, message data, and the full packet as arguments.

### server.off(msgType)

Remove a message type handler.

- **msgType** (`string`) Message type identifier

### server.use(fn)

Add middleware that runs before every message handler.

- **fn** (`fun(clientId: number, packet: NetworkPacket, next: function)`) Middleware function that runs before message handlers. Receives the client ID, full packet, and a `next` function to call to continue processing. Middleware can modify the packet or perform actions before or after calling `next()`.

### server.onConnect(fn)

Called when a new client connects. fn(clientId)

- **fn** (`fun(clientId: number)`) Callback function that is called when a new client connects. Receives the client ID as an argument.

### server.onDisconnect(fn)

Called when a client disconnects. fn(clientId)

- **fn** (`fun(clientId: number)`) Callback function that is called when a client disconnects. Receives the client ID as an argument.

### server.enableAuth(db, opts)

Enable the built-in auth system.

- **db** (`Collection`) An Obsidian DB collection
- **opts** (`AuthOptions`, optional) Optional configuration for the auth system (e.g. password requirements)

### server.onTick(fn)

Register a callback to be called every server tick. fn(dt)

- **fn** (`fun(dt: number)`) Callback function that is called every server tick. Receives the delta time in seconds since the last tick as an argument.

### server.setTickRate(n)

Set the server tick rate (ticks per second, default 20).

- **n** (`number`) Desired tick rate (ticks per second). Must be a positive number; values less than 1 will be treated as 1.

### server.setTimeout(seconds)

Set the client timeout in seconds (0 to disable). Default 30.

- **seconds** (`number`) Desired timeout in seconds. Set to 0 to disable.

### server.setHeartbeatInterval(seconds)

Set the heartbeat interval in seconds (0 to disable). Default 5.

- **seconds** (`number`) Desired heartbeat interval in seconds. Set to 0 to disable automatic heartbeats.

### server.enableSequencing()

Enable per-client message sequence numbers.

### server.getPing(clientId)

Returns the last measured ping (ms) for a client, or nil if unknown.

- **clientId** (`number`) Client ID to query

- **returns** **ping** (`number|nil`) Last measured ping in milliseconds, or nil if no heartbeat response received yet

### server.sendToList(idList, msgType, data)

Send a typed message to a list of specific client IDs.

- **idList** (`number[]`) List of client IDs to send the message to
- **msgType** (`string`) Message type identifier
- **data** (`table`, optional) Optional message data payload

### server.init(protocol, hostname, side)

Initialise the server: open modem, host protocol.

- **protocol** (`string`) Protocol name to host (must match what clients connect to)
- **hostname** (`string`) Human-readable server name (used for discovery, can be same as protocol)
- **side** (`string`, optional) Optional modem side to use (e.g. "back"); if not specified, will use the first available modem

- **returns** **success** (`boolean`) True if the server was successfully initialized, false if there was an error (e.g. no modem found or failed to host protocol)

### server.stop()

Shut down the server, kick all clients, and close the modem.

### server.processEvent(rawEvent)

Process a single raw OS event. Called by server.run() internally or by the
Engine event loop for non-blocking integrated use.

- **rawEvent** (`table`) The raw event table as returned by os.pullEventRaw()

### server.start()

Start the server without blocking. Events must be fed via server.processEvent()
or by calling server.run(). Returns false if server.init() was not called first.

- **returns** **success** (`boolean`) True if the server started successfully, false if server.init() was not called

### server.run()

Run the server loop (blocking, for dedicated server computers).
Equivalent to server.start() followed by a manual os.pullEventRaw() loop.
