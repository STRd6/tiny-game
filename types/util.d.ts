// Util

import { Behavior, Behaviors } from "./core";

export type ConstructorType<T> = T extends { new(...args: infer Args): infer Ret } ? { new(...args: Args): Ret } : never;

export interface mapBehaviors {
  (tags: string[] | Behavior[], table: Behaviors): Behavior[]
}

export interface noop {
  (...args: any[]): undefined
}

export interface rand {
  <T>(n: T[]): T | undefined
  (n: number): number
}

export interface stopKeyboardHandler {
  (e: KeyboardEvent, element: HTMLElement, combo: string): boolean
}

export interface wrap<T> {
  (array: T[], index: number): T | undefined
}

export interface xorshift32 {
  (state: { seed: number }): number
}
