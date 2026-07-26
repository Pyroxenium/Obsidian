# network

Obsidian Engine: Low-level Network (Rednet Wrapper)
Injected by the bundler / init.lua loader; see src/init.lua.

## Types

### `NetworkClient`

Network Client class representing a connected client on the host.

| Field | Type | Description |
| --- | --- | --- |
| id | `number` | Computer ID |
| connectedAt | `number` | Timestamp (epoch ms) |
| lastPing | `number` | Last received ping timestamp |

### `NetworkModule`

Network Module providing high-level APIs for hosting, connecting, and messaging over rednet.

| Field | Type | Description |
| --- | --- | --- |
| modemSide | `string\|nil` | The side the modem is on (if any) |
| isOpen | `boolean` | Whether the modem is open |
| isHost | `boolean` | Whether this computer is currently hosting a protocol |
| serverId | `number\|nil` | The server ID this client is connected to (if any) |
| clients | `table<number, NetworkClient>` | Table of connected clients (host only) |

## Methods

### network.onMessage(fn)

Register a handler that receives all incoming messages.

- **fn** (`fun(sender:number, message:any, protocol?:string)`) 

- **returns** **unsubscribe** (`fun()`) Unsubscribe the handler

### network.offMessage(fn)

Remove a handler previously registered with `onMessage`.

- **fn** (`function`) The handler function to remove

### network.onMessageType(typeName, fn)

Register a handler for a given message.type.

- **typeName** (`string`) The message.type to handle
- **fn** (`fun(sender:number, message:any, protocol?:string)`) 

- **returns** **unsubscribe** (`fun()`) Unsubscribe the handler

### network.offMessageType(typeName, fn)

Remove a previously-registered message.type handler.
Note: Only removes the first occurrence if the function was registered multiple times.

- **typeName** (`string`) The message.type to handle
- **fn** (`function`) The handler function to remove

### network.open(side)

Open one or more modems.

- **side** (`string`, optional) Specific side to open. If nil, searches all sides.

- **returns** **success** (`boolean`) True if at least one modem was opened successfully.

### network.close()

Close all open modems.

### network.disconnect()

Disconnect from current session and close modems.
Sends SERVER_SHUTDOWN if host, or CLIENT_LEAVE if client.

### network.send(targetId, message, protocol)

Send a message to a specific target.

- **targetId** (`number`) Computer ID of the target
- **message** (`any`) Message to send (can be any serializable value)
- **protocol** (`string`, optional) Optional protocol to send on (defaults to current protocol)

- **returns** **success** (`boolean`) True if the message was sent successfully

### network.broadcast(message, protocol)

Broadcast a message to all reachable computers on the protocol.

- **message** (`any`) Message to broadcast (can be any serializable value)
- **protocol** (`string`, optional) Optional protocol to broadcast on (defaults to current protocol)

- **returns** **success** (`boolean`) True if the message was broadcast successfully

### network.connect(protocol, hostname, callback, timeout)

Connect to a server.

- **protocol** (`string`) Protocol to connect on
- **hostname** (`string`) Hostname to connect to
- **callback** (`fun(ok: boolean, reason: number|string)`, optional) result callback
- **timeout** (`number`, optional) Seconds to wait (default 5)

- **returns** **ok** (`boolean`) True if the connection process started successfully, false if there was an immediate error (e.g. no modem, already connecting)
- **returns** **reason** (`string?`) Error reason if the connection process failed to start, or if an immediate error occurred. Note that connection failures after starting will be reported via the callback and "network.connectionFailed" event, not this return value.

### network.cancelConnect(reason)

Cancel an in-flight connection attempt.

- **reason** (`string`, optional) Reason for cancellation

### network.host(protocol, hostname)

Host a protocol as a specific name.

- **protocol** (`string`) Protocol to host
- **hostname** (`string`) Hostname to host as

- **returns** **success** (`boolean`) True if hosting started successfully, false if there was an immediate error (e.g. no modem, already hosting)

### network.lookup(protocol, hostname)

Find a computer ID by hostname and protocol.

- **protocol** (`string`) Protocol to look up
- **hostname** (`string`) Hostname to look up

- **returns** **id** (`number|nil`) Computer ID if found, or nil if not found or if network is not open

### network.setHeartbeat(interval, timeout)

Configure heartbeat settings.

- **interval** (`number`, optional) Seconds between pings (default: 10)
- **timeout** (`number`, optional) Seconds before connection is considered dead (default: 30)

### network.processEvent(eventData)

Process raw OS events for network logic.
This is called by the engine's main event loop and should not be called directly.

- **eventData** (`table`) Raw event data from os.pullEvent
