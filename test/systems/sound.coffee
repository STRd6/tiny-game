SoundSystem = require "../../source/systems/sound"

describe "Sound", ->
  it "should play sounds", ->
    sound = SoundSystem({})
    sound.create()
    sound.play('wat')

  it "should not play sounds when game is replaying", ->
    game =
      replaying: true
    sound = SoundSystem(game)
    sound.create()
    sound.play('wat')
