InputSnapshot = require "../../source/input/snapshot"

describe "InputSnapshot", ->
  it "should return null input bytes when no controller is given", ->
    InputSnapshot.bytesFrom null
