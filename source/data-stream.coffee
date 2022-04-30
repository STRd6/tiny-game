#@ts-nocheck TODO
###*
DataStream

Read or write bytes to a DataView, auto-advancing the position.

DataView methods but with get/put instead of get/set.

@type {DataStreamConstructor}
###

DataStream = (buffer) ->
  @byteLength = buffer.byteLength
  @byteView = new Uint8Array buffer
  @view = new DataView buffer
  @position = 0

  return this

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

module.exports = DataStream
