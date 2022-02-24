CustomTicker = require "../source/custom-ticker"

describe "CustomTicker", ->
  it "should create", (done) ->
    ticker = CustomTicker 60, ->
      ticker.destroy()
      done()

  it "should tick away using both interval and animation frame", (done) ->
    ticker = CustomTicker 60, ->

    setTimeout ->
      ticker.destroy()
      done()
    , 2000 / 60

  it "should tick accumulated frames", (done) ->
    t = 0
    i = 0
    ticker = CustomTicker 60, ->
      if ++i is 5
        ticker.destroy()
        done()
    ,
      now: -> t

    t = 5.1 * 1000 / 60

  it "should skip frames if it falls way behind", (done) ->
    t = 0
    i = 0
    ticker = CustomTicker 60, ->
      i++

      if i is 10
        setTimeout ->
          done()
        ticker.destroy()
    ,
      now: -> t

    t = 100 * 1000 / 60
