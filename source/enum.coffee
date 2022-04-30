#@ts-nocheck TODO
###*
Enum

Experimental enum helper
###
createEnum = (values) ->
  Enum = (name, value) ->
    @name = name
    @value = value

    # Add integer and string keys to constructor object
    Enum[name] = @
    Enum[value] = @

    return

  Object.assign Enum::,
    toJSON: ->
      @name
    toString: ->
      @name
    valueOf: ->
      @value

  Enum.propertyFor = (key) ->
    get: ->
      Enum[@[key]]
    set: (v) ->
      @[key] = Enum[v]

  if typeof values is "string"
    values = values.split(/\s+/)

  values.forEach (name, value) ->
    new Enum(name, value)

  return Enum

module.exports = createEnum
