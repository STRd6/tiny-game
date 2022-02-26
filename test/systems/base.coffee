BaseSystem = require "../../source/systems/base"

describe "Base", ->
  it "should get behaviors by id", ->
    base = BaseSystem({})
    base.getBehaviorById(0)

  it "should trigger die when entity is destroyed", ->
    called = false

    base = BaseSystem({})
    e =
      behaviors: [
        die: ->
          called = true
      ]
      die: true
    base.destroyEntity(e)

    assert called

  it "should throw an error when creating more than 255 classes", ->
    game = {}
    base = BaseSystem(game)

    assert.throws ->
      for i in [0...256]
        game.addClass
          behaviors: []
    , /Can't create more than 256/

  it "should update behaviors of existing entites when initBehaviors is called", ->
    game =
      system:
        base: null
      behaviors:
        "test:cool": {}
      entities: [{
        behaviors: ["test:cool"]
      }]

    base = BaseSystem(game)
    game.system.base = base
    base.initBehaviors(game)
