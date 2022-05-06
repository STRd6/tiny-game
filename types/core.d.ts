import Peer from "peerjs"
import { InputSystem } from "./input"
import { ExtendedConnection, NetworkSystem } from "./network"
import { PropertyDefinition } from "./state-manager"

declare const NSym: unique symbol

export type BIT = 0 | 1
export type U8 = number & { [NSym]: "U8" }
export type U16 = number & { [NSym]: "U16" }
export type U32 = number & { [NSym]: "U32" }
export type I8 = number & { [NSym]: "I8" }
export type I16 = number & { [NSym]: "I16" }
export type I32 = number & { [NSym]: "I32" }

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
  replaying: boolean
  seed: U32
  system: {
    base: BaseSystem
    network: NetworkSystem
    input: InputSystem
  }
  systems: System[]
  textures: unknown[]
  tick: U32

  addEntity(e: EntitySource): unknown
  addBehaviors(behaviors: Behaviors): unknown
  classChecksum(): U32
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

  // Network
  hosting: {
    connections: ExtendedConnection[]
    peer?: Peer
  }
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
