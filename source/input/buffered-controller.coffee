{max} = Math

InputSnapshot = require "./snapshot"

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

    if window.paused
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

module.exports = BufferedController
