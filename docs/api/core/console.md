# console

## Methods

### Console.isOpen()

Returns true if the console is currently open.

- **returns** (`boolean`) 

### Console.open()

Opens the console, allowing it to receive input and draw on screen.

### Console.close()

Closes the console and clears the input line (but not history).

### Console.toggle()

Toggles the console open/closed.

### Console.setEnv(env)

Set the Lua environment used when executing commands.
Called from engine.lua: Console.setEnv(setmetatable({Engine=Engine}, {__index=_G}))

- **env** (`table`) 

### Console.addLine(text, fg)

Add a line of text to the console history, splitting into multiple lines if needed.

- **text** (`any`) Text to add (will be converted to string)
- **fg** (`string`, optional) Optional foreground color code (default "0" = white)

### Console.print(text)

Write a line to the console output (callable from user code).

- **text** (`any`) Text to print (will be converted to string)

### Console.addCommand(name, fn, description)

Register a named command callable from the console.

- **name** (`string`) Command name (e.g. "test", "spawnPlayer")
- **fn** (`function`) Function to call. Receives any space-separated args as strings.
- **description** (`string`, optional) Optional help text shown by the built-in "help" command.

- **returns** (`nil`) 

### Console.removeCommand(name)

Remove a previously registered command.

- **name** (`string`) Command name to remove

- **returns** (`nil`) 

### Console.exec(cmd)

Execute a console command string.

- **cmd** (`string`) Command string to execute (e.g. "spawnPlayer Bob 100 200")

- **returns** (`nil`) 

### Console.handleEvent(event, consumed)

Process a raw event table.
When console is closed, only watches for the toggle character (^).
When open, consumes all events except term_resize.

- **event** (`table`) Raw event table: { eventName, p1, p2, ... }
- **consumed** (`boolean`, optional) true if the UI already consumed this event

- **returns** **true** (`boolean`) if the console consumed the event

### Console.draw(buf)

Draw the console overlay onto the provided buffer.
Should be called every frame after scene draw, before buf:present().

- **buf** (`BufferInstance`) 

- **returns** (`nil`) 
