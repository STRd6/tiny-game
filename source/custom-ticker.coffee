module.exports = CustomTicker = (fps=60, fn, performance=window.performance) ->
  {cancelAnimationFrame, requestAnimationFrame} = window
  stopped = false

  accum = 0
  now = performance.now()
  accumulate = ->
    t = performance.now()
    delta = t - now
    now = t
    accum += delta

  dt = 1000 / fps
  process = ->
    # clamp very slow frames
    if accum > 10 * dt
      accum = 10 * dt

    while accum >= dt
      accum -= dt
      fn()

  _i = setInterval ->
    accumulate()
    process()
  , 1

  step = ->
    return if stopped
    _raf = requestAnimationFrame step
    accumulate()
    process()

  _raf = requestAnimationFrame step

  destroy: ->
    stopped = true
    clearInterval _i
    cancelAnimationFrame _raf
