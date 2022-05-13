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

import * as util from "./util"
export * from "./util"

export {
  util
}

export interface TinyGame {
  util: typeof util
}

export default TinyGame
