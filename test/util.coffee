{
  DataType
  StateManager
  approach
  average
  axisToNibble
  clamp
  floatToUint8
  mapBehaviors
  nibbleToAxis
  noop
  rand
  randId
  remove
  squirrel3
  stopKeyboardHandler
  toHex
  triggerToNibble
  uint8ToFloat
  wrap
  xorshift32
} = require "../source/util"

describe "Util", ->

  it "approach", ->
    assert.equal approach(5, 10, 1), 6
    assert.equal approach(5, 10, 10), 10

    assert.equal approach(25, 10, 10), 15

    assert.equal approach(10, 10, 1), 10

  it "average", ->
    assert.equal average([]), undefined

  it "axisToNibble <-> nibbleToAxis", ->
    assert.equal axisToNibble(0), 0
    assert.equal axisToNibble(-1), 8
    assert.equal axisToNibble(1), 15

    assert.equal nibbleToAxis(0), 0
    assert.equal nibbleToAxis(15), 1
    assert.equal nibbleToAxis(8), -1

  it "clamp", ->
    assert.equal clamp(5, 1, 3), 3

  it "floatToUint8 <-> uint8ToFloat", ->
    assert.equal floatToUint8(0), 128
    assert.equal floatToUint8(-1), 0
    assert.equal floatToUint8(1), 255

    assert.equal uint8ToFloat(128), 0
    assert.equal uint8ToFloat(0), -1
    assert.equal uint8ToFloat(255), 1

  it "map behaviors", ->
    mapBehaviors ["not-there"], {}

  it "noop", ->
    assert.equal noop(), undefined

  it "rand", ->
    assert rand(10) < 10

    assert.equal rand([]), undefined
    assert.equal rand([1]), 1

  it "randId", ->
    assert randId()

  it "remove", ->
    a = [1, 2, 3]

    remove(a, 1)
    assert.deepEqual a, [2, 3]

    remove(a, 1)
    assert.deepEqual a, [2, 3]


  it "squirrel3", ->
    assert.equal squirrel3(0), 0x1a0a9606

  it "stopKeyboardHandler", ->
    e = new window.KeyboardEvent("keydown")
    element =
      tagName: "INPUT"
    combo = "ctrl+s"

    assert.equal stopKeyboardHandler(e, element, combo), false

    combo = "1"
    assert.equal stopKeyboardHandler(e, element, combo), true

    element =
      contentEditable: "true"
    assert.equal stopKeyboardHandler(e, element, combo), true

  it "toHex", ->
    assert.equal toHex(0), "00"
    assert.equal toHex(15), "0f"
    assert.equal toHex(240), "f0"

  it "triggerToNibble", ->
    assert.equal triggerToNibble(1), 15
    assert.equal triggerToNibble(0), 0

  it "wrap", ->
    assert.equal wrap([1, 2], 0), 1
    assert.equal wrap([1, 2], 1), 2

    assert.equal wrap([1, 2], -1), 2
    assert.equal wrap([1, 2], -2), 1
    assert.equal wrap([1, 2], -3), 2
    assert.equal wrap([1, 2], -4), 1

  it "xorshift32", ->
    c =
      seed: 123

    assert xorshift32(c)

  describe "DataType and StateManager", ->
    it "Should efficiently bind bits and bytes to memory locations", ->

      {BIT, U8, UNIT} = DataType

      props =
        b0: BIT
        b1: BIT
        b2: BIT
        b3: BIT
        b4: BIT
        b5: BIT
        b6: BIT
        b7: BIT
        u: U8
        b8: UNIT
        b9: BIT
        b10: BIT
        b11: BIT
        b12: BIT
        b13: BIT
        b14: BIT
        b15: BIT
        prop:
          get: -> "heyy"

      m = new StateManager()
      def = m.bindProps props

      o = Object.defineProperties {}, def

      o.$data = m.alloc()

      assert.equal m.size(), 3
      assert.equal o.$data.byteLength, 3

      assert.equal o.b0, false
      o.b0 = true
      assert.equal o.b0, true
      assert.equal o.prop, "heyy"

      assert.equal o.b8, -1
      o.b8 = 1
      assert.equal o.b8, 1

      assert.equal o.u, 0
      o.u = 1
      assert.equal o.u, 1

    it "should handle floats and ints of various sizes", ->
      {I8, I16, I32, U16, U32, FIXED16, FIXED32} = DataType

      props =
        i8: I8
        i16: I16
        i32: I32
        u16: U16
        u32: U32
        f16: FIXED16()
        f32: FIXED32()

      m = new StateManager()
      def = m.bindProps props

      o = Object.defineProperties {}, def

      o.$data = m.alloc()

      o.i8 = 16
      assert.equal o.i8, 16

      o.i16 = 16
      assert.equal o.i16, 16

      o.i32 = 16
      assert.equal o.i32, 16

      o.u16 = 16
      assert.equal o.u16, 16

      o.u32 = 16
      assert.equal o.u32, 16

      o.f16 = 16
      assert.equal o.f16, 16

      o.f32 = 16
      assert.equal o.f32, 16

    it "should reserve bytes", ->
      {RESERVE} = DataType

      m = new StateManager()
      def = m.bindProps
        r: RESERVE(24)

      o = Object.defineProperties {}, def

      o.$data = m.alloc()

      assert.equal o.$data.byteLength, 24

      o.r

    it "should read and write write U16 ararys", ->
      {U16A} = DataType

      m = new StateManager()
      def = m.bindProps
        u16: U16A(16)

      o = Object.defineProperties {}, def
      o.$data = m.alloc()

      assert.equal o.$data.byteLength, 32
      assert.equal o.u16.length, 16
