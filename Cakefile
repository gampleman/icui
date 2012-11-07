{exec} = require 'child_process'

task "build", ->
  exec "coffee -cb lib/icui.coffee", (e) ->
    console.log e if e
    exec "uglifyjs2 lib/strftime.js lib/icui.js -o js/jquery.icui.min.js -c -m", (e) ->
      console.log e if e
      exec "rm lib/icui.js"
  exec "git checkout gh-pages", (e) ->
    console.log e if e
    exec "docco -o docs lib/icui.coffee", (e) ->
      console.log e if e
      exec "git add docs", (e) ->
        exec "git commit -m \"Updated docs\"", (e) ->
          exec "git checkout master", (e) ->
            exec "rm -r docs"
        