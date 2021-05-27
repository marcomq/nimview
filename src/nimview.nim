# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os, system, tables
import json, logging, macros
# run "nake release" or "nake debug" to compile

when not defined(just_core):
  const compileWithWebview = defined(useWebview) or not defined(useServer)
  import strutils, uri
  import nimpy
  from nimpy/py_types import PPyObject
  import asynchttpserver, asyncdispatch
  import globalToken
  # import browsers
  when compileWithWebview:
    import webview except debug
    var myWebView: Webview
  var responseHttpHeader {.threadVar.}: seq[tuple[key, val: string]] # will be set when starting httpserver
else:
  const compileWithWebview = false
  var myWebView = nil
  # Just core features. Disable httpserver, webview nimpy and exportpy
  macro exportpy(def: untyped): untyped =
    result = def

type ReqDeniedException* = object of CatchableError
type ServerException* = object of CatchableError
type ReqUnknownException* = object of CatchableError
    
import requestMap
export requestMap

var requestLogger* {.threadVar.}: FileLogger
var staticDir: string

const indexContent = 
  if fileExists(getProjectPath() / "../dist/index.html"):
    staticRead(getProjectPath() / "../dist/index.html")
  else:
    ""
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
      "[values]")

proc enableRequestLogger*() {.exportpy.} =
  ## Start to log all requests with content, even passwords, into file "requests.log".
  ## The file can be used for automated tests, to archive and replay all actions.
  if requestLogger.isNil:
    debug "creating request logger, further requests will be logged to file and flushed at application end"
    if not os.fileExists("requests.log"):
      var createFile = system.open("requests.log", system.fmWrite)
      createFile.close()
    var requestLoggerTmp = newFileLogger("requests.log", fmtStr = "")

    requestLogger.swap(requestLoggerTmp)
  requestLogger.levelThreshold = logging.lvlAll

proc disableRequestLogger*() {.exportpy.} =
  ## Will stop to log to "requests.log" (default)
  if not requestLogger.isNil:
    requestLogger.levelThreshold = logging.lvlNone

var useServer* = not compileWithWebview or 
  (defined(useServer) or not defined(release) or (os.fileExists("/.dockerenv")))
var useGlobalToken* = defined(release)

proc setUseServer*(val: bool) {.exportpy.} =
  useServer = val

proc setUseGlobalToken*(val: bool) {.exportpy.} =
  useGlobalToken = val

logging.addHandler(newConsoleLogger())

proc dispatchRequest*(request: string, value: string): string =
  ## Global string dispatcher that will trigger a previously registered functions
  getCallbackFunc(request)(%value) # % converts to json
  
proc dispatchJsonRequest*(jsonMessage: JsonNode): string =
  ## Global json dispatcher that will be called from webview AND httpserver
  ## This will extract specific values that were prepared by backend-helper.js
  ## and forward those values to the string dispatcher.
  let request = jsonMessage["request"].getStr()
  if request == "getGlobalToken":
    return $ %* {"useGlobalToken": useGlobalToken}
  if not requestLogger.isNil:
    requestLogger.log(logging.lvlInfo, $jsonMessage)
  let callbackFunc = getCallbackFunc(request)
  result = callbackFunc(jsonMessage["data"])

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
      let retVal = dispatchCommandLineArg(line.string)
      debug retVal
    close(file)
  else:
    logging.error "File does not exist: " & filename

when not defined(just_core):

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

  proc handleRequest(request: Request): Future[void] {.gcsafe, async.} =
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
        if not indexContent.isEmptyOrWhitespace():
          header = @[("Content-Type", "text/html;charset=utf-8")]
          header.add(responseHttpHeader)
          await request.respond(Http200, indexContent, newHttpHeaders(header))
          return
          
    try:
      var potentialFilename = staticDir & "/" &
          requestPath.replace("..", "")
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

  proc copyBackendHelper (indexHtml: string) =
    let folder = indexHtml.parentDir()
    let targetJs = folder / "backend-helper.js"
    try:
      if not os.fileExists(targetJs) and indexHtml.endsWith(".html"):
        # read index html file and check if it actually requires backend helper
        let indexHtmlContent = system.readFile(indexHtml)
        if indexHtmlContent.contains("backend-helper.js"):
          let sourceJs = getCurrentAppDir() / "../src/js/backend-helper.js"
          if (not os.fileExists(sourceJs) or ((system.hostOS == "windows") and not defined(release))):
            debug "writing to " & targetJs
            os.copyFile(sourceJs, targetJs)
          elif (os.fileExists(sourceJs)):
              debug "symlinking to " & targetJs
              os.createSymlink(sourceJs, targetJs)
    except:
      logging.error "backend-helper.js not copied"

  proc checkFileExists(filePath: string, message: string) =
    if not os.fileExists(filePath):
      raise newException(IOError, message)

  proc toDataUrl(stream: string): string {.compileTime.} =
    ## creates a dada url and escapes %
    ## encoding all would be correct, but IE is slow when doing so
    result = "data:text/html, " & stream.replace("%", uri.encodeUrl("%")) 

  proc getAbsPath(indexHtmlFile: string): (string, string) =
    let separatorFound = indexHtmlFile.rfind({'#', '?'})
    if separatorFound == -1:
      result[0] = indexHtmlFile
    else:
      result[0] = indexHtmlFile[0 ..< separatorFound]
      result[1] = indexHtmlFile[separatorFound .. ^1]
    if (not os.isAbsolute(result[0])):
      result[0] = getCurrentAppDir() / indexHtmlFile

  proc startHttpServer*(indexHtmlFile: string = "../dist/index.html", port: int = 8000,
      bindAddr: string = "localhost") {.exportpy.} =
    ## Start Http server in blocking mode. indexHtmlFile will displayed for "/".
    ## Files in parent folder or sub folders may be accessed without further check. Will run forever.
    let (indexHtmlPath, parameter) = getAbsPath(indexHtmlFile)
    discard parameter # needs to be inserted into url manually
    when not defined(release):
      if indexContent.isEmptyOrWhitespace() or indexHtmlFile != "../dist/index.html":
        checkFileExists(indexHtmlPath, "Required file index.html not found at " & indexHtmlPath & 
          "; cannot start UI; the UI folder needs to be relative to the binary")
        copyBackendHelper(indexHtmlPath)
      debug "Starting internal webserver on http://" & bindAddr & ":" & $port
      echo "To develop javascript, run 'npm run serve' and open a browser on http://localhost:5000"
    var origin = "http://" & bindAddr
    if (bindAddr == "0.0.0.0"):
      origin = "*"
    responseHttpHeader = @[("Access-Control-Allow-Origin", origin)]
    staticDir = indexHtmlPath.parentDir()
    var server = newAsyncHttpServer()
    {.gcsafe.}:
      waitFor server.serve(Port(port), handleRequest, address=bindAddr)
    # debug "open default browser"
    # browsers.openDefaultBrowser("http://" & bindAddr & ":" & $port / parameter)

  proc stopDesktop*() {.exportpy.} =
    ## Will stop the Http server - may trigger application exit.
    when compileWithWebview:
      debug "stopping ..."
      if not myWebView.isNil():
        myWebView.terminate()

  proc startDesktopWithUrl(url: string, title: string, width: int, height: int, 
      resizable: bool, debug: bool)  =
    ## Will start Webview Desktop UI to display the index.hmtl file in blocking mode.
    when compileWithWebview:
      # var fullScreen = true
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
          evalJsCode = "window.ui.discardResponse(" & $requestId & ");" 
        debug evalJsCode
        {.gcsafe.}:
          let responseCode = myWebView.eval(evalJsCode)
          discard responseCode

      )
#[    proc changeColor() = myWebView.setColor(210,210,210,100)
      proc toggleFullScreen() = fullScreen = not myWebView.setFullscreen(fullScreen) ]#
      myWebView.run()
      myWebView.exit()
      dealloc(myWebView)

  proc startDesktop*(indexHtmlFile: string = "../dist/index.html", 
        title: string = "nimview",
        width: int = 640, height: int = 480, resizable: bool = true,
        debug: bool = defined(release)) {.exportpy.} = 
    if (indexHtmlFile.contains("dist/index.html") and not indexContent.isEmptyOrWhitespace()):
      startDesktopWithUrl(toDataUrl(indexContent), title, width, height, resizable, debug)
    else:
      let (indexHtmlPath, parameter) = getAbsPath(indexHtmlFile)
      checkFileExists(indexHtmlPath, "Required file index.html not found at " & indexHtmlPath & 
        "; cannot start UI; the UI folder needs to be relative to the binary")
      copyBackendHelper(indexHtmlPath)
      startDesktopWithUrl("file://" / indexHtmlPath & parameter, title, width, height, resizable, debug)

  proc start*(indexHtmlFile: string = "../dist/index.html", port: int = 8000, 
        bindAddr: string = "localhost", title: string = "nimview",
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
      let indexHtmlFile = "../examples/vue/dist/index.html"
      enableRequestLogger()
      startDesktop(indexHtmlFile)
      # startHttpServer(indexHtmlFile)

when isMainModule:
  main()
