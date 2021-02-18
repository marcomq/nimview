# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os
import json
import system
import uri
import strutils
import sharedtables
import logging

# run "nimble release" or "nimble debug" to compile

const compileWithWebview = defined(useWebview) or not defined(useJester)

when not defined(just_core):
  import jester
  import nimpy
  when compileWithWebview:
    import webview except debug
    var myWebView: Webview
  # import browsers
else:
  # Just core features. Disable jester, webview nimpy and exportpy
  macro exportpy(def: untyped): untyped =
    result = def

type ReqUnknownException* = object of CatchableError

var responseHttpHeader = {"Access-Control-Allow-Origin": "None"} # will be overwritten when starting Jester
var useJester* = not compileWithWebview or (defined(useJester) or defined(debug) or (os.fileExists("/.dockerenv")))
var reqMap: SharedTable[string, proc(value: string): string ] 
reqMap.init()

let stdLogger = newConsoleLogger()
logging.addHandler(stdLogger)
var requestLogger: FileLogger = nil

proc enableRequestLogger*() {.exportpy.} = 
  ## Start to log all requests with content, even passwords, into file "requests.log". 
  ## The file can be used for automated tests, to archive and replay all actions.
  if requestLogger.isNil:
    if not fileExists("requests.log"):
      var createFile = system.open("requests.log", system.fmWrite)
      createFile.close()
    let requestLoggerTmp = newFileLogger("requests.log", fmtStr = "")
    requestLogger = requestLoggerTmp;
  requestLogger.levelThreshold = logging.lvlAll
    
proc disableRequestLogger*() {.exportpy.} = 
  ## Will stop to log to "requests.log" (default)
  if not requestLogger.isNil:
    requestLogger.levelThreshold = logging.lvlNone

proc addRequest*(request: string, callback: proc(value: string): string ) {.exportpy.} = 
  ## This will register a function "callback" that can run on back-end.
  ## "addRequest" will be executed with "value" each time the javascript client calls:
  ## `window.ui.backend(request, value, function(response) {...})`
  ## with the specific "request" value.
  ## There is a wrapper for python, C and C++ to handle strings in each specific programming language
  nimview.reqMap[request] = callback

proc dispatchRequest*(request: string, value: string): string {.exportpy.} = 
  ## Global string dispatcher that will trigger a previously registered functions 
  {.gcsafe.}: 
    nimview.reqMap.withValue(request, callbackFunc) do:
      result = callbackFunc[](value) 
    do:
      raise newException(ReqUnknownException, "404 - Request unknown")

proc dispatchJsonRequest*(jsonMessage: JsonNode): string = 
  ## Global json dispatcher that will be called from webview AND jester
  ## This will extract specific values that were prepared by backend-helper.js 
  ## and forward those values to the string dispatcher.
  var value = $jsonMessage["value"].getStr() 
  if (value == ""):
    value = $jsonMessage["value"]
  let request = $jsonMessage["request"].getStr()
  {.gcsafe.}:
    if not requestLogger.isNil:
      requestLogger.log(logging.lvlInfo, $jsonMessage)
  result = dispatchRequest(request, value)

proc dispatchCommandLineArg*(escapedArgv: string): string = 
  ## Will handle previously logged request json and forward those to registered functions.
  try:
    let jsonMessage = parseJson(escapedArgv)
    result = dispatchJsonRequest(jsonMessage)
  except ReqUnknownException:
    warn "Request is unknown in " & escapedArgv
  except: 
    warn "Couldn't parse specific line arg: " & escapedArgv

proc readAndParseJsonCmdFile*(filename: string) = 
  ## Will open, parse a file of previously logged requests and re-runs those requests.
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
  when defined release:
    const backendHelperJs = system.staticRead("backend-helper.js")
  else:
    let backendHelperJs = system.readFile("backend-helper.js")

  proc dispatchHttpRequest*(jsonMessage: JsonNode, headers: HttpHeaders): string = 
    ## Modify this, if you want to add some authentication, input format validation
    ## or if you want to process HttpHeaders. 
    result = dispatchJsonRequest(jsonMessage)

  template respond(code: untyped, header:untyped, message: untyped): untyped =
    mixin resp
    {.gcsafe.}:
      resp code, header, message
  
  template respond(message: untyped): untyped =
      respond Http200, nimview.responseHttpHeader, message

  proc handleRequest(request: Request): Future[ResponseData] {.async.} =
    ## used by HttpServer
    block route:
      var response: string
      var requestPath: string = request.pathInfo 
      var resultId = 0
      case requestPath
      of "/backend-helper.js":
        var header = @{"Content-Type": "application/javascript"}
        {.gcsafe.}: header.add(nimview.responseHttpHeader)
        respond Http200, header, nimview.backendHelperJs
      else:
        try:
          if (requestPath == "/"): 
            requestPath = "/index.html"
          
          var potentialFilename = request.getStaticDir() & "/" & requestPath.replace("..", "")
          if os.fileExists(potentialFilename):
            debug "Sending " & potentialFilename
            # jester.sendFile(potentialFilename)
            let fileData = splitFile(potentialFilename)
            let contentType = case fileData.ext:
              of ".json": "application/json;charset=utf-8"
              of ".js": "text/javascript;charset=utf-8"
              of ".css": "text/css;charset=utf-8"
              of ".jpg": "image/jpeg"
              of ".txt": "text/plain;charset=utf-8"
              of ".map": "application/octet-stream"
              else: "text/html;charset=utf-8"
            var header = @{"Content-Type": contentType}
            {.gcsafe.}: header.add(nimview.responseHttpHeader)
            respond Http200, header, system.readFile(potentialFilename)
          else:
            if (request.body == ""):
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
          respond Http404, nimview.responseHttpHeader, $ %* { "error":"404", "value": getCurrentExceptionMsg(), "resultId": resultId }
        except:
          respond Http500, nimview.responseHttpHeader, $ %* { "error":"500", "value":"request doesn't contain valid json", "resultId": resultId }

  proc copyBackendHelper (folder: string) {.gcsafe.} =
    let targetJs =  folder / "backend-helper.js"
    try:
      when (system.hostOS == "windows"):
        if (not os.fileExists(targetJs) or defined(debug)):
            debug "writing to " & targetJs
            {.gcsafe.}:
              system.writeFile(targetJs, backendHelperJs)
      else:
        if (not os.fileExists(targetJs)):
            debug "symlinking to " & targetJs
            os.createSymlink(system.currentSourcePath.parentDir() / "backend-helper.js", targetJs)
    except:
      logging.error "backend-helper.js not copied" 

  proc getAbsPath(indexHtmlFile: string): string = 
    result = indexHtmlFile
    if (not os.isAbsolute(indexHtmlFile)):
      debug os.getAppFilename().extractFilename()
      if (os.getAppFilename().extractFilename().startsWith("python")):
        result = os.getCurrentDir() / indexHtmlFile
      else:
        result = os.getAppDir() / indexHtmlFile

  proc startHttpServer*(indexHtmlFile: string, port: int = 8000, bindAddr: string = "localhost") {.exportpy.} =
    ## Start Http server (Jester) in blocking mode. indexHtmlFile will displayed for "/".
    ## Files in parent folder or sub folders may be accessed without further check. Will run forever.
    var absIndexHtml = nimview.getAbsPath(indexHtmlFile)
    nimview.copyBackendHelper(absIndexHtml.parentDir())
    var origin = "http://" & bindAddr
    if (bindAddr == "0.0.0.0"):
      origin = "*"
    {.gcsafe.}:
      nimview.responseHttpHeader = { "Access-Control-Allow-Origin": origin }
    let settings = jester.newSettings(port=Port(port), bindAddr=bindAddr, staticDir = absIndexHtml.parentDir())
    var myJester = jester.initJester(nimview.handleRequest, settings=settings)
    # debug "open default browser"
    # browsers.openDefaultBrowser("http://" & bindAddr & ":" & $port)
    myJester.serve()
    

  proc stopDesktop*() {.exportpy.} =
    ## Will stop the Http server - may trigger application exit.
    if not myWebView.isNil():
      myWebView.terminate()

  proc startDesktop*(indexHtmlFile: string, title: string = "nimview", 
      width: int = 640, height: int = 480, resizable: bool = true, debug: bool = defined release) {.exportpy.} =
    ## Will start Webview Desktop UI to display the index.hmtl file in blocking mode.
    when compileWithWebview: 
      var absIndexHtml = nimview.getAbsPath(indexHtmlFile)
      nimview.copyBackendHelper(absIndexHtml.parentDir())
      os.setCurrentDir(absIndexHtml.parentDir()) # unfortunately required, let me know if you have a workaround
      # var fullScreen = true
      myWebView = webview.newWebView(title, "file://" / absIndexHtml, width, height, resizable = resizable, debug = debug)
      myWebView.bindProc("backend", "alert", proc (message: string) = webview.info(myWebView, "alert", message))
      myWebView.bindProc("backend", "call", proc (message: string) = 
        info message
        let jsonMessage = json.parseJson(message)
        let resonseId = jsonMessage["responseId"].getInt()
        let response = dispatchJsonRequest(jsonMessage)
        let evalJsCode = "window.ui.applyResponse('" & response.replace("\\", "\\\\").replace("\'", "\\'")  & "'," & $resonseId & ");"
        let responseCode =  webview.eval(myWebView, evalJsCode)
        discard responseCode
      )
#[    proc changeColor() = myWebView.setColor(210,210,210,100)
      proc toggleFullScreen() = fullScreen = not myWebView.setFullscreen(fullScreen) ]#
      myWebView.run()
      myWebView.exit()
      dealloc(myWebView)
  
  when declared(Thread):
    proc startHttpServerByTuple(args: tuple[indexHtmlFile: string, port: int, bindAddr: string]) {.thread.} =
      nimview.startHttpServer(args.indexHtmlFile, args.port, args.bindAddr)

    proc startHttpServerThread*(indexHtmlFile: string, port: int = 8000, bindAddr: string = "localhost") {.thread.} =
      ## Only available if compiled with --threads:on - will start webserver in thread. 
      ## Check nim manual about multithreading and use with care.
      var thread: Thread[tuple[indexHtmlFile: string, port: int, bindAddr: string]]
      createThread(thread, startHttpServerByTuple, (indexHtmlFile, port, bindAddr))

  proc start*(indexHtmlFile: string, port: int = 8000, bindAddr: string = "localhost", title: string = "nimview", 
      width: int = 640, height: int = 480, resizable: bool = true) {.exportpy.} =
    ## Tries to automatically select the Http server in debug mode or when no UI available
    ## and the Webview Desktop App in Release mode, if UI available.
    ## Notice that this may take the debug mode information of the dll at dll compile timenim.
    let displayAvailable = when (system.hostOS == "windows"): true else: (os.getEnv("DISPLAY") != "")
    if useJester or not displayAvailable:
      startHttpServer(indexHtmlFile, port, bindAddr)
    else:
      startDesktop(indexHtmlFile, title, width, height, resizable)

proc main() =
  when not defined(noMain):
    debug "starting nim main"
    when system.appType != "lib" and not defined(just_core):
      nimview.addRequest("appendSomething", proc (value: string): string =
        result = "'" & value & "' modified by Nim Backend")
      
      let argv = os.commandLineParams()
      for arg in argv:
        nimview.readAndParseJsonCmdFile(arg)
      # let indexHtmlFile = os.getCurrentDir() / "tests/vue/dist/index.html"
      let indexHtmlFile = os.getCurrentDir() / "tests/svelte/public/index.html"
      nimview.enableRequestLogger()
      # nimview.startHttpServerThread(indexHtmlFile)
      echo "started"
      nimview.start(indexHtmlFile)
      # nimview.startHttpServer(indexHtmlFile)
      # nimview.startDesktop(indexHtmlFile)
      echo "ended"

when isMainModule:
  main()