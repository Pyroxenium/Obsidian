# color

Obsidian logical color registry and terminal palette mapper.

Render surfaces store one registry index per color cell as a raw byte. The
mapper assigns visible registry colors to the terminal's 16 hardware slots
only when a frame is presented. Native blit colors keep their slots while
custom RGB colors reuse currently invisible native slots.

## color

### color.rgb(r, g, b)

Register a reusable custom RGB color.
Accepts 0xRRGGBB, #RGB/#RRGGBB, 0-1 floats or 0-255 components.

- **returns** **handle** (`number`) Opaque color handle accepted by all draw methods.

### color.encode(value, default)

Encode a public color as a one-byte registry value.

- **value** (`any`) 
- **default** (`any|nil`, optional) Used only when value is nil.

- **returns** **byte** (`string|nil`) 

### color.indexOf(value)

### color.getRGB(index)

### color.newMapper(t)

Create a sticky palette mapper for one terminal-like target.

## Mapper

### Mapper:build(used)

Build a registry-byte -> blit-character map for the visible colors.

- **used** (`table<number, boolean>`) 

- **returns** **map** (`table`) 
- **returns** **forceRedraw** (`boolean`) 

### Mapper:restore()

Restore all palette slots changed by this mapper.
