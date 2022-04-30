interface U8 extends U16 { }
interface U16 extends U32 { }
interface U32 extends Number { }
interface I8 extends I16 { }
interface I16 extends I32 { }
interface I32 extends Number { }

interface AdHocEntityInstance {

}

interface DataStreamConstructor {
  new(): DataStream
  prototype: DataStreamProto
}

interface DataStreamProto {
  getUint8: (littleEndian?: boolean) => U8
  getUint16: (littleEndian?: boolean) => U16
  getUint32: (littleEndian?: boolean) => U32

  getInt8: (littleEndian?: boolean) => I8
  getInt16: (littleEndian?: boolean) => I16
  getInt32: (littleEndian?: boolean) => I32

  putUint8: (v: U8, littleEndian?: boolean) => void
  putUint16: (v: U16, littleEndian?: boolean) => void
  putUint32: (v: U16, littleEndian?: boolean) => void

  putInt8: (v: I8, littleEndian?: boolean) => void
  putInt16: (v: I16, littleEndian?: boolean) => void
  putInt32: (v: I32, littleEndian?: boolean) => void
}

interface DataStream extends DataStreamProto {
  byteLength: number
  byteView: Uint8Array
  view: DataView
  position: number
}
