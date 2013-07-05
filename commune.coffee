###
  * Commune.js
  * Web workers lose their chains
  * 0.2.1
  * Easy, DRY, transparent worker threads for your app
  * Dan Motzenbecker
  * http://oxism.com
  * MIT License
###

root     = @
communes = {}
makeBlob = null


class Commune

  constructor: (fnString) ->
    if fnString.match /\bthis\b/
      console?.warn '''
                    Commune: Referencing `this` within a worker process might not work as expected.
                    `this` will refer to the worker itself or an object created within the worker.
                    '''

    if (lastReturnIndex = fnString.lastIndexOf 'return') is -1
      throw new Error 'Commune: Target function has no return statement.'

    @blobUrl = makeBlob (fnString[...lastReturnIndex] +
                """
                  self.postMessage(#{ fnString.substr(lastReturnIndex).replace /return\s+|;|\}$/g, '' });
                }
                """).replace(/^function(.+)?\(/, 'function __communeInit(') +
                '''
                if (typeof window === 'undefined') {
                  self.addEventListener('message', function(e) {
                    __communeInit.apply(this, e.data);
                  });
                }
                '''

    @blobUrl = makeBlob fnString


  spawnWorker: (args, cb) ->
    worker = new Worker @blobUrl
    worker.addEventListener 'message', (e) ->
      cb e.data
      worker.terminate()
    worker.postMessage args


threadSupport = do ->
  try
    testBlob = new root.Blob
    Blob     = root.Blob
  catch e
    Blob = root.BlobBuilder or root.WebKitBlobBuilder or root.MozBlobBuilder or false

  URL = root.URL or root.webkitURL or root.mozURL or false
  return false unless Blob and URL and root.Worker

  testString = 'true'
  try
    if Blob is root.Blob
      testBlob    = new Blob [testString]
      sliceMethod = Blob::slice or Blob::webkitSlice or Blob::mozSlice
      rawBlob     = sliceMethod.call testBlob

      makeBlob = (string) ->
        blob = new Blob [string], type: 'application\/javascript'
        URL.createObjectURL sliceMethod.call blob

    else
      testBlob = new Blob
      testBlob.append testString
      rawBlob = testBlob.getBlob()
      makeBlob = (string) ->
        blob = new Blob
        blob.append string
        URL.createObjectURL blob.getBlob()

    testUrl    = URL.createObjectURL rawBlob
    testWorker = new Worker testUrl
    testWorker.terminate()
    true

  catch e
    if e.name is 'SECURITY_ERR'
      console?.warn 'Commune: Cannot provision workers when serving' +
        'via `file://` protocol. Serve over http(s) to use worker threads.'
    false


root.commune = (fn, args, cb) ->
  unless typeof fn is 'function'
    throw new Error 'Commune: Must pass a function as first argument.'

  if typeof args is 'function'
    cb   = args
    args = []

  if threadSupport
    fnString = fn.toString()
    unless communes[fnString]
      unless typeof cb is 'function'
        throw new Error 'Commune: Must pass a callback to utilize worker result.'
      commune = communes[fnString] = new Commune fnString
    else
      commune = communes[fnString]

    commune.spawnWorker args, cb

  else
    cb fn.apply @, args


root.communify = (fn, args) ->
  if args
    (cb) -> commune fn, args, cb
  else
    (args, cb) -> commune fn, args, cb


root.commune.isThreaded     = -> threadSupport
root.commune.disableThreads = -> threadSupport = false
root.commune.enableThreads  = -> threadSupport = true

