FXXPlayer = require "../source/fxx-player"

mockContext = {}
fxxBuffer = new ArrayBuffer 240
b = new Uint8Array fxxBuffer
b[9] = 60

# Mock FXZ
global.FXZ = ->

describe "FXX Player", ->
  it "should play FXX", ->
    FXXPlayer(fxxBuffer, mockContext)
