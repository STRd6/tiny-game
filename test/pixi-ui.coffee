{HealthBar, UIButton} = require "../source/pixi-ui"

describe "PIXI UI", ->
  describe "HeathBar", ->
    it "creates a display object", ->
      HealthBar(10)

  describe "UI Button", ->
    it "creates a display object", ->
      UIButton("Hey", ->)
