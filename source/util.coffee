{floor, max, min, pow, random} = Math

## Util

###*
# Approach target by amount
# @param x {number} Starting number
# @param t {number} Target number
# @param amount {number} Maximum amount
###
approach = (x, t, amount) ->
  if x > t
    max x - amount, t
  else if x < t
    min x + amount, t
  else
    t

#
###*
@param arr {number[]} Array of numbers to average
###
average = (arr) ->
  if arr.length is 0
    return

  sum = arr.reduce (a, b) ->
    a + b
  , 0

  sum / arr.length

#
###*
Clamp a value to be between low and high.

@param v {number}
@param low {number}
@param high {number}
###
clamp = (v, low, high) ->
  max min(v, high), low

mapBehaviors = (tags, table) ->
  result = []
  i = 0
  l = tags.length
  while i < l
    tag = tags[i++]
    behavior = table[tag]
    if !behavior
      console.warn "Couldn't find behavior #{JSON.stringify(tag)}"
      continue

    result.push behavior

  return result

noop = -> return

#
###*
Get a random integer <= `n` or a random element from an array.
@param n {number[] | number}
###
rand = (n) ->
  if Array.isArray n
    n[floor random() * n.length]
  else
    floor n * random()

# Generate a random string identifier
randId = ->
  (random() * pow(2, 53)).toString(36)

#
###*
@template T
@param array {T[]}
@param item {T}
###
remove = (array, item) ->
  index = array.indexOf(item)

  if (index > -1)
    return array.splice(index, 1)[0]

  return undefined

#
###*
# Returns an unsigned integer containing 31 reasonably-well-scrambled
# bits, based on a given (signed) integer input parameter `n` and optional
# `seed`.  Kind of like looking up a value in a non-existent table of 2^31
# previously generated random numbers.
# https://www.youtube.com/watch?v=LWFzPP8ZbdU
#
# @param n {number}
# @param seed {number}
###
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

#
###*
@param f {number}
###
floatToUint8 = (f) ->
  if f < 0
    v = (f * 128)|0
  else if f > 0
    v = (f * 128 - 1)|0
  else
    v = 0

  v + 128

#
###*
@param n {number}
###
uint8ToFloat = (n) ->
  v = n - 128
  if v < 0
    v / 128
  else if v > 0
    (v + 1) / 128
  else
    0

#
###*
0 zero 1-8 negative axis -0.125 - -1.0, 9-15 positive axis 0.25-1.0
@param f {number}
###
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

#
###*
@param n {number}
###
nibbleToAxis = (n)  ->
  v = (n & 0xf)

  if v is 0
    0
  else if v <= 8
    -v / 8
  else
    (v - 7) / 8

#
###*
@param v {number}
###
triggerToNibble = (v) ->
  if v > 0
    (v * 16 - 1) & 0xf
  else
    0

#
###*
Convert a number to hex padding up to length with leading zeroes
@param n {number}
@param length {number}
###
toHex = (n, length=2) ->
  n.toString(16).padStart(length, "0")

#
###*
DataType manages bit and byte access for entity properties. bind is called in
the context of the state manager. The property methods execute in the context
of the entity object. Don't let the different `this` scopes fool you.

@type {DataTypeDefinitions}
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
        @$data.setUint8 offset, @$data.getUint8(offset) & (~(1 << bit)) | ((1 & v) << bit)

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
        @$data.setUint8 offset, @$data.getUint8(offset) & (~(1 << bit)) | ((1 & v) << bit)

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
      @reserveBytes(length)

      get: ->

###*
Map state into bits and bytes. Make every byte count for the network!

Tracks offsets and total size, reserves bits and bytes using DataType
definitions.
###
StateManager = ->
  size = 0
  availableBits = 0
  lastBitOffset = 0

  #
  ###* @type {StateManagerInstance} ###
  self =
    alloc: ->
      new DataView new ArrayBuffer size

    bindProps: (properties) ->
      ###* @type {{[key: string]: PropertyDescriptor}} ###
      o = {}
      context = this
      Object.entries(properties).forEach ([key, definition]) ->
        if "bind" of definition
          {bind} = definition
          o[key] = bind.call context
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

  return self

module.exports = {
  DataStream: require "./data-stream"
  DataType
  StateManager
  approach
  average
  axisToNibble
  clamp
  createEnum: require "./enum"
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
}

#
###*
@typedef {import("../types/types").DataTypeDefinitions} DataTypeDefinitions
@typedef {import("../types/types").StateManagerInstance} StateManagerInstance
@typedef {import("../types/types").PropertyDefinition} PropertyDefinition
###
