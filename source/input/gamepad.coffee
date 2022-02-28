# Extend the browser Gamepad object with some useful properties

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

  info: get: ->
    """
      [#{@index}]: #{@id}
      #{@buttons.map((x)->x.value.toFixed(1)).join(", ")}
      #{@axes.map((x) -> x.toFixed(3)).join(", ")}
    """

Object.assign Gamepad::,
  vibrate: ->
    @vibrationActuator.playEffect "dual-rumble", arguments...
