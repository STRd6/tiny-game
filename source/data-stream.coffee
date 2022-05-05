###*
DataStream

Read or write bytes to a DataView, auto-advancing the position.

DataView methods but with get/put instead of get/set.

@type {import("../types/types").DataStreamConstructor}
###
#@ts-ignore
DataStream = (buffer) ->
  @byteLength = buffer.byteLength
  @byteView = new Uint8Array buffer
  @view = new DataView buffer
  @position = 0

  return this

[8, 16, 32].forEach (size) ->
  bytes = size / 8

  ["getUint", "getInt"].forEach (type) ->
    #
    ###* @type {"getUint8" | "getUint16" | "getUint32" | "getInt8" | "getInt16" | "getInt32" } ###
    #@ts-ignore
    fn = type + size

    #
    ###* @type {(this: import("../types/types").DataStream, littleEndian?: boolean) => number} ###
    DataStream.prototype[fn] = (littleEndian) ->
      v = @view[fn](@position, littleEndian)
      @position += bytes
      return v

  ["setUint", "setInt"].forEach (type) ->
    #
    ###* @type {"setUint8" | "setUint16" | "setUint32" | "setInt8" | "setInt16" | "setInt32" } ###
    #@ts-ignore
    fn = type + size

    #
    ###* @type {(this: import("../types/types").DataStream, v: number, littleEndian?: boolean) => void} ###
    #@ts-ignore
    DataStream::[fn.replace(/^se/, "pu")] = (v, littleEndian) ->
      @view[fn](@position, v, littleEndian)
      @position += bytes
      return

  #
  ###* @type {(this: import("../types/types").DataStream, littleEndian?: boolean) => number} ###
  DataStream::getFloat32 = (littleEndian) ->
    v = @view.getFloat32(@position, littleEndian)
    @position += 4
    return v

  #
  ###* @type {(this: import("../types/types").DataStream, littleEndian?: boolean) => number} ###
  DataStream::getFloat64 = (littleEndian) ->
    v = @view.getFloat64(@position, littleEndian)
    @position += 8
    return v

  #
  ###* @type {(this: import("../types/types").DataStream, v: number, littleEndian?: boolean) => void} ###
  DataStream::putFloat32 = (v, littleEndian) ->
    @view.setFloat32(@position, v, littleEndian)
    @position += 4
    return

  #
  ###* @type {(this: import("../types/types").DataStream, v: number, littleEndian?: boolean) => void} ###
  DataStream::putFloat64 = (v, littleEndian) ->
    @view.setFloat64(@position, v, littleEndian)
    @position += 8
    return

{MAX_SAFE_INTEGER} = Number

# ascii is a subset of utf-8
utf8Decoder = new TextDecoder 'utf-8'
#
###* @type {import("../types/types").DataStream}###
#@ts-ignore
instanceMethods =
  bytes: ->
    return @byteView.subarray 0, @position

  done: ->
    @position >= @byteLength

  reset: ->
    @position = 0
    return

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

  getVarUint: ->
    result = 0
    loop
      b = @getUint8()
      #@ts-ignore
      if b & 0x80
        #@ts-ignore
        result += (b & 0x7f)
        result *= 0x80
      else
        #@ts-ignore
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
    return

Object.assign DataStream::, instanceMethods

module.exports = DataStream
