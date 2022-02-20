## Sound FX
## Currently just a hacky wrapper around FXZ to test out the api/ux

{floor} = Math

{rand} = require "./util"

module.exports = FXXPlayer = (fxxBuffer, context) ->
  MAX_ENTRIES = 1024
  context ?= new AudioContext
  sounds = {}

  parseName = (nameBuffer) ->
    lastNull = nameBuffer.indexOf(0)

    if lastNull >= 0
      nameBuffer = nameBuffer.slice(0, lastNull)

    name = new TextDecoder("utf-8").decode(nameBuffer)

  self =
    loadData: (fxxBuffer) ->
      sounds = {}

      fxxData = new Uint8Array(fxxBuffer)
      l = fxxData.length

      numEntries = floor (l - 8) / 116

      if numEntries > MAX_ENTRIES
        numEntries = MAX_ENTRIES

      # Populate data entries
      data = {}
      n = 0
      while n < numEntries
        # Parse Name
        p = n * 116 + 8
        name = parseName fxxData.slice(p, p + 16)

        # Synthesize Waveform
        buffer = fxxData.slice(p + 16, p + 116)
        # Add to sounds list
        sounds[name] ||= []
        sounds[name].push FXZ buffer.buffer, context
        n += 1

    play: (name) ->
      # Don't play sounds for network replay
      # TODO: Maybe need a better name for this
      return if game.replaying

      audioBuffer = rand sounds[name]

      unless audioBuffer
        console.warn "No sound named #{name}"

      node = new AudioBufferSourceNode context,
        buffer: audioBuffer
      node.connect context.destination

      node.start()

  if fxxBuffer
    self.loadData fxxBuffer

  return self
