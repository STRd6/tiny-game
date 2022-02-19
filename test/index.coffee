{DataStream, createEnum} = require "../source/util"

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

describe "Engine", ->
  describe "DataStream", ->
    it "should write ascii values", ->
      dataStream = new DataStream new ArrayBuffer 8

      dataStream.putAscii("abcd1234")

      dataStream.reset()
      assert.equal dataStream.getAscii(8), "abcd1234"

    it "should read and write varUints", ->
      dataStream = new DataStream new ArrayBuffer 8
  
      dataStream.putVarUint(0)
      assert.equal dataStream.position, 1
  
      dataStream.reset()
      dataStream.putVarUint(1 << 30)
      assert.equal dataStream.position, 5
  
      dataStream.reset()
      v = dataStream.getVarUint()
      assert.equal v, 1 << 30
  
      dataStream.reset()
      dataStream.putVarUint(128)
      assert.equal dataStream.position, 2
  
      dataStream.reset()
      v = dataStream.getVarUint()
      assert.equal v, 128
  
      dataStream.reset()
      v = dataStream.getUint8()
      assert.equal v, 0x81
  
      v = dataStream.getUint8()
      assert.equal v, 0
  
      dataStream.reset()
      dataStream.putVarUint(16383)
      assert.equal dataStream.position, 2
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), 16383
  
      dataStream.reset()
      dataStream.putVarUint(16384)
      assert.equal dataStream.position, 3
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), 16384
  
      dataStream.reset()
      dataStream.putVarUint(2097151) # (1 << 21) - 1
      assert.equal dataStream.position, 3
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), 2097151
  
      dataStream.reset()
      dataStream.putVarUint(2097152) # (1 << 21)
      assert.equal dataStream.position, 4
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), 2097152
  
      dataStream.reset()
      dataStream.putVarUint(268435455) # (1 << 28) - 1
      assert.equal dataStream.position, 4
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), 268435455
  
      dataStream.reset()
      dataStream.putVarUint(268435456) # (1 << 28)
      assert.equal dataStream.position, 5
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), 268435456
  
      dataStream.reset()
      dataStream.putVarUint(0x7fffffff)
      assert.equal dataStream.position, 5
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), 0x7fffffff
  
      dataStream.reset()
      dataStream.putVarUint(0x80000000)
      assert.equal dataStream.position, 5
  
      dataStream.reset()
      dataStream.putVarUint(Number.MAX_SAFE_INTEGER)
      assert.equal dataStream.position, 8
  
      dataStream.reset()
      assert.equal dataStream.getVarUint(), Number.MAX_SAFE_INTEGER


  describe "Enum", ->
    E = createEnum """
      sick
      cool
      rad
      wicked
    """

    it "should make enums", ->
      assert E.sick
      assert E.cool

    it "should store as bytes", ->
      u = new Uint8Array 3

      u[0] = E.sick
      u[1] = E.cool
      u[2] = E.rad

      assert.equal u[0], 0
      assert.equal u[1], 1
      assert.equal u[2], 2

    it "should work with instance of", ->
      assert E.sick instanceof E

    it "should toString", ->
      assert.equal String(E.sick), "sick"

    it "should toJSON", ->
      assert.equal JSON.stringify(E.sick), "\"sick\""

    it "should work in switch statements", (done) ->
      state = E.cool
      
      switch state
        when E.sick
          assert false
        when E.wicked
          assert false
        when E.cool
          assert true
          done()
        else
          assert false

    it "should work in switch with value", (done) ->
      state = E.cool

      switch state.value
        when 0
          assert false
        when 1
          done()
        when 2
          assert false
          

    it "should provide a property mapping", ->
      o = Object.defineProperties {},
        key:
          value: 0
          writable: true
        state: E.propertyFor "key"

      assert.equal o.state, E.sick

      o.state = E.rad

      assert.equal o.state, E.rad
      assert.equal o.key, 2

      o.state = E.wicked

      assert.equal o.state, E.wicked
      assert.equal o.key, 3
