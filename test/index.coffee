TinyGame = require "../source/index"

# Clean up PIXI tickers after all tests
after ->
  PIXI.Ticker.shared.stop()
  PIXI.Ticker.system.stop()

describe "TinyGame", ->
  it "should add classes and behaviors", ->
    game = TinyGame()

    game.behaviors =
      test:
        properties:
          yo: get: ->

    game.addBehaviors({
      wat: {}
    })

    TestClass = game.addClass
      behaviors: ["test"]

    TestClass()

    game.create()

    game.addEntity
      x: 'yolo'

    game.update()

    game.debugEntities()

    game.data()

    game.reloadBuffer game.dataBuffer()

    game.destroy()

  it "should have a crude checksum for classes", ->
    game = TinyGame()
    game.classChecksum()

  describe "buffer loading", ->
    it "should revert to a previous state", ->
      game = TinyGame()
      game.create()

      state = game.dataBuffer()

      game.addEntity {}
      game.update()
      assert.equal game.entities.length, 1

      nextState = game.dataBuffer()

      game.reloadBuffer state
      game.update()
      assert.equal game.entities.length, 0

      game.reloadBuffer nextState
      game.update()
      assert.equal game.entities.length, 1

      game.destroy()

    it "should throw an error when reloading an invalid buffer", ->
      game = TinyGame()
      assert.throws ->
        game.reloadBuffer new ArrayBuffer 10
      , /SNAPSHOT/

  it "should exec program", ->
    game = TinyGame()
    game.execProgram()

  it "should hard reset", ->
    game = TinyGame()
    game.hardReset()
    game.destroy()

  it "should render", ->
    game = TinyGame()
    game.render()

  it "should reload", ->
    game = TinyGame()

    reloadData =
      seed: 0x123
      tick: 4
      entities:[{
        behaviors: []
        a: "wat"
      }]

    game.reload reloadData
    game.reload reloadData

    reloadData.entities[0].ID = 5
    game.reload reloadData
