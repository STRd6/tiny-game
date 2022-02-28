{triggerToNibble, axisToNibble, nibbleToAxis} = require "../util"

# 5 bytes of data to represent the controller. Can be a slice of a byte array
InputSnapshot = (bytes) ->
  this.data = bytes
  return

Object.assign InputSnapshot,
  SIZE: 5 # size in bytes
  NULL: new Uint8Array 5
  bytesFrom: (controller) ->
    data = new Uint8Array(InputSnapshot.SIZE)

    if !controller
      return data

    {a, b, x, y, lb, rb, lt, rt, back, start, ls, rs, up, down, left, right, home, axes} = controller

    # buttons
    data[0] = (start<<7) + (back<<6) + (rb<<5) + (lb<<4) + (y<<3) + (x<<2) + (b<<1) + a
    data[1] = (home<<6) + (rs<<5) + (ls<<4) + (right<<3) + (left<<2) + (down<<1) + up
    # triggers
    data[2] = (triggerToNibble(rt) << 4 ) + triggerToNibble(lt)
    # axes
    data[3] = (axisToNibble(axes[1]) << 4 ) + axisToNibble(axes[0])
    data[4] = (axisToNibble(axes[3]) << 4 ) + axisToNibble(axes[2])

    return data

  from: (controller) ->
    new InputSnapshot InputSnapshot.bytesFrom(controller)

Object.defineProperties InputSnapshot::,
  a: get: -> @data[0] & 0x1
  b: get: -> (@data[0] & 0x2) >> 1
  x: get: -> (@data[0] & 0x4) >> 2
  y: get: -> (@data[0] & 0x8) >> 3
  lb: get: -> (@data[0] & 0x10) >> 4
  rb: get: -> (@data[0] & 0x20) >> 5
  lt: get: ->
    v = @data[2] & 0x0f
    if v > 0
      (v + 1) / 16
    else
      0
  rt: get: ->
    v = (@data[2] & 0xf0) >> 4
    if v > 0
      (v + 1) / 16
    else
      0
  back: get: -> (@data[0] & 0x40) >> 6
  start: get: -> (@data[0] & 0x80) >> 7
  ls: get: -> (@data[1] & 0x10) >> 4
  rs: get: -> (@data[1] & 0x20) >> 5
  up: get: -> @data[1] & 0x1
  down: get: -> (@data[1] & 0x2) >> 1
  left: get: -> (@data[1] & 0x4) >> 2
  right: get: -> (@data[1] & 0x8) >> 3
  home: get: -> (@data[1] & 0x40) >> 6
  axes: get: ->
    [
      nibbleToAxis  @data[3] & 0x0f
      nibbleToAxis (@data[3] & 0xf0) >> 4
      nibbleToAxis  @data[4] & 0x0f
      nibbleToAxis (@data[4] & 0xf0) >> 4
    ]

module.exports = InputSnapshot
