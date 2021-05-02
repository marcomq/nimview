# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os, system, tables
import json, logging, macros

# run "nake release" or "nake debug" to compile

when not defined(just_core):
  const compileWithWebview = defined(useWebview) or not defined(useServer)
  import strutils
  import nimpy
  from nimpy/py_types import PPyObject
  import jester
  import globalToken
  # import browsers
  when compileWithWebview:
    import webview except debug
    var myWebView: Webview
  var responseHttpHeader {.threadVar.}: seq[tuple[key, val: string]] # will be set when starting Jester
else:
  const compileWithWebview = false
  var myWebView = nil
  # Just core features. Disable jester, webview nimpy and exportpy
  macro exportpy(def: untyped): untyped =
    result = def

type ReqUnknownException* = object of CatchableError
type ReqDeniedException* = object of CatchableError
type ServerException* = object of CatchableError

var reqMap {.threadVar.}: Table[string, proc (values: JsonNode): string] 
var requestLogger {.threadVar.}: FileLogger
var useServer* = not compileWithWebview or 
  (defined(useServer) or defined(debug) or (os.fileExists("/.dockerenv")))
var useGlobalToken* = true

proc setUseServer*(val: bool) {.exportpy.} =
  useServer = val

proc setUseGlobalToken*(val: bool) {.exportpy.} =
  useGlobalToken = val

logging.addHandler(newConsoleLogger())

proc enableRequestLogger*() {.exportpy.} =
  ## Start to log all requests with content, even passwords, into file "requests.log".
  ## The file can be used for automated tests, to archive and replay all actions.
  if nimview.requestLogger.isNil:
    debug "creating request logger, further requests will be logged to file and flushed at application end"
    if not os.fileExists("requests.log"):
      var createFile = system.open("requests.log", system.fmWrite)
      createFile.close()
    var requestLoggerTmp = newFileLogger("requests.log", fmtStr = "")

    nimview.requestLogger.swap(requestLoggerTmp)
  nimview.requestLogger.levelThreshold = logging.lvlAll

proc disableRequestLogger*() {.exportpy.} =
  ## Will stop to log to "requests.log" (default)
  if not requestLogger.isNil:
    requestLogger.levelThreshold = logging.lvlNone

proc parseAny[T](value: string): T =
  when T is string:
    result = value
  elif T is JsonNode:
    result = json.parseJsonvalue(value)
  elif T is bool:
    result = strUtils.parseBool(value)
  elif T is enum:
    result = strUtils.parseEnum(value)
  elif T is uint:
    result = strUtils.parseUInt(value)
  elif T is int:
    result = strUtils.parseInt(value)
  elif T is float:
    result = strUtils.parseFloat(value)
  # when T is array:
  #   result = strUtils.parseEnum(value)

template withStringFailover[T](value: JsonNode, jsonType: JsonNodeKind, body: untyped) =
    if value.kind == jsonType:
      body
    elif value.kind == JString:
      result = parseAny[T](value.getStr())
    else: 
      result = parseAny[T]($value)

proc parseAny[T](value: JsonNode): T =
  when T is JsonNode:
    result = value
  elif T is (int or uint):
    withStringFailover[T](value, Jint):
      result = value.getInt()
  elif T is float:
    withStringFailover[T](value, JFloat):
      result = value.getFloat()
  elif T is bool:
    withStringFailover[T](value, JBool):
      result = value.getBool()
  elif T is string:
    if value.kind == JString:
      result = value.getStr()
    else: 
      result = parseAny[T]($value)
  elif T is varargs[string]:
    if (value.kind == JArray):
      newSeq(result, value.len)
      for i in value.len:
        result[i] = parseAny[string](value[i])
    else:
      result = value.to(T)
  else: 
    result = value.to(T)

proc addRequest*(request: string, callback: proc(values: JsonNode): string) =
  {.gcsafe.}: 
    nimview.reqMap[request] = callback

proc addRequest*(request: string, callback: proc(valuesdef: varargs[PPyObject]): string) {.exportpy.} =
   nimview.addRequest(request, proc (values: JsonNode): string =
    var argSeq = newSeq[PPyObject]()
    if (values.kind == JArray):
      newSeq(argSeq, values.len)
      for i in 0 ..< values.len:
        argSeq[i] = parseAny[string](values[i]).toPyObjectArgument()
    elif (values.kind != JNull):
      argSeq.add(parseAny[string](values).toPyObjectArgument())
    result = callback(argSeq))

proc addRequest*[T](request: string, callback: proc(value: T): string) =
    nimview.addRequest(request, proc (values: JsonNode): string =
      result = callback(parseAny[T](values)))

proc addRequest*[T1, T2](request: string, callback: proc(value1: T1, value2: T2): string) =
    nimview.addRequest(request, proc (values: JsonNode): string = 
      if values.len > 1:
        result = callback(parseAny[T1](values[0]), parseAny[T2](values[1]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 2 arguments"))

proc addRequest*[T1, T2, T3](request: string, callback: proc(value1: T1, value2: T2, value3: T3): string) =
    nimview.addRequest(request, proc (values: JsonNode): string = 
      if values.len > 2:
        result = callback(parseAny[T1](values[0]), parseAny[T2](values[1]), parseAny[T3](values[3]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 3 arguments"))

proc addRequest*(request: string, callback: proc(): string) =
    nimview.addRequest(request, proc (values: JsonNode): string = 
      callback())

proc addRequest*(request: string, callback: proc(value: string): string {.gcsafe.}) =
  ## This will register a function "callback" that can run on back-end.
  ## "addRequest" will be performed with "value" each time the javascript client calls:
  ## `window.ui.backend(request, value, function(response) {...})`
  ## with the specific "request" value.
  ## There are also overloaded functions for less or additional parameters
  ## There is a wrapper for python, C and C++ to handle strings in each specific programming language
  ## Notice for python: There is no check for correct function signature!
  nimview.addRequest[string](request, callback)

proc getCallbackFunc(request: string): proc(values: JsonNode): string =
  nimview.reqMap.withValue(request, callbackFunc) do: # if request available, run request callback
    try:
      result = callbackFunc[]
    except:
      raise newException(ServerException, "Server error calling request '" & 
        request & "': " & getCurrentExceptionMsg())
  do:
    raise newException(ReqUnknownException, "404 - Request unknown")

proc dispatchRequest*(request: string, value: string): string =
  ## Global string dispatcher that will trigger a previously registered functions
  nimview.getCallbackFunc(request)(%value) # % converts to json
  
proc dispatchJsonRequest*(jsonMessage: JsonNode): string =
  ## Global json dispatcher that will be called from webview AND jester
  ## This will extract specific values that were prepared by backend-helper.js
  ## and forward those values to the string dispatcher.
  let request = $jsonMessage["request"].getStr()
  if request == "getGlobalToken":
    return
  if not requestLogger.isNil:
    requestLogger.log(logging.lvlInfo, $jsonMessage)
  let callbackFunc = nimview.getCallbackFunc(request)
  result = callbackFunc(jsonMessage["value"])

proc selectFolderDialog*(title: string): string  {.exportpy.} =
  ## Will open a "sect folder dialog" if in webview mode and return the selection.
  ## Will return emptys string in webserver mode
  when compileWithWebview:
    if not myWebView.isNil():
      result = myWebView.dialogOpen(title=if title != "" : title else: "Select Folder", flag=webview.dFlagDir)

proc selectFileDialog*(title: string): string  {.exportpy.} =
  ## Will open a "sect file dialog" if in webview mode and return the selection.
  ## Will return emptys string in webserver mode
  when compileWithWebview:
    if not myWebView.isNil():
      result = myWebView.dialogOpen(title=if title != "" : title else: "Select File", flag=webview.dFlagFile)

proc dispatchCommandLineArg*(escapedArgv: string): string  {.exportpy.} =
  ## Will handle previously logged request json and forward those to registered functions.
  try:
    let jsonMessage = parseJson(escapedArgv)
    result = dispatchJsonRequest(jsonMessage)
  except ReqUnknownException:
    warn "Request is unknown in " & escapedArgv
  except ServerException:
     warn "Error calling function, args: " & escapedArgv
  except:
    warn "Error during specific line arg: " & escapedArgv

proc readAndParseJsonCmdFile*(filename: string) {.exportpy.} =
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
    const backendHelperJsStatic = system.staticRead("backend-helper.js")
    var backendHelperJs {.threadVar.}: string

  proc dispatchHttpRequest*(jsonMessage: JsonNode, headers: HttpHeaders): string =
    ## Modify this, if you want to add some authentication, input format validation
    ## or if you want to process HttpHeaders.
    if not nimview.useGlobalToken or globalToken.checkToken(headers):
        return dispatchJsonRequest(jsonMessage)
    else:
        let request = $jsonMessage["request"].getStr()
        if request != "getGlobalToken":
            raise newException(ReqDeniedException, "403 - Token expired")

  template respond(code: untyped, header: untyped, message: untyped): untyped =
    mixin resp
    jester.resp code, header, message

  proc handleRequest(request: Request): Future[ResponseData] {.async.} =
    ## used by HttpServer
    block route:
      var response: string
      var requestPath: string = request.pathInfo
      var resultId = 0
      case requestPath
      of "/backend-helper.js":
        var header = @{"Content-Type": "application/javascript"}
        header.add(nimview.responseHttpHeader)
        respond Http200, header, nimview.backendHelperJs
      else:
        try:
          let separatorFound = requestPath.rfind({'#', '?'})
          if separatorFound != -1:
            requestPath = requestPath[0 ..< separatorFound]
          if (requestPath == "/"):
            requestPath = "/index.html"

          var potentialFilename = request.getStaticDir() & "/" &
              requestPath.replace("..", "")
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
            header.add(nimview.responseHttpHeader)
            respond Http200, header, system.readFile(potentialFilename)
          else:
            if (request.body == ""):
              raise newException(ReqUnknownException, "404 - File not found")

            # if not a file, assume this is a json request
            var jsonMessage: JsonNode
            debug request.body
            # if unlikely(request.body == ""):
            #   jsonMessage = parseJson(uri.decodeUrl(requestPath))
            # else:
            jsonMessage = parseJson(request.body)
            resultId = jsonMessage["responseId"].getInt()
            {.gcsafe.}:
              var currentToken = globalToken.byteToString(globalToken.getFreshToken())
              response = dispatchHttpRequest(jsonMessage, request.headers)
              var header = @{"Global-Token": currentToken}
              respond Http200, header, response

        except ReqUnknownException:
          respond Http404, nimview.responseHttpHeader, $ %* {"error": "404",
              "value": getCurrentExceptionMsg(), "resultId": resultId}
        except ReqDeniedException:
          respond Http403, nimview.responseHttpHeader, $ %* {"error": "403",
              "value": getCurrentExceptionMsg(), "resultId": resultId}
        except ServerException:
          respond Http500, nimview.responseHttpHeader, $ %* {"error": "500",
              "value": getCurrentExceptionMsg(), "resultId": resultId}
        except:
          respond Http500, nimview.responseHttpHeader, $ %* {"error": "500",
              "value": "request doesn't contain valid json",
              "resultId": resultId}
        
  proc getCurrentAppDir(): string =
      let applicationName = os.getAppFilename().extractFilename()
      debug applicationName
      if (applicationName.startsWith("python") or applicationName.startsWith("platform-python")):
        result = os.getCurrentDir()
      else:
        result = os.getAppDir()

  proc copyBackendHelper (indexHtml: string) =
    let folder = indexHtml.parentDir()
    let targetJs = folder / "backend-helper.js"
    try:
      if not os.fileExists(targetJs) and indexHtml.endsWith(".html"):
        # read index html file and check if it actually requires backend helper
        let indexHtmlContent = system.readFile(indexHtml)
        if indexHtmlContent.contains("backend-helper.js"):
          let sourceJs = nimview.getCurrentAppDir() / "../src/backend-helper.js"
          if (not os.fileExists(sourceJs) or ((system.hostOS == "windows") and defined(debug))):
            debug "writing to " & targetJs
            if nimview.backendHelperJs != "":
              system.writeFile(targetJs, nimview.backendHelperJs)
          elif (os.fileExists(sourceJs)):
              debug "symlinking to " & targetJs
              os.createSymlink(sourceJs, targetJs)
    except:
      logging.error "backend-helper.js not copied"

  proc getAbsPath(indexHtmlFile: string): (string, string) =
    let separatorFound = indexHtmlFile.rfind({'#', '?'})
    if separatorFound == -1:
      result[0] = indexHtmlFile
    else:
      result[0] = indexHtmlFile[0 ..< separatorFound]
      result[1] = indexHtmlFile[separatorFound .. ^1]
    if (not os.isAbsolute(result[0])):
      result[0] = nimview.getCurrentAppDir() / indexHtmlFile

  proc checkFileExists(filePath: string, message: string) =
    if not os.fileExists(filePath):
      raise newException(IOError, message)

  proc startHttpServer*(indexHtmlFile: string, port: int = 8000,
      bindAddr: string = "localhost") {.exportpy.} =
    ## Start Http server (Jester) in blocking mode. indexHtmlFile will displayed for "/".
    ## Files in parent folder or sub folders may be accessed without further check. Will run forever.
    var (indexHtmlPath, parameter) = nimview.getAbsPath(indexHtmlFile)
    discard parameter # needs to be inserted into url manually
    nimview.checkFileExists(indexHtmlPath, "Required file index.html not found at " & indexHtmlPath & 
      "; cannot start UI; the UI folder needs to be relative to the binary")
    when not defined release:
      nimview.backendHelperJs = nimview.backendHelperJsStatic
      try:
        nimview.backendHelperJs = system.readFile(nimview.getCurrentAppDir() / "../src/backend-helper.js")
      except: 
        discard
    nimview.copyBackendHelper(indexHtmlPath)
    var origin = "http://" & bindAddr
    if (bindAddr == "0.0.0.0"):
      origin = "*"
    nimview.responseHttpHeader = @{"Access-Control-Allow-Origin": origin}
    let settings = jester.newSettings(
        port = Port(port),
        bindAddr = bindAddr,
        staticDir = indexHtmlPath.parentDir())
    var myJester = jester.initJester(nimview.handleRequest, settings = settings)
    # debug "open default browser"
    # browsers.openDefaultBrowser("http://" & bindAddr & ":" & $port / parameter)
    myJester.serve()

  proc stopDesktop*() {.exportpy.} =
    ## Will stop the Http server - may trigger application exit.
    when compileWithWebview:
      debug "stopping ..."
      if not myWebView.isNil():
        myWebView.terminate()

  proc startDesktop*(indexHtmlFile: string, title: string = "nimview",
      width: int = 640, height: int = 480, resizable: bool = true,
          debug: bool = defined release) {.exportpy.} =
    ## Will start Webview Desktop UI to display the index.hmtl file in blocking mode.
    when compileWithWebview:
      var (indexHtmlPath, parameter) = nimview.getAbsPath(indexHtmlFile)
      nimview.checkFileExists(indexHtmlPath, "Required file index.html not found at " & indexHtmlPath & 
        "; cannot start UI; the UI folder needs to be relative to the binary")
      nimview.copyBackendHelper(indexHtmlPath)
      # var fullScreen = true
      myWebView = webview.newWebView(title, "file://" / indexHtmlPath & parameter, width,
          height, resizable = resizable, debug = debug)
      myWebView.bindProc("backend", "alert", proc (message: string) =
        {.gcsafe.}:
          myWebView.info("alert", message))
      myWebView.bindProc("backend", "call", proc (message: string) =
        info message
        let jsonMessage = json.parseJson(message)
        let resonseId = jsonMessage["responseId"].getInt()
        let response = dispatchJsonRequest(jsonMessage)
        let evalJsCode = "window.ui.applyResponse('" & 
            response.replace("\\", "\\\\").replace("\'", "\\'") &
            "'," & $resonseId & ");"
        {.gcsafe.}:
          let responseCode = myWebView.eval(evalJsCode)
          discard responseCode
      )
#[    proc changeColor() = myWebView.setColor(210,210,210,100)
      proc toggleFullScreen() = fullScreen = not myWebView.setFullscreen(fullScreen) ]#
      myWebView.run()
      myWebView.exit()
      dealloc(myWebView)

  proc start*(indexHtmlFile: string, port: int = 8000, bindAddr: string = "localhost", title: string = "nimview",
        width: int = 640, height: int = 480, resizable: bool = true) {.exportpy.} =
    ## Tries to automatically select the Http server in debug mode or when no UI available
    ## and the Webview Desktop App in Release mode, if UI available.
    ## The debug mode information will not be available for python or dll.
    let displayAvailable = 
      when (system.hostOS == "windows"): true 
      else: ( os.getEnv("DISPLAY") != "")
    if useServer or not displayAvailable:
      startHttpServer(indexHtmlFile, port, bindAddr)
    else:
      startDesktop(indexHtmlFile, title, width, height, resizable)

proc main() =
  when not defined(noMain):
    debug "starting nim main"
    when system.appType != "lib" and not defined(just_core):
      nimview.addRequest("appendSomething4", proc(): string =
        debug "called func"
        result = "'' modified by Nim Backend")

      nimview.addRequest("appendSomething", proc(val: int): string =
        result = ":)'" & $(val) & "' modified by Nim Backend")

      let argv = os.commandLineParams()
      for arg in argv:
        nimview.readAndParseJsonCmdFile(arg)
      # let indexHtmlFile = "../examples/vue/dist/index.html"
      let indexHtmlFile = "../examples/svelte/public/index.html"
      nimview.enableRequestLogger()
      # nimview.startDesktop(indexHtmlFile)
      # nimview.startHttpServer(indexHtmlFile)
      nimview.start(indexHtmlFile)

when isMainModule:
  main()
