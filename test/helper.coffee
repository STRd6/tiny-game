{JSDOM} = require("jsdom")
{window} = new JSDOM("")
{document} = window

Object.assign global,
  document: document
  window: window
  self: window
  TEST: true

Object.assign global,
  assert: require "assert"
  PIXI: require "pixi.js"
  Gamepad: -> # stub gamepad

# Stub for testing
PIXI.Application = ->
  _ticker:
    remove: ->
