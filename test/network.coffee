NetworkSystem = require "../source/network"

describe "network", ->
  it "should do network stuff", (done) ->
    game = {}
    networkSystem = NetworkSystem(game)

    networkSystem.create(game)
    peer = game.hostGame()

    networkSystem.beforeUpdate(game)

    peer.on 'open', ->
      peer.disconnect()
      done()
