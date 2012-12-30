{exec, spawn} = require 'child_process'

output = (data) -> console.log data.toString()

print = (fn) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr
    fn?()


task 'build', 'Build, minify, and generate docs for Commune', ->
  exec 'coffee -c commune.coffee', print ->
    exec 'uglifyjs -o commune.min.js commune.js', print()


task 'watch', 'Build Commune continuously', ->
  watcher = spawn 'coffee', ['-wc', 'commune.coffee']
  watcher.stdout.on 'data', output
  watcher.stderr.on 'data', output
