import { System } from "./core";

export interface SoundSystem extends System {
  play(name: string): void
}
