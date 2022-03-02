{JSDOM} = require("jsdom")
{window} = new JSDOM "",
  # Need this for JSDOM to add requestAnimationFrame and cancelAnimationFrame
  pretendToBeVisual: true

{
  cancelAnimationFrame
  document
  navigator
  self
  requestAnimationFrame
} = window

# Stub
global.system =
  pkg:
    exec: ->

# Stub

Gamepad = ->
  @axes = new Array(4).fill(0)
  @buttons = new Array(17).fill
    value: 0
  @id = "Mock Gamepad"
  @index = 0
  @mapping = "standard"
  @timestamp = window.performance.now()
  @vibrationActuator =
    playEffect: ->
    type: "dual-rumble"

  return this

mockGamepad = new Gamepad

navigator.getGamepads = ->
  [mockGamepad]

# Mock Audio Context
mockContext =
  createBufferSource: ->
    connect: ->
    start: ->

# jsdom and Browser environment
Object.assign global, {
  AudioContext: ->
    mockContext
  Blob: window.Blob
  FileReader: window.FileReader
  HTMLImageElement: window.HTMLImageElement
  HTMLCanvasElement: window.HTMLCanvasElement
  HTMLVideoElement: window.HTMLVideoElement
  Image: window.Image
  WebSocket: require 'ws'
  XMLHttpRequest: window.XMLHttpRequest
  cancelAnimationFrame
  document
  fetch: require 'node-fetch'
  navigator
  requestAnimationFrame
  self
  window
}
, require 'wrtc'

# Hacky fix for webrtc segfault issue
# https://github.com/node-webrtc/node-webrtc/issues/636#issuecomment-774171409
process.on 'beforeExit', process.exit

{peerjs} = require "../vendor/peerjs"

# PIXI JS shims/stubs

PIXI = require "pixi.js-legacy"
PIXI.utils.skipHello()

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
  Gamepad: Gamepad
