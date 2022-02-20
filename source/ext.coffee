# extensions beyond system (fs, etc.)

{floor} = Math

{toHex} = require "./util"

{Rectangle, Texture} = PIXI

## Tilemaps

defaultPalette = """
#000000
#222034
#45283C
#663931
#8F563B
#DF7126
#D9A066
#EEC39A
#FBF236
#99E550
#6ABE30
#37946E
#4B692F
#524B24
#323C39
#3F3F74
#306082
#5B6EE1
#639BFF
#5FCDE4
#CBDBFC
#FFFFFF
#9BADB7
#847E87
#696A6A
#595652
#76428A
#AC3232
#D95763
#D77BBA
#8F974A
#8A6F30
""".toLowerCase().split("\n")

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

module.exports = {
  loadSpritesheet
  parseLevel
}
