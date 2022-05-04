export type BIT = 0 | 1
export interface U8 extends U16 { }
export interface U16 extends U32 { }
export interface U32 extends Number { }
export interface I8 extends I16 { }
export interface I16 extends I32 { }
export interface I32 extends Number { }

export interface AdHocEntity extends Entity { }

export interface AdHocEntityConstructor {
  (properties: { behaviors: Behavior[] }): AdHocEntity

  /** Construct from a backing buffer using the same memory reference */
  fromBuffer(game: GameInstance, buffer: ArrayBufferLike, offest: number): AdHocEntity
}

export interface DataStreamConstructor {
  new(buffer: ArrayBufferLike): DataStream
  prototype: DataStreamProto
}

export interface DataStreamProto {
  getUint8(littleEndian?: boolean): U8
  getUint16(littleEndian?: boolean): U16
  getUint32(littleEndian?: boolean): U32

  getInt8(littleEndian?: boolean): I8
  getInt16(littleEndian?: boolean): I16
  getInt32(littleEndian?: boolean): I32

  putUint8(v: U8, littleEndian?: boolean): void
  putUint16(v: U16, littleEndian?: boolean): void
  putUint32(v: U32, littleEndian?: boolean): void

  putInt8(v: I8, littleEndian?: boolean): void
  putInt16(v: I16, littleEndian?: boolean): void
  putInt32(v: I32, littleEndian?: boolean): void

  putBytes(bytes: ArrayLike<number>): void

  done(): boolean
}

export interface DataStream extends DataStreamProto {
  byteLength: number
  byteView: Uint8Array
  view: DataView
  position: number
}

export interface EntitySource {
  ID: I32
  behaviors: Behavior[]
  $class: U8
}

export interface Entity {
  ID: I32
  $class: U8
  $behaviorCount: U8
  $byteLength: number
  $data: DataView
  info(): string
}

export interface Behavior {
  _id: number
  _tag: string
  properties: {
    [key: string]: PropertyDefinition
  }
  toString(): string
  toJSON(): string
}

export interface Behaviors {
  [key: string]: Behavior
}

export interface Configuration {
  screenWidth: number
  screenHeight: number
}

export interface GameState {
  entities: EntitySource[]
  seed: U32
  tick: U32
}

export interface GameInstance extends NetworkInstance {
  behaviors: Behaviors
  config: Configuration
  defaultBehaviors: unknown[]
  entities: Entity[]
  entityMap: Map<Entity["ID"], Entity>
  localId: string
  pendingEntities: Entity[]
  seed: U32
  system: {
    base: BaseSystem
    [key: string]: System
  }
  systems: System[]
  textures: unknown[]
  tick: U32

  addEntity(e: EntitySource): unknown
  addBehaviors(behaviors: Behaviors): unknown
  create(): GameInstance
  createEntity(e: Entity): Entity
  data(): string
  dataBuffer(): ArrayBuffer
  debugEntities(): void
  destroy(): void
  destroyEntity(e: Entity): Entity

  execProgram(): void
  hardReset(): void

  /** Reload game state from JSON string data */
  reload(data?: GameState): U32
  reloadBuffer(buffer: ArrayBufferLike): U32

  render(): void
  update(): void
}

export interface System {
  beforeUpdate(self: GameInstance): void
  update(self: GameInstance): void
  afterUpdate(self: GameInstance): void

  create(self: GameInstance): void
  createEntity(e: Entity): Entity

  destroyEntity(e: Entity): unknown

  destroy(self: GameInstance): void
}

export interface BaseSystem extends System {
  getBehaviorById(id: number): Behavior
}

export interface NetworkInstance {
  hosting: boolean
}

export interface TinyGame {
  (options?: any): GameInstance
}

export interface BoundDescriptor<T> extends PropertyDescriptor {
  get?(this: T): any
  set?(this: T, v: any): any
  value?: (this: T) => any
}

export type PropertyDefinition = {
  bytes: number
  bits?: number
  bind: (this: StateManagerInstance) => BoundDescriptor<Entity>
} | BoundDescriptor<Entity>

export interface PropertyDefinitions {
  [key: string]: PropertyDefinition
}

export interface DataTypeDefinitions {
  BIT: PropertyDefinition
  I8: PropertyDefinition
  I16: PropertyDefinition
  I32: PropertyDefinition
  UNIT: PropertyDefinition
  U8: PropertyDefinition
  U16: PropertyDefinition
  U32: PropertyDefinition
  /** ! DANGER: this writes in little endian format (actually machine specific)
  whereas DataView writes in big endian by default.
  TODO: is there a good way to return an array-like that is efficient and
  works well? */
  U16A: (length: number) => PropertyDefinition
  FIXED16: (precision: number) => PropertyDefinition
  FIXED32: (precision: number) => PropertyDefinition
  /** Reserve a fixed number of bytes */
  RESERVE: (length: number) => PropertyDefinition
}

export interface StateManagerInstance {
  _size: number
  _availableBits: number
  _lastBitOffset: number

  alloc(): DataView
  bindProps(properties: PropertyDefinitions): Object
  reserveBits(n: number): {
    offset: number
    bit: number
  }
  reserveBytes(n: number): number
  size(): number
}

/**
Map state into bits and bytes. Make every byte count for the network!

Tracks offsets and total size, reserves bits and bytes using DataType definitions.
*/
export interface StateManager {
  new(): StateManagerInstance
  (this: StateManagerInstance): StateManagerInstance
}

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

export interface Controller extends ButtonValues, TriggerValues, AxesValues { }

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
  (this: BufferedController, id: U8, clientId: U8, description: string, startTick: number, bufferSize: number): BufferedController
  new(id: U8, clientId: U8, description: string, startTick: number, bufferSize: number): BufferedController

  BUTTONS: string[]
  defaultBufferSize: number
}

export interface CustomTickerInstance {
  destroy(): void
}

export interface CustomTicker {
  (fps: number, fn: () => void, performance?: { now(): DOMHighResTimeStamp }): CustomTickerInstance
}

// Enum TODO: TypeScript has real trouble indexing classes

interface EnumInstance extends EnumPrototype {

}

interface EnumPrototype {
  toJSON(): string
  toString(): string
  valueOf(): number
}

interface EnumConstructor {
  new(name: string, value: number): EnumInstance
  prototype: EnumPrototype
  propertyFor(key: string): PropertyDescriptor
}

interface createEnum {
  (values: string | string[]): EnumConstructor
}

// Util

export interface mapBehaviors {
  (tags: string[], table: Behaviors): Behavior[]
}

export interface rand<T> {
  (n: number): number
  (n: T[]): T
}

export interface stopKeyboardHandler {
  (e: KeyboardEvent, element: HTMLElement, combo: string): boolean
}

export interface wrap<T> {
  (array: T[], index: number): T | undefined
}

export interface xorshift32 {
  (state: { seed: number }): number
}

export type ConstructorType<T> = T extends { new(...args: infer Args): infer Ret } ? { new(...args: Args): Ret } : never;
