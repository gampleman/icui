{exec} = require 'child_process'

task "full", ->
  exec "coffee -cb lib/icui.coffee", (e) ->
    console.log e if e
    exec "uglifyjs lib/strftime.js lib/icui.js -o js/jquery.icui.min.js -c -m", (e) ->
      console.log e if e
      exec "rm lib/icui.js"
  exec "git checkout gh-pages", (e) ->
    console.log e if e
    exec "git merge master -m 'update docs'", (e) ->
      console.log e if e
      exec "docco -o docs lib/icui.coffee", (e) ->
        console.log e if e
        exec "git add docs", (e) ->
          exec "git commit -m \"Updated docs\"", (e) ->
            exec "git checkout master", (e) ->
              exec "rm -r docs"


build = (cb) ->
  exec "coffee -cb lib/icui.coffee", (e) ->
    console.log e if e
    exec "uglifyjs2 lib/strftime.js lib/icui.js -o js/jquery.icui.min.js -c -m", (e) ->
      console.log e if e
      exec "rm lib/icui.js", (e) ->
        cb() if cb

task 'build', ->
  exec "coffee -cb lib/icui.coffee", (e) ->
      console.log e if e
      exec "uglifyjs2 lib/strftime.js lib/icui.js -o js/jquery.icui.min.js -c -m", (e) ->
        console.log e if e
        exec "rm lib/icui.js"

fs  = require("fs")
task 'develop', ->
  http = require("http")
  url = require("url")

  console.log "Listening on http://localhost:8888/ ..."
  http.createServer (request, response) ->
    uri = url.parse(request.url).pathname
    extension = uri.split('.').pop()
    if uri == '/'
      response.writeHead(200)
      response.write("""<html>
        <head>
          <title>ICUI Test</title>
          <script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
          <script src="icui.js?nocache=#{Math.random()}"></script>
          <link rel="stylesheet" href="app.css" />
        </head>
        <body>
          <h1>Blank</h1>
          <form>
            <input type="hidden" class="icuiinp" />
            <input type="submit"/>
          </form>

          <h1>Editing</h1>
          <form>
            <input type="hidden" class="icuiinp" value='{"start_date":"2013-06-23T17:30:00.000Z","rrules":[{"rule_type":"IceCube::WeeklyRule", "count": 3, "interval":1,"validations":{"offset_from_pascha": [-3]}}]}' />
            <input type="submit"/>
          </form>
          <h1>Make new</h1>
          <form>
            <textarea id="ic"></textarea>
            <button id="st">Init ICUI with Data</button>
          </form>
          <script>
            $('.icuiinp').icui({submit: function(d){console.log(d, JSON.stringify(d))}})
            $('#st').click(function(e) {
              e.preventDefault()
              $('#ic').icui({submit: function(d){console.log(d, JSON.stringify(d))}});
              return false;
            });
          </script>
        </body>
      </html>""", "UTF-8")
      response.end()
    else if uri == '/icui.js'
      exec "coffee -cb lib/icui.coffee", (e) ->
        if e
          console.log e
          response.write("""$(function() {document.write("<h1>Compile Error</h1><pre>#{("" + e).replace(/\n/g, "\\n")}</pre>");});""", 'UTF-8')
          response.end()
        else
          exec "cat lib/icui.js > js/icui.js && cat lib/strftime.js >> js/icui.js", (e) ->
            if e
              response.write("""document.body.write('<h1>Compile Error</h1><pre>#{e}</pre>)""", 'UTF-8')
              response.end()
            else
              fs.readFile 'js/icui.js', "binary", (err, file) ->
                response.write(file, "binary")
                response.end()
    else if extension == 'js' && !uri.match(/jasmine/)
      comps = uri.split('.')
      comps.pop()
      sendCompiledFile(response, comps.join('.'))
    else
      sendFile(response, uri[1..])
  .listen 8888


sendFile = (response, path, cb = ->) ->
  fs.readFile path, "binary", (err, file) ->
    if err
      console.log err
      response.writeHead 404
      response.end()
    else
      response.write(file, "binary")
      response.end()
      cb()

sendCompiledFile = (response, path, cb = ->) ->
  path = path[1..]
  exec "coffee -cb #{path}.coffee", (e) ->
    if e
      console.log e
      response.write("""$(function() {document.write("<h1>Compile Error</h1><pre>#{("" + e).replace(/\n/g, "\\n")}</pre>");});""", 'UTF-8')
      response.end()
    else
      sendFile response, "#{path}.js", cb
