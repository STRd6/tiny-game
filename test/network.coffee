NetworkSystem = require "../source/network"

describe.skip "network", ->
  it "should do network stuff", ->
    game = {}
    networkSystem = NetworkSystem(game)

    networkSystem.create(game)
    game.hostGame()
    networkSystem.beforeUpdate(game)
