# render

## Methods

### render.drawEl(buf, el, rx, ry, pressedEl, focusedEl, rowsToRestore)

Draw a single non-container element at absolute position (rx, ry).

- **buf** (`Buffer`) 
- **el** (`table`) Element table
- **rx** (`number`) Absolute render X
- **ry** (`number`) Absolute render Y
- **pressedEl** (`table|nil`, optional) Currently pressed element
- **focusedEl** (`table|nil`, optional) Currently focused element
- **rowsToRestore** (`table`) Table populated with touched row indices

### render.drawContainer(buf, el, rx, ry, ctx, rowsToRestore)

- **buf** (`Buffer`) 
- **el** (`table`) Container element table
- **rx** (`number`) Absolute render X
- **ry** (`number`) Absolute render Y
- **ctx** (`table`) UI context (for pressedElement / focusedElement)
- **rowsToRestore** (`table`) Table populated with touched row indices
