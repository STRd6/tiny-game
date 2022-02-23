TinyGame = require "../source/index"

{createEnum} = require "../source/util"

describe "TinyGame", ->
  it "should create", ->
    game = TinyGame()

    game.create()
    game.update()

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

    it "should create enums from an array of keys", ->
      E2 = createEnum ["heyy"]

      assert.equal E2.heyy, 0
