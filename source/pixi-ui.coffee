## UI Helpers for PIXI.js
{
  BitmapText
  Container
  NineSlicePlane
  Sprite
  Texture
  TilingSprite
} = PIXI

UIButton = (text, action) ->
  text = new BitmapText text,
    fontName: "m5x7"
    tint: 0x222034
  text.x = 2

  bg = new TilingSprite game.textures.buttonBG, text.width + 4, text.height + 4
  bg.interactive = true
  bg.click = (e) ->
    action.call button, e
  bg.buttonMode = true

  button = new Container
  button.addChild bg
  button.addChild text

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
HealthBar = (height) ->
  bgColor = 0x000000
  fgColor = 0xAC3232
  borderColor = 0xFFFFFF
  width = (pointWidth = 5) + 2

  border = new NineSlicePlane game.textures.highlight_9s, 1, 1, 1, 1
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
