import { GameInstance, System, U16, U32, U8 } from "./core"

export interface NetworkInstance {
  hosting: boolean
}

export interface NetworkSystem extends System {
  clientId: U8
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
  init(game: GameInstance, client: unknown): void
  input(game: GameInstance): void
  snapshot(game: GameInstance): void
  status(avgRtt: U16): void
}

// TODO: TypeScript enum?
export interface MessageTypes {
  INIT: U8
  INPUT: U8
  SNAPSHOT: U8
  STATUS: U8
  ACK: U8
}
