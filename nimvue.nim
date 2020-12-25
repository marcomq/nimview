import webview
import os
import json
import system
import jester
import re
import uri
import strutils
import nimpy
import tables

# nim c -r --threads:on --debuginfo  --debugger:native -d:useStdLib --verbosity:2 -d:debug nimvue.nim 
# nim c --verbosity:2 -d:release -d:useStdLib --app:lib --out:nimvue.pyd --nimcache=./generated_c nimvue.nim
# python
# >>> import nimvue
# >>> nimvue.startWebview("E:/apps/nimvue/ui/dist/index.html")
# >>> nimvue.startJester("E:/apps/nimvue/ui/dist/index.html")

proc NimMain() {.importc.}

proc appendSomething(value: string): string {.noSideEffect, gcsafe.} =
   result = value & " modified by nim"

type RequestCallbacks* = ref object of RootObj
  map: Table[string, proc(value: string): string {.gcsafe.} ]
# var requestMap = tables.toTable({"appendSomething": appendSomething})
var req {.threadvar.}: RequestCallbacks

# var requestMap {.threadvar.}: Table[string, proc(value: string): string]
# var requestMap = tables.toTable({"appendSomething": appendSomething})

proc addRequest(request: string, callback: proc(value: string): string {.gcsafe.} ) = 
  req.map[request] = callback

proc initRequestFunctions() = 
  # requestMap = tables.toTable({"appendSomething": appendSomething})
  req = new RequestCallbacks
  nimvue.addRequest("appendSomething", nimvue.appendSomething)

proc dispatchRequest(request, value: string): string {.gcsafe.} = 
  if req.map.hasKey(request):
    let callback = req.map[request]
    result = callback(value) 
  else :
    result = "404" 

# main dispatcher
# used by webview AND jester
proc dispatchJsonRequest(jsonMessage: JsonNode, headers: HttpHeaders): string = 
  let value = $jsonMessage["value"].getStr() 
  let request = $jsonMessage["request"].getStr()
  result = dispatchRequest(request, value)

# required for jester web server - it is not recommended to modify this, use "dispatchRequest" to add functionality
router myrouter:
  get re"^\/(.*)$":
    try:
      var requestContent: string = request.matches[0]
      var response: string
      if (requestContent == ""): 
        requestContent = "/index.html"
      # var potentialFilename = settings.staticDir & "/" & requestContent.replace("..", "")
      var potentialFilename = request.getStaticDir() & "/" & requestContent.replace("..", "")
      echo potentialFilename
      if existsFile(potentialFilename):
        jester.sendFile(potentialFilename)
        return
      else:
        let jsonMessage = parseJson(uri.decodeUrl(requestContent))
        try:
          response = dispatchJsonRequest(jsonMessage, request.headers)
        except:
          var errorResponse =  %* { "request":"500", "value":"internal error", "resultId": $jsonMessage["responseId"] } 
          resp errorResponse
        let jsonResponse = %* { ($jsonMessage["responseKey"]).unescape(): response }
        resp jsonResponse
    except:
      resp """{"request":"500","value":"request doesn't contain valid json","resultId":0}"""
  post "/":
    try:
      var jsonMessage = parseJson(request.body)
      let response = dispatchJsonRequest(jsonMessage, request.headers)
      let jsonResponse = %* { ($jsonMessage["responseKey"]).unescape(): response }
      resp jsonResponse
    except:
      var errorResponse =  %* { "request":"500", "value":"request doesn't contain valid json", "resultId": 0 } 
      resp errorResponse

proc startJesterInt(folder: string) =
  initRequestFunctions()
  let port = 8000
  let settings = jester.newSettings(port=Port(port), staticDir = folder.parentDir())
  var jester = jester.initJester(myrouter, settings=settings)
  jester.serve()

proc startJester*(folder: string) {.exportc, dynlib, exportpy.} =
  NimMain()
  startJesterInt(folder)

proc startWebviewInt(folder: string) =
  initRequestFunctions() 
  os.setCurrentDir(folder.parentDir())
  let myView = newWebView("NimVue", "file://" / folder)

  var fullScreen = true
  myView.bindProcs("nim"): 
      proc alert(message: string) = myView.info("alert", message)
      proc call(message: string) = 
        echo message
        let jsonMessage = json.parseJson(message)
        let resonseId = jsonMessage["responseId"].getInt()
        let emptyHeaders = jester.newHttpHeaders([("Content-Type","application/json")])
        let response = dispatchJsonRequest(jsonMessage, emptyHeaders)
        let evalJsCode = "window.nimUi.applyResponse('" & response  & "'," & $resonseId & ");"
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


proc startWebview*(folder: string) {.exportc, dynlib, exportpy.} = 
  NimMain()
  startWebviewInt(folder)

when system.appType == "lib":
  proc startJesterThread(folder: string) {.thread.} =
    var thread: Thread[string]
    createThread(thread, startJesterInt, folder)


#proc startWebviewThread(folder: string) {.thread.} =
#  startWebview(folder)

proc main() =
  when system.appType != "lib":
    let folder = os.getCurrentDir() / "ui/dist/" / "index.html"
    # startJesterThread(folder)
    startWebviewInt(folder)
  
  

when isMainModule:
  main()