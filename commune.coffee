###
  * Commune.js
  * Web workers lose their chains
  * Easy, DRY, transparent worker threads for your app
  * Dan Motzenbecker
  * MIT License
###


communes = {}
makeBlob = null


class Commune

  constructor: (fn) ->
    fnString = fn.toString()

    if fnString.match /this/
      console? and console.warn """
      Commune: Referencing `this` within a worker process will not work.

      The passed function appears to use it, but the worker will still be created.
      """

    lastReturnIndex = fnString.lastIndexOf 'return'

    if lastReturnIndex is -1
      throw new Error 'Commune: Target function has no return statement'

    returnStatement = fnString.substr(lastReturnIndex)
      .replace('return', '').replace(/\}$/, '').replace ';', ''

    fnString = fnString.slice(0, lastReturnIndex) +
      '\nself.postMessage(' + returnStatement + ');\n}'

    fnName = fnString.match /function\s(.+)\(/i

    if fnName[1]?
      fnString = fnString.replace fnName[1], 'communeInit'

    fnString += 'if(typeof window === \'undefined\'){\n' +
      'self.addEventListener(\'message\', function(e){\n' +
      '\ncommuneInit.apply(this, e.data);\n});\n}'

    @blobUrl = makeBlob fnString


  spawnWorker: (args, cb) ->
    worker = new Worker @blobUrl
    worker.addEventListener 'message', (e) ->
      cb e.data
      worker.terminate()

    worker.postMessage args



testSupport = ->
  blobConstructor = window.BlobBuilder or window.WebKitBlobBuilder or
    window.MozBlobBuilder or false

  return false if not blobConstructor

  try
    testBlob = new Blob
    BlobBuilder = window.Blob
  catch e
    BlobBuilder = blobConstructor

  URL = window.URL or window.webkitURL or window.mozURL or false

  return false if not URL or not window.Worker

  testString = 'commune.js'
  try
    if BlobBuilder is window.Blob
      testBlob = new BlobBuilder [testString]
      sliceMethod = BlobBuilder::slice or BlobBuilder::webkitSlice or
        BlobBuilder::mozSlice
      rawBlob = sliceMethod.call testBlob
      makeBlob = (string) ->
        blob = new BlobBuilder [string]
        URL.createObjectURL sliceMethod.call blob
    else
      testBlob = new BlobBuilder
      testBlob.append testString
      rawBlob = testBlob.getBlob()
      makeBlob = (string) ->
        blob = new BlobBuilder
        blob.append string
        URL.createObjectURL blob.getBlob()

    testUrl = URL.createObjectURL rawBlob
    testWorker = new Worker testUrl
    testWorker.terminate()
    true
  catch e
    if e.name is 'SECURITY_ERR'
      console? and console.warn 'Commune: Cannot provision workers when serving via `file://` protocol. Serve over http to use worker threads.'
    false



threadSupport = testSupport()

window.commune = (fn, args, cb) ->
  self = window.commune.caller
  if not self?
    self = window

  if typeof fn isnt 'function'
    throw new Error 'Commune: Must pass a function as first argument'

  if threadSupport

    if Array.isArray args
      argList = args
      if typeof cb is 'function'
        callback = cb
      else
        throw new Error 'Commune: Must pass a callback to utilize worker result'

    else if typeof args is 'function'
      callback = args
      argList = []
    else if not args?
      throw new Error 'Commune: Must pass a callback to utilize worker result'

    fnString = fn.toString()
    if not communes[fnString]
      commune = new Commune fn
      communes[fnString] = commune
    else
      commune = communes[fnString]

    commune.spawnWorker argList, callback

  else

    if not args? and not cb?
      return fn.call self

    if typeof args is 'function' or not args?
      cb = args
      args = []

    result = fn.apply self, args
    cb and cb result

