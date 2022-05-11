# Network Experiments
# max cross browser data packet size is 16 * 1024

#@ts-ignore
Peer = require "peerjs"
#@ts-ignore
Peer = Peer.default

{ceil, min} = Math
{DataStream, average, noop, remove} = require "../util"
InputSnapshot = require "../input/snapshot"

#
###* @type {NetworkSystemConstructor} ###
NetworkSystem = (game) ->
  #
  ###* @type {MessageTypes} ###
  messageTypes =
    #@ts-ignore
    INIT: 0x01
    #@ts-ignore
    INPUT: 0x02
    #@ts-ignore
    SNAPSHOT: 0x1f
    # Network status message sent to clients
    #@ts-ignore
    STATUS: 0x21
    # Acknowledge receiving data for a specific tick
    #@ts-ignore
    ACK: 0x22

  {INIT, INPUT, SNAPSHOT, STATUS, ACK} = messageTypes

  # TODO: consolidate message creation
  ###* @type {Msg} ###
  Msg =
    ack: (tick) ->
      sendStream.reset()

      sendStream.putUint8 ACK
      sendStream.putUint32 tick

      sendStream.bytes()

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
        #@ts-ignore bytes.length number -> U8
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

  #
  ###* @type {ExtendedConnection["_handleDataMessage"]}###
  _handleDataMessage = ({data}) ->
    @emit "data", data
    return

  #
  ###*
  @this {ExtendedConnection}
  @param data {ArrayBufferLike}
  ###
  send = (data) ->
    try
      @dataChannel.send data
    catch e
      console.error("DC#:#{@connectionId} Error when sending:", e)

      @close()

  #
  ###*
  Override `send` and `_handleDataMessage` of the peerjs dataconnection to
  gain full control over the serialization and data channel. Also track
  connection status metadata.
  @param c {DataConnection}
  @return {ExtendedConnection}
  ###
  modifyDataConnection = (c) ->
    #
    ###* @type {ConnectionMeta} ###
    #@ts-ignore
    connectionMeta =
      tickMap: new Map
      rtts: []
      stats:
        received: 0 # bytes received from client
      _handleDataMessage: _handleDataMessage
      send: send

    #@ts-ignore emit and connectionId aren't declared on connectionMeta, they are internal but available to `Peer.DataConnection`
    Object.assign c, connectionMeta

  # target tick = 1/2 avg rtt + 1 frame
  ###* @type {Peer.DataConnection | null} ###
  host = null
  #
  ###* @type {GameInstance["hosting"]} ###
  hosting =
    connections: []

  latestSnapshot =
    avgRtt: 150
    buffer: new ArrayBuffer 0
    needsUpdate: false
    needsReset: true
    tick: -1

  targetTick = 0

  #
  ###* @type {ExtendedConnection[]} ###
  connections = []
  nextClientId = 1
  # client string id -> client
  ###* @type {Map<string, ExtendedConnection>} ###
  clientMap = new Map

  hostGame = ->
    # Close old connections
    if hosting
      hosting.connections.forEach (conn) -> conn.close()
      try
        hosting.peer?.disconnect()

    connections.length = 0
    nextClientId = 1
    clientMap.clear()

    peer = new Peer(game.localId)

    peer.on 'error', console.error

    peer.on 'open', (id) ->
      console.log "Host connection open!", id

    peer.on 'connection', (c) ->
      # console.log 'connection', client
      client = modifyDataConnection c

      client.on 'data', (data) ->
        if data.constructor is ArrayBuffer
          {byteLength} = data
          client.stats.received += byteLength

          recvStream = new DataStream data

          switch recvStream.getUint8()
            when ACK
              recvTick = recvStream.getUint32()

              #TODO: Free old tickmap entries eventually
              #@ts-ignore
              rtt = performance.now() - client.tickMap.get(recvTick)
              client.rtts.unshift rtt
              client.rtts.length = min 300, client.rtts.length

              #@ts-ignore number -> U16
              client.send Msg.status average(client.rtts) or 0

            when INPUT
              {tick, system} = game

              recvTick = recvStream.getUint32()

              while recvStream.position < byteLength
                inputId = recvStream.getUint8()
                length = recvStream.getUint8()

                bytes = recvStream.getBytes length * InputSnapshot.SIZE

                CID = "#{client.peer}-#{client.id}:#{inputId}"
                # console.log "T:#{tick} <- INPUT[#{recvTick}]", CID, bytes

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
        self.registerConnection(client)
        return

      client.on 'close', ->
        # console.log "Close", client
        if hosting
          remove hosting.connections, client
        return

    game.hosting = hosting = {
      connections
      peer
    }

    return peer

  #
  ###*
  @param hostId {string}
  ###
  joinGame = (hostId) ->
    # Re-init to make sure controllers pick up client id
    game.hardReset()

    game.hosting = hosting = undefined

    latestSnapshot =
      avgRtt: 150
      buffer: new ArrayBuffer 0
      needsUpdate: false
      needsReset: true
      tick: -1

    id = game.localId
    peer = new Peer(id)

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

      #@ts-ignore Expose connection for testing / debugging. TODO: expose more cleanly
      peer._conn = conn

      conn.on 'close', ->
        # console.log "Closed connection", conn
        host = null

      conn.on 'open', ->
        host = conn
        conn.send 'hi!'

      conn.on 'data', (data) ->
        if data.constructor is ArrayBuffer
          recvStream = new DataStream data
          stats.received += data.byteLength

          switch recvStream.getUint8()
            when INIT
              clientId = recvStream.getUint8()

              # Checksum of data properties and protocol
              # sum of number of bytes each class's data uses
              # this can catch not-always-obvious errors where the client is on
              # a different version and time would be wasted debugging rather
              # than just refreshing the page.
              serverChecksum = recvStream.getUint32()
              clientChecksum = game.classChecksum()
              assert.equal serverChecksum, clientChecksum,
                "Class checksum must match. Server: #{serverChecksum}, Client: #{clientChecksum}"

              self.clientId = clientId

              # console.log "Setting clientId: #{clientId}"

            when SNAPSHOT
              recvStream.getUint32() # seed
              tick = recvStream.getUint32()

              assert host
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
        else # string
          stats.received += data.length
          console.log "T:#{game.tick} <- UNKNOWN", data

  sendStream = new DataStream new ArrayBuffer 16 * 1024

  #
  ###*
  @type {NetworkSystem}
  ###
  self =
    #@ts-ignore number -> U8
    clientId: 0
    registerConnection: (client) ->
      key = client.peer
      existing = clientMap.get(key)
      if existing
        throw new Error "TODO: Handle client reconnection"
        # remove connections, existing
        # existing.close()
        # id = existing.id
      else
        ###* @type {U8} ###
        #@ts-ignore number -> U8
        id = nextClientId++

      if id > 0xff
        throw new Error "Too many client connections"

      client.id = id
      clientMap.set(key, client)

      connections.push client
      client.send Msg.init game, client

      return client

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
          {tick, avgRtt} = latestSnapshot
          avgRtt ||= 150

          if latestSnapshot.needsReset
            #@ts-ignore number -> U32
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
          #@ts-ignore number -> U32
          game.tick = tick

          # simulate up to current tick, replaying input
          while game.tick < targetTick
            game.replaying = true
            game.update()
          game.replaying = false

      return

    update: noop

    afterUpdate: (game) ->
      if hosting and hosting.connections.length
        # if game.tick % 300 is 0
        #   console.log hosting.connections.map (c) ->
        #     c.rtts

        snap = Msg.snapshot(game)
        {connections} = hosting
        i = 0
        while connection = connections[i++]
          # track time to ack of outstanding requests
          connection.tickMap.set game.tick, performance.now()
          connection.send snap

      return

    destroy: ->
      # Close all connections
      hosting?.connections?.forEach (conn) -> conn.close()
      host?.close()

      host = null
      hosting =
        connections: []

      targetTick = 0
      #@ts-ignore number -> U8
      self.clientId = 0

      return

  return self

module.exports = NetworkSystem

#
###*
@typedef {import("peerjs").DataConnection} DataConnection
@typedef {typeof import("peerjs")} Peer

@typedef {import("../../types/types").ConnectionMeta} ConnectionMeta
@typedef {import("../../types/types").ExtendedConnection} ExtendedConnection
@typedef {import("../../types/types").GameInstance} GameInstance
@typedef {import("../../types/types").MessageTypes} MessageTypes
@typedef {import("../../types/types").Msg} Msg
@typedef {import("../../types/types").NetworkSystem} NetworkSystem
@typedef {import("../../types/types").NetworkSystemConstructor} NetworkSystemConstructor
@typedef {import("../../types/types").U8} U8
###
