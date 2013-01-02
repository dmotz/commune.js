# Commune.js
# Mocha test suite
# Dan Motzenbecker

base = 1e8

adder = (a = 0, b = 0, c = 0) ->
  for i in [0..1e8]
    a++
    b++
    c++

  [a, b, c]


describe 'Commune.js', ->
  @timeout 2e4

  describe '#commune()', ->
    it 'should compute a function', () ->
      commune adder, [1, 2, 3], (r) ->
        [a, b, c] = r
        expect(a).to.equal base + 2
        expect(b).to.equal base + 3
        expect(c).to.equal base + 4

    it 'should compute a function without being given arguments', ->
      commune adder, (r) ->
        [a, b, c] = r
        expect(a).to.equal base + 1
        expect(b).to.equal base + 1
        expect(c).to.equal base + 1

    it 'should compute a function without thread support', ->
      commune.disableThreads()
      commune adder, [1, 2, 3], (r) ->
        [a, b, c] = r
        expect(a).to.equal base + 2
        expect(b).to.equal base + 3
        expect(c).to.equal base + 4

    it 'should compute a function without thread support and without arguments', ->
       commune.disableThreads()
       commune adder, (r) ->
         [a, b, c] = r
         expect(a).to.equal base + 1
         expect(b).to.equal base + 1
         expect(c).to.equal base + 1

    describe '#commune.disableThreads()', ->
      it 'should disable threading', ->
        commune.disableThreads()
        expect(commune.isThreaded()).to.equal false

    describe '#commune.enableThreads()', ->
      it 'should enable threading', ->
        commune.enableThreads()
        expect(commune.isThreaded()).to.equal true

  describe '#communify()', ->
    it 'should return a Commune.js version of a function', ->
      communify(adder) [1, 2, 3], (r) ->
        [a, b, c] = r
        expect(a).to.equal base + 2
        expect(b).to.equal base + 3
        expect(c).to.equal base + 4

    it 'should return a partially applied function when given arguments', ->
      communify(adder, [1, 2, 3]) (r) ->
        [a, b, c] = r
        expect(a).to.equal base + 2
        expect(b).to.equal base + 3
        expect(c).to.equal base + 4

