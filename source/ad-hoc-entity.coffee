{DataType, StateManager} = require "./util"
{I32, U8, RESERVE} = DataType

#
###*
@type {AdHocEntityConstructor}
###
#@ts-ignore
AdHocEntity = (properties) ->
  assert properties
  {behaviors} = properties

  l = behaviors.length
  stateManager = new StateManager

  # These need to be first so we have a consistent byte order for the meta data
  ###* @type {{[key: string]: PropertyDefinition}} ###
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

        #@ts-ignore TODO this is needed when building the docs since it doesn't use exactly the same transformations that CoffeeSense uses
        {$data} = @
        # u8, i32, u8 = 6 bytes
        # TODO: This hardcoded offset is brittle
        offset = 6
        # Write id for each behavior
        i = 0
        while i < l
          behavior = behaviors[i]
          assert behavior
          $data.setUint16(offset + 2 * i, behavior._id)
          i++
    info:
      value: ->
        """
          #{@ID} #{@$data.byteLength}/#{@$byteLength} #{behaviors}
        """

  i = 0
  while i < l
    b = behaviors[i++]
    assert b
    Object.assign combinedProperties, b.properties

  return Object.defineProperties {$data: null},
    #@ts-ignore
    stateManager.bindProps(combinedProperties)

#
###* @type {AdHocEntityConstructor["fromBuffer"]} ###
#@ts-ignore
AdHocEntity.fromBuffer = (game, buffer, offset) ->
  data = new DataView buffer, offset
  $class = data.getUint8(0)
  data.getUint32(1) # ID

  assert.equal $class, 0,
    "Attempted to use AdHocEntity constructor for a registered class: #{$class}"

  {getBehaviorById} = game.system.base
  behaviorLength = data.getUint8(5)
  #
  ###* @type {Behavior[]} ###
  behaviors = new Array behaviorLength
  i = 0
  while i < behaviorLength
    id = data.getUint16(6 + 2 * i)
    behavior = getBehaviorById(id)
    assert behavior, "Couldn't find behavior with id: #{id}"
    behaviors[i] = behavior
    i++

  e = AdHocEntity({behaviors})
  e.$data = new DataView buffer, offset, e.$byteLength

  return e

module.exports = AdHocEntity

#
###*
@typedef {import("../types/types").AdHocEntityConstructor} AdHocEntityConstructor
@typedef {import("../types/types").AdHocEntity} AdHocEntity
@typedef {import("../types/types").PropertyDefinition} PropertyDefinition
@typedef {import("../types/types").Behavior} Behavior
###
