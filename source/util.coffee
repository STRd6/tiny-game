{PI, abs, atan2, ceil, cos, floor, max, min, pow, random, sin, sign} = Math

## Util

# Approach target by amount
approach = (x, t, amount) ->
  if x > t
    max x - amount, t
  else if x < t
    min x + amount, t
  else
    t

clamp = (v, low, high) ->
  max min(v, high), low

noop = -> return

rand = (n) ->
  if Array.isArray n
    n[floor random() * n.length]
  else
    floor n * random()

# Generate a random string identifier
randId = ->
  (random() * pow(2, 53)).toString(36)

remove = (array, item) ->
  index = array.indexOf(item)

  if (index > -1)
    array.splice(index, 1)[0]

# Returns an unsigned integer containing 31 reasonably-well-scrambled
# bits, based on a given (signed) integer input parameter `n` and optional
# `seed`.  Kind of like looking up a value in a non-existent table of 2^31
# previously generated random numbers.
# https://www.youtube.com/watch?v=LWFzPP8ZbdU
squirrel3 = (n, seed=0) ->
    n *= 0xb5297a4d
    n += seed
    n ^= n >> 8
    n += 0x68e31da4
    n ^= n << 8
    n *= 0x1b56c4e9
    n ^= n >> 8

    return n

# Override default stop callback behavior
stopKeyboardHandler = (e, element, combo) ->
  # Don't stop for ctrl+key etc. even in textareas
  if combo.match /^(ctrl|alt|meta|option|command)\+/
    return false

  # stop for input, select, textarea, and content editable
  return element.tagName == 'INPUT' || 
    element.tagName == 'SELECT' || 
    element.tagName == 'TEXTAREA' || 
    (element.contentEditable && element.contentEditable == 'true')

wrap = (array, index) ->
  {length} = array
  index = floor(index) % length
  if index < 0
    index += length

  return array[index]

xorshift32 = (state) ->
	x = state.seed
	x ^= x << 13
	x ^= x >> 17
	x ^= x << 5

	return state.seed = x

## Input

# Store controller snapshots as byte arrays so they can travel the network

floatToUint8 = (f) ->
  if f < 0
    v = (f * 128)|0
  else if f > 0
    v = (f * 128 - 1)|0
  else
    v = 0

  v + 128

uint8ToFloat = (n) ->
  v = n - 128
  if v < 0
    v / 128
  else if v > 0
    (v + 1) / 128
  else
    0

# 0 zero 1-8 negative axis -0.125 - -1.0, 9-15 positive axis 0.25-1.0
axisToNibble = (f) ->
  # This could be < 0 instead of <= -0.25. The purpose is to discard jittery
  # values near 0 for better input compression options.
  if f <= -0.25
    v = (-f * 8)|0
  else if f >= 0.25
    v = (f * 8 + 7)|0
  else
    v = 0

  v & 0xf

nibbleToAxis = (n)  ->
  v = (n & 0xf)

  if v is 0
    0
  else if v <= 8
    -v / 8
  else
    (v - 7) / 8

triggerToNibble = (v) ->
  if v > 0
    (v * 16 - 1) & 0xf
  else
    0

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

# Convert a number to hex padding up to length with leading zeroes
toHex = (n, length=2) ->
  n.toString(16).padStart(length, "0")

###
DataStream

Read or write bytes to a DataView, auto-advancing the position.

DataView methods but with get/put instead of get/set.
###

DataStream = (buffer) ->
  @byteLength = buffer.byteLength
  @byteView = new Uint8Array buffer
  @view = new DataView buffer
  @position = 0

[8, 16, 32].forEach (size) ->
  bytes = size / 8

  ["getUint", "getInt"].forEach (type) ->
    fn = type + size
    DataStream::[fn] = (littleEndian) ->
      v = @view[fn](@position, littleEndian)
      @position += bytes
      return v

  ["setUint", "setInt"].forEach (type) ->
    fn = type + size
    DataStream::[fn.replace(/^se/, "pu")] = (v, littleEndian) ->
      @view[fn](@position, v, littleEndian)
      @position += bytes
      return

[32, 64].forEach (size) ->
  bytes = size / 8
  do ->
    fn = "getFloat" + size

    DataStream::[fn] = (littleEndian) ->
      v = @view[fn](@position, littleEndian)
      @position += bytes
      return v

  do ->
    fn = "setFloat" + size

    DataStream::[fn.replace(/^se/, "pu")] = (v, littleEndian) ->
      @view[fn](@position, v, littleEndian)
      @position += bytes
      return

do ->
  {MAX_SAFE_INTEGER} = Number

  # ascii is a subset of utf-8
  utf8Decoder = new TextDecoder 'utf-8'

  Object.assign DataStream::,
    # Subarray of bytes to send over the network
    # Classic pattern is to call reset, write out the data, then pass the result
    # of `bytes` directly to the socket.
    bytes: ->
      return @byteView.subarray 0, @position
  
    done: ->
      @position >= @byteLength
  
    reset: ->
      @position = 0

    getAscii: (length) ->
      utf8Decoder.decode @getBytes(length)

    putAscii: (str) ->
      bytes = new Uint8Array str.length

      str.split('').forEach (c, i) ->
        code = c.charCodeAt(0)

        if code >= 0x80
          throw new Error "Character out of range in '#{str}', index: #{i} char: #{c} (#{code} > #{0x80})"

        bytes[i] = code

      @putBytes bytes
  
    getBytes: (length) ->
      p = @position
      result = @byteView.subarray p, p + length
      @position += length
  
      return result
  
    putBytes: (bytes) ->
      @byteView.set(bytes, @position)
      @position += bytes.length
  
      return
  
    ###
    read a MIDI-style variable-length unsigned integer
    (big-endian value in groups of 7 bits,
    with top bit set to signify that another byte follows)
    ###
    getVarUint: ->
      result = 0
      loop
        b = @getUint8()
        if b & 0x80
          result += (b & 0x7f)
          result *= 0x80
        else
          return result + b
  
    putVarUint: (v) ->
      if v > MAX_SAFE_INTEGER
        throw new Error "Number out of range: #{v} > #{MAX_SAFE_INTEGER}"
  
      b = 0x2000000000000 # 2^49
  
      while b > 1
        if v >= b
          @putUint8( (v / b) | 0x80 )
        b /= 0x80
  
      @putUint8(v & 0x7f)

###
Enum

Experimental enum helper
###
createEnum = (values) ->
  Enum = (name, value) ->
    @name = name
    @value = value

    # Add integer and string keys to constructor object
    Enum[name] = @
    Enum[value] = @

    return

  Object.assign Enum::,
    toJSON: ->
      @name
    toString: ->
      @name
    valueOf: ->
      @value

  Enum.propertyFor = (key) ->
    get: ->
      Enum[@[key]]
    set: (v) ->
      @[key] = Enum[v]

  if typeof values is "string"
    values = values.split(/\s+/)

  values.forEach (name, value) ->
    new Enum(name, value)

  return Enum

###
DataType manages bit and byte access for entity properties. bind is called in
the context of the state manager. The property methods execute in the context
of the entity object. Don't let the different `this` scopes fool you.
###

DataType =
  # 0 or 1
  BIT:
    bytes: 0
    bits: 1
    bind: ->
      {offset, bit} = @reserveBits(1)

      enumerable: true
      get: ->
        (@$data.getUint8(offset) & (1 << bit)) >> bit
      set: (v) ->
        @$data.setUint8 offset, @$data.getUint8(offset) & (~(1 << bit)) | (!!v << bit)

  # -1 or 1
  UNIT:
    bytes: 0
    bits: 1
    bind: ->
      {offset, bit} = @reserveBits(1)

      enumerable: true
      get: ->
        (((@$data.getUint8(offset) & (1 << bit)) >> bit) - 0.5) * 2
      set: (v) ->
        v = (v / 2) + 0.5
        @$data.setUint8 offset, @$data.getUint8(offset) & (~(1 << bit)) | (!!v << bit)

  # 0-0xff (0-255)
  U8:
    bytes: 1
    bind: ->
      offset = @reserveBytes(1)

      enumerable: true
      get: ->
        @$data.getUint8(offset)
      set: (v) ->
        @$data.setUint8(offset, clamp v, 0, 0xff)

  U16:
    bytes: 2
    bind: ->
      offset = @reserveBytes(2)

      enumerable: true
      get: ->
        @$data.getUint16(offset)
      set: (v) ->
        @$data.setUint16(offset, clamp v, 0, 0xffff)

  U32:
    bytes: 4
    bind: ->
      offset = @reserveBytes(4)

      enumerable: true
      get: ->
        @$data.getUint32(offset)
      set: (v) ->
        @$data.setUint32(offset, clamp v, 0, 0xffffffff)

  # ! DANGER: this writes in little endian format (actually machine specific)
  # whereas DataView writes in big endian by default.
  # TODO: is there a good way to return an array-like that is efficient and
  # works well?
  U16A: (size) ->
    bytes: 2 * size
    bind: ->
      offset = @reserveBytes(2 * size)

      enumerable: true
      get: ->
        {buffer, byteOffset} = @$data

        return new Uint16Array(buffer, byteOffset + offset, size)

  FIXED16: (precision=0x100) ->
    bytes: 2
    bind: ->
      offset = @reserveBytes(2)

      enumerable: true
      get: ->
        @$data.getInt16(offset) / precision
  
      set: (v) ->
        @$data.setInt16(offset, v * precision)

  FIXED32: (precision=0x100) ->
    bytes: 4
    bind: ->
      offset = @reserveBytes(4)

      enumerable: true
      get: ->
        @$data.getInt32(offset) / precision

      set: (v) ->
        @$data.setInt32(offset, v * precision)

  I8:
    bytes: 1
    bind: ->
      offset = @reserveBytes(1)

      enumerable: true
      get: ->
        @$data.getInt8(offset)
  
      set: (v) ->
        @$data.setInt8(offset, clamp v, -0x80, 0x7F)

  I16:
    bytes: 2
    bind: ->
      offset = @reserveBytes(2)

      enumerable: true
      get: ->
        @$data.getInt16(offset)
  
      set: (v) ->
        @$data.setInt16(offset, clamp v, -0x8000, 0x7FFF)

  I32:
    bytes: 4
    bind: ->
      offset = @reserveBytes(4)

      enumerable: true
      get: ->
        @$data.getInt32(offset)
  
      set: (v) ->
        @$data.setInt32(offset, clamp v, -0x80000000, 0x7FFFFFFF)

  # Reserve a fixed number of bytes
  RESERVE: (length) ->
    bytes: length
    bind: ->
      offset = @reserveBytes(length)

      get: ->

###
Map state into bits and bytes. Make every byte count for the network!

Tracks offsets and total size, reserves bits and bytes using DataType
definitions.
###
StateManager = ->
  size = 0
  availableBits = 0
  lastBitOffset = null

  alloc: ->
    new DataView new ArrayBuffer size

  bindProps: (properties) ->
    keys = Object.keys(properties)
    i = 0
    o = {}
    while key = keys[i++]
      {bind} = definition = properties[key]

      if typeof bind is 'function'
        o[key] = bind.call @
      else
        o[key] = definition

    return o

  reserveBits: (n) ->
    if availableBits >= n
      offset = lastBitOffset
    else
      offset = lastBitOffset = size
      availableBits = 8
      size += 1

    bit = 8 - availableBits
    availableBits -= n

    offset: offset
    bit: bit

  reserveBytes: (n) ->
    offset = size
    size += n

    return offset

  size: ->
    size

module.exports = {
  DataStream
  DataType
  StateManager
  approach
  axisToNibble
  clamp
  createEnum
  floatToUint8
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
  xorshift32
  wrap
}
