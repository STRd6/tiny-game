{HealthBar, UIButton} = require "../source/pixi-ui"

describe "PIXI UI", ->
  describe "HeathBar", ->
    it "creates a display object", ->
      hb = HealthBar(10)

      hb.health = 10
      hb.maxHealth = 20
      hb.regen = 1

  describe "UI Button", ->
    it "creates a display object", ->
      uiButton = UIButton("Hey", ->)

      uiButton.children[0].click()

      uiButton.active
      uiButton.active = true
      uiButton.active = false
