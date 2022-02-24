CustomTicker = require "../source/custom-ticker"

describe "CustomTicker", ->
  it "should create", (done) ->
    t = CustomTicker 60, ->
      process.nextTick ->
        t.destroy()
        done()
