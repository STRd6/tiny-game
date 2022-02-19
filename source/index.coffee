# engine/index.coffee
# stuff for the engine itself, not involved with editing, just running the game
# and providing the base environment

# Game engine itself, very much work in progress

mapBehaviors = (tags, table) ->
  result = []
  i = 0
  while tag = tags[i++]
    behavior = table[tag]
    if !behavior
      console.warn "Couldn't find behavior #{JSON.stringify(tag)}"
      continue

    result.push behavior

  return result

AdHocEntity = do ->
  {I32, U8, RESERVE} = DataType

  Constructor = (properties) ->
    {behaviors} = properties

    l = behaviors.length
    stateManager = new StateManager

    # These need to be first so we have a consistent byte order for the meta data
    combinedProperties =
      $class: U8
      behaviors:
        get: -> behaviors
        set: ->
        enumerable: true
      # Int32 so negative ids can be used for local objects
      # TODO: see if there is a better way to handle local non-network entities
      ID: I32
      $behaviorCount: U8
      # Reserve space for a uint16 array of behavior ids immediately after class byte, id int32, and behavior count uint8
      $behaviorIds: RESERVE(l * 2)
      $byteLength: 
        get: -> stateManager.size()
      $alloc:
        value: ->
          @$data = stateManager.alloc()
      $init:
        value: ->
          # Store class id of zero (optional since defaults to zero)
          @$class = 0

          # Store behavior count uint8
          @$behaviorCount = l

          {$data} = @
          # u8, i32, u8 = 6 bytes
          # TODO: This hardcoded offset is brittle
          offset = 6 
          # Write id for each behavior
          i = 0
          while i < l
            $data.setUint16(offset + 2 * i, behaviors[i]._id)
            i++
      info:
        value: ->
          """
            #{@ID} #{@$data.byteLength}/#{@$byteLength} #{behaviors}
          """

    i = 0
    while b = behaviors[i++]
      Object.assign combinedProperties, b.properties

    return Object.defineProperties {$data: null},
      stateManager.bindProps(combinedProperties)

  # Construct from a backing buffer using the same memory reference
  Constructor.fromBuffer = (buffer, offset) ->
    data = new DataView buffer, offset
    $class = data.getUint8(0)
    ID = data.getUint32(1)

    assert.equal $class, 0,
      "Attempted to use AdHocEntity constructor for a registered class: #{$class}"

    behaviorLength = data.getUint8(5)
    {getBehaviorById} = game.system.base

    behaviors = new Array behaviorLength
    i = 0
    while i < behaviorLength
      id = data.getUint16(6 + 2 * i)
      behavior = getBehaviorById(id)
      assert behavior, "Couldn't find behavior with id: #{id}"
      behaviors[i] = behavior
      i++

    e = Constructor({behaviors})
    e.$data = new DataView buffer, offset, e.$byteLength

    return e

  return Constructor


BaseSystem = (game) ->
  {U8, I32} = DataType
  {assign, defineProperties, freeze} = Object
  
  behaviorToJSON = -> @_tag

  # These maps don't get reset across program reloads
  # The goal is to maintain the same ids for the same behavior names during
  # live editing and development. If the ids shifted around then it could make
  # reloading the data from the bytecode very challenging
  #
  # When the game is published these maps will be created at startup and not
  # change during runtime. This will allow for correct network communication
  # among the same versions of the game.
  #
  # Once we have replays then we'll need to have a way to migrate ids as needed
  # to keep the data in sync.
  behaviorTagMap = new Map
  behaviorIdMap = new Map
  nextBehaviorId = 0

  registerBehavior = (behavior) ->
    {_tag: tag} = behavior
    previous = behaviorTagMap.get tag

    if previous
      # Keep the previous id and update the reference
      id = behavior._id = previous._id
      behaviorTagMap.set tag, behavior
      behaviorIdMap.set id, behavior
    else
      # Assign a new id and store lookups
      id = behavior._id = nextBehaviorId++
      behaviorTagMap.set tag, behavior
      behaviorIdMap.set id, behavior

  initBehaviors = (game) ->
    {behaviors, entities} = game

    # Initialize behavior table
    tags = Object.keys(behaviors)
    i = 0
    while tag = tags[i++]
      behavior = behaviors[tag]
      behavior._tag = tag

      # Assign byteId
      # same names should get the same id, even across reloads / restarts
      registerBehavior behavior

      # toJSON back to tags for sending over the network
      if !behavior.toJSON
        behavior.toJSON = behavior.toString = behaviorToJSON

      # Each behavior belongs to a system based on its name
      # display:camera:default
      # input:controller
      # flamable
      # player
      # 
      # Keep the simulation systems in the root space for better semantics
      # when people build their own behaviors. A person should be able to
      # make their entire game without needing to know anything about
      # systems
      match = tag.match /^([^:]+):/
      if match
        behavior._system = game.system[match[1]]
      else
        behavior._system = game.system.base

    i = 0
    while e = entities[i++]
      e.behaviors = mapBehaviors e.behaviors, behaviors

    return

  nextClassId = 1
  classes = [AdHocEntity]
  getClassById = (id) ->
    classes[id]

  addClass = ({behaviors, defaults, properties}) ->
    # Map behaviors from string tags into objects
    # TODO: maybe this can be simplified if everything is required to go through
    # addClass...
    behaviors = freeze mapBehaviors behaviors, game.behaviors

    id = nextClassId++

    if id > 255
      # TODO: replace with varint?
      throw new Error "Can't create more than 256 classes!"

    # State data manager
    stateManager = StateManager()

    # These need to be first since they have the $class id
    combinedProperties =
      $class: U8
      ID: I32 # ID is negative for client entities
      behaviors:
        value: behaviors
        writable: false
        enumerable: true

    i = 0
    while b = behaviors[i++]
      assign combinedProperties, b.properties

    # Optional implicit class properties in addition to behavior properties
    assign combinedProperties, properties

    proto =
      $data: null
      info: ->
        """
          #{toHex(@ID)} #{@$data.byteLength}/#{stateManager.size()} #{behaviors}
        """
      toJSON: ->
        self = this

        jsonKeys.reduce (o, key) ->
          o[key] = self[key]
          return o
        , {}

    defineProperties proto, stateManager.bindProps(combinedProperties)

    # Save enumerable keys for toJSON method 
    jsonKeys = Object.entries(Object.getOwnPropertyDescriptors(proto)).filter ([key, {enumerable}]) ->
      enumerable
    .map ([key]) ->
      key

    classes[id] = Constructor = (properties) ->
      e = Object.create(proto)

      e.$data = stateManager.alloc()
      e.$class = id

      return assign e, defaults, properties

    Constructor.byteLength = stateManager.size()
    # Construct from a backing buffer using the same memory reference
    Constructor.fromBuffer = (buffer, offset) ->
      e = Constructor()
      e.$data = new DataView buffer, offset, stateManager.size()

      return e

    return id

  # Add our mixins
  assign game,
    # define a class and return a constructor that adds entities as instances
    addClass: (definition) ->
      id = addClass definition

      # Create and add instance
      (properties) ->
        game.addEntity classes[id](properties)

    classChecksum: ->
      classes.reduce (s, C) ->
        s + C.byteLength|0
      , 0

  self =
    name: "base"
    initBehaviors: initBehaviors
    getBehaviorById: (id) ->
      behaviorIdMap.get id
    getClassById: getClassById

    create: (game) ->
      initBehaviors(game)

    # Update each entity according to its systems and behaviors
    # if any entities are added during the update they are held in a separate
    # list of pending entities then added together at the end of the loop.
    # Any entities that have been flagged with `.destroy` have the destroy
    # events called for their respective systems.

    # Entities must be stored in order of lowest to highest ID.

    update: (game) ->
      {entities, pendingEntities, destroyEntity} = game
      es = entities.concat pendingEntities
      pendingEntities.length = 0
      keep = []

      {updateEntity} = self

      i = 0
      while e = es[i++]
        updateEntity(e)

        if e.destroy
          destroyEntity e
        else
          keep.push e

      game.entities = keep.concat pendingEntities
      pendingEntities.length = 0

    destroy: ->
      nextClassId = 1
      classes = [AdHocEntity]

    # The `base` system handles common events for all behaviors:
    # - `create`
    # - `update`
    # - `destroy`

    createEntity: (e) ->
      {behaviors} = e

      # TODO: assign the correct prototype to the entity based on the set of 
      # behaviors

      i = 0
      while b = behaviors[i++]
        b.create?(e)
      return

    updateEntity: (e) ->
      {behaviors} = e
      i = 0
      while b = behaviors[i++]
        b.update?(e)
      return

    # Note: die is for things that drop items in game when killed, it is a
    # little weird here but not sure how else to implement it for the moment.
    # Basically `e.die` is set if something in the game world killed it:
    # taking damage, etc. Otherwise it is unset and the loot drop behavior won't
    # occur such as when removing an object from a state snapshot update.
    destroyEntity: (e) ->
      {behaviors} = e
      i = behaviors.length
      while b = behaviors[--i]
        if e.die
          b.die?(e)
        b.destroy?(e)
      return

Engine =
  Game: (options) ->
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
        if game.hosting
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
        displaySystem.create(self)

        return self.behaviors

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
          e = fromBuffer(buffer, p)

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

      sound:
        play: (name) ->
          fxxPlayer.play name

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

    Object.assign self,
      systems: [inputSystem, baseSystem, displaySystem, networkSystem]
      # Table of systems that behaviors map to
      system:
        base: baseSystem
        display: displaySystem
        network: networkSystem
        input: inputSystem

    return self
