BufferedController = require "../../source/input/buffered-controller"
InputSnapshot = require "../../source/input/snapshot"
#
###* @type {import("../../types/types").U8} ###
#@ts-ignore
ID = 0

#
###* @type {import("../../types/types").U8} ###
#@ts-ignore
CID = 0

describe "BufferedController", ->
  it 'should use a buffer to track current and previous input', ->
    b = new BufferedController ID, CID

    b.key
    b.axes

    assert.equal b.lt, 0
    assert.equal b.rt, 0
    b.current.data[2] = 0xff
    assert.equal b.lt, 1
    assert.equal b.rt, 1

    BufferedController.BUTTONS.forEach (btn) ->
      b[btn]
      b.pressed[btn]
      b.released[btn]

    assert b.toString()

  it 'should return the null snapshot if there is no data for this tick', ->
    b = new BufferedController ID, CID

    b.startTick = 10

    assert.equal b.recent(1), InputSnapshot.NULL

  it "should not set data if in the past ", ->
    b = new BufferedController ID, CID
    b.startTick = 10
    b.set 0, InputSnapshot.NULL

  it "should drop input frames when receiving network inputs from the future", ->
    b = new BufferedController ID, CID
    b.bufferFromNetwork 1,
      tick: 5
      data: InputSnapshot.NULL
