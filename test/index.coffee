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

  it "should send data over the network", (done) ->
    @timeout 5000

    client = TinyGame()
    client.create()
    host = TinyGame()
    host.create()

    peer = host.hostGame()

    # Register a controller on client and server
    e = new window.Event "keydown"
    e.code = "Space"
    document.dispatchEvent e

    peer.on 'open', (hostId) ->
      clientPeer = client.joinGame(hostId)

      clientPeer.on 'error', done

      clientPeer.on 'open', ->
        setTimeout ->
          try
            host.update()
            client.update()

            setTimeout ->
              host.hosting.connections.forEach (c) ->
                c.send new Uint8Array 10
                c.send "wat"
                c.send new Blob ['wat']

              clientPeer._conn.send new Uint8Array 10

              host.update()
              host.update()
              client.update()

              host.system.network.status()
              client.system.network.status()
            , 100
            setTimeout ->
              host.update()
              client.update()
            , 200
          catch e
            done e

          setTimeout ->
            clientPeer.disconnect()
            clientPeer._conn.close()
            clientPeer._conn.send new Uint8Array 10
            peer.disconnect()
            host.destroy()
            client.destroy()
            done()
          , 500
        , 500

    peer.on 'error', done

  it "should close existing connections when hosting a new game", ->
    host = TinyGame()
    host.create()

    host.hostGame()

    called = false
    host.hosting.connections.push
      close: ->
        called = true

    host.localId = Math.random()
    host.hostGame()

    host.destroy()

    assert called

  it.skip "should discard out of order snapshots", (done) ->
    @timeout 5000

    client = TinyGame()
    client.create()
    host = TinyGame()
    host.create()

    # Register a controller on client and server
    e = new window.Event "keydown"
    e.code = "Space"
    document.dispatchEvent e

    hostPeer = host.hostGame()
    clientPeer = null

    hostPeer.on 'open', (hostId) ->
      clientPeer = client.joinGame(hostId)

      clientPeer.on 'error', done

      clientPeer.on 'open', ->
        setTimeout ->
          host.tick = 2
          host.update()
          host.tick = 1
          host.update()
        , 100

        setTimeout ->
          hostPeer.disconnect()
          clientPeer.disconnect()
          host.destroy()
          client.destroy()
          done()
        , 500

  it.skip "client should reconnect", (done) ->
    @timeout 5000

    client = TinyGame()
    client.create()
    host = TinyGame()
    host.create()

    peer = host.hostGame()
    clientPeer = null

    peer.on 'open', (hostId) ->
      clientPeer = client.joinGame(hostId)

      clientPeer.on 'error', done

      reconnected = false
      clientPeer.on 'disconnected', ->
        if !reconnected
          clientPeer.reconnect()

        reconnected = true

    setTimeout ->
      clientPeer.disconnect()
      host.destroy()
      done()
    , 500
