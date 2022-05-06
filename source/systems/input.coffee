{noop} = require "../util"

BufferedController = require "../input/buffered-controller"
InputSnapshot = require "../input/snapshot"
require "../input/gamepad" # Gamepad extensions
KeyboardController = require "../input/keyboard-controller"

## Gamepads

###* @type {InputSystemConstructor} ###
#@ts-ignore game unused
module.exports = (game) ->

  # Debugging info for gamepads
  ###* @param e {GamepadEvent} ###
  gamepadConnectedHandler = ({gamepad}) ->
    #@ts-ignore
    console.log gamepad.info

  # Keyboard handling using code (physical key without layout or modifiers)
  ###* @type {Keydown} ###
  keydown = {}
  #
  ###* @param e {KeyboardEvent} ###
  keydownHandler = ({code}) ->
    keydown[code] = true
  #
  ###* @param e {KeyboardEvent} ###
  keyupHandler = ({code}) ->
    keydown[code] = false

  keyboardController = new KeyboardController(keydown)

  controllerMap = new Map
  #
  ###* @type {BufferedController[]} ###
  controllers = []

  #
  ###* @type {InputSystem["updateController"]} ###
  updateController = (id, clientId, CID, tick, controller) ->
    existingController = self.getController(id, clientId)

    # not registered and any button pressed
    if !existingController and (controller.data[0] or controller.data[1])
      existingController = registerController(id, clientId, CID, tick)

    if existingController
      existingController.set tick, controller.data

    return

  #
  ###* @type {InputSystem["registerController"]} ###
  registerController = (id, clientId, CID, tick) ->
    c = new BufferedController id, clientId, CID, tick - 1
    key = (clientId << 8) + id
    controllerMap.set key, c

    console.log "Registered controller #{CID}"
    controllers.length = 0
    controllerMap.forEach (c) -> controllers.push c

    return c

  #
  ###* @type {InputSystem} ###
  self =
    name: "input"
    controllers: controllers
    controllerMap: controllerMap
    registerController: registerController
    updateController: updateController

    #@ts-ignore
    nullController: new BufferedController 0xff, 0xff, "NullController", -1, 10

    getController: (id, clientId) ->
      key = (clientId << 8) + id

      return controllerMap.get(key)

    resetControllers: (tick) ->
      controllers.forEach (controller) ->
        controller.reset(tick)
      return


    createEntity: noop
    destroyEntity: noop

    beforeUpdate: (game) ->
      {replaying, tick} = game

      # Check for any gamepads where start was pressed and add them to the list
      # of active controller ids
      if !replaying
        # clientId is 0 for local gamepads
        # TODO: need to re-register gamepads when joining a game
        clientId = game.system.network.clientId

        # Update gamepads
        # index 0-7 reserved for gamepads
        Array.from(navigator.getGamepads()).forEach (gamepad, index) ->
          #@ts-ignore number -> U8
          updateController index, clientId, "#{game.localId}-#{index}", tick, InputSnapshot.from(gamepad)

        # Update keyboard inputs
        # index 8-9 reserved for keyboard
        #@ts-ignore number -> U8
        updateController 8, clientId, "#{game.localId}-8", tick, InputSnapshot.from(keyboardController)

      # Update all controllers (network, replay, all) to be at current tick
      self.controllers.forEach (c) ->
        c.at(tick)

        # if c.network
        #   console.log c.current.data
        # if tick % 60 is 0
        #   console.log c.current.data

    #@ts-ignore
    create: (game) ->
      document.addEventListener "keydown", keydownHandler
      document.addEventListener "keyup", keyupHandler

      window.addEventListener "gamepadconnected", gamepadConnectedHandler

    update: noop

    #@ts-ignore
    destroy: (game) ->
      document.removeEventListener "keydown", keydownHandler
      document.removeEventListener "keyup", keyupHandler

      window.removeEventListener "gamepadconnected", gamepadConnectedHandler

      controllerMap.clear()
      controllers.length = 0

  return self


Object.assign module.exports, {
  BufferedController
  Gamepad
  InputSnapshot
  KeyboardController
}

#
###*
@typedef {import("../../types/types").BufferedController} BufferedController
@typedef {import("../../types/types").Controller} Controller
@typedef {import("../../types/types").InputSystem} InputSystem
@typedef {import("../../types/types").InputSystemConstructor} InputSystemConstructor
@typedef {import("../../types/types").Keydown} Keydown
###
