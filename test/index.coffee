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

      game.reloadBuffer state
      game.update()
      assert.equal game.entities.length, 0

      game.destroy()

    it "should throw an error when reloading an invalid buffer", ->
      game = TinyGame()
      assert.throws ->
        game.reloadBuffer new ArrayBuffer 10
      , /SNAPSHOT/
