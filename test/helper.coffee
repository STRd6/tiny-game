{JSDOM} = require("jsdom")
{window} = new JSDOM "",
  # Need this for JSDOM to add requestAnimationFrame and cancelAnimationFrame
  pretendToBeVisual: true
{document, navigator, self, window} = window

# Stub
navigator.getGamepads = -> []

# Mock Audio Context
mockContext =
  createBufferSource: ->
    connect: ->
    start: ->

# jsdom and Browser environment
Object.assign global, {
  TEST: true
  AudioContext: ->
    mockContext
  FileReader: window.FileReader
  HTMLImageElement: window.HTMLImageElement
  HTMLCanvasElement: window.HTMLCanvasElement
  HTMLVideoElement: window.HTMLVideoElement
  Image: window.Image
  WebSocket: require 'ws'
  XMLHttpRequest: window.XMLHttpRequest
  document
  fetch: require 'node-fetch'
  navigator
  self
  window
}
, require 'wrtc'

# Hacky fix for webrtc segfault issue
# https://github.com/node-webrtc/node-webrtc/issues/636#issuecomment-774171409
process.on 'beforeExit', process.exit

{peerjs} = require "../vendor/peerjs"

# PIXI JS shims/stubs

PIXI = require "pixi.js"

bmfd = new PIXI.BitmapFontData()
Object.assign bmfd,
  common: [
    lineHeight: 9
  ]
  info: [
    face: "m5x7",
    size: 7
  ]
  kerning: []
  page: [
    file: ""
  ]

PIXI.BitmapFont.install bmfd, []

Object.assign global,
  assert: require "assert"
  PIXI: PIXI
  peerjs: peerjs
  Gamepad: -> # stub gamepad

# Stub for testing
PIXI.Application = ->
  _ticker:
    remove: ->
