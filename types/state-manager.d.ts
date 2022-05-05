import { Behavior, Entity } from "./core"

export interface BoundDescriptor<T> extends PropertyDescriptor {
  get?(this: T): any
  set?(this: T, v: any): any
  value?: (this: T) => any
}

export interface ClassDefinition {
  behaviors: Behavior[]
  defaults: unknown
  properties: PropertyDefinitions
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
