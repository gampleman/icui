{exec} = require 'child_process'

task "build", ->
  exec "coffee -cb lib/icui.coffee", (e) ->
    console.log e if e
    exec "uglifyjs2 lib/strftime.js lib/icui.js -o js/jquery.icui.min.js -c -m", (e) ->
      console.log e if e
      exec "rm lib/icui.js"