# buffer

Obsidian retained renderer.

Backwards compatible with the original Buffer API while adding:
  * logical RGB colors resolved through a sticky terminal palette mapper,
  * nested translation/clipping contexts,
  * a 2x3 subpixel canvas compiled into CC mosaic characters,
  * optional z-sorted surfaces with per-channel transparency.
Injected by the bundler / init.lua loader; see src/init.lua.

## Surface

### Surface:getSize()

### Surface:getVirtualSize()

### Surface:setVisible(visible)

### Surface:setZIndex(zIndex)

### Surface:push(x, y, width, height)

Push a translated local coordinate system and intersect its clip rectangle.

### Surface:pop()

### Surface:setClip(x1, y1, x2, y2)

Legacy absolute clipping API.

### Surface:clearClip()

### Surface:clear(charValue, fore, back)

### Surface:drawText(x, y, text, fore, back)

### Surface:drawLine(y, text, fore, back)

### Surface:drawRect(x, y, width, height, charValue, fore, back)

### Surface:drawSprite(frame, x, y, camX, camY)

### Surface:drawImage(image, x, y, frameIndex, camX, camY)

### Surface:drawSubpixel(vx, vy, value, bgValue)

### Surface:drawSubpixelRect(vx, vy, width, height, value, bgValue)

### Surface:drawSubpixelLine(x1, y1, x2, y2, value)

### Surface:clearSubpixels()

### Surface:copyTo(target)

### Surface:copyFrom(source)

### Surface:restoreLine(y, source)

### Surface:present()

## buffer

### buffer.new(width, height, targetTerm)

## Buffer

### Buffer:getSize()

### Buffer:getVirtualSize()

### Buffer:setSize(width, height)

### Buffer:getTarget()

### Buffer:addLayer(name, zIndex)

### Buffer:getLayer(name)

### Buffer:getLayers()

### Buffer:removeLayer(layerOrName)

### Buffer:getDefaultLayer()

### Buffer:present()

### Buffer:invalidate()

### Buffer:restorePalette()

### Buffer:compileSubpixels()
