{noop} = require "./util"

# 5 bytes of data to represent the controller. Can be a slice of a byte array
InputSnapshot = (bytes) ->
  this.data = bytes
  return

Object.assign InputSnapshot,
  SIZE: 5 # size in bytes
  NULL: new Uint8Array 5
  bytesFrom: (controller) ->
    data = new Uint8Array(InputSnapshot.SIZE)
  
    if !controller
      return data
  
    {a, b, x, y, lb, rb, lt, rt, back, start, ls, rs, up, down, left, right, home, axes} = controller
  
    # buttons
    data[0] = (start<<7) + (back<<6) + (rb<<5) + (lb<<4) + (y<<3) + (x<<2) + (b<<1) + a
    data[1] = (home<<6) + (rs<<5) + (ls<<4) + (right<<3) + (left<<2) + (down<<1) + up
    # triggers
    data[2] = (triggerToNibble(rt) << 4 ) + triggerToNibble(lt)
    # axes
    data[3] = (axisToNibble(axes[1]) << 4 ) + axisToNibble(axes[0])
    data[4] = (axisToNibble(axes[3]) << 4 ) + axisToNibble(axes[2])
  
    return data

  from: (controller) ->
    new InputSnapshot InputSnapshot.bytesFrom(controller)

Object.defineProperties InputSnapshot::,
  a: get: -> @data[0] & 0x1
  b: get: -> (@data[0] & 0x2) >> 1
  x: get: -> (@data[0] & 0x4) >> 2
  y: get: -> (@data[0] & 0x8) >> 3
  lb: get: -> (@data[0] & 0x10) >> 4
  rb: get: -> (@data[0] & 0x20) >> 5
  lt: get: ->
    v = @data[2] & 0x0f
    if v > 0
      (v + 1) / 16
    else
      0
  rt: get: ->
    v = (@data[2] & 0xf0) >> 4
    if v > 0
      (v + 1) / 16
    else
      0
  back: get: -> (@data[0] & 0x40) >> 6
  start: get: -> (@data[0] & 0x80) >> 7
  ls: get: -> (@data[1] & 0x10) >> 4
  rs: get: -> (@data[1] & 0x20) >> 5
  up: get: -> @data[1] & 0x1
  down: get: -> (@data[1] & 0x2) >> 1
  left: get: -> (@data[1] & 0x4) >> 2
  right: get: -> (@data[1] & 0x8) >> 3
  home: get: -> (@data[1] & 0x40) >> 6
  axes: get: ->
    [
      nibbleToAxis  @data[3] & 0x0f
      nibbleToAxis (@data[3] & 0xf0) >> 4
      nibbleToAxis  @data[4] & 0x0f
      nibbleToAxis (@data[4] & 0xf0) >> 4
    ]

## Gamepads
# TODO: de-globalize this listener
window.addEventListener "gamepadconnected", ({gamepad}) ->
  {index, id, buttons, axes} = gamepad
  console.log """
    [#{index}]: #{id}
    #{buttons.map((x)->x.value.toFixed(1)).join(", ")}
    #{axes.map((x) -> x.toFixed(3)).join(", ")}
  """

KeyboardController = (keydown) ->
  this.keydown = keydown
  return this

Object.defineProperties KeyboardController::,
  a:     get: -> @keydown.Space|0
  b:     get: -> @keydown.KeyL|0
  x:     get: -> @keydown.KeyJ|0
  y:     get: -> @keydown.KeyK|0
  lb:    get: -> @keydown.KeyQ|0
  rb:    get: -> @keydown.KeyE|0
  lt:    get: -> 0
  rt:    get: -> 0
  back:  get: -> 0
  start: get: -> @keydown.Enter|0
  ls:    get: -> 0
  rs:    get: -> 0
  up:    get: -> @keydown.KeyX|0
  down:  get: -> @keydown.KeyC|0
  left:  get: -> @keydown.KeyZ|0
  right: get: -> @keydown.KeyV|0
  home:  get: -> 0
  axes:
    get: -> 
      x = (@keydown.KeyD|0) - (@keydown.KeyA|0)
      y = (@keydown.KeyS|0) - (@keydown.KeyW|0)

      [
        x
        y
        0
        0
      ]

# lt and rt are floats in range [0, 1]
# axes are floats [-1, 1]
# the rest of the buttons are bool on/off [0, 1]

Object.defineProperties Gamepad::,
  a: get: -> @buttons[0].value
  b: get: -> @buttons[1].value
  x: get: -> @buttons[2].value
  y: get: -> @buttons[3].value
  lb: get: -> @buttons[4].value
  rb: get: -> @buttons[5].value
  lt: get: -> @buttons[6].value
  rt: get: -> @buttons[7].value 
  back: get: -> @buttons[8].value
  start: get: -> @buttons[9].value
  ls: get: -> @buttons[10].value
  rs: get: -> @buttons[11].value
  up: get: -> @buttons[12].value
  down: get: -> @buttons[13].value
  left: get: -> @buttons[14].value
  right: get: -> @buttons[15].value
  home: get: -> @buttons[16].value

Object.assign Gamepad::,
  vibrate: ->
    @vibrationActuator.playEffect "dual-rumble", arguments...

# cid is string source id
# byteId is network identifier
BufferedController = (id, clientId, description, startTick=-1, bufferSize=BufferedController.defaultBufferSize) ->
  # Input starts with a blank input at tick -1 so `prev` is valid for frame 0
  # ~1MB = 1 hour of input frames

  @id = id # uint8
  @clientId = clientId # uint8
  @description = description # string
  
  @data = new Uint8Array bufferSize * InputSnapshot.SIZE
  @latestData = @startTick = startTick
  @tick = startTick+1 # current tick

  @current = new InputSnapshot @data
  @prev = new InputSnapshot @data
  @_update()

  @pressed = pressed = Object.create @
  @released = released = Object.create @

  BufferedController.BUTTONS.forEach (b) ->
    Object.defineProperty pressed, b,
      get: -> @current[b] and !@prev[b]

    Object.defineProperty released, b,
      get: -> !@current[b] and @prev[b]

  return this

Object.assign BufferedController,
  BUTTONS: "a b x y lb rb lt rt back start ls rs up down left right home".split " "
  defaultBufferSize: 60 * 60 * 60 # 1 hour of input snapshots

Object.assign BufferedController::,
  toString: ->
    "#{@clientId}:#{@id} #{@description}"
  # Updates current and prev snapshot pointers
  _update: ->
    {SIZE} = InputSnapshot

    t = @tick - @startTick
    @current.data = @data.subarray(t * SIZE, (t+1) * SIZE)
    @prev.data = @data.subarray((t - 1) * SIZE, t * SIZE)

    return

  # Update `current` and `prev` pointers to match the given tick.
  at: (tick) ->
    if @network and tick > @latestData
      console.warn "T:#{tick} > latest buffered data tick #{@latestData}"
      @tick = @latestData
    else
      @tick = tick

    @_update()

    return @

  dataAt: (tick) ->
    {SIZE} = InputSnapshot

    t = tick - @startTick
    @data.subarray(t * SIZE, (t+1) * SIZE)

  # c.recent(1).data == c.current.data
  # returns a subarray of the buffered data with the last entry for the current
  # tick
  recent: (n=15) ->
    t = @tick - @startTick
    {SIZE} = InputSnapshot
    
    if t <= 0
      return InputSnapshot.NULL

    s = max t - n + 1, 0

    @data.subarray(s * SIZE, (t+1) * SIZE)

  # reset controller data to be empty starting at the tick before this one
  reset: (tick) ->
    @startTick = tick-1
    @tick = tick
    @data.fill 0

  # Set the latest snapshot and update the current tick
  set: (tick, data) ->
    {SIZE} = InputSnapshot
    n = tick - @latestData
    # There is a gap in our buffer but if it's too far back don't fill in
    if 1 < n < 6
      fillData = @dataAt(@latestData)
      console.warn "T:#{tick} skipped #{n} input frames, filling in with #{fillData}"

      t = @latestData + 1 - @startTick
      i = 0
      while i < n
        # Fill in gap by duplicating latest data
        @data.set fillData, (t + i) * SIZE
        i++

      @latestData = @tick = tick
    else
      @latestData = @tick = tick
      t = tick - @startTick
      return if t < 0
  
      @data.set data, t * SIZE

    @_update()

    return

  # Tick is the current game tick that we are setting input for
  # we don't want to change anything in the past before that but we do want to
  # fill up as much input into the future as we have.
  bufferFromNetwork: (tick, input) ->
    {SIZE} = InputSnapshot
    {data} = input

    l = data.length / SIZE
    earliestTickReceived = input.tick - l + 1

    # Data insert index
    t = tick - @startTick
    
    if paused
      console.log "T:#{tick} <- BUFFER[#{earliestTickReceived}-#{input.tick}]"

    if earliestTickReceived <= tick
      sliceStartIndex = tick - earliestTickReceived
      @data.set data.subarray(sliceStartIndex * SIZE), t * SIZE
    else
      # Dropped n input frames
      n = earliestTickReceived - tick
      console.log("T:#{tick} INPUT DROPPED #{n} frames")
      @data.set data, (t + n) * SIZE

    @latestData = input.tick

    return

Object.defineProperties BufferedController::,
  key: get: ->
    (@clientId << 8) + @id

  axes: get: -> @current.axes
  a: get: -> @current.a
  b: get: -> @current.b
  x: get: -> @current.x
  y: get: -> @current.y
  lb: get: -> @current.lb
  rb: get: -> @current.rb
  lt: get: -> @current.lt
  rt: get: -> @current.rt
  back: get: -> @current.back
  start: get: -> @current.start
  ls: get: -> @current.ls
  rs: get: -> @current.rs
  up: get: -> @current.up
  down: get: -> @current.down
  left: get: -> @current.left
  right: get: -> @current.right
  home: get: -> @current.home

module.exports = InputSystem = (game) ->
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

    update: noop

    destroy: (game) ->
      document.removeEventListener "keydown", keydownHandler
      document.removeEventListener "keyup", keyupHandler

      controllerMap.clear()
      controllers.length = 0

Object.assign module.exports, {
  BufferedController
  Gamepad
  InputSnapshot
  KeyboardController
}
