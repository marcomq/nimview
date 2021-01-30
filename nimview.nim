# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os
import json
import system
import uri
import strutils
import tables
import logging

when not defined(just_core):
  import jester
  import nimpy
  import webview except debug
  # import browsers
else:
  # Just core features. Disable jester, webview nimpy and exportpy
  macro exportpy(def: untyped): untyped =
    result = def

# nim c -r --threads:on -d:debug --debuginfo  --debugger:native -d:useStdLib --verbosity:2 nimview.nim
# cp .\generated_c\nimview.h .
# nim c --verbosity:2 -d:release -d:useStdLib --header:nimview.h --app:lib --out:nimview.dll --nimcache=./tmp_c nimview.nim
# nim c --verbosity:2 -d:release -d:useStdLib --header:nimview.h --nimcache=./tmp_c nimview.nim
# nim c --verbosity:2 -d:release -d:useStdLib --noMain:on --noLinking:on  --compileOnly:on --header:nimview.h --nimcache=./tmp_c nimview.nim
# nim c --verbosity:2 -d:release -d:useStdLib --noMain:on -d:noMain --noLinking:on --header:nimview.h --nimcache=./tmp_c nimview.nim    
# gcc -c -w -o tmp_c/c_sample.o -fmax-errors=3 -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -DWEBVIEW_WINAPI=1 -O3 -fno-strict-aliasing -fno-ident -IC:\Users\Mmengelkoch\.nimble\pkgs\webview-0.1.0\webview -IC:\Users\Mmengelkoch\.choosenim\toolchains\nim-1.4.2\lib -Itmp_c tests/c_sample.c
# gcc -w -o tests/c_sample.exe tmp_c/*.o -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32 -Itmp_c 

type ReqUnknownException* = object of CatchableError
type RequestCallbacks* = ref object of RootObj
  map: Table[string, proc(value: string): string ]
  
var req* : RequestCallbacks
var useJester* = defined(debug)
var responseHttpHeader = {"Access-Control-Allow-Origin": "None"} # will be overwritten when starting Jester
var logger = newConsoleLogger()
logging.addHandler(logger)

proc addRequest*(request: string, callback: proc(value: string): string ) {.exportpy.} = 
  if (isNil(req)):
    req = new RequestCallbacks
    debug "new request map initialized"
  {.cast(gcsafe).}:
    req.map[request] = callback

proc initRequestFunctions*() = 
  nimview.addRequest("ping", proc (value: string): string = result = value)

proc dispatchRequest*(request, value: string): string {.exportpy.} = 
  {.cast(gcsafe).}:
    if req.map.hasKey(request):
      let callbackFunc = req.map[request]
      result = callbackFunc(value) 
    else :
      raise newException(ReqUnknownException, "404 - Request unknown")

# main dispatcher
# used by webview AND jester
proc dispatchJsonRequest*(jsonMessage: JsonNode): string = 
  var value = $jsonMessage["value"].getStr() 
  if (value.isEmptyOrWhitespace()):
    value = $jsonMessage["value"]
  let request = $jsonMessage["request"].getStr()
  result = dispatchRequest(request, value)

proc dispatchCommandLineArg*(escapedArgv: string): string = 
  try:
    let jsonMessage = parseJson(escapedArgv)
    result = dispatchJsonRequest(jsonMessage)
  except ReqUnknownException:
    warn "Request is unknown in " & escapedArgv
  except: 
    warn "Couldn't parse specific line arg: " & escapedArgv

proc readAndParseJsonCmdFile*(filename: string) = 
  if (os.fileExists(filename)):
    debug "opening file for parsing: " & filename
    let file = system.open(filename, system.FileMode.fmRead)
    var line: TaintedString
    while (file.readLine(line)):
      # TODO: escape line if source file cannot be trusted
      let retVal = nimview.dispatchCommandLineArg(line.string)
      debug retVal
    close(file)
  else:
    logging.error "File does not exist: " & filename

when not defined(just_core):
  const backendHelperJs = system.staticRead("backend-helper.js")

  proc dispatchHttpRequest*(jsonMessage: JsonNode, headers: HttpHeaders): string = 
    # optional but not implemented yet - check credentials from header information
    result = dispatchJsonRequest(jsonMessage)

  template respond(code: untyped, message: untyped): untyped =
    mixin resp
    {.cast(gcsafe).}:
      resp code, nimview.responseHttpHeader, message
  
  template respond(message: untyped): untyped =
      respond Http200, message

  proc handleRequest(request: Request): Future[ResponseData] {.async.} =
    block route:
      var response: string
      var requestPath: string = request.pathInfo 
      var resultId = 0
      case requestPath
      of "/backend-helper.js":
        respond nimview.backendHelperJs
      else:
        try:
          if (requestPath == "/"): 
            requestPath = "/index.html"
          
          var potentialFilename = request.getStaticDir() & "/" & requestPath.replace("..", "")
          if fileExists(potentialFilename):
            debug "Sending " & potentialFilename
            # jester.sendFile(potentialFilename)
            respond system.readFile(potentialFilename)
          else:
            if ((request.body == "") and potentialFilename.isValidFilename()):
              raise newException(ReqUnknownException, "404 - File not found")

            # if not a file, assume this is a json request 
            var jsonMessage: JsonNode
            echo request.body
            if (request.body != ""):
              jsonMessage = parseJson(request.body)
            else:
              jsonMessage = parseJson(uri.decodeUrl(requestPath))
            resultId = jsonMessage["responseId"].getInt()
            response = dispatchHttpRequest(jsonMessage, request.headers)
            let jsonResponse = %* { ($jsonMessage["key"]).unescape(): response }
            respond $jsonResponse

        except ReqUnknownException:
          respond Http404, $ %* { "error":"404", "value": getCurrentExceptionMsg(), "resultId": resultId }
        except:
          respond Http500, $ %* { "error":"500", "value":"request doesn't contain valid json", "resultId": resultId } 

  proc copyBackendHelper (folder: string) =
    let targetJs =  folder.parentDir() / "backend-helper.js"
    try:
      when (system.hostOS == "windows"):
        if (not os.fileExists(targetJs) or defined(debug)):
            debug "writing to " & targetJs
            system.writeFile(targetJs, backendHelperJs)
      else:
        if (not os.fileExists(targetJs)):
            debug "symlinking to " & targetJs
            os.createSymlink(system.currentSourcePath.parentDir() / "backend-helper.js", targetJs)
    except:
      logging.error "backend-helper.js not copied" 
    debug "backend-helper.js finalized" 

  proc startJester*(folder: string, port: int = 8000, bindAddr: string = "localhost") {.exportpy.} =
    var absFolder = folder
    if (not os.isAbsolute(folder)): 
      if (os.getAppFilename().startsWith("python")):
        absFolder = os.getCurrentDir() / folder
      else:
        absFolder = os.getAppDir() / folder
    copyBackendHelper(absFolder)
    var origin = "http://" & bindAddr
    if (bindAddr == "0.0.0.0"):
      origin = "*"
    nimview.responseHttpHeader = { "Access-Control-Allow-Origin": origin }
    let settings = jester.newSettings(port=Port(port), bindAddr=bindAddr, staticDir = absFolder.parentDir())
    var jester = jester.initJester(handleRequest, settings=settings)
    # debug "open default browser"
    # browsers.openDefaultBrowser("http://" & bindAddr & ":" & $port)
    jester.serve()

  proc startWebview*(folder: string) {.exportpy.} =
    var absFolder = folder
    if (not os.isAbsolute(folder)):
      debug os.getAppFilename().extractFilename()
      if (os.getAppFilename().extractFilename().startsWith("python")):
        absFolder = os.getCurrentDir() / folder
      else:
        absFolder = os.getAppDir() / folder
    copyBackendHelper(absFolder)
    os.setCurrentDir(absFolder.parentDir())
    let myView = newWebView("nimview", "file://" / absFolder)
    var fullScreen = true
    myView.bindProcs("backend"): 
        proc alert(message: string) = myView.info("alert", message)
        proc call(message: string) = 
          info message
          let jsonMessage = json.parseJson(message)
          let resonseId = jsonMessage["responseId"].getInt()
          let response = dispatchJsonRequest(jsonMessage)
          let evalJsCode = "window.ui.applyResponse('" & response.replace("\\", "\\\\").replace("\'", "\\'")  & "'," & $resonseId & ");"
          let responseCode =  myView.eval(evalJsCode)
          discard responseCode
#[          # just sample functions without current real functionality
        proc open() = info myView.dialogOpen()
        proc save() = info myView.dialogSave()
        proc opendir() = info myView.dialogOpen(flag=dFlagDir)
        proc message() = myView.msg("hello", "message")
        proc warn() = myView.warn("hello", "warn")
        proc error() = myView.error("hello", "error")
        proc changeTitle(title: string) = myView.setTitle(title)
        proc close() = myView.terminate()
        proc changeColor() = myView.setColor(210,210,210,100)
        proc toggleFullScreen() = fullScreen = not myView.setFullscreen(fullScreen) ]#
    myView.run()
    myView.exit()

  when declared(Thread):
    proc startJesterThread(folder: string) {.thread.} =
      var thread: Thread[string]
      # TODO: potentially re-initialize function map for each thread
      # createThread(thread, startJester, folder, 8000)

  proc start*(folder: string) {.exportpy.} = 
    if useJester:
      startJester(folder)
    else:
      startWebview(folder)

proc main() =
  debug "starting nim main"
  let argv = os.commandLineParams()
  for arg in argv:
    readAndParseJsonCmdFile(arg)
  when system.appType != "lib" and not defined(just_core):
    let folder = os.getCurrentDir() / "tests/vue/dist/index.html"
    # startJester(folder)
    addRequest("appendSomething", proc (value: string): string =
      result = "'" & value & "' modified by Nim Backend")
    start(folder)

initRequestFunctions() 
when isMainModule and not defined(noMain):
  main()