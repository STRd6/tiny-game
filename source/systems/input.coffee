{noop, triggerToNibble, axisToNibble, nibbleToAxis} = require "../util"

BufferedController = require "../input/buffered-controller"
InputSnapshot = require "../input/snapshot"
require "../input/gamepad" # Gamepad extensions
KeyboardController = require "../input/keyboard-controller"

## Gamepads

module.exports = (game) ->

  # Debugging info for gamepads
  gamepadConnectedHandler = ({gamepad}) ->
    console.log gamepad.info

  # Keyboard handling using code (physical key without layout or modifiers)
  keydown = {}
  keydownHandler = ({code}) ->
    keydown[code] = true
  keyupHandler = ({code}) ->
    keydown[code] = false

  keyboardController = new KeyboardController(keydown)

  controllerMap = new Map
  controllers = []

  # Set of entities that have input controls
  entitiesControls = new Set

  # CID (controller ID) is a string to identify the controller. It should be
  # somewhat readable for easy debugging K0 is keyboard G0-3 are gamepads
  # Network controllers are prefixed with the client id.
  # id is a byte representing the id of the controller on the local system
  # clientId is a byte linking the controller to a network client
  # host's clientId is 0
  updateController = (id, clientId, CID, tick, controller) ->
    existingController = self.getController(id, clientId)

    # not registered and any button pressed
    if !existingController and (controller.data[0] or controller.data[1])
      existingController = registerController(id, clientId, CID, tick)

    if existingController
      existingController.set tick, controller.data

    return

  registerController = (id, clientId, CID, tick) ->
    c = new BufferedController id, clientId, CID, tick - 1
    key = (clientId << 8) + id
    controllerMap.set key, c

    console.log "Registered controller #{CID}"
    controllers.length = 0
    controllerMap.forEach (c) -> controllers.push c

    return c

  self =
    controllers: controllers
    controllerMap: controllerMap
    registerController: registerController

    nullController: new BufferedController 0xff, 0xff, "NullController", -1

    getController: (id, clientId) ->
      key = (clientId << 8) + id

      return controllerMap.get(key)

    resetControllers: (tick) ->
      controllers.forEach (controller) ->
        controller.reset(tick)

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
          updateController index, clientId, "#{game.localId}-#{index}", tick, InputSnapshot.from(gamepad)

        # Update keyboard inputs
        # index 8-9 reserved for keyboard
        updateController 8, clientId, "#{game.localId}-8", tick, InputSnapshot.from(keyboardController)

      # Update all controllers (network, replay, all) to be at current tick
      self.controllers.forEach (c) ->
        c.at(tick)

        # if c.network
        #   console.log c.current.data
        # if tick % 60 is 0
        #   console.log c.current.data

    create: (game) ->
      document.addEventListener "keydown", keydownHandler
      document.addEventListener "keyup", keyupHandler

      window.addEventListener "gamepadconnected", gamepadConnectedHandler

    update: noop

    destroy: (game) ->
      document.removeEventListener "keydown", keydownHandler
      document.removeEventListener "keyup", keyupHandler

      window.removeEventListener "gamepadconnected", gamepadConnectedHandler

      controllerMap.clear()
      controllers.length = 0

Object.assign module.exports, {
  BufferedController
  Gamepad
  InputSnapshot
  KeyboardController
}
