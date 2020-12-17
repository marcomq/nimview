import webview
import os
import json
import system
import jester
import re
import uri
import strutils

proc getUiDir(): string =
  result = getCurrentDir() 

proc dispatchRequest(request, value: string): string = 
  # request might contain model & action
  # value may contain json with further actions
  case request:
    of "appendSomething":
      result = value & " modified by nim"
    of "":
      result = value & " evaluated by nim" 
    else:
      # echo "'" , value , '"'
      result = "404" 

# main dispatcher
# used by webview AND jester
proc dispatchJsonRequest(jsonMessage: JsonNode): string = 
  let value = $jsonMessage["value"].getStr() 
  let request = $jsonMessage["request"].getStr()
  result = dispatchRequest(request, value)

#required for jester web server
router myrouter:
  get re"^\/(.*)$":
    var jsonMessage: JsonNode
    try:
      var requestContent: string = request.matches[0]
      var response: string
      if (requestContent == ""): 
        requestContent = "/index.html"
      var potentialFilename = getUiDir() & "/" & requestContent.replace("..", "")
      echo potentialFilename
      if existsFile(potentialFilename):
        jester.sendFile(potentialFilename)
        return
      else:
        jsonMessage = parseJson(uri.decodeUrl(requestContent))
        response = dispatchJsonRequest(jsonMessage)
      var jsonresponse = %* { ($jsonMessage["responseKey"]).unescape(): response }
      resp jsonresponse
    except:
      resp """{"request":"500","value":"request doesn't contain valid json","resultId":0}"""
  post "/":
    resp dispatchJsonRequest(parseJson(request.body))

proc startJester() {.thread.} =
  let port = 8000
  let settings = jester.newSettings(port=Port(port), staticDir = getUiDir())
  var jester = jester.initJester(myrouter, settings=settings)
  jester.serve()

proc startWebview(folder: string) = 
  let myView = newWebView("test", "file://" / folder)

  var fullScreen = true
  myView.bindProcs("nim"): 
      proc alert(message: string) = myView.info("alert", message)
      proc call(message: string) = 
        echo message
        let jsonMessage = json.parseJson(message)
        let resonseId = jsonMessage["responseId"].getInt()
        let response = dispatchJsonRequest(jsonMessage)
        let evalJsCode = "window.ui.applyResponse('" & response  & "'," & $resonseId & ");"
        let responseCode =  myView.eval(evalJsCode)
        discard responseCode
      # just sample functions without current real functionality
      proc open() = echo myView.dialogOpen()
      proc save() = echo myView.dialogSave()
      proc opendir() = echo myView.dialogOpen(flag=dFlagDir)
      proc message() = myView.msg("hello", "message")
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


proc main() =
  # startJester()
  let folder = os.getCurrentDir() / "ui/dist/" / "index.html"
  os.setCurrentDir(folder.parentDir())

  var thread: Thread[void]
  createThread(thread, startJester)
  startWebview(folder)
  
  

when isMainModule:
  main()