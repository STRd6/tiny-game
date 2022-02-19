{DataStream} = require "../source/util"

describe "DataStream", ->
  buffer = new ArrayBuffer 8

  it "should write ascii values", ->
    dataStream = new DataStream buffer

    dataStream.putAscii("abcd1234")

    dataStream.reset()
    assert.equal dataStream.getAscii(8), "abcd1234"

  it "should throw an error when ascii is out of range", ->
    stream = new DataStream buffer

    assert.throws ->
      stream.putAscii "🍆"

  it "should know byte length", ->
    stream = new DataStream buffer

    assert.equal stream.byteLength, 8

  it "should get and put utf8"

  it "should get and put ascii", ->
    stream = new DataStream buffer

    stream.putAscii "hello"
    stream.reset()
    assert.equal stream.getAscii(5), "hello"

  it "should be done when buffer is full", ->
    stream = new DataStream new ArrayBuffer 0

    assert stream.done()
  
  it "should return a subarray of bytes up to the current position", ->
    stream = new DataStream buffer

    bytes = stream.bytes()
    assert.equal bytes.byteLength, 0

    stream.putInt32 5
    stream.putInt32 45

    bytes = stream.bytes()
    assert.equal bytes.byteLength, 8

  it "should get and set floats", ->
    stream = new DataStream buffer

    stream.putFloat32 128
    stream.reset()
    assert.equal stream.getFloat32(), 128

  it "should read and write varUints", ->
    dataStream = new DataStream new ArrayBuffer 8

    dataStream.putVarUint(0)
    assert.equal dataStream.position, 1

    dataStream.reset()
    dataStream.putVarUint(1 << 30)
    assert.equal dataStream.position, 5

    dataStream.reset()
    v = dataStream.getVarUint()
    assert.equal v, 1 << 30

    dataStream.reset()
    dataStream.putVarUint(128)
    assert.equal dataStream.position, 2

    dataStream.reset()
    v = dataStream.getVarUint()
    assert.equal v, 128

    dataStream.reset()
    v = dataStream.getUint8()
    assert.equal v, 0x81

    v = dataStream.getUint8()
    assert.equal v, 0

    dataStream.reset()
    dataStream.putVarUint(16383)
    assert.equal dataStream.position, 2

    dataStream.reset()
    assert.equal dataStream.getVarUint(), 16383

    dataStream.reset()
    dataStream.putVarUint(16384)
    assert.equal dataStream.position, 3

    dataStream.reset()
    assert.equal dataStream.getVarUint(), 16384

    dataStream.reset()
    dataStream.putVarUint(2097151) # (1 << 21) - 1
    assert.equal dataStream.position, 3

    dataStream.reset()
    assert.equal dataStream.getVarUint(), 2097151

    dataStream.reset()
    dataStream.putVarUint(2097152) # (1 << 21)
    assert.equal dataStream.position, 4

    dataStream.reset()
    assert.equal dataStream.getVarUint(), 2097152

    dataStream.reset()
    dataStream.putVarUint(268435455) # (1 << 28) - 1
    assert.equal dataStream.position, 4

    dataStream.reset()
    assert.equal dataStream.getVarUint(), 268435455

    dataStream.reset()
    dataStream.putVarUint(268435456) # (1 << 28)
    assert.equal dataStream.position, 5

    dataStream.reset()
    assert.equal dataStream.getVarUint(), 268435456

    dataStream.reset()
    dataStream.putVarUint(0x7fffffff)
    assert.equal dataStream.position, 5

    dataStream.reset()
    assert.equal dataStream.getVarUint(), 0x7fffffff

    dataStream.reset()
    dataStream.putVarUint(0x80000000)
    assert.equal dataStream.position, 5

    dataStream.reset()
    dataStream.putVarUint(Number.MAX_SAFE_INTEGER)
    assert.equal dataStream.position, 8

    dataStream.reset()
    assert.equal dataStream.getVarUint(), Number.MAX_SAFE_INTEGER

  it "should throw an error when placing a varInt that is too large", ->
    stream = new DataStream buffer

    assert.throws ->
      stream.putVarUint Math.pow(2, 64)
