# flimg

FLIMG v1 binary image codec.

The on-disk format uses palette-indexed byte planes, independently encoded
frame patches, and periodic keyframes. It deliberately avoids textutils and
string.pack so the same module works on Lua 5.1/CraftOS-PC and CC:Tweaked.

## Reader

### Reader.new(data)

### Reader:take(length, label)

### Reader:u8(label)

### Reader:u16(label)

### Reader:i16(label)

### Reader:u32(label)

## flimg

### flimg.normalize(source)

Validates and canonicalizes an in-memory FLIMG image.

### flimg.rleEncode(data)

PackBits encoder. Repeated runs of at least three bytes are compressed.

### flimg.rleDecode(data, expectedLength)

### flimg.encode(source, options)

Encodes an image into the FLIMG v1 binary representation.

### flimg.decode(data)

Decodes a FLIMG v1 binary string into the canonical in-memory model.

### flimg.load(path)

### flimg.save(path, image, options)

### flimg.compose(image, frameIndex)

### flimg.fromBimg(bimg)

Converts a legacy BIMG table to a cell-mode FLIMG image.

### flimg.fromSprite(sprite, options)
