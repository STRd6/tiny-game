{JSDOM} = require("jsdom")
{window} = new JSDOM("")
{document} = window

Object.assign global,
  document: document
  window: window
  self: window

Object.assign global,
  assert: require "assert"
  PIXI: require "pixi.js"
