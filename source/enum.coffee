###*
Enum

Experimental enum helper

@type {import("../types/types").createEnum}
###
createEnum = (values) ->
  class Enum
    #
    ###*
    @param name {string}
    @param value {number}
    ###
    constructor: (name, value) ->
      @name = name
      @value = value

      # Add integer and string keys to constructor object
      #@ts-ignore TS has trouble indexing classes
      Enum[name] = @
      #@ts-ignore TS has trouble indexing classes
      Enum[value] = @

    toJSON: ->
      @name
    toString: ->
      @name
    valueOf: ->
      @value

    #
    ###*
    @param key {string}
    @return {PropertyDescriptor}
    ###
    @propertyFor: (key) ->
      get: ->
        #@ts-ignore TS has trouble indexing classes
        Enum[@[key]]
      set: (v) ->
        #@ts-ignore TS has trouble indexing classes
        @[key] = Enum[v]

  if typeof values is "string"
    values = values.split(/\s+/)

  values.forEach (name, value) ->
    new Enum(name, value)

  return Enum

module.exports = createEnum
