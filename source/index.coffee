# engine/index.coffee
# stuff for the engine itself, not involved with editing, just running the game
# and providing the base environment, very much work in progress

{floor} = Math

CustomTicker = require "./custom-ticker"
FXXPlayer = require "./fxx-player"

{
  DataType
  DataStream
  StateManager
  mapBehaviors
  rand
  randId
  toHex
} = util = require "./util"
ui = require "./pixi-ui"

BaseSystem = require "./systems/base"
DisplaySystem = require "./systems/display"
InputSystem = require "./systems/input"
NetworkSystem = require "./systems/network"
SoundSystem = require "./systems/sound"

module.exports = (options) ->
  # Need to start above zero so we can use negatives to represent client
  # predicted objects
  nextID = 1

  # Map from ID -> entity data for each active entity
  entityMap = new Map

  self =
    pendingEntities: []
    # Creates and adds an entity to the pending entities list,
    # pending entities get merged in at the end of each update loop
    # assigns the next ID to the entity as well.
    addEntity: (e) ->
      # uppercase ID is ECS entity id.
      if self.hosting
        e.ID = nextID++
      else # Client entities
        e.ID = -nextID++

      e.behaviors ?= self.defaultBehaviors
      # Re-hydrate behaviors
      e.behaviors = mapBehaviors e.behaviors, self.behaviors

      # Ad-hoc class
      if !e.$class?
        o = baseSystem.getClassById(0)(e)
        o.$alloc()
        o.$init()
        Object.assign o, e
        e = o

      self.pendingEntities.push self.createEntity(e)

      return e

    # List of all the behaviors
    behaviors: {}

    # Register and initialize behaviors that entities can use, using an array
    # of string tags
    addBehaviors: (behaviors) ->
      Object.assign self.behaviors, behaviors
      baseSystem.initBehaviors(self)
      # TODO: Maybe have an `addBehaviors` handler that systems can subscribe to.
      displaySystem.behaviorsAdded(self)

      return self.behaviors

    config:
      screenWidth: 640
      screenHeight: 360

    # Create / Initialize each subsystem
    create: ->
      {systems} = self

      # Roll a new random seed
      self.seed = floor rand 0x100000000

      # Initialize systems
      i = 0
      while system = systems[i++]
        system.create(self)

      return self

    # Create an entity by running the create method of each behavior it has
    # for each system.
    createEntity: (e) ->
      {systems} = self

      entityMap.set e.ID, e

      # Delegate to each system
      i = 0
      while system = systems[i++]
        system.createEntity(e)

      return e

    debugEntities: ->
      info = self.entities.map (e) ->
        e.info()
      .join("\n")

      console.log info

    # Export a JSON string of game data
    data: ->
      JSON.stringify
        entities: self.entities
        seed: self.seed
        tick: self.tick

    dataBuffer: ->
      # Header
      # msgType 0x1F SNAPSHOT
      # seed 4 bytes
      # tick 4 bytes

      # Add entities data length
      l = 9
      i = 0
      es = self.entities
      while e = es[i++]
        l += e.$data.byteLength

      buffer = new ArrayBuffer l
      dataStream = new DataStream buffer
      dataStream.putUint8 0x1F
      dataStream.putUint32 self.seed
      dataStream.putUint32 self.tick

      # write entities
      i = 0
      while e = es[i++]
        {buffer:b, byteOffset, byteLength} = e.$data
        dataStream.putBytes new Uint8Array(b, byteOffset, byteLength)

      return buffer

    # Reload from a backing buffer using it as references, not copying or
    # allocating a new array. Pass in a copy using `buffer.slice()`
    # to preserve old buffer.
    reloadBuffer: (buffer) ->
      # Hydrate entities array from buffer data
      dataStream = new DataStream buffer

      msgType = dataStream.getUint8()
      if msgType != 0x1F
        throw new Error "Expected SNAPSHOT message type 0x1f got 0x#{toHex(msgType)}"
      seed = dataStream.getUint32()
      tick = dataStream.getUint32()

      entities = []
      while !dataStream.done()
        $class = dataStream.getUint8()
        # Not advancing position because this is included in entity byte length
        p = --dataStream.position

        {fromBuffer} = baseSystem.getClassById($class)
        e = fromBuffer(self, buffer, p)

        dataStream.position += e.$data.byteLength
        entities.push e

      # Merge entity state
      toDestroy = new Set entityMap.keys()
      {createEntity, pendingEntities} = self

      entities.forEach (e) ->
        {ID} = e
        toDestroy.delete ID

        existing = entityMap.get(ID)

        if !existing
          console.log "creating #{ID}"

          pendingEntities.push createEntity e
        else # update
          # keep same reference to existing object
          # update state
          existing.$data = e.$data

      toDestroy.forEach (ID) ->
        console.log "set destroy flag #{ID}"
        # TODO: Should we actually destroy here instead of flaging?
        entityMap.get(ID).destroy = true

      self.seed = seed
      self.tick = tick

    # Default behaviors for entities added without any behavior list defined.
    defaultBehaviors: []

    # more of a reset really...
    # destroys all entities and restores game to empty initial state
    destroy: ->
      {destroyEntity, entities: es, systems} = self
      i = es.length
      while e = es[--i]
        destroyEntity e

      i = systems.length
      while system = systems[--i]
        system.destroy(self)

      self.entities.length = 0
      self.pendingEntities.length = 0

      nextID = 1
      self.tick = 0

      return self

    destroyEntity: (e) ->
      {systems} = self

      # Delegate to each system to handle their own destroy events
      i = systems.length
      while system = systems[--i]
        system.destroyEntity(e)

      entityMap.delete(e.ID)

      return e

    entities: []
    entityMap: entityMap

    execProgram: ->
      system.pkg.exec(self.program)

    hardReset: ->
      self.destroy()
      self.execProgram()
      self.create()

    localId: randId()

    # Reload game state from a json object or from the existing state
    reload: (data) ->
      data ?= JSON.parse self.data()

      {createEntity} = self
      {entities, seed, tick} = data

      toDestroy = new Set entityMap.keys()

      i = 0
      while e = entities[i++]
        {ID} = e
        toDestroy.delete ID

        # Rehydrate behaviors
        e.behaviors = mapBehaviors e.behaviors, self.behaviors

        if !entityMap.has ID
          console.log "creating #{ID}"

          self.pendingEntities.push createEntity e
        else # update
          # keep same reference to existing object
          Object.assign entityMap.get(ID), e

      toDestroy.forEach (ID) ->
        console.log "set destroy flag #{ID}"
        # All client entites are destroyed because they have negative e.IDs
        # some may be re-created during the simulation
        # others will correspond to entities received from the server
        entityMap.get(ID).destroy = true

      self.seed = seed
      self.tick = tick

    render: ->
      displaySystem.render(self)

    seed: 0

    systems: null
    system: null

    # Store textures by name and id for ease of use
    textures: []

    # Current game tick (frames)
    tick: 0

    update: ->
      {systems} = self

      i = 0
      while system = systems[i++]
        system.beforeUpdate?(self)

      i = 0
      while system = systems[i++]
        system.update(self)

      i = 0
      while system = systems[i++]
        system.afterUpdate?(self)

      self.tick++

      return self.tick

  # Init systems
  baseSystem = BaseSystem(self)
  displaySystem = DisplaySystem(self)
  networkSystem = NetworkSystem(self)
  inputSystem = InputSystem(self)
  soundSystem = SoundSystem(self)

  Object.assign self,
    systems: [inputSystem, baseSystem, displaySystem, networkSystem, soundSystem]
    # Table of systems that behaviors map to
    system:
      base: baseSystem
      display: displaySystem
      input: inputSystem
      network: networkSystem
      sound: soundSystem

  return self

Object.assign module.exports, {
  CustomTicker
  FXXPlayer
  ui
  util
}
