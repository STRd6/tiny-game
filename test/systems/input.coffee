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
