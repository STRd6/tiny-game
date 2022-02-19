module.exports = CustomTicker = (fps=60, fn) ->
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
    _raf = requestAnimationFrame step
    accumulate()
    process()

  _raf = requestAnimationFrame step

  destroy: ->
    clearInterval _i
    canccelAnimationFrame _raf
