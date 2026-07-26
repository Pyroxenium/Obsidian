# buffer

Obsidian retained renderer.

Backwards compatible with the original Buffer API while adding:
  * logical RGB colors resolved through a sticky terminal palette mapper,
  * nested translation/clipping contexts,
  * a 2x3 subpixel canvas compiled into CC mosaic characters,
  * optional z-sorted surfaces with per-channel transparency.
Injected by the bundler / init.lua loader; see src/init.lua.

## Types

### `Buffer`

The compositor. Owns the terminal target, the stack of layers and the
palette mapper, and turns them into blit calls on `present()`. All legacy
drawing methods are delegated to the opaque default layer, so a Buffer can
be used exactly like a single surface.

| Field | Type | Description |
| --- | --- | --- |
| name | `string` | Name of the default layer ("default") |
| BufferModule | `table` | Back-reference to the module table |

### `Surface`

One drawing layer inside a Buffer. Cells left untouched on a transparent
surface stay nil and let lower layers show through; the default layer is
opaque and always resolves to a character, foreground and background.

| Field | Type | Description |
| --- | --- | --- |
| name | `string` | Unique layer name |
| zIndex | `number` | Lower values are composed first |
| visible | `boolean` | Whether the layer takes part in composition |

## Surface

### Surface:getSize()

Size of the layer in terminal cells.

- **returns** **size** (`number, number`) width and height in cells

### Surface:getVirtualSize()

Size of the layer in subpixels: two per cell horizontally, three vertically.

- **returns** **size** (`number, number`) width and height in subpixels

### Surface:setVisible(visible)

Show or hide the layer. A hidden layer keeps its content but is skipped
during composition.

- **visible** (`boolean`) 

- **returns** **self** (`Surface`) 

### Surface:setZIndex(zIndex)

Change the composition order. Layers with equal z keep their creation
order.

- **zIndex** (`number`) Lower values are composed first

- **returns** **self** (`Surface`) 

### Surface:push(x, y, width, height)

Push a translated local coordinate system and intersect its clip rectangle.
Subsequent draw calls treat (1,1) as (x,y) and are clipped to the given
box. Restore the previous context with `pop()`.

- **x** (`number`) Origin x in the current coordinate system
- **y** (`number`) Origin y in the current coordinate system
- **width** (`number`) Width of the clip rectangle in cells
- **height** (`number`) Height of the clip rectangle in cells

- **returns** **self** (`Surface`) 

### Surface:pop()

Restore the coordinate system and clip rectangle saved by the matching
`push()`. Errors on an unbalanced call.

- **returns** **self** (`Surface`) 

### Surface:setClip(x1, y1, x2, y2)

Legacy absolute clipping API. Prefer `push()`/`pop()`, which nest.

- **x1** (`number|nil`, optional) Left edge in cells (default 1)
- **y1** (`number|nil`, optional) Top edge in cells (default 1)
- **x2** (`number|nil`, optional) Right edge in cells (default buffer width)
- **y2** (`number|nil`, optional) Bottom edge in cells (default buffer height)

- **returns** **self** (`Surface`) 

### Surface:clearClip()

Drop any clip rectangle set by `setClip()` and draw to the whole layer.

- **returns** **self** (`Surface`) 

### Surface:clear(charValue, fore, back)

Reset every cell of the layer, discarding subpixels. On a transparent
layer, omitting an argument clears that channel back to transparent; on the
opaque default layer the omitted channels fall back to space on black.

- **charValue** (`string|nil`, optional) Fill character
- **fore** (`any|nil`, optional) Foreground colour (blit char, colors.* value, RGB handle or "#RRGGBB")
- **back** (`any|nil`, optional) Background colour

- **returns** **self** (`Surface`) 

### Surface:drawText(x, y, text, fore, back)

Draw a string, clipped to the current clip rectangle. Omitting a colour
leaves that channel untouched on a transparent layer.

- **x** (`number`) Column, 1-based, in the current coordinate system
- **y** (`number`) Row, 1-based
- **text** (`string`) Text to draw
- **fore** (`any|nil`, optional) Foreground colour
- **back** (`any|nil`, optional) Background colour

- **returns** **self** (`Surface`) 

### Surface:drawLine(y, text, fore, back)

Draw a full-width row, padding with spaces or truncating as needed.

- **y** (`number`) Row, 1-based
- **text** (`string`) Text to draw
- **fore** (`any|nil`, optional) Foreground colour
- **back** (`any|nil`, optional) Background colour

- **returns** **self** (`Surface`) 

### Surface:drawRect(x, y, width, height, charValue, fore, back)

Fill a rectangle with a single character.

- **x** (`number`) Left column, 1-based
- **y** (`number`) Top row, 1-based
- **width** (`number`) Width in cells
- **height** (`number`) Height in cells
- **charValue** (`string|nil`, optional) Fill character (default space)
- **fore** (`any|nil`, optional) Foreground colour
- **back** (`any|nil`, optional) Background colour

- **returns** **self** (`Surface`) 

### Surface:drawSprite(frame, x, y, camX, camY)

Draw one frame of an `.obs` sprite. Spaces in a layer are transparent, so
a cell keeps whatever was already there.

- **frame** (`SpriteFrame`) Frame table: [1]=chars, [2]=foreground, [3]=background
- **x** (`number`) World x of the sprite's top-left corner
- **y** (`number`) World y of the sprite's top-left corner
- **camX** (`number|nil`, optional) Camera x subtracted from the position
- **camY** (`number|nil`, optional) Camera y subtracted from the position

- **returns** **self** (`Surface`) 

### Surface:drawImage(image, x, y, frameIndex, camX, camY)

Draws a FLIMG image at terminal-cell coordinates. Pixel-mode images keep
their virtual pixels until the surface is composed; cell-mode images apply
channel transparency directly. Composed frames are cached on the image.

- **image** (`table`) Decoded FLIMG image from `loader.loadImage()`
- **x** (`number`) Cell column of the top-left corner
- **y** (`number`) Cell row of the top-left corner
- **frameIndex** (`number|nil`, optional) Frame to draw, clamped to the image (default 1)
- **camX** (`number|nil`, optional) Camera x subtracted from the position
- **camY** (`number|nil`, optional) Camera y subtracted from the position

- **returns** **self** (`Surface`) 

### Surface:drawSubpixel(vx, vy, value, bgValue)

Set one subpixel. Six subpixels share a cell (2 wide, 3 tall) and are
compiled into a mosaic character when the buffer is composed.

- **vx** (`number`) Subpixel column, 1-based
- **vy** (`number`) Subpixel row, 1-based
- **value** (`any`) Colour of the subpixel
- **bgValue** (`any|nil`, optional) Colour for the surrounding subpixels of that cell

- **returns** **self** (`Surface`) 

### Surface:drawSubpixelRect(vx, vy, width, height, value, bgValue)

Fill a rectangle in subpixel space.

- **vx** (`number`) Left subpixel column, 1-based
- **vy** (`number`) Top subpixel row, 1-based
- **width** (`number`) Width in subpixels
- **height** (`number`) Height in subpixels
- **value** (`any`) Fill colour
- **bgValue** (`any|nil`, optional) Colour for untouched subpixels of the covered cells

- **returns** **self** (`Surface`) 

### Surface:drawSubpixelLine(x1, y1, x2, y2, value)

Draw a Bresenham line in subpixel space.

- **x1** (`number`) Start subpixel column
- **y1** (`number`) Start subpixel row
- **x2** (`number`) End subpixel column
- **y2** (`number`) End subpixel row
- **value** (`any`) Line colour

- **returns** **self** (`Surface`) 

### Surface:clearSubpixels()

Discard every subpixel on the layer, leaving cell content untouched.

- **returns** **self** (`Surface`) 

### Surface:copyTo(target)

Snapshot the layer into a plain table, reusing its arrays when possible.
Scenes use this to cache their static background.

- **target** (`table`) Table to fill; receives t, f, b and the subpixel planes

- **returns** **target** (`table`) the same table, now holding the snapshot

### Surface:copyFrom(source)

Restore a snapshot produced by `copyTo()` over the whole layer.

- **source** (`table`) Snapshot table

- **returns** **self** (`Surface`) 

### Surface:restoreLine(y, source)

Restore a single row from a snapshot. This is the partial-redraw path:
only rows an entity touched last frame need to be put back.

- **y** (`number`) Row to restore, 1-based
- **source** (`table`) Snapshot table produced by `copyTo()`

- **returns** **self** (`Surface`) 

### Surface:present()

Compose and flush the owning buffer. Provided so a layer can stand in for
a Buffer in code that only draws and presents.

- **returns** **owner** (`Buffer`) 

## buffer

### buffer.new(width, height, targetTerm)

Create a buffer bound to a terminal-like target. Called with a single table
argument, that argument is taken as the target and the size is read from it.

- **width** (`number|table|nil`, optional) Width in cells, or the target terminal
- **height** (`number|nil`, optional) Height in cells
- **targetTerm** (`table|nil`, optional) Terminal-like target (default `term`)

- **returns** **buffer** (`Buffer`) 

## Buffer

### Buffer:getSize()

Size of the buffer in terminal cells.

- **returns** **size** (`number, number`) width and height in cells

### Buffer:getVirtualSize()

Size of the buffer in subpixels: two per cell horizontally, three vertically.

- **returns** **size** (`number, number`) width and height in subpixels

### Buffer:setSize(width, height)

Resize the buffer. Every layer is reset to empty, so redraw after calling
this; the engine does so on `term_resize`.

- **width** (`number`) New width in cells
- **height** (`number`) New height in cells

- **returns** **self** (`Buffer`) 

### Buffer:getTarget()

The terminal-like object this buffer writes to.

- **returns** **target** (`table`) 

### Buffer:addLayer(name, zIndex)

Add a transparent layer. Cells it never touches let lower layers show
through. Errors if the name is already taken.

- **name** (`string`) Unique layer name
- **zIndex** (`number|nil`, optional) Lower values are composed first (default 0)

- **returns** **layer** (`Surface`) 

### Buffer:getLayer(name)

Look a layer up by name.

- **name** (`string`) Layer name

- **returns** **layer** (`Surface|nil`) 

### Buffer:getLayers()

All layers in composition order, as a copy that is safe to iterate.

- **returns** **layers** (`Surface[]`) 

### Buffer:removeLayer(layerOrName)

Remove a layer. The default layer cannot be removed.

- **layerOrName** (`Surface|string`) Layer instance or its name

- **returns** **removed** (`boolean`) false if it was unknown or the default layer

### Buffer:getDefaultLayer()

The opaque layer that all the buffer's own drawing methods delegate to.

- **returns** **layer** (`Surface`) 

### Buffer:present()

Compose the layers and write the changed rows to the terminal. Rows that
are identical to what is already on screen are skipped, and the palette is
reassigned only for the colours actually visible this frame.

- **returns** **self** (`Buffer`) 

### Buffer:invalidate()

Forget what is currently on screen and force a full redraw on the next
`present()`. Use after something else has written to the terminal.

- **returns** **self** (`Buffer`) 

### Buffer:restorePalette()

Put every palette slot this buffer overrode back to its native colour.
The engine calls this on shutdown and before the panic screen.

- **returns** **self** (`Buffer`) 

### Buffer:compileSubpixels()

Compile pending subpixels into mosaic characters without flushing to the
terminal. `present()` does this anyway; call it directly only to inspect
the composed result first.

- **returns** **self** (`Buffer`) 
