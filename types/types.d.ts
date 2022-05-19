export * from "./ad-hoc-entity"
export * from "./core"
export * from "./custom-ticker"
export * from "./data-stream"
export * from "./display"
export * from "./enum"
export * from "./input"
export * from "./network"
export * from "./state-manager"
export * from "./sound"

import * as PIXI from "pixi.js"
import * as ui from "./ui"
import * as util from "./util"

export {
  PIXI,
  util,
  ui,
}

export declare const TinyGame: {
  PIXI: typeof PIXI,
  util: typeof util,
  ui: typeof ui,
}
