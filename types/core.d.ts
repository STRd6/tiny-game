import { PropertyDefinition } from "./state-manager"

export type BIT = 0 | 1
export interface U8 extends U16 { }
export interface U16 extends U32 { }
export interface U32 extends Number { }
export interface I8 extends I16 { }
export interface I16 extends I32 { }
export interface I32 extends Number { }

export interface EntityConstructor<T extends Entity = Entity> {
  (properties?: EntityProps): T
  byteLength?: number
  /** Construct from a backing buffer using the same memory reference */
  fromBuffer(game: GameInstance, buffer: ArrayBufferLike, offest: number): T
}

export interface EntityProps {
  behaviors: Behavior[]
}

export interface EntitySource {
  ID: number // I32 TODO: TypeScript is really awkward about number subtypes
  behaviors: Behavior[]
  $class: U8
}

export interface Entity {
  ID: number // I32 TODO: TypeScript is really awkward about number subtypes
  $class: U8
  $behaviorCount: U8
  $byteLength: number
  $data: DataView

  behaviors: Behavior[]
  destroy?: boolean
  die?: boolean

  info(): string
}

export interface Behavior {
  _id: number
  _system: System
  _tag: string
  properties: {
    [key: string]: PropertyDefinition
  }

  create?(e: Entity): void
  destroy?(e: Entity): void
  die?(e: Entity): void
  update?(e: Entity): void

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

export interface GameInstance {
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
  name: string

  beforeUpdate?(self: GameInstance): void
  update(self: GameInstance): void
  afterUpdate?(self: GameInstance): void

  create(self: GameInstance): void
  createEntity(e: Entity): void

  destroyEntity(e: Entity): unknown

  destroy(self: GameInstance): void
}

export interface SystemConstructor<T extends System> {
  (game: GameInstance): T
}

export interface BaseSystemConstructor extends SystemConstructor<BaseSystem> { }

export interface BaseSystem extends System {
  name: "base"
  getBehaviorById(id: number): Behavior
  getClassById(id: number): EntityConstructor<Entity>
  initBehaviors(game: GameInstance): void
  updateEntity(e: Entity): void
}

export interface TinyGame {
  (options?: any): GameInstance
}
