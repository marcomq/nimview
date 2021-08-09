# Nimview UI Library 
# © Copyright 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os, system, tables
import json, macros
import logging as log
import asynchttpserver, asyncdispatch
# run "nimble demo" to to compile and nur demo application

const copyright_nimview* = "© Copyright 2021, by Marco Mengelkoch"

when not defined(just_core):
  const compileWithWebview = defined(useWebview) or not defined(useServer)
  import uri, strutils
  import nimpy
  from nimpy/py_types import PPyObject
  # import browsers
  when compileWithWebview:
    import webview except debug
    var myWebView*: Webview
else:
  const compileWithWebview = false
  var myWebView*: pointer = nil
  # Just core features. Disable httpserver, webview nimpy and exportpy
  macro exportpy(def: untyped): untyped =
    result = def
  type PPyObject = string

type ReqDeniedException* = object of CatchableError
type ServerException* = object of CatchableError
type ReqUnknownException* = object of CatchableError
import nimview/globalToken
import nimview/storage
export storage
include nimview/requestMap

var responseHttpHeader {.threadVar.}: seq[tuple[key, val: string]] # will be set when starting httpserver
var requestLogger* {.threadVar.}: FileLogger
var staticDir {.threadVar.}: string

type NimviewSettings = object
  indexHtmlFile*: string
  port*: int
  bindAddr*: string
  title*: string
  width*: int
  height*: int
  resizable*: bool
  debug*: bool
  useStaticIndexContent*: bool
  run*: bool

const defaultIndex = 
  when not defined(release):
    "../dist/index.html"
  else:
    "../dist/inlined.html"

proc initSettings*(indexHtmlFile: string = defaultIndex, port: int = 8000, 
        bindAddr: string = "localhost", title: string = "nimview",
        width: int = 640, height: int = 480, resizable: bool = true): NimviewSettings =
  result.indexHtmlFile = indexHtmlFile
  result.port = port
  result.bindAddr = bindAddr
  result.title = title
  result.width = width
  result.height = height
  result.resizable = resizable
  result.debug = not defined release
  result.run = true
  result.useStaticIndexContent =
    when declared(doNotLoadIndexContent):
      true
    else:
      false

const defaultSettings = initSettings()
var nimviewSettings* = defaultSettings.deepCopy()

log.addHandler(newConsoleLogger())

var indexContent {.threadVar.}: string
const indexContentStatic = 
  if fileExists(getProjectPath() & "/" & defaultSettings.indexHtmlFile):
    staticRead(getProjectPath() & "/" & defaultSettings.indexHtmlFile)
  else:
    ""


proc enableStorage*(fileName: cstring) {.exportc: "nimview_$1".} =
  ## Registers "getStoredVal" and "setStoredVal" as requests
  ## Use "backend.setStoredVal(key, x)" to store a value persistent in "storage.json"
  ## Use "backend.getStoredVal(key)" in js to read a stored value
  initStorage($fileName)
  addRequest("getStoredVal", getStoredVal)
  addRequest("setStoredVal", setStoredVal)

proc enableStorage*()  =
  ## Registers "getStoredVal" and "setStoredVal" as requests
  ## Use "backend.setStoredVal(key, x)" to store a value persistent in "storage.json"
  ## Use "backend.getStoredVal(key)" in js to read a stored value
  enableStorage("storage.json")

when not defined(just_core):
  proc addRequest*(request: string, callback: proc(valuesdef: varargs[PPyObject]): string) {.exportpy.} =
    addRequest(request, proc (values: JsonNode): string =
        var argSeq = newSeq[PPyObject]()
        if (values.kind == JArray):
          newSeq(argSeq, values.len)
          for i in 0 ..< values.len:
            argSeq[i] = parseAny[string](values[i]).toPyObjectArgument()
        elif (values.kind != JNull):
          argSeq.add(parseAny[string](values).toPyObjectArgument())
        result = callback(argSeq),
      "array")

proc enableRequestLogger*() {.exportpy.} =
  ## Start to log all requests with content, even passwords, into file "requests.log".
  ## The file can be used for automated tests, to archive and replay all actions.
  if requestLogger.isNil:
    debug "creating request logger, further requests will be logged to file and flushed at application end"
    if not os.fileExists("requests.log"):
      var createFile = system.open("requests.log", system.fmWrite)
      createFile.close()
    var requestLoggerTmp = newFileLogger("requests.log", fmtStr="",bufSize=0)

    requestLogger.swap(requestLoggerTmp)
  requestLogger.levelThreshold = log.lvlAll

proc disableRequestLogger*() {.exportpy.} =
  ## Will stop to log to "requests.log" (default)
  if not requestLogger.isNil:
    requestLogger.levelThreshold = log.lvlNone

const displayAvailable = 
  when (system.hostOS == "windows"): 
    true 
  else: os.getEnv("DISPLAY") != ""
var useServer* = 
  not compileWithWebview or 
  defined(useServer) or 
  not defined(release) or 
  not displayAvailable or 
  (os.fileExists("/.dockerenv"))
var useGlobalToken* = defined(release)

proc setUseServer*(val: bool) {.exportpy.} =
  ## If true, use Http Server instead of Webview.
  useServer = val

proc setUseGlobalToken*(val: bool) {.exportpy.} =
  ## The global token is a weak session-free CSRF check. Still much better than no CSRF protection.
  ## Per default enabled in release mode.
  ## If false, deactivate global token in release mode.
  useGlobalToken = val
  
proc dispatchJsonRequest*(jsonMessage: JsonNode): string =
  ## Global json dispatcher that will be called from webview AND httpserver
  ## This will extract specific values that were prepared by nimview.js
  ## and forward those values to the string dispatcher.
  let request = jsonMessage["request"].getStr()
  if request == "getGlobalToken":
    return $ %* {"useGlobalToken": useGlobalToken}
  if not requestLogger.isNil:
    requestLogger.log(log.lvlInfo, $jsonMessage)
  let callbackFunc = getCallbackFunc(request)
  result = callbackFunc(jsonMessage["data"])

proc dispatchRequest*(request: string, value: string): string =
  ## Global string dispatcher that will trigger a previously registered functions
  ## Used for testing or Android
  let jsonRequest = parseJson("{\"request\":\"" & request & "\", \"data\": " & value & "}")
  result = dispatchJsonRequest(jsonRequest);

proc dispatchRequest*(request, value: cstring): cstring {.exportc: "nimview_$1".} =
  result = $dispatchRequest($request, $value)

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
  except JsonParsingError:
     warn "Error in json parsing, args: " & escapedArgv
  except:
    warn "Error calling line arg: " & escapedArgv & ", " & getCurrentExceptionMsg()

proc dispatchCommandLineArg*(escapedArgv: cstring): cstring {.exportc: "nimview_$1".} =
  result = $dispatchCommandLineArg($escapedArgv)

proc readAndParseJsonCmdFile*(filename: string) {.exportpy.} =
  ## Will open, parse a file of previously logged requests and re-runs those requests.
  if (os.fileExists(filename)):
    debug "opening file for parsing: " & filename
    let file = system.open(filename, system.FileMode.fmRead)
    var line: TaintedString
    while (file.readLine(line)):
      # TODO: escape line if source file cannot be trusted
      let retVal = dispatchCommandLineArg(line.string)
      debug retVal
    close(file)
  else:
    log.error "File does not exist: " & filename

proc readAndParseJsonCmdFile*(filename: cstring) {.exportc: "nimview_$1".} =
  readAndParseJsonCmdFile($filename)

proc dispatchHttpRequest*(jsonMessage: JsonNode, headers: HttpHeaders): string =
  ## Modify this, if you want to add some authentication, input format validation
  ## or if you want to process HttpHeaders.
  if not useGlobalToken or globalToken.checkToken(headers):
      return dispatchJsonRequest(jsonMessage)
  else:
      let request = jsonMessage["request"].getStr()
      if request == "getGlobalToken":
        return $ %* {"useGlobalToken": useGlobalToken}
      else:
        raise newException(ReqDeniedException, "403 - Token expired")

proc handleRequest(request: Request): Future[void] {.async.} =
  ## used by HttpServer
  var response: string
  var requestPath: string = request.url.path
  var header = @[("Content-Type", "application/javascript")]
  let separatorFound = requestPath.rfind({'#', '?'})
  if separatorFound != -1:
    requestPath = requestPath[0 ..< separatorFound]
  if requestPath == "/":
    requestPath = "/index.html"
  if requestPath == "/index.html":
    when defined(release):
      if not indexContent.isEmptyOrWhitespace() and indexContent == indexContentStatic:
        header = @[("Content-Type", "text/html;charset=utf-8")]
        header.add(responseHttpHeader)
        await request.respond(Http200, indexContent, newHttpHeaders(header))
        return
        
  try:
    var potentialFilename = staticDir &
        requestPath.replace("../", "").replace("..", "")
    if os.fileExists(potentialFilename):
      debug "Sending " & potentialFilename
      let fileData = splitFile(potentialFilename)
      let contentType = case fileData.ext:
        of ".json": "application/json;charset=utf-8"
        of ".js": "text/javascript;charset=utf-8"
        of ".css": "text/css;charset=utf-8"
        of ".jpg": "image/jpeg"
        of ".txt": "text/plain;charset=utf-8"
        of ".map": "application/octet-stream"
        else: "text/html;charset=utf-8"
      header = @[("Content-Type", contentType)]
      header.add(responseHttpHeader)
      await request.respond(Http200, system.readFile(potentialFilename), newHttpHeaders(header))
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
      {.gcsafe.}:
        var currentToken = globalToken.byteToString(globalToken.getFreshToken())
        response = dispatchHttpRequest(jsonMessage, request.headers)
        var header = @{"global-token": currentToken}
        await request.respond(Http200, response, newHttpHeaders(header))

  except ReqUnknownException: 
    await request.respond(Http404, 
      $ %* {"error": "404", "value": getCurrentExceptionMsg()}, 
      newHttpHeaders(responseHttpHeader))
  except ReqDeniedException:
    await request.respond(Http403, 
      $ %* {"error": "403", "value": getCurrentExceptionMsg()}, 
      newHttpHeaders(responseHttpHeader))
  except ServerException:        
    await request.respond(Http500, 
      $ %* {"error": "500", "value": getCurrentExceptionMsg()}, 
      newHttpHeaders(responseHttpHeader))
  except JsonParsingError, KeyError:
    await request.respond(Http500, 
      $ %* {"error": "500", "value": "request doesn't contain valid json"}, 
      newHttpHeaders(responseHttpHeader))
  except:
    await request.respond(Http500, 
      $ %* {"error": "500", "value": "server error: " & getCurrentExceptionMsg()}, 
      newHttpHeaders(responseHttpHeader))
      
proc getCurrentAppDir(): string =
    let applicationName = os.getAppFilename().extractFilename()
    # debug applicationName
    if (applicationName.startsWith("python") or applicationName.startsWith("platform-python")):
      result = os.getCurrentDir()
    else:
      result = os.getAppDir()
      
when not defined(release):
  proc checkFileExists(filePath: string, message: string) =
    if not os.fileExists(filePath):
      raise newException(IOError, message)

proc getAbsPath(indexHtmlFile: string): (string, string) =
  let separatorFound = indexHtmlFile.rfind({'#', '?'})
  if separatorFound == -1:
    result[0] = indexHtmlFile
  else:
    result[0] = indexHtmlFile[0 ..< separatorFound]
    result[1] = indexHtmlFile[separatorFound .. ^1]
  if (not os.isAbsolute(result[0])):
    result[0] = getCurrentAppDir() & "/" & indexHtmlFile

proc updateIndexContent(indexHtmlFile: string) =
  if not nimviewSettings.useStaticIndexContent:
    if os.fileExists(indexHtmlFile):
      if (not indexHtmlFile.contains(defaultSettings.indexHtmlFile.replace("../", "")) or
        (os.getFileSize(indexHtmlFile) != indexContentStatic.len)):
        indexContent = system.readFile(indexHtmlFile)
  if indexContent.isEmptyOrWhitespace:
    debug "Using default " & defaultSettings.indexHtmlFile
    indexContent = indexContentStatic
    
proc serve() {.async.} = 
  var server = newAsyncHttpServer()
  listen(server, Port(nimviewSettings.port), nimviewSettings.bindAddr)
  while nimviewSettings.run:
    if server.shouldAcceptRequest():
      await server.acceptRequest(handleRequest)
    else:
      poll()

proc run*() {.exportpy, exportc: "nimview_$1".} =
  nimviewSettings.run = true
  if useServer:
    waitFor serve()
  else:
    when compileWithWebview:
      if not myWebView.isNil():
        myWebView.run()
        myWebView.exit()
      else:
        log.error "Webview not initialzied yet. Use 'startWebview' first" 

proc startHttpServer*(indexHtmlFile: string = nimviewSettings.indexHtmlFile, 
    port: int = nimviewSettings.port,
    bindAddr: string = nimviewSettings.bindAddr,
    run: bool = nimviewSettings.run) {.exportpy.} =
  ## Start Http server in blocking mode. indexHtmlFile will displayed for "/".
  ## Files in parent folder or sub folders may be accessed without further check. Will run forever.
  nimviewSettings.port = port
  nimviewSettings.bindAddr = bindAddr
  nimviewSettings.run = run
  useServer = true
  let (indexHtmlPath, parameter) = getAbsPath(indexHtmlFile)
  updateIndexContent(indexHtmlPath)
  discard parameter # needs to be inserted into url manually
  when not defined(release):
    if indexContent.isEmptyOrWhitespace():
      checkFileExists(indexHtmlPath, "Required file index not found at " & indexHtmlPath & 
        "; cannot start UI; the UI folder needs to be relative to the binary")
  debug "Starting internal webserver on http://" & bindAddr & ":" & $port
  when not defined(release):
    echo "To develop javascript, run 'npm run serve' and open a browser on http://localhost:5000"
  var origin = "http://" & bindAddr
  if (bindAddr == "0.0.0.0"):
    origin = "*"
  responseHttpHeader = @[("Access-Control-Allow-Origin", origin)]
  staticDir = indexHtmlPath.parentDir()
  if run:
    nimview.run()

proc startHttpServer*(indexHtmlFile: cstring, 
    port: cint = nimviewSettings.port.cint,
    bindAddr: cstring = nimviewSettings.bindAddr,
    run: cint = nimviewSettings.run.cint) {.exportc: "nimview_$1".} = 
  startHttpServer($indexHtmlFile, port, $bindAddr, run)

proc stopHttpServer*() {.exportpy, exportc: "nimview_$1".} =
  ## Will stop the Http server async - will not wait for stop
  nimviewSettings.run = false

when not defined(just_core):
  proc toDataUrl(stream: string): string =
    ## creates a dada url and escapes %
    ## encoding all would be correct, but IE is super slow when doing so
    # result = "data:text/html, " & stream.encodeUrl() 
    result = "data:text/html, " & stream.replace("%", uri.encodeUrl("%")) 

  proc stopDesktop*() {.exportpy, exportc: "nimview_$1".} =
    ## Will stop the Desktop app - may trigger application exit.
    when compileWithWebview:
      debug "stopping ..."
      if not myWebView.isNil():
        myWebView.terminate()
        dealloc(myWebView)

  proc stop*() {.exportpy, exportc: "nimview_$1".} =
    ## Will stop the Http server - will not wait for stop
    stopHttpServer()
    stopDesktop()

  proc startDesktopWithUrl(url: string, title: string, width: int, height: int, 
      resizable: bool, debug: bool, run: bool)  =
    when compileWithWebview:
      # var fullScreen = true
      if myWebView.isNil:
        myWebView = webview.newWebView(title, url, width,
           height, resizable = resizable, debug = debug)
      myWebView.bindProc("nimview", "alert", proc (message: string) =
        {.gcsafe.}:
          myWebView.info("alert", message))
      myWebView.bindProc("nimview", "call", proc (message: string) =
        info message
        let jsonMessage = json.parseJson(message)
        let requestId = jsonMessage["requestId"].getInt()
        var evalJsCode: string 
        try:
          let response = dispatchJsonRequest(jsonMessage)
          evalJsCode = "window.ui.applyResponse(" & $requestId & ",'" & 
              response.replace("\\", "\\\\").replace("\'", "\\'") & "');"
        except: 
          evalJsCode = "window.ui.rejectResponse(" & $requestId & ");" 
        let responseCode = myWebView.eval(evalJsCode)
        discard responseCode
      )
#[    proc changeColor() = myWebView.setColor(210,210,210,100)
      proc toggleFullScreen() = fullScreen = not myWebView.setFullscreen(fullScreen) ]#
      if run:
        nimview.run()

  proc startDesktop*(indexHtmlFile: string = nimviewSettings.indexHtmlFile, 
        title: string = nimviewSettings.title,
        width: int = nimviewSettings.width, height: int = nimviewSettings.height, 
        resizable: bool = nimviewSettings.resizable,
        debug: bool = nimviewSettings.debug,
        run: bool = nimviewSettings.run) {.exportpy.} = 
    ## Will start Webview Desktop UI to display the index.hmtl file in blocking mode.
    useServer = false
    let (indexHtmlPath, parameter) = getAbsPath(indexHtmlFile)
    discard parameter
    updateIndexContent(indexHtmlPath)
    when not defined(release):
      checkFileExists(indexHtmlPath, "Required file index.html not found at " & indexHtmlPath & 
        "; cannot start UI; the UI folder needs to be relative to the binary")
    if parameter.isEmptyOrWhitespace() and indexHtmlFile.contains("inlined.html"):
      debug "Starting desktop with data url"
      startDesktopWithUrl(toDataUrl(indexContent), title, width, height, resizable, debug, run)
    else:
      debug "Starting desktop with file url"
      startDesktopWithUrl("file://" & indexHtmlPath & parameter, title, width, height, resizable, debug, run)

  proc startDesktop*(indexHtmlFile: cstring, 
        title: cstring = nimviewSettings.title,
        width: cint = nimviewSettings.width.cint, height: cint = nimviewSettings.height.cint, 
        resizable: cint = nimviewSettings.resizable.cint,
        debug: cint = nimviewSettings.debug.cint,
        run: cint = nimviewSettings.run.cint) {.exportc: "nimview_$1".} = 
      startDesktop($indexHtmlFile, $title, width, height, 
        cast[bool](resizable), cast[bool](debug), cast[bool](run))

  proc start*(indexHtmlFile: string = nimviewSettings.indexHtmlFile, port: int = nimviewSettings.port, 
        bindAddr: string = nimviewSettings.bindAddr, title: string = nimviewSettings.title,
        width: int = nimviewSettings.width, height: int = nimviewSettings.height, 
        resizable: bool = nimviewSettings.resizable,
        run: bool = nimviewSettings.run) {.exportpy.} =
    ## Tries to automatically select the Http server in debug mode or when no UI available
    ## and the Webview Desktop App in Release mode, if UI available.
    ## The debug mode information will not be available for python or dll.
    if useServer:
      startHttpServer(indexHtmlFile, port, bindAddr, run=run)
    else:
      startDesktop(indexHtmlFile, title, width, height, resizable=resizable, run=run)

  proc start*(indexHtmlFile: cstring, port: cint = nimviewSettings.port.cint, 
        bindAddr: cstring = nimviewSettings.bindAddr, title: cstring = nimviewSettings.title,
        width: cint = nimviewSettings.width.cint, height: cint = nimviewSettings.width.cint, 
        resizable: cint = nimviewSettings.resizable.cint,
        run: cint = nimviewSettings.run.cint) {.exportc: "nimview_$1".} =
      start($indexHtmlFile, port, $bindAddr, $title, width, height, 
        resizable=cast[bool](resizable), run=cast[bool](run))
  
  proc setBorderless*(decorated: bool = false) {.exportc, exportpy.} =
    ## Use gtk mode without borders, only works on linux and only in desktop mode
    when defined(linux) and compileWithWebview: 
      if not myWebView.isNil():
        {.emit: "gtk_window_set_decorated(GTK_WINDOW(`myWebView`->priv.window), `decorated`);".}

  proc setFullscreen*(fullScreen: bool = true) {.exportc, exportpy.} =
    when compileWithWebview:
      if not myWebView.isNil():
        discard myWebView.setFullscreen(fullScreen)

  proc setColor*(r, g, b, alpha: uint8) {.exportc, exportpy.} =
    when compileWithWebview:
      if not myWebView.isNil():
        myWebView.setColor(r, g, b, alpha)

when isMainModule:
  proc main() =
    when not defined(noMain):
      debug "starting nim main"
      when system.appType != "lib" and not defined(just_core):
        addRequest("appendSomething4", proc(): string =
          debug "called func"
          result = "'' modified by Nim Backend")

        addRequest("appendSomething", proc(val: string): string =
          result = ":)'" & $(val) & "' modified by Nim Backend")

        addRequest("appendSomething3", proc(val: int, val2: string): string =
          result = ":)'" & $(val) & " " & $(val2) & "' modified by Nim Backend")

        let argv = os.commandLineParams()
        for arg in argv:
          readAndParseJsonCmdFile(arg)
        let indexHtmlFile = "../examples/svelte/dist/index.html"
        enableRequestLogger()
        enableStorage()
        startDesktop(indexHtmlFile)
        # startHttpServer(indexHtmlFile)
  main()

when defined(nimHasUsed):
  # 'import nimview' is already doing stuff, so
  # that Nim shouldn't produce a warning for that import,
  # even if currently unused:
  {.used.}