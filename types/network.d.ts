import Peer from "peerjs"

import { GameInstance, System, SystemConstructor, U16, U32, U8 } from "./core"

export interface NetworkSystemConstructor extends SystemConstructor<NetworkSystem> { }

export interface NetworkSystem extends System {
  clientId: U8
  registerConnection(client: ExtendedConnection): void
  /** Log a network status message to console. */
  status(): void
}

export interface Msg {
  ack(tick: U32): void
  /**
   First message sent to client after connection is established.
   sends seed to sync up procedural generation.
   Don't need to send nextId because it will be impossible to keep in sync.
   Many objects can be created on the server between snapshots received by
   client.
   Probably want to simulate with client only obects that don't predict until
   receiving the actual server id (food type, item type, etc.). It looks bad
   if a food swaps sprite, but should look fine if it starts as a blur/cloud
   and pops in before hitting the ground.
   in sync with the server
   */
  init(game: GameInstance, client: ExtendedConnection): ArrayBufferLike
  input(game: GameInstance): ArrayBufferLike
  snapshot(game: GameInstance): ArrayBufferLike
  status(avgRtt: U16): ArrayBufferLike
}

// TODO: TypeScript enum?
export interface MessageTypes {
  INIT: U8
  INPUT: U8
  SNAPSHOT: U8
  STATUS: U8
  ACK: U8
}

export interface ConnectionMeta {
  id: U8

  tickMap: Map<U32, number>
  rtts: number[]
  stats: { [key: string]: any }

  _handleDataMessage(this: ExtendedConnection, e: { data: ArrayBuffer }): void
  send(data: ArrayBufferLike): void
}

export interface ExtendedConnection extends Omit<Peer.DataConnection, "send">, ConnectionMeta {
  // These exist on Peer.DataConnection but aren't exposed in the types
  connectionId: number

  emit(type: "data", data: ArrayBuffer): void
}
