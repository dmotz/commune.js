{exec, spawn} = require 'child_process'

output = (data) -> console.log data.toString()

print  = (fn) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr
    fn?()


task 'build', 'Build, minify, and generate docs for Commune', ->
  exec 'coffee -mc commune.coffee', print ->
    exec 'uglifyjs -o commune.min.js commune.js', print()
  exec 'coffee -mc test/main.coffee', print()


task 'watch', 'Build Commune continuously', ->
  watcher = spawn 'coffee', ['-mwc', 'commune.coffee']
  tests   = spawn 'coffee', ['-mwc', 'test/main.coffee']
  watcher.stdout.on 'data', output
  watcher.stderr.on 'data', output
  tests.stdout.on   'data', output
  tests.stderr.on   'data', output
