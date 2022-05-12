{Container, Sprite} = PIXI
Display = require "../../source/systems/display"

otherBehavior = {}

{KeyboardEvent} = window

describe "Display", ->
  it "should do stuff", ->
    displaySystem = Display
      config:
        screenWidth: 640
        screenHeight: 360

    displaySystem.render
      entities: [{
        behaviors: [{
          display: true
          name: "test"
          type: "object"
        }]
      }]

  it "should add cameras and objects", ->
    entities = []
    game =
      config:
        screenWidth: 640
        screenHeight: 360
      entities: entities

    displaySystem = Display game

    cameraBehavior =
      _system: displaySystem
      _tag: "display:camera:test"
      display: true
      name: "camera"
      type: "camera"
      display: (e) ->
        camera = new Container
        camera.viewport = camera

        return camera
      render: ->

    displaySystem.behaviorsAdded
      behaviors:
        "display:camera:test": cameraBehavior

    hudBehavior =
      _system: displaySystem
      display: true
      name: "hud"
      type: "hud"
      display: (e) ->
        new Container
      render: ->

    objectBehavior =
      _system: displaySystem
      display: true
      name: "object"
      type: "object"
      display: (e) ->
        new Sprite
      render: ->

    componentBehavior =
      _system: displaySystem
      display: true
      name: "component"
      type: "component"
      display: (e) ->
        new Sprite
      render: ->

    cameraEntity =
      ID: 1
      behaviors: [ cameraBehavior ]
    entities.push cameraEntity
    displaySystem.createEntity cameraEntity

    objectEntity =
      behaviors: [
        objectBehavior
        componentBehavior
        otherBehavior
      ]

    entities.push objectEntity
    displaySystem.createEntity objectEntity

    cameraEntity2 =
      ID: 2
      behaviors: [ cameraBehavior ]
    entities.push cameraEntity2
    displaySystem.createEntity cameraEntity2

    # HUD
    hudEntity =
      behaviors: [ hudBehavior ]
    entities.push hudEntity
    displaySystem.createEntity hudEntity

    displaySystem.create(game)
    displaySystem.render(game)

    displaySystem.destroyEntity cameraEntity2
    displaySystem.destroyEntity objectEntity
    displaySystem.destroy(game)

    entities.length = 0
    displaySystem.create(game)
    displaySystem.createEntity hudEntity
    displaySystem.destroyEntity hudEntity
    displaySystem.destroy(game)

  it "should toggle fullscreen when F11 is pressed", ->
    game =
      config:
        screenWidth: 640
        screenHeight: 360

    displaySystem = Display game

    called = false
    displaySystem.app.view.requestFullscreen = ->
      called = true
      Promise.resolve()

    # Ignores other key presses
    displaySystem.fullscreenHandler new KeyboardEvent "keydown",
      key: "a"

    assert !called

    mockEvent = new KeyboardEvent "keydown",
      key: "F11"
    displaySystem.fullscreenHandler mockEvent

    assert called

    do (origDocument=document) ->
      called = false
      global.document =
        #@ts-ignore
        fullscreenElement: document
        exitFullscreen: ->
          called = true
          Promise.resolve()

      assert !called
      displaySystem.fullscreenHandler mockEvent
      assert called

      global.document = origDocument
