# Base type behaviors for display system
# each `camera` gets added to stage
# each `object` gets added to all cameras
# each `hud` gets added to stage
# each `component` gets added to parent object
{noop} = require "../util"
{floor, min} = Math

#
###* @type {import("../../types/types").DisplaySystemConstructor} ###
DisplaySystem = (game) ->
  {screenWidth, screenHeight} = game.config

  cameraMap = new Map
  cameras = []
  huds = {}

  #@ts-ignore TODO global PIXI
  Object.assign PIXI.settings,
    #@ts-ignore TODO global PIXI
    SCALE_MODE: PIXI.SCALE_MODES.NEAREST

  #@ts-ignore TODO global PIXI
  app = new PIXI.Application
    width: screenWidth
    height: screenHeight
    backgroundColor: 0x323C39

  # Take more control of render step
  app._ticker.remove(app.render, app)
  app._ticker.stop()

  adjustResolution = ->
    res = floor min window.innerWidth / screenWidth, window.innerHeight / screenHeight
    renderer = app.renderer

    renderer.plugins.interaction.resolution = renderer.resolution = res
    renderer.resize(screenWidth, screenHeight)

  window.addEventListener "resize", adjustResolution
  adjustResolution()

  #
  ###* @param e {KeyboardEvent} ###
  fullscreenHandler = (e) ->
    {key} = e
    if key is "F11"
      e.preventDefault()
      if document.fullscreenElement
        document.exitFullscreen()
      else
        app.view.requestFullscreen()

  #
  ###*
  @param e {Entity}
  @param behavior {DisplayObjectBehavior}
  @param camera {Camera}
  ###
  addObjectToCamera = (e, behavior, camera) ->
    behavior.create?(e)
    displayObject = behavior.display(e)
    displayObject.entity = e
    displayObject.EID = e.ID

    camera.viewport.addChild displayObject
    camera.entityMap.set e.ID, displayObject

  #
  ###*
  @param e {Entity}
  @param behavior {DisplayComponentBehavior}
  @param name {string}
  @param camera {Camera}
  ###
  addComponentToCamera = (e, behavior, name, camera) ->
    behavior.create?(e)
    displayObject = behavior.display(e)
    displayObject.entity = e
    displayObject.EID = e.ID
    displayObject.name = name

    parent = camera.entityMap.get e.ID
    assert parent
    parent.addChild displayObject

  # If a camera is added after there are displayable objects then each of those
  # objects needs to be added to the camera
  ###*
  @param entities {Entity[]}
  @param camera {Camera}
  ###
  addEntitiesToCamera = (entities, camera) ->
    j = 0
    while e = entities[j++]
      {behaviors} = e
      i = 0
      l = behaviors.length
      while i < l
        b = behaviors[i++]
        assert b
        if b._system is self
          #
          ###* @type {DisplayBehavior} ###
          #@ts-ignore BLOCKED: https://github.com/jashkenas/coffeescript/issues/5418
          displayBehavior = b
          if displayBehavior.type is 'object'
            addObjectToCamera(e, displayBehavior, camera)
          else if displayBehavior.type is 'component'
            addComponentToCamera(e, displayBehavior, displayBehavior.name, camera)

    return



  self =
    app: app
    fullscreenHandler: fullscreenHandler
    name: "display"
    camera:
      create: (e, behavior) ->
        behavior.create?(e)
        camera = behavior.display(e)
        camera.entity = e

        camera.entityMap = new Map
        cameraMap.set e.ID, camera
        cameras.push camera

        addEntitiesToCamera game.entities, camera

        app.stage.addChild camera

        return

      render: (e, behavior) ->
        camera = cameraMap.get e.ID
        behavior.render(e, camera)
        return

      destroy: (e) ->
        cameraMap.get(e.ID).destroy
          children: true
        cameraMap.delete e.ID
        cameras = Array.from cameraMap.values()
        return

    # A component of another display object
    component:
      create: (e, behavior, name) ->
        cameras.forEach (camera) ->
          addComponentToCamera(e, behavior, name, camera)
        return

      render: (e, behavior, name) ->
        cameras.forEach (camera) ->
          parent = camera.entityMap.get e.ID

          behavior.render e, parent.getChildByName(name)
        return

      destroy: -> # Handled by parent

    object:
      create: (e, behavior) ->
        cameras.forEach (camera) ->
          addObjectToCamera e, behavior, camera
        return

      render: (e, behavior) ->
        cameras.forEach (camera) ->
          displayObject = camera.entityMap.get(e.ID)
          behavior.render e, displayObject
        return

      destroy: (e) ->
        cameras.forEach (camera) ->
          displayObject = camera.entityMap.get(e.ID)
          camera.entityMap.delete(e.ID)
          displayObject.destroy
            children: true
        return

    hud:
      create: (e, behavior, name) ->
        key = "#{name}:#{e.ID}"
        behavior.create?(e)
        hud = behavior.display(e)
        hud.EID = e.ID

        huds[key] = hud
        app.stage.addChild hud

        return

      render: (e, behavior, name) ->
        key = "#{name}:#{e.ID}"
        hud = huds[key]
        behavior.render(e, hud)
        return

      destroy: (e, behavior, name) ->
        behavior.destroy?(e)
        key = "#{name}:#{e.ID}"
        huds[key].destroy
          children: true
        delete huds[key]
        return

    createEntity: (e) ->
      {behaviors} = e
      i = 0
      while b = behaviors[i++]
        if b._system is self
          {name, type} = b
          self[type].create(e, b, name)
      return

    updateEntity: noop

    destroyEntity: (e) ->
      {behaviors} = e
      i = 0
      while b = behaviors[i++]
        if b._system is self
          {name, type} = b
          self[type].destroy(e, b, name)
      return

    behaviorsAdded: ({behaviors}) ->
      Object.values(behaviors).forEach (b) ->
        # Annotate display behaviors with type and name
        if b._system is self
          [_, type, name] = b._tag.split ":"
          b.type = type
          b.name = name
      return

    # When engine is created/initialized
    create: ->
      app._ticker.start()
      document.addEventListener "keydown", fullscreenHandler
      return

    # game.update
    update: noop

    # When engine is destroyed / reset
    destroy: ->
      app._ticker.stop()
      document.removeEventListener "keydown", fullscreenHandler

      cameras.forEach (camera) ->
        camera.destroy
          children: true
      cameraMap.clear()
      cameras.length = 0

      Object.values(huds).forEach (hud) ->
        hud.destroy
          children: true
      huds = {}

      return

    # When game.render is called
    render: ({entities}) ->
      i = 0
      while e = entities[i++]
        {behaviors} = e
        j = 0
        while b = behaviors[j++]
          if b.display
            {name, type} = b
            self[type].render(e, b, name)

      app.renderer.render(app.stage)

      return

  return self

module.exports = DisplaySystem

#
###*
@typedef {import("../../types/types").BaseSystem} BaseSystem
@typedef {import("../../types/types").DisplayBehavior} DisplayBehavior
@typedef {import("../../types/types").DisplayComponentBehavior} DisplayComponentBehavior
@typedef {import("../../types/types").DisplayObjectBehavior} DisplayObjectBehavior
@typedef {import("../../types/types").Camera} Camera
@typedef {import("../../types/types").ClassDefinition} ClassDefinition
@typedef {import("../../types/types").GameInstance} GameInstance
@typedef {import("../../types/types").Entity} Entity
@typedef {import("../../types/types").EntityProps} EntityProps
###
