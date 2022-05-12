SoundSystem = require "../../source/systems/sound"

describe "Sound", ->
  it "should play sounds", ->
    sound = SoundSystem({})
    sound.create()
    sound.play('wat')

  it "should not play sounds when game is replaying", ->
    #
    ###* @type {import("../../types/types").GameInstance} ###
    #@ts-ignore
    game =
      replaying: true
    sound = SoundSystem(game)
    sound.create(game)
    sound.play('wat')
