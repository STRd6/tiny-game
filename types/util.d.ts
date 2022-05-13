// Util

import { Behavior, Behaviors } from "./core";

export type ConstructorType<T> = T extends { new(...args: infer Args): infer Ret } ? { new(...args: Args): Ret } : never;

export function mapBehaviors(tags: string[] | Behavior[], table: Behaviors): Behavior[]

/** A function that does nothing and returns undefined. */
export function noop(...args: any[]): undefined

/** Return a random element of an array. */
export function rand<T>(n: T[]): T | undefined
/** Return a random integer < n. */
export function rand(n: number): number

/**
 * Given a keyboard event returns true if the event is taking place inside an
 * input element where regular keyboard inputs should not trigger actions.
 */
export function stopKeyboardHandler(e: KeyboardEvent, element: HTMLElement, combo: string): boolean

/** Return an element from the array as if the array wrapped infinitely. */
export function wrap<T>(array: T[], index: number): T | undefined

export function xorshift32(state: { seed: number }): number
