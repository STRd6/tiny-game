
describe "JS Features", ->
  # https://stackoverflow.com/a/18557503/68210
  describe "defineProperties", ->
    describe "accessor descriptors", ->
      it "should not redefine properties", ->
        o = {}

        Object.defineProperties o,
          cool: get: -> 'cool'
        assert.equal o.cool, 'cool'

        assert.throws ->
          Object.defineProperties o,
            cool: get: -> 'rad'

      it "should redefine properties if configurable", ->
        o = {}

        Object.defineProperties o,
          cool:
            get: -> 'cool'
            configurable: true
        assert.equal o.cool, 'cool'

        Object.defineProperties o,
          cool: get: -> 'rad'
        assert.equal o.cool, 'rad'

      it "should cover attributes", ->
        o =
          cool: "heyy"
        assert.equal o.cool, 'heyy'

        Object.defineProperties o,
          cool: get: -> 'cool'
        assert.equal o.cool, 'cool'

      it "should not stringify in json", ->
        o = {}

        Object.defineProperties o,
          cool: get: -> 'cool'

        assert.equal JSON.stringify(o), "{}"

      it "should work on prototypes", ->
        base = {}

        Object.defineProperties base,
          cool: get: -> 'cool'

        o = Object.create base
        assert.equal o.cool, 'cool'

        o.cool = "wat"
        assert.equal o.cool, 'cool'

    describe "data descriptors", ->
      it "should not redefine properties", ->
        o = {}

        Object.defineProperties o,
          cool:
            value: 'cool'
        assert.equal o.cool, 'cool'

        assert.throws ->
          Object.defineProperties o,
            cool: get: -> 'rad'

      it "should not set properties if not writable", ->
        o = {}

        Object.defineProperties o,
          cool:
            value: 'cool'

        o.cool = "rad"
        assert.equal o.cool, "cool"

      it "should set properties if writable", ->
        o = {}

        Object.defineProperties o,
          cool:
            value: 'cool'
            writable: true

        o.cool = "rad"
        assert.equal o.cool, "rad"

      it "should not set inherited non-writable properties", ->
        base = {}

        Object.defineProperties base,
          cool:
            value: 'cool'

        o = Object.create base

        o.cool = "rad" # ! no error, just silent failure
        assert.equal o.cool, "cool"

      it "should not output set writable properties in JSON", ->
        o = {}

        Object.defineProperties o,
          cool:
            value: 'cool'
            writable: true

        assert.equal JSON.stringify(o), '{}'

        o.cool = "rad"
        assert.equal o.cool, "rad"

        assert.equal JSON.stringify(o), '{}'

      it "should output set enumerable properties in JSON", ->
        o = {}

        Object.defineProperties o,
          cool:
            value: 'cool'
            writable: true
            enumerable: true

        assert.equal JSON.stringify(o), '{"cool":"cool"}'

        o.cool = "rad"
        assert.equal o.cool, "rad"

        assert.equal JSON.stringify(o), '{"cool":"rad"}'

      it "should not output inherited properties in JSON", ->
        base = {}

        Object.defineProperties base,
          cool:
            value: 'cool'
            writable: true
            enumerable: true

        o = Object.create base

        assert.equal JSON.stringify(o), '{}'

      it "should output based on inherited toJSON method", ->
        base = {}

        Object.defineProperties base,
          cool:
            value: 'cool'
            writable: true
            enumerable: true
          toJSON:
            value: ->
              {
                @cool
              }
            writable: true
            enumerable: true

        o = Object.create base

        assert.equal JSON.stringify(o), '{"cool":"cool"}'

      it "should inherit from prototype but not set to it", ->
        base = {}

        Object.defineProperties base,
          cool:
            value: "cool"
            writable: true

        o = Object.create base

        assert.equal base.cool, "cool"
        assert.equal o.cool, "cool"
        o.cool = "rad"
        assert.equal base.cool, "cool"
        assert.equal o.cool, "rad"


  describe "Object.freeze", ->
    describe "arrays", ->
      it "should prevent adding to an array", ->
        a = []
        Object.freeze(a)
        assert.throws ->
          a.push "yo"

  describe "Object.seal", ->
    describe "arrays", ->
      it "should prevent adding to an array", ->
        a = []
        Object.seal(a)

        assert.throws ->
          a.push "yo"

  describe "timeouts and intervals", ->
    it "should set and clear", (done) ->
      v = setInterval ->
        clearInterval v
        done()
      , 1

    it "setTimeout should not call if cleared", (done) ->
      step = ->
        t = setTimeout step, 1
        done new Error "Should not be called"

      clearTimeout setTimeout step
      done()
