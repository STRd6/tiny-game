// Input

import { BIT, System, SystemConstructor, U32, U8 } from "./core"

export interface ButtonValues {
  a: BIT
  b: BIT
  x: BIT
  y: BIT
  lb: BIT
  rb: BIT
  back: BIT
  start: BIT
  ls: BIT
  rs: BIT
  up: BIT
  down: BIT
  left: BIT
  right: BIT
  home: BIT
}

export interface TriggerValues {
  /** Amount left trigger is pressed 0, 2/16, 3/16, ..., 15/16, 16/16 */
  lt: number
  /** Amount right trigger is pressed 0, 2/16, 3/16, ..., 15/16, 16/16 */
  rt: number
}

export interface AxesValues {
  axes: [number, number, number, number]
}

export interface Controller extends ButtonValues, TriggerValues, AxesValues {
  at(tick: U32): void
  reset(tick: U32): void
}

export interface Keydown {
  [key: string]: boolean
}

export interface KeyboardController extends Controller {
  keydown: Keydown
}

export interface KeyboardControllerConstructor {
  (this: KeyboardController, keydown: { [key: string]: boolean }): KeyboardController
  new(keydown: { [key: string]: boolean }): KeyboardController
}

export interface InputSnapshot extends Controller {
  data: Uint8Array
}

export interface InputSnapshotConstructor {
  (this: InputSnapshot, bytes: Uint8Array): InputSnapshot
  new(bytes: Uint8Array): InputSnapshot

  from(controller: Controller): InputSnapshot
  bytesFrom(controller: Controller): Uint8Array

  SIZE: number
  NULL: Uint8Array
}

export interface BufferedController extends Controller {
  clientId: U8
  current: InputSnapshot
  data: Uint8Array
  description: string
  id: U8
  latestData: number
  network?: boolean
  pressed: BufferedController
  prev: InputSnapshot
  released: BufferedController
  startTick: number
  tick: number

  /** Updates `current` and `prev` snapshot pointers */
  _update(this: BufferedController): void
  /** Update `current` and `prev` pointers to match the given tick. */
  at(this: BufferedController, tick: number): BufferedController
  /** Tick is the current game tick that we are setting input for
  we don't want to change anything in the past before that but we do want to
  fill up as much input into the future as we have. */
  bufferFromNetwork(this: BufferedController, tick: number, input: { data: Uint8Array, tick: number }): void
  dataAt(this: BufferedController, tick: number): Uint8Array
  /**
   * `c.recent(1).data === c.current.data`
   * returns a subarray of the buffered data with the last entry for the current
   * tick
   */
  recent(this: BufferedController, n: number): Uint8Array
  /** reset controller data to be empty starting at the tick before this one */
  reset(this: BufferedController, tick: number): void
  /** Set the latest snapshot and update the current tick */
  set(this: BufferedController, tick: number, data: Uint8Array): void
  toString(this: BufferedController): string

}

export interface BufferedControllerConstructor {
  (this: BufferedController, id: U8, clientId: U8, description: string, startTick: number, bufferSize?: number): BufferedController
  new(id: U8, clientId: U8, description: string, startTick: number, bufferSize?: number): BufferedController

  BUTTONS: [keyof ButtonValues]
  defaultBufferSize: number
}

export interface InputSystemConstructor extends SystemConstructor<InputSystem> { }

export interface InputSystem extends System {
  controllers: BufferedController[]
  controllerMap: Map<number, BufferedController>
  nullController: Controller

  getController(id: U8, clientId: U8): BufferedController
  registerController(id: U8, clientId: U8, CID: string, tick: number): BufferedController
  resetControllers(tick: U32): void
  /**
  CID (controller ID) is a string to identify the controller. It should be
  somewhat readable for easy debugging K0 is keyboard G0-3 are gamepads
  Network controllers are prefixed with the client id.
  id is a byte representing the id of the controller on the local system
  clientId is a byte linking the controller to a network client
  host's clientId is 0
  # */
  updateController(id: U8, clientId: U8, CID: string, tick: number, controller: InputSnapshot): void

}
