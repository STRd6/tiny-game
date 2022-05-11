// Enum TODO

export interface Enum {
  toJSON(): string
  toString(): string
  valueOf(): number
}

export interface EnumConstructor {
  new(name: string, value: number): Enum
  propertyFor(key: string): PropertyDescriptor
}

export interface createEnum {
  (values: string | string[]): EnumConstructor
}
