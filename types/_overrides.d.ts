// TypeScript lib.es5.d.ts is less accurate than these
declare interface DataDescriptor<T = any> {
  configurable?: boolean;
  enumerable?: boolean;
  value?: T;
  writable?: boolean;
}

declare interface AccessorDescriptor<T = any> {
  configurable?: boolean;
  enumerable?: boolean;
  get?(): T;
  set?(v: T): void;
}

interface VibrationActuator {
  playEffect(effect: string, ...args: any[]): unknown
}

interface Gamepad {
  vibrate(...args: any[]): void // Added from gamepad.coffee
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
