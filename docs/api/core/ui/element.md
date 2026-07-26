# element

## Methods

### M.wrapText(text, maxW)

Word-wrap `text` to fit within `maxW` columns.
Splits on explicit newlines first, then wraps long paragraphs by word.

- **returns** **of** (`table`) line strings

### M.make(name, type_, x, y, config)

Build a flat element table from common parameters.

- **name** (`string`) Unique element name
- **type_** (`string`) Widget type ("button", "text", "input", …)
- **x** (`number`) Column relative to the context origin
- **y** (`number`) Row relative to the context origin
- **config** (`table|nil`, optional) Caller-supplied options

- **returns** **element** (`table`) 

### M.makeContainer(name, x, y, w, h, config)

Build a container element table. Containers clip and scroll their children.

- **name** (`string`) Unique element name
- **x** (`number`) Column relative to the context origin
- **y** (`number`) Row relative to the context origin
- **w** (`number`) Width in cells (required)
- **h** (`number`) Height in cells (required)
- **config** (`table|nil`, optional) Caller-supplied options

- **returns** **element** (`table`) 
