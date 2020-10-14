import webview
import os
import json
import system
import jester
import re
import uri

proc dispatchRequest(jsonMessage: JsonNode): string = 
  var value = $jsonMessage["value"].getStr() 
  let request = $jsonMessage["request"].getStr()
  case request:
    of "\"\"":
      result = value & "evaluated by nim"
    of "":
      result = value & "modified by nim" 
    of "404":
      result = "404" 
    else:
      # echo "'" , value , '"'
      result = value & " applied by nim"

router myrouter:
  get re"^\/(.*)$":
    var jsonMessage: JsonNode
    try:
      jsonMessage = parseJson(uri.decodeUrl(request.matches[0]))
    except:
      jsonMessage = parseJson("""{"request":"404","value":"","resultId":0}""")
    resp dispatchRequest(jsonMessage)
  post "/":
    resp dispatchRequest(parseJson(request.body))

proc startJester() {.thread.} =
  let port = 8000
  let settings = jester.newSettings(port=Port(port))
  var jester = jester.initJester(myrouter, settings=settings)
  jester.serve()


proc main() =
  # startJester()
  var thread: Thread[void]
  createThread(thread, startJester)
  
  let folder = os.getCurrentDir() / "ui/dist/" / "index.html"
  # let folder = os.getCurrentDir() / "ui/public/" / "index2.html"
  os.setCurrentDir(folder.parentDir())
  # let myView = cast[webview.Webview](alloc0(sizeof(webview.WebviewObj)))
  let myView = newWebView("test", "file://" / folder)
  # const localJs = system.staticRead("D:/apps/testNimWebview/svelte/public/build/bundle.js")

 # myView.run()
  var fullScreen = true
  myView.bindProcs("nim"): 
      proc open() = echo myView.dialogOpen()
      proc save() = echo myView.dialogSave()
      proc opendir() = echo myView.dialogOpen(flag=dFlagDir)
      proc message() = myView.msg("hello", "message")
      proc alert(message: string) = myView.info("alert", message)
      proc call(message: string) = 
        echo message
        let jsonMessage = json.parseJson(message)
        let resonseId = jsonMessage["responseId"].getInt()
        let response = dispatchRequest(jsonMessage)
        let evalJsCode = "window.ui.applyResponse('" & response  & "'," & $resonseId & ");"
        let responseCode =  myView.eval(evalJsCode)
        discard responseCode
      proc warn() = myView.warn("hello", "warn")
      proc error() = myView.error("hello", "error")
      proc changeTitle(title: string) = myView.setTitle(title)
      proc close() = myView.terminate()
      proc changeColor() = myView.setColor(210,210,210,100)
      proc toggleFullScreen() = fullScreen = not myView.setFullscreen(fullScreen)
  # let responseCode = myView.eval("alert('got it');")
  # const clientSideJavascript = system.staticRead("ui/src/callAndStore.js")
  # discard myView.eval(clientSideJavascript)
  myView.run()
  myView.exit()

when isMainModule:
  main()