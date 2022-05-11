FXXPlayer = require "../fxx-player"
{noop} = require "../util"

###*
@param game {import("../../types/types").GameInstance}
@return {import("../../types/types").SoundSystem}
###
module.exports = (game) ->
  player = FXXPlayer()

  self =
    name: "sound"
    create: noop
    createEntity: noop
    destroy: noop
    destroyEntity: noop
    player: player
    ###* @param name {string} ###
    play: (name) ->
      # Don't play sounds for network replay
      # TODO: Maybe need a better name for this
      return if game.replaying
      player.play name
      return
    update: noop

  game.sound = self

  return self
