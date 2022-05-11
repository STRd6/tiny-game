interface VibrationActuator {
  playEffect(effect: string, ...args: any[]): unknown
}

interface Gamepad {
  vibrationActuator: VibrationActuator
}

// Required for PIXI.js
interface OffscreenCanvas { }
interface OffscreenCanvasRenderingContext2D { }

// Stub these for CoffeeScript types
declare module '@babel/core' {
  export type BabelFileResult = unknown
  export type TransformOptions = unknown
}
