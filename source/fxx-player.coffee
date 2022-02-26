## Sound FX
## Currently just a hacky wrapper around FXZ to test out the api/ux

{floor} = Math
{rand} = require "./util"

decoder = new TextDecoder("utf-8")
stripNulls = /\u0000+$/

parseName = (nameBuffer) ->
  decoder.decode(nameBuffer).replace(stripNulls, "")

module.exports = FXXPlayer = (fxxBuffer, context) ->
  context ?= new AudioContext
  sounds = {}

  self =
    bind: (newContext) ->
      context = newContext

    loadData: (fxxBuffer) ->
      sounds = {}

      fxxData = new Uint8Array(fxxBuffer)
      l = fxxData.length

      numEntries = floor (l - 8) / 116

      # Populate data entries
      data = {}
      n = 0
      while n < numEntries
        # Parse Name
        p = n * 116 + 8
        name = parseName fxxData.subarray(p, p + 16)

        # Synthesize Waveform
        buffer = fxxData.subarray(p + 16, p + 116)
        # Add to sounds list
        sounds[name] ||= []
        sounds[name].push FXZ buffer.buffer, context
        n += 1

    play: (name) ->
      audioBuffer = rand sounds[name]

      unless audioBuffer
        console.warn "No sound named #{name}"

      node = context.createBufferSource()
      node.buffer = audioBuffer
      node.connect context.destination
      node.start()

  if fxxBuffer
    self.loadData fxxBuffer

  return self
