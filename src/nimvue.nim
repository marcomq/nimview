import os
import json
import system
import re
import uri
import strutils
import tables
import macros
import std/compilesettings

when not defined(just_core):
  import jester
  from jester/private/utils import Settings 
  import nimpy
  import webview
else:
  # Just core features. Disable jester, webview nimpy and exportpy
  macro exportpy(def: untyped): untyped =
    result = def

# nim c -r --threads:on --debuginfo  --debugger:native -d:useStdLib --verbosity:2 -d:debug nimvue.nim 
# nim c --verbosity:2 -d:release -d:useStdLib --app:lib --out:nimvue.pyd --nimcache=./generated_c nimvue.nim
# python
# >>> import nimvue
# >>> nimvue.startWebview("E:/apps/nimvue/ui/dist/index.html")
# >>> nimvue.startJester("E:/apps/nimvue/ui/dist/index.html")

when (querySetting(backend) == "c"):
  proc NimMain() {.importc.}
  
elif (querySetting(backend) == "cpp"):
  proc NimMain() {.importcpp.}

else:
  proc NimMain() =
    discard

proc ping(value: string): string {.noSideEffect, gcsafe.} =
   result = value

type ReqUnknownException* = object of CatchableError
type RequestCallbacks* = ref object of RootObj
  map: Table[string, proc(value: string): string {.gcsafe.} ]
  
var req* {.threadvar.}: RequestCallbacks

proc addRequest*(request: string, callback: proc(value: string): string {.gcsafe.} ) {.exportc, dynlib, exportpy.} = 
  if (isNil(req)):
    req = new RequestCallbacks
  req.map[request] = callback

# macro backendRequest*(nameOrProc: untyped): untyped =  
#  expectKind(nameOrProc, {nnkProcDef, nnkFuncDef, nnkIteratorDef})
  # echo nameOrProc.name
  #quote do:
  #  echo `nameOrProc`

proc initRequestFunctions*() {.exportc, dynlib.} = 
  nimvue.addRequest("ping", nimvue.ping)

proc dispatchRequest*(request, value: string): string {.gcsafe.} = 
  if req.map.hasKey(request):
    let callback = req.map[request]
    result = callback(value) 
  else :
    raise newException(ReqUnknownException, "404 - Request unknown")

# main dispatcher
# used by webview AND jester
proc dispatchJsonRequest*(jsonMessage: JsonNode): string {.gcsafe.} = 
  let value = $jsonMessage["value"].getStr() 
  let request = $jsonMessage["request"].getStr()
  # optional - check credentials from header information
  result = dispatchRequest(request, value)

proc dispatchCommandLineArg*(escapedArgv: string): string = 
  try:
    let jsonMessage = parseJson(escapedArgv)
    result = dispatchJsonRequest(jsonMessage)
  except ReqUnknownException:
    echo "Request is unknown in " & escapedArgv
  except: 
    echo "Couldn't parse specific line arg: " & escapedArgv

proc readAndParseJsonCmdFile*(filename: string) = 
  if (os.fileExists(filename)):
    echo "opening file for parsing: " & filename
    let file = system.open(filename, system.FileMode.fmRead)
    var line: TaintedString
    while (file.readLine(line)):
      # TODO: escape line if source file cannot be trusted
      echo nimvue.dispatchCommandLineArg(line.string)
    close(file)
  else:
    echo "File does not exist: " & filename

when not defined(just_core):
  const backendHelperJs = system.staticRead("backend-helper.js")
  proc dispatchHttpRequest*(jsonMessage: JsonNode, headers: HttpHeaders): string {.gcsafe.} = 
    # optional - check credentials from header
    result = dispatchJsonRequest(jsonMessage)

  # required for jester web server - it is not recommended to modify this, use "dispatchRequest" to add functionality
  router myrouter:
    get re"^\/(.*)$":
      try:
        var requestContent: string = request.matches[0]
        var response: string
        # send file if exists
        if (requestContent == ""): 
          requestContent = "index.html"
        if (requestContent == "backend-helper.js"):
          resp backendHelperJs
        var potentialFilename = request.getStaticDir() & "/" & requestContent.replace("..", "")
        if fileExists(potentialFilename):
          echo "Sending " & potentialFilename
          jester.sendFile(potentialFilename)
          return
        else:
          if (potentialFilename.isValidFilename()):
            raise newException(ReqUnknownException, "404 - File not found")
          # if not a file, assume this is a json request 
          echo "Parsing " & requestContent
          let jsonMessage = parseJson(uri.decodeUrl(requestContent))
          try:
            response = dispatchHttpRequest(jsonMessage, request.headers)
          except ReqUnknownException:
            var errorResponse =  %* { "error":"404", "value": getCurrentExceptionMsg(), "resultId": $jsonMessage["responseId"] } 
            resp Http404, $errorResponse
          except:
            var errorResponse =  %* { "error":"500", "value":"internal error", "resultId": $jsonMessage["responseId"] } 
            resp errorResponse
          let jsonResponse = %* { ($jsonMessage["responseKey"]).unescape(): response }
          resp jsonResponse
      except ReqUnknownException:
        resp Http404, "File not found"
      except:
        echo "Error " & getCurrentExceptionMsg()
        var errorResponse =  %* { "error":"500", "value":"request doesn't contain valid json", "resultId": 0 } 
        resp Http500, $errorResponse

    post re"^\/(.*)$":
      try:
        # post data is always asumed to be a request
        var jsonMessage = parseJson(request.body)
        let response = dispatchHttpRequest(jsonMessage, request.headers)
        let jsonResponse = %* { ($jsonMessage["responseKey"]).unescape(): response }
        resp jsonResponse
      except:
        var errorResponse =  %* { "error":"500", "value":"request doesn't contain valid json", "resultId": 0 } 
        resp Http500, $errorResponse

  proc copyBackendHelper (folder: string) =
    let targetJs =  folder.parentDir() / "backend-helper.js"
    when (system.hostOS == "windows"):
      if (not os.fileExists(targetJs) or defined debug):
          system.writeFile(targetJs, backendHelperJs)
    else:
      if (not os.fileExists(targetJs)):
          os.createSymlink(system.currentSourcePath.parentDir() / "backend-helper.js", target)

  proc startJester*(folder: string, port: int = 8000, bindAddr: string = "127.0.0.1") =
    copyBackendHelper(folder)
    let settings = jester.newSettings(port=Port(port), bindAddr=bindAddr, staticDir = folder.parentDir())
    var jester = jester.initJester(myrouter, settings=settings)
    jester.serve()
    
  proc startJesterExt*(folder: string, port: int) {.exportc, dynlib, exportpy.} =
    NimMain()
    startJester(folder, port)

  proc startWebview*(folder: string) =
    copyBackendHelper(folder)
    os.setCurrentDir(folder.parentDir())
    let myView = newWebView("NimVue", "file://" / folder)

    var fullScreen = true
    myView.bindProcs("backend"): 
        proc alert(message: string) = myView.info("alert", message)
        proc call(message: string) = 
          echo message
          let jsonMessage = json.parseJson(message)
          let resonseId = jsonMessage["responseId"].getInt()
          let response = dispatchJsonRequest(jsonMessage)
          let evalJsCode = "window.ui.applyResponse('" & response.replace("\\", "\\\\").replace("\'", "\\'")  & "'," & $resonseId & ");"
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
    myView.run()
    myView.exit()

  proc startWebviewExt*(folder: string) {.exportc, dynlib, exportpy.} = 
    NimMain()
    startWebview(folder)

  when declared(Thread):
    proc startJesterThread(folder: string) {.thread.} =
      var thread: Thread[string]
      # TODO: initRequestFunctions()
      createThread(thread, startJester, folder, 8000)

#proc startWebviewThread(folder: string) {.thread.} =
#  startWebview(folder)

proc main() =
  let argv = os.commandLineParams()
  for arg in argv:
    readAndParseJsonCmdFile(arg)
  when system.appType != "lib" and not defined(just_core):
    let folder = os.getCurrentDir() / "ui/dist/index.html"
    startJester(folder)
    # startWebview(folder)

when isMainModule:
  initRequestFunctions() 
  main()