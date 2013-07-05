###
  * Commune.js
  * Web workers lose their chains
  * 0.2.2
  * Easy, DRY, transparent worker threads for your app
  * Dan Motzenbecker
  * http://oxism.com
  * MIT License
###

communes = {}
makeBlob = null
mime     = 'application\/javascript'


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


  spawnWorker: (args, cb) ->
    worker = new Worker @blobUrl
    worker.addEventListener 'message', (e) ->
      cb e.data
      worker.terminate()
    worker.postMessage args


threadSupport = do ->
  try
    testBlob = new @Blob
    Blob     = @Blob
  catch e
    Blob = @BlobBuilder or @WebKitBlobBuilder or @MozBlobBuilder or false

  URL = @URL or @webkitURL or @mozURL or false
  return false unless Blob and URL and @Worker

  testString = 'true'
  try
    if Blob is @Blob
      testBlob = new Blob [testString], type: mime
      makeBlob = (string) -> URL.createObjectURL new Blob [string], type: mime

    else
      testBlob = new Blob
      testBlob.append testString
      rawBlob  = testBlob.getBlob mime
      makeBlob = (string) ->
        blob = new Blob
        blob.append string
        URL.createObjectURL blob.getBlob mime

    testUrl    = URL.createObjectURL testBlob
    testWorker = new Worker testUrl
    testWorker.terminate()
    true

  catch e
    if e.name is 'SECURITY_ERR'
      console?.warn 'Commune: Cannot provision workers when serving' +
        'via `file://` protocol. Serve over http(s) to use worker threads.'
    false


@commune = (fn, args, cb) ->
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
    setTimeout (-> cb fn.apply @, args), 0


@communify = (fn, args) ->
  if args
    (cb) ->       commune fn, args, cb
  else
    (args, cb) -> commune fn, args, cb


@commune.isThreaded     = -> threadSupport
@commune.disableThreads = -> threadSupport = false
@commune.enableThreads  = -> threadSupport = true

