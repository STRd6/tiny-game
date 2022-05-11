## Sound FX
## Currently just a hacky wrapper around FXZ to test out the api/ux

{floor} = Math
{rand} = require "./util"

decoder = new TextDecoder("utf-8")
stripNulls = /\u0000+$/

#
###*
@param nameBuffer {Uint8Array}
###
parseName = (nameBuffer) ->
  decoder.decode(nameBuffer).replace(stripNulls, "")

#
###*
@param fxxBuffer {ArrayBufferLike}
@param [maybeContext] {AudioContext}
###
FXXPlayer = (fxxBuffer, maybeContext) ->
  context = maybeContext or new AudioContext
  #
  ###* @type {{[key: string]: AudioBuffer[]}} ###
  sounds = {}

  self =
    ###*
    @param newContext {AudioContext}
    ###
    bind: (newContext) ->
      context = newContext

    ###*
    @param fxxBuffer {ArrayBufferLike}
    ###
    loadData: (fxxBuffer) ->
      sounds = {}

      fxxData = new Uint8Array(fxxBuffer)
      l = fxxData.length

      numEntries = floor (l - 8) / 116

      # Populate data entries
      n = 0
      while n < numEntries
        # Parse Name
        p = n * 116 + 8
        name = parseName fxxData.subarray(p, p + 16)

        # Synthesize Waveform
        # TODO: update FXZ to load from backing buffer so we don't need to slice
        buffer = fxxData.slice(p + 16, p + 116)
        # Add to sounds list
        sounds[name] ||= []
        #@ts-ignore TODO import FXZ instead of global
        sounds[name].push FXZ buffer.buffer, context
        n += 1

    ###*
    @param name {string}
    ###
    play: (name) ->
      choices = sounds[name]
      if choices
        audioBuffer = rand choices

      unless audioBuffer
        console.warn "No sound named #{name}"
        return

      node = context.createBufferSource()
      node.buffer = audioBuffer
      node.connect context.destination
      node.start()

  if fxxBuffer
    self.loadData fxxBuffer

  return self

module.exports = FXXPlayer
