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

module.exports = KeyboardController
