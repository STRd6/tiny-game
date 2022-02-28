InputSystem = require "../../source/systems/input"

describe "Input", ->
  it "should input stuff", ->
    game = {}

    inputSystem = InputSystem(game)

    inputSystem.create(game)
    inputSystem.update(game)
    inputSystem.destroy(game)

  it "should reset controllers", ->
    game = {}

    inputSystem = InputSystem(game)
    inputSystem.resetControllers 0

  it "should display info when gamepad is connected", ->
    inputSystem = InputSystem()

    inputSystem.create()
    e = new window.Event "gamepadconnected"
    e.gamepad = new Gamepad
    window.dispatchEvent e
    inputSystem.destroy()

  it "should detect input from keyboard controller", ->
    inputSystem = InputSystem()
    inputSystem.create()

    e = new window.Event "keydown"
    e.code = "Space"
    document.dispatchEvent e

    inputSystem.beforeUpdate
      replaying: false
      tick: 0
      system:
        network:
          clientId: "test"

    e = new window.Event "keyup"
    e.code = "Space"
    document.dispatchEvent e

    inputSystem.beforeUpdate
      replaying: true
      tick: 0
      system:
        network:
          clientId: "test"

    inputSystem.resetControllers(0)

    inputSystem.destroy()
