export interface U8 extends U16 { }
export interface U16 extends U32 { }
export interface U32 extends Number { }
export interface I8 extends I16 { }
export interface I16 extends I32 { }
export interface I32 extends Number { }

export interface AdHocEntityInstance {

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
  ID?: I32
  behaviors?: unknown
  $class?: U8
}

export interface Entity {
  ID: I32
  $data: DataView
  info(): string
}

export interface Behavior { }

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

export interface NetworkInstance {
  hosting: boolean
}

export interface TinyGame {
  (options?: any): GameInstance
}

export interface BoundDescriptor<T> extends PropertyDescriptor {
  get?(this: T): any
  set?(this: T, v: any): any
}

export interface PropertyDefinition {
  bytes: number
  bits?: number
  bind?: (this: StateManagerInstance) => BoundDescriptor<Entity>
}

export interface PropertyDefinitions {
  [key: string]: PropertyDefinition | ((...args: any[]) => PropertyDefinition)
}

export interface StateManagerInstance {
  alloc(): DataView
  bindProps(properties: PropertyDefinitions): Object
  reserveBits(n: number): {
    offset: number
    bit: number
  }
  reserveBytes(n: number): number
  size(): number
}
