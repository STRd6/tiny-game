AdHocEntity = require "../source/ad-hoc-entity"

describe "AdHocEntity", ->
  it "should have info", ->
    e = AdHocEntity
      behaviors: []

    e.$alloc()
    e.$init()
    e.ID = 5

    assert e.info()

  it "should have properties from behaviors", ->
    e = AdHocEntity
      behaviors: [
        _id: 7
        properties:
          x: get: -> 5
      ]

    e.$alloc()
    e.$init()

    assert.equal e.x, 5

  it "should reconstruct from data buffer", ->
    behaviors = [
      undefined
      {
        _id: 1
        properties:
          y: get: -> 3
      }
    ]

    getBehaviorById = (id) ->
      behaviors[id]

    e = AdHocEntity
      behaviors: [behaviors[1]]

    e.$alloc()
    e.$init()

    game =
      system:
        base:
          getBehaviorById: getBehaviorById

    e2 = AdHocEntity.fromBuffer game, e.$data.buffer, 0

    assert.equal e2.ID, e.ID

    delete global.game
