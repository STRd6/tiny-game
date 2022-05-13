// Util

import { Behavior, Behaviors, U8 } from "./core";
import { DataTypeDefinitions } from "./state-manager";

export { createEnum } from "./enum"

export type ConstructorType<T> = T extends { new(...args: infer Args): infer Ret } ? { new(...args: Args): Ret } : never;

/**
DataType manages bit and byte access for entity properties. bind is called in
the context of the state manager. The property methods execute in the context
of the entity object. Don't let the different `this` scopes fool you.
*/
export const DataType: DataTypeDefinitions

/** Approach `target` from `value` by `amount`. */
export function approach(value: number, target: number, amount: number): number

/** Return the average value of the array of numbers. */
export function average(array: number[]): number | undefined

/** Clamp `value` between low and high. */
export function clamp(value: number, low: number, high: number): number

export function mapBehaviors(tags: string[] | Behavior[], table: Behaviors): Behavior[]

/** A function that does nothing and returns undefined. */
export function noop(...args: any[]): undefined

/** Return a random element of an array. */
export function rand<T>(n: T[]): T | undefined
/** Return a random integer < n. */
export function rand(n: number): number

/** Generate a psuedorandom string identifier. */
export function randId(): string

/** Return a random item from the array. */
export function randItem<T>(array: T[]): T | undefined

/** Remove an element from an array modifying it in place. */
export function remove<T>(array: T[], item: T): T | undefined

/**
Returns an unsigned integer containing 31 reasonably-well-scrambled
bits, based on a given (signed) integer input parameter `n` and optional
`seed`.  Kind of like looking up a value in a non-existent table of 2^31
previously generated random numbers.
https://www.youtube.com/watch?v=LWFzPP8ZbdU
*/
export function squirrel3(n: number, seed?: number): number

/**
 * Given a keyboard event returns true if the event is taking place inside an
 * input element where regular keyboard inputs should not trigger actions.
 */
export function stopKeyboardHandler(e: KeyboardEvent, element: HTMLElement, combo: string): boolean

/** Return an element from the array as if the array wrapped infinitely. */
export function wrap<T>(array: T[], index: number): T | undefined

/** Generate a psuedorandom number and advance the seed. */
export function xorshift32(state: { seed: number }): number

// Input Utils

/** Convert a float from between -1 and 1 to an 8 bit unsigned integer. */
export function floatToUint8(f: number): U8
/** Convert an 8 bit unsigned integer to a float between -1 and 1.*/
export function uint8ToFloat(n: U8): number

/** 0 zero 1-8 negative axis -0.125 - -1.0, 9-15 positive axis 0.25-1.0 */
export function axisToNibble(f: number): number

export function nibbleToAxis(n: number): number

/** Convert a float between 0 and 1 to a 4 bit unsigned integer. */
export function triggerToNibble(v: number): number

/** Convert a number to hex padding up to length with leading zeroes. */
export function toHex(n: number, minLength?: number): string
