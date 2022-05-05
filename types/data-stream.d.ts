import { U8, U16, U32, I8, I16, I32 } from "./core"

export interface DataStreamConstructor {
  (this: DataStream, buffer: ArrayBufferLike): DataStream
  new(buffer: ArrayBufferLike): DataStream
  prototype: DataStreamProto
}

export interface DataStreamProto {
  getAscii(length: number): string
  getBytes(length: number): Uint8Array

  getUint8(littleEndian?: boolean): U8
  getUint16(littleEndian?: boolean): U16
  getUint32(littleEndian?: boolean): U32

  getInt8(littleEndian?: boolean): I8
  getInt16(littleEndian?: boolean): I16
  getInt32(littleEndian?: boolean): I32

  getFloat32(littleEndian?: boolean): number
  getFloat64(littleEndian?: boolean): number

  /**
   Read a MIDI-style variable-length unsigned integer
   (big-endian value in groups of 7 bits,
   with top bit set to signify that another byte follows)
   */
  getVarUint(): number

  putAscii(str: string): void
  putBytes(bytes: Uint8Array): void

  putUint8(v: U8, littleEndian?: boolean): void
  putUint16(v: U16, littleEndian?: boolean): void
  putUint32(v: U32, littleEndian?: boolean): void

  putInt8(v: I8, littleEndian?: boolean): void
  putInt16(v: I16, littleEndian?: boolean): void
  putInt32(v: I32, littleEndian?: boolean): void

  putFloat32(v: number, littleEndian?: boolean): void
  putFloat64(v: number, littleEndian?: boolean): void

  putVarUint(v: number): void

  /**
   Subarray of bytes to send over the network
   A classic pattern is to call reset, write out the data, then pass the result
   of `bytes` directly to the socket.
   */
  bytes(): Uint8Array
  done(): boolean

  reset(): void
}

export interface DataStream extends DataStreamProto {
  byteLength: number
  byteView: Uint8Array
  view: DataView
  position: number
}
