import { BIT, Entity, I16, I32, I8, U16, U32, U8, UNIT } from "./core"

export interface BoundAccessorDescriptor<T, V = any> extends AccessorDescriptor {
  get?(this: T): V
  set?(this: T, v: V): void
}

export type BoundDescriptor<T, V> = DataDescriptor<V> | BoundAccessorDescriptor<T, V>

export type DefinitionValue<T> = T extends PropertyDefinition<infer V> ? V : any

export type BoundDefinition<T> = {
  bytes: number
  bits?: number
  bind: (this: StateManagerInstance) => BoundDescriptor<Entity, T>
}

export type PropertyDefinition<V = any> = BoundDefinition<V> | BoundDescriptor<Entity, V>

export interface PropertyDefinitions {
  [key: string]: PropertyDefinition
}

export interface DataTypeDefinitions {
  BIT: PropertyDefinition<BIT>
  I8: PropertyDefinition<I8>
  I16: PropertyDefinition<I16>
  I32: PropertyDefinition<I32>
  UNIT: PropertyDefinition<UNIT>
  U8: PropertyDefinition<U8>
  U16: PropertyDefinition<U16>
  U32: PropertyDefinition<U32>
  /** ! DANGER: this writes in little endian format (actually machine specific)
  whereas DataView writes in big endian by default.
  TODO: is there a good way to return an array-like that is efficient and
  works well? */
  U16A: (length: number) => PropertyDefinition<U16[]>
  FIXED16: (precision?: number) => PropertyDefinition<number>
  FIXED32: (precision?: number) => PropertyDefinition<number>
  /** Reserve a fixed number of bytes */
  RESERVE: (length: number) => PropertyDefinition<undefined>
}

export interface StateManagerInstance {
  _size: number
  _availableBits: number
  _lastBitOffset: number

  alloc(): DataView
  bindProps<T extends PropertyDefinitions>(properties: T): { [P in keyof T]: DefinitionValue<T[P]> }
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
