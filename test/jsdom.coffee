describe "JSDOM", ->
  # JSDOM needs `pretendToBeVisual: true` option set for these to appear
  # another libs polyfill for cancelAnimation frame would fail this test
  it "requestAnimationFrame shouldn't call if cancelled", (done) ->
    {requestAnimationFrame, cancelAnimationFrame} = window

    step = ->
      done new Error "should not be called"

    cancelAnimationFrame requestAnimationFrame step
    done()
