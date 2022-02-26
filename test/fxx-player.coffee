FXXPlayer = require "../source/fxx-player"

fxxBuffer = new ArrayBuffer 240
b = new Uint8Array fxxBuffer
b[8] = 48
b[9] = 74

# Mock FXZ
global.FXZ = -> {}

describe "FXX Player", ->
  it "should play FXX", ->
    player = FXXPlayer(fxxBuffer)

    player.play("0J")
    player.play("not-known")

    FXXPlayer(null)

  it "should bind to a new context", ->
    player = FXXPlayer(fxxBuffer)

    player.bind({})
