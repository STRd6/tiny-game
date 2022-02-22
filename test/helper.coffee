{JSDOM} = require("jsdom")
{window} = new JSDOM("")
{document, navigator, self, window} = window

# jsdom and Browser environment
Object.assign global, {
  TEST: true
  document
  fetch: require 'node-fetch'
  navigator
  self
  window
  WebSocket: require 'ws'
}
, require 'wrtc'

# Hacky fix for webrtc segfault issue
# https://github.com/node-webrtc/node-webrtc/issues/636#issuecomment-774171409
process.on 'beforeExit', process.exit

{peerjs} = require "../vendor/peerjs"

Object.assign global,
  assert: require "assert"
  PIXI: require "pixi.js"
  peerjs: peerjs
  Gamepad: -> # stub gamepad

# Stub for testing
PIXI.Application = ->
  _ticker:
    remove: ->
