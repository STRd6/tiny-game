AdHocEntity = require "../ad-hoc-entity"
{
  DataType
  StateManager
  mapBehaviors
  toHex
} = require "../util"


#
###*
@type {import("../../types/types").BaseSystemConstructor}
###
module.exports = (game) ->
  {U8, I32} = DataType
  {assign, defineProperties, freeze} = Object

  #
  ###* @this {Behavior} ###
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

  #
  ###* @param behavior {Behavior} ###
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

  #
  ###* @param game {GameInstance} ###
  initBehaviors = (game) ->
    {behaviors, entities} = game

    # Initialize behavior table
    tags = Object.keys(behaviors)
    i = 0
    l = tags.length
    while i < l
      tag = tags[i++]
      assert tag
      behavior = behaviors[tag]
      assert behavior
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
        systemName = match[1]
        assert systemName
        #@ts-ignore
        sys = game.system[systemName]
        assert sys
        behavior._system = sys
      else
        behavior._system = game.system.base

    i = 0
    l = entities.length
    while i < l
      e = entities[i++]
      assert e
      e.behaviors = mapBehaviors e.behaviors, behaviors

    return

  nextClassId = 1
  #
  ###* @type {EntityConstructor<Entity>[]} ###
  classes = [AdHocEntity]
  #
  ###* @param id {number} ###
  getClassById = (id) ->
    klass = classes[id]
    assert klass
    return klass

  #
  ###* @param definition {import("../../types/types").ClassDefinition} ###
  addClass = ({behaviors:definedBehaviors, defaults, properties}) ->
    # Map behaviors from string tags into objects
    # TODO: maybe this can be simplified if everything is required to go through
    # addClass...
    behaviors = freeze mapBehaviors definedBehaviors, game.behaviors

    id = nextClassId++

    if id > 255
      # TODO: replace with varint?
      throw new Error "Can't create more than 256 classes!"

    # State data manager
    stateManager = new StateManager()

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
      assert b
      assign combinedProperties, b.properties

    # Optional implicit class properties in addition to behavior properties
    assign combinedProperties, properties

    proto =
      $data: null
      ###* @this {Entity} ###
      info: ->
        """
          #{toHex(@ID)} #{@$data.byteLength}/#{stateManager.size()} #{behaviors}
        """

      ###* @return {Object} ###
      toJSON: ->
        self = this

        Object.fromEntries jsonKeys.map (key) ->
          #@ts-ignore
          [key, self[key]]

    #@ts-ignore
    defineProperties proto, stateManager.bindProps(combinedProperties)

    # Save enumerable keys for toJSON method
    #@ts-ignore
    jsonKeys = Object.entries(Object.getOwnPropertyDescriptors(proto)).filter ([key, {enumerable}]) ->
      enumerable
    .map ([key]) ->
      key

    #
    ###* @type {EntityConstructor<Entity>} ###
    Constructor = (properties) ->
      e = Object.create(proto)

      e.$data = stateManager.alloc()
      e.$class = id

      return assign e, defaults, properties

    classes[id] = Constructor

    Constructor.byteLength = stateManager.size()
    # Construct from a backing buffer using the same memory reference
    #@ts-ignore
    Constructor.fromBuffer = (game, buffer, offset) ->
      e = Constructor()
      e.$data = new DataView buffer, offset, stateManager.size()

      return e

    return id

  # Add our mixins
  assign game,
    # define a class and return a constructor that adds entities as instances
    ###* @param definition {ClassDefinition} ###
    addClass: (definition) ->
      id = addClass definition

      # Create and add instance
      ###* @param properties {EntityProps} ###
      (properties) ->
        C = classes[id]
        assert C
        game.addEntity C(properties)

    classChecksum: ->
      classes.reduce (s, C) ->
        #@ts-ignore
        s + C.byteLength|0
      , 0

  #
  ###* @type {BaseSystem} ###
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
        assert e
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
        assert b
        b.create?(e)
      return

    updateEntity: (e) ->
      {behaviors} = e
      i = 0
      l = behaviors.length
      while i < l
        b = behaviors[i++]
        assert b
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
        assert b
        if e.die
          b.die?(e)
        b.destroy?(e)
      return

  return self

#
###*
@typedef {import("../../types/types").BaseSystem} BaseSystem
@typedef {import("../../types/types").Behavior} Behavior
@typedef {import("../../types/types").ClassDefinition} ClassDefinition
@typedef {import("../../types/types").GameInstance} GameInstance
@typedef {import("../../types/types").Entity} Entity
@typedef {import("../../types/types").EntityProps} EntityProps
###

#
###*
@template T
@typedef {import("../../types/types").EntityConstructor} EntityConstructor
###
