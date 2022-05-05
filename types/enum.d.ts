// Enum TODO

interface EnumInstance extends EnumPrototype {

}

interface EnumPrototype {
  toJSON(): string
  toString(): string
  valueOf(): number
}

interface EnumConstructor {
  new(name: string, value: number): EnumInstance
  prototype: EnumPrototype
  propertyFor(key: string): PropertyDescriptor
}

interface createEnum {
  (values: string | string[]): EnumConstructor
}
