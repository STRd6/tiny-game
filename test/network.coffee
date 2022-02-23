NetworkSystem = require "../source/network"

describe "network", ->
  it "should do network stuff", (done) ->
    @timeout 5000
    game =
      classChecksum: -> 0
      dataBuffer: ->
        new Uint8Array 10
    networkSystem = NetworkSystem(game)

    networkSystem.create(game)
    peer = game.hostGame()

    networkSystem.beforeUpdate(game)

    peer.on 'open', (hostId) ->
      clientGame =
        classChecksum: -> 0
        hardReset: ->
        system:
          input:
            controllers: [
            ]
      clientNet = NetworkSystem clientGame
      clientNet.create(clientGame)
      clientPeer = clientGame.joinGame(hostId)

      clientPeer.on 'error', done

      clientPeer.on 'open', ->
        setTimeout ->
          try
            clientNet.beforeUpdate(clientGame)
            networkSystem.afterUpdate(game)
          catch e
            done e

          setTimeout ->
            clientPeer.disconnect()
            peer.disconnect()
            clientNet.destroy()
            networkSystem.destroy()
            done()
          , 500
        , 500

    peer.on 'error', done
