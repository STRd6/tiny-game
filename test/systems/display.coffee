Display = require "../../source/systems/display"

describe "Display", ->
  it "should do stuff", ->
    displaySystem = Display
      config:
        screenWidth: 640
        screenHeight: 360

    displaySystem.render
      entities: [{
        behaviors: [{
          display: true
          name: "test"
          type: "object"
        }]
      }]
