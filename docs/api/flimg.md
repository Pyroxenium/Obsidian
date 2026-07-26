# flimg

FLIMG v1 binary image codec.

The on-disk format uses palette-indexed byte planes, independently encoded
frame patches, and periodic keyframes. It deliberately avoids textutils and
string.pack so the same module works on Lua 5.1/CraftOS-PC and CC:Tweaked.

## Methods

### flimg.normalize(source)

Validates and canonicalizes an in-memory FLIMG image.

### flimg.rleEncode(data)

PackBits encoder. Repeated runs of at least three bytes are compressed.

### flimg.rleDecode(data, expectedLength)

PackBits decoder, the counterpart to `rleEncode`.

### flimg.encode(source, options)

Encodes an image into the FLIMG v1 binary representation.

### flimg.decode(data)

Decodes a FLIMG v1 binary string into the canonical in-memory model.

### flimg.load(path)

Reads and decodes a .flimg file. Works with the CraftOS fs API and with
plain Lua io.

### flimg.save(path, image, options)

Encodes an image and writes it to a .flimg file, returning the byte count.

### flimg.compose(image, frameIndex)

Composes one canonical frame into canvas-sized palette-index rows.
For cell images each result row is {text, foreground, background}.

### flimg.fromBimg(bimg)

Converts a legacy BIMG table to a cell-mode FLIMG image.

### flimg.fromSprite(sprite, options)

Converts an Obsidian/OSF sprite table to a cell-mode FLIMG image.
Numeric power-of-two colors are interpreted as colors.* constants. Other
numeric values and #RRGGBB strings are stored as RGB colors.
