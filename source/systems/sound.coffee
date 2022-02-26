FXXPlayer = require "../fxx-player"
{noop} = require "../util"

module.exports = (game) ->
  player = null

  self =
    create: ->
      player = FXXPlayer()
    createEntity: noop
    destroy: noop
    destroyEntity: noop
    player: player
    play: (name) ->
      # Don't play sounds for network replay
      # TODO: Maybe need a better name for this
      return if game.replaying
      player.play name
    update: noop

  game.sound = self

  return self
