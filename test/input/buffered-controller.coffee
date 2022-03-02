BufferedController = require "../../source/input/buffered-controller"
InputSnapshot = require "../../source/input/snapshot"

describe "BufferedController", ->
  it 'should use a buffer to track current and previous input', ->
    b = new BufferedController

    b.key
    b.axes

    BufferedController.BUTTONS.forEach (btn) ->
      b[btn]
      b.pressed[btn]
      b.released[btn]

    assert b.toString()

  it 'should return the null snapshot if there is no data for this tick', ->
    b = new BufferedController

    b.startTick = 10

    assert.equal InputSnapshot.NULL, b.recent(1)

  it "should not set data if in the past ", ->
    b = new BufferedController
    b.startTick = 10
    b.set 0, InputSnapshot.NULL

  it "should drop input frames when receiving network inputs from the future", ->
    b = new BufferedController
    b.bufferFromNetwork 1,
      tick: 5
      data: InputSnapshot.NULL
