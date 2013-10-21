{exec, spawn} = require 'child_process'

output = (data) -> console.log data.toString()

print  = (fn) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr
    fn?()

startWatcher = (bin, args) ->
  watcher = spawn bin, args?.split ' '
  watcher.stdout.pipe process.stdout
  watcher.stderr.pipe process.stderr


task 'build', 'Build, minify, and generate docs for Commune', ->
  exec 'coffee -mc commune.coffee', print ->
    exec 'uglifyjs -o commune.min.js commune.js', print()
  exec 'coffee -mc test/main.coffee', print()


task 'watch', 'Build Commune continuously', ->
  startWatcher.apply @, pair for pair in [
    ['coffee', '-mwc commune.coffee']
    ['coffee', '-mwc test/main.coffee']
  ]

