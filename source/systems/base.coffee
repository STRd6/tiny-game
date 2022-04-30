AdHocEntity = require "../ad-hoc-entity"
{
  DataType
  StateManager
  mapBehaviors
  toHex
} = util = require "../util"

module.exports = (game) ->
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
    l = tags.length
    while i < l
      tag = tags[i++]
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
    l = entities.length
    while i < l
      e = entities[i++]
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
    l = behaviors.length
    while i < l
      b = behaviors[i++]
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

    #@ts-ignore TODO
    Constructor.byteLength = stateManager.size()
    # Construct from a backing buffer using the same memory reference
    #@ts-ignore TODO
    Constructor.fromBuffer = (game, buffer, offset) ->
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
      l = es.length
      while i < l
        e = es[i++]
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

      i = 0
      l = behaviors.length
      while i < l
        b = behaviors[i++]
        b.create?(e)
      return

    updateEntity: (e) ->
      {behaviors} = e
      i = 0
      l = behaviors.length
      while i < l
        b = behaviors[i++]
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
      while i > 0
        b = behaviors[--i]
        if e.die
          b.die?(e)
        b.destroy?(e)
      return
