# extensions beyond system (fs, etc.)

loadSpritesheet = (path) ->
  fs.read(path)
  .then Image.fromBlob
  .then (img) ->
    # Canvas for the PIXIJS base texture
    canvas = document.createElement 'canvas'
    updateCanvas(canvas, img)

    # TODO: Handle hot reloading

    {width, height} = img
    tileWidth = 16
    tileHeight = 16
    tilesWide = floor width / tileWidth
    tilesTall = floor height / tileHeight

    textures = []

    baseTexture = Texture.from(canvas)
    i = 0
    while i < tilesWide * tilesTall
      x = i % tilesWide
      y = floor i / tilesWide
      texture = new Texture baseTexture,
        new Rectangle(x * tileWidth, y * tileHeight, tileWidth, tileHeight)
      texture.spritesheet = true
      textures[i] = texture
      i++

    return textures


# Convert a path to an image file into UInt8Array data using a palette
# simple hack to turn a pixel editor inte a tile editor
parseLevel = (path, palette=defaultPalette) ->
  fs.read path
  .then (blob) ->
    Image.fromBlob blob
  .then (img) ->
    {width, height} = img
    canvas = document.createElement 'canvas'
    canvas.width = width
    canvas.height = height

    ctx = canvas.getContext('2d')
    ctx.drawImage(img, 0, 0)

    imageData = ctx.getImageData 0, 0, width, height
    data = new Uint8Array width * height
    idd = imageData.data

    n = width * height
    for i in [0...n]
      p = i * 4
      r = idd[p++]
      g = idd[p++]
      b = idd[p++]
      data[i] = palette.indexOf("##{toHex(r)}#{toHex(g)}#{toHex(b)}")

    {
      data
      width
      height
    }
