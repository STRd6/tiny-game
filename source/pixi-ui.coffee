## UI Helpers for PIXI.js

{min} = Math

{
  BitmapText
  Container
  NineSlicePlane
  Sprite
  Texture
} = require "pixi.js"

Highlight9S = Texture.from "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAMAAAADCAQAAAD8IX00AAAAEklEQVQI12P4DwYMQMQApkAAAKdtD/E89U+YAAAAAElFTkSuQmCC"

#
###*
@param text {string}
@param action {(this: Container, e: any) => any}
###
UIButton = (text, action) ->
  textObject = new BitmapText text,
    fontName: "m5x7"
    tint: 0x222034
  textObject.x = 2

  bg = new Sprite Texture.WHITE
  bg.tint = 0xCBDBFC
  bg.interactive = true
  #@ts-ignore PIXI.js types don't have this apparently
  bg.click = (e) ->
    action.call button, e
  bg.buttonMode = true

  button = new Container
  button.addChild bg
  button.addChild textObject

  active = false
  Object.defineProperty button, "active",
    get: ->
      active
    set: (a) ->
      active = a
      if active
        bg.tint = 0x88FF88
      else
        bg.tint = 0xFFFFFF

  return button

# A basic health bar
# TODO: interface is a little clunky, room for improvement
###*
@param height {number}
###
HealthBar = (height) ->
  bgColor = 0x000000
  fgColor = 0xAC3232
  borderColor = 0xFFFFFF
  pointWidth = 5
  width = pointWidth + 2

  border = new NineSlicePlane Highlight9S, 1, 1, 1, 1
  border.tint = borderColor
  border.width = width
  border.height = height

  bg = new Sprite Texture.WHITE
  bg.x = bg.y = 1
  bg.width = width - 2
  bg.height = height - 2
  bg.tint = bgColor

  fg = new Sprite Texture.WHITE
  fg.x = fg.y = 1
  fg.width = width - 2
  fg.height = height - 2
  fg.tint = fgColor

  # Regeneration bar
  rg = new Sprite Texture.WHITE
  rg.x = rg.y = 1
  rg.height = height - 2
  rg.tint = fgColor
  rg.alpha = 0.5

  border.addChild bg
  border.addChild fg
  border.addChild rg

  Object.defineProperties border,
    health:
      set: (health) ->
        fg.width = health * pointWidth
        rg.x = fg.x + fg.width

    maxHealth:
      set: (maxHealth) ->
        border.width = maxHealth * pointWidth + 2
        bg.width = maxHealth * pointWidth

    regen:
      set: (regen) ->
        rg.width = min regen * pointWidth, bg.width - fg.width

  return border

module.exports = {
  HealthBar
  UIButton
}
