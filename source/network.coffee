# Network Experiments
# max cross browser data packet size is 16 * 1024

{DataStream, noop} = require "./util"

module.exports = NetworkSystem = (game) ->

  INIT = 0x01
  INPUT = 0x02

  SNAPSHOT = 0x1f

  # Network status message sent to clients
  STATUS = 0x21
  # Acknowledge receiving data for a specific tick
  ACK = 0x22

  # TODO: consolidate message creation
  Msg =
    ack: (tick) ->
      sendStream.reset()

      sendStream.putUint8 ACK
      sendStream.putInt32 tick

      sendStream.bytes()

    # First message sent to client after connection is established.
    # sends seed to sync up procedural generation.
    # Don't need to send nextId because it will be impossible to keep in sync.
    # Many objects can be created on the server between snapshots received by
    # client.
    # Probably want to simulate with client only obects that don't predict until
    # receiving the actual server id (food type, item type, etc.). It looks bad
    # if a food swaps sprite, but should look fine if it starts as a blur/cloud
    # and pops in before hitting the ground.
    # in sync with the server
    init: (game, client) ->
      sendStream.reset()

      sendStream.putUint8 INIT
      sendStream.putUint8 client.id
      sendStream.putUint32 game.classChecksum()

      sendStream.bytes()

    input: (game) ->
      sendStream.reset()

      sendStream.putUint8 INPUT
      sendStream.putUint32 game.tick

      game.system.input.controllers.forEach (controller) ->
        sendStream.putUint8 controller.id
        bytes = controller.recent(3)
        sendStream.putUint8 bytes.length / InputSnapshot.SIZE
        sendStream.putBytes bytes

      sendStream.bytes()

    snapshot: (game) ->
      game.dataBuffer()

    status: (avgRtt) ->
      sendStream.reset()

      sendStream.putUint8 STATUS
      sendStream.putUint16 avgRtt

      sendStream.bytes()

  _handleDataMessage = ({data}) ->
    @emit "data", data

  send = (data) ->
    try
      @dataChannel.send data
    catch e
      console.error("DC#:#{@connectionId} Error when sending:", e)

      @close()

  ###
  Override `send` and `_handleDataMessage` of the peerjs dataconnection to
  gain full control over the serialization and data channel.
  ###
  modifyDataConnection = (c) ->
    Object.assign c,
      _handleDataMessage: _handleDataMessage
      send: send

  # target tick = 1/2 avg rtt + 1 frame
  host = null
  hosting =
    connections: []

  latestSnapshot =
    entities: []
    needsUpdate: false
    needsReset: true
    tick: -1

  targetTick = 0

  average = (arr) ->
    if arr.length is 0
      return

    sum = arr.reduce (a, b) ->
      a + b
    , 0

    sum / arr.length

  hostGame = ->
    # Close old connections
    hosting.connections?.forEach (conn) -> conn.close()
    connections = []

    nextClientId = 1
    # client string id -> client
    clientMap = new Map
    registerConnection = (client) ->
      key = client.peer
      existing = clientMap.get(key)
      if existing
        throw new Error "TODO: Handle client reconnection"

      id = nextClientId++

      if id > 0xff
        throw new Error "Too many client connections"

      client.id = id
      clientMap.set(key, client)

      connections.push client
      client.send Msg.init game, client

      return client

    peer = new peerjs.Peer(game.localId)

    peer.on 'error', console.error

    peer.on 'open', (id) ->
      console.log "Host connection open!", id

    peer.on 'connection', (client) ->
      console.log 'connection', client

      modifyDataConnection client

      client.tickMap = new Map
      client.rtts = []
      client.stats =
        received: 0 # bytes received from client

      client.on 'data', (data) ->
        if data.constructor is ArrayBuffer
          {byteLength} = data
          client.stats.received += byteLength

          recvStream = new DataStream data

          switch recvStream.getUint8()
            when ACK
              recvTick = recvStream.getUint32()
              rtt = performance.now() - client.tickMap.get(recvTick)
              client.rtts.unshift rtt
              client.rtts.length = min 300, client.rtts.length

              client.send Msg.status average client.rtts

            when INPUT
              {tick, system} = game

              recvTick = recvStream.getUint32()

              while recvStream.position < byteLength
                inputId = recvStream.getUint8()
                length = recvStream.getUint8()

                bytes = recvStream.getBytes length * InputSnapshot.SIZE

                CID = "#{client.peer}-#{client.id}:#{inputId}"
                if paused
                  console.log "T:#{tick} <- INPUT[#{recvTick}]", CID, bytes
                controller = system.input.getController(inputId, client.id)
                unless controller
                  controller = system.input.registerController(inputId, client.id, CID, tick)
                  controller.network = true

                controller.bufferFromNetwork tick,
                  tick: recvTick
                  data: bytes
            else
              console.log "T:#{tick} <- UNKNOWN", data
        else
          console.log "T:#{tick} <-", data

        return

      # Can't send until open
      client.on 'open', ->
        registerConnection(client)

      client.on 'close', ->
        console.log "Close", client
        if hosting.connections
          remove hosting.connections, client

    game.hosting = hosting = {connections}

    return peer

  joinGame = (hostId) ->
    # Re-init to make sure controllers pick up client id
    game.hardReset()

    game.hosting = hosting = false

    latestSnapshot =
      entities: []
      needsUpdate: false
      needsReset: true
      tick: -1

    id = game.localId
    peer = new peerjs.Peer(id)

    stats =
      # snapshots
      past: 0
      present: 0
      future: 0
      discard: 0
      doubleUpdate: 0

      # connection
      received: 0 # bytes received

    # setInterval ->
    #   console.log stats
    # , 5000

    peer.on 'error', console.error
    
    peer.on 'open', ->
      # Can't call connect until open occurs
      conn = peer.connect hostId
      conn.on 'error', console.error

      modifyDataConnection conn

      conn.on 'close', ->
        console.log "Closed connection", conn
        host = null

      conn.on 'open', ->
        host = conn
        conn.send 'hi!'

      conn.on 'data', (data) ->
        if typeof data is "string"
          stats.received += data.length

          console.log "T:#{game.tick} <- UNKNOWN", data
        else if data.constructor is ArrayBuffer
          recvStream = new DataStream data
          stats.received += data.byteLength

          switch recvStream.getUint8()
            when INIT
              clientId = recvStream.getUint8()
              
              # Checksum of data properties and protocol
              # sum of number of bytes each class's data uses
              # this can catch not-always-obvios errors where the client is on
              # a different version and time would be wasted debugging rather
              # than just refreshing the page.
              serverChecksum = recvStream.getUint32()
              clientChecksum = game.classChecksum()
              assert.equal serverChecksum, clientChecksum,
                "Class checksum must match. Server: #{serverChecksum}, Client: #{clientChecksum}"

              self.clientId = clientId

              console.log "Setting clientId: #{clientId}"

            when SNAPSHOT
              seed = recvStream.getUint32()
              tick = recvStream.getUint32()

              host.send Msg.ack tick

              if latestSnapshot.tick < tick
                latestSnapshot.tick = tick
                latestSnapshot.buffer = data
                if latestSnapshot.needsUpdate
                  stats.doubleUpdate++
                latestSnapshot.needsUpdate = true
              else
                stats.discard++

            when STATUS
              latestSnapshot.avgRtt = recvStream.getUint16() # ms
            else
              console.log "T:#{game.tick} <- UNKNOWN", data

  sendStream = new DataStream new ArrayBuffer 16 * 1024

  self =
    clientId: 0
    status: ->
      if hosting
        "connections:\n" + hosting.connections.map (c) ->
          rtts = c.rtts.slice(0, 10)

          "  #{c.peer} [#{rtts},...] avg: #{average rtts}"
        .join("\n")
      else
        "avg rtt: #{latestSnapshot.avgRtt}ms"

    create: (game) ->
      game.joinGame = joinGame
      game.hostGame = hostGame
      game.hosting = hosting

    createEntity: noop
    destroyEntity: noop

    beforeUpdate: (game) ->
      if !hosting
        # Send all local controllers to server
        if !game.replaying
          host?.send Msg.input game

        # Reconcile game state with previous states
        if latestSnapshot.needsUpdate
          latestSnapshot.needsUpdate = false
          {tick, entities, avgRtt} = latestSnapshot
          avgRtt ||= 150

          if latestSnapshot.needsReset
            game.system.input.resetControllers tick
            latestSnapshot.needsReset = false

          # This is our prevous latest tick
          # TODO: Prevent drift
          targetTick = tick + 2 + ceil avgRtt / 30
          # TODO: should prefer `game.tick + 1` so we don't skip inputs
          # should adjust update rate slightly to match target frame based on
          # network rtt

          # update game state from buffer data
          game.reloadBuffer(latestSnapshot.buffer)
          game.tick = tick

          # simulate up to current tick, replaying input
          while game.tick < targetTick
            game.replaying = true
            game.update()
          game.replaying = false

    update: noop

    afterUpdate: (game) ->
      if hosting and hosting.connections.length
        # if game.tick % 300 is 0
        #   console.log hosting.connections.map (c) ->
        #     c.rtts

        snap = game.dataBuffer()
        {connections} = hosting
        i = 0
        while connection = connections[i++]
          # track time to ack of outstanding requests
          connection.tickMap.set game.tick, performance.now()
          connection.send snap

      return

    destroy: ->
      # Close all connections
      hosting.connections?.forEach (conn) -> conn.close()
      host?.close()

      host = null
      hosting =
        connections: []

      targetTick = 0
      self.clientId = 0
