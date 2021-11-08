# Nimview UI Library 
# © Copyright 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os, system, tables, strutils
import json, macros, httpcore, asyncdispatch
import logging as log
# run "nimble demo" to to compile and nur demo application

# available compileFlags: -d:useServer -d:useWebview -d:just_core -d:useWebviewSingleThreaded -d:noMain

const copyright_nimview* = "© Copyright 2021, by Marco Mengelkoch"
import nimview/storage
export storage
import nimview/sharedTypes
import nimview/requestMap
requestMap.init()
import nimview/globals
import nimview/dispatchJsonRequest
export dispatchJsonRequest.dispatchJsonRequest
export requestMap.add
export requestMap.add_argc_argv_rstr
export globals.nimviewSettings
log.addHandler(newConsoleLogger())

template addRequest*(x,y) {.used, deprecated:" use 'add' instead".} = add(x,y)
template addRequest_argc_argv_rstr*(x,y) {.used, deprecated:" use 'add' instead".} = add_argc_argv_rstr(x,y)

when not defined(just_core):
  import nimpy
  # nimpy needs to be called first in file nimview.nim to work properly
  proc setUseServer*(val: bool) {.exportpy.} =
    ## If true, use Http Server instead of Webview.
    nimviewSettings.useHttpServer = val

  import uri, base64
  from nimpy/py_types import PPyObject
  import nimview/httpRenderer
  when compileWithWebview:
    import nimview/webviewRenderer
    export selectFolderDialog, selectFileDialog, setMinSize, setMaxSize, focus
    export stopDesktop, setBorderless, setFullScreen, setColor, setIcon
else:
  # Just core features. Disable httpserver, webview nimpy and exportpy
  macro exportpy(def: untyped): untyped =
    result = def
  type PPyObject = string
  proc evalJs(evalJsCode: string) = discard

proc enableStorage*(fileName: cstring) {.exportc: "nimview_$1".} =
  ## Registers "getStoredVal" and "setStoredVal" as requests
  ## Use "backend.setStoredVal(key, x)" to store a value persistent in "storage.json"
  ## Use "backend.getStoredVal(key)" in js to read a stored value
  storage.initStorage($fileName)
  add("getStoredVal", getStoredVal)
  add("setStoredVal", setStoredVal)

proc enableStorage*()  =
  ## Registers "getStoredVal" and "setStoredVal" as requests
  ## Use "backend.setStoredVal(key, x)" to store a value persistent in "storage.json"
  ## Use "backend.getStoredVal(key)" in js to read a stored value
  enableStorage("storage.json")

proc callFrontendJsEscaped(functionName: string, params: string) =
  ## "params" should be JS escaped values, separated by commas with surrounding quotes for string values
  {.gcsafe.}:
    if not nimviewVars.customJsEval.isNil:
      let jsExec = "window.ui.callFunction(\"" & functionName & "\"," & params & ");"
      cast[CstringFunc](nimviewVars.customJsEval)(jsExec.cstring) 
    elif nimviewSettings.useHttpServer:
      when not defined(just_core):
        callFrontendJsEscapedHttp(functionName, params)
    else:
      when compileWithWebview:
        callFrontendJsEscapedWebview(functionName, params)

proc callJs*(functionName: string, argsString: string) {.exportpy.} =
  callFrontendJsEscaped(functionName, "\"" & argsString & "\"")

proc callJs*(functionName: cstring, argsString: cstring) {.exportc: "nimview_$1".} =
  callFrontendJsEscaped($functionName, "\"" & $argsString & "\"")

macro callJs*(functionName: string, params: varargs[untyped]) =
  ## Call a function on the JS frontend immediately.
  ## Avoid calling this function from another thread as there might be issues with
  ## the Nim garbage collector.
  ## "params" should be a JS compatible value
  quote do:
    callFrontendJsEscaped(`functionName`, $(%*`params`))

template callFrontendJs*(x,y) {.used, deprecated:" use 'callJs' instead".} = 
  callJs(x,y)

when not defined(just_core):
  proc add*(request: string, callback: proc(valuesdef: varargs[PPyObject]): string) {.exportpy.} =
    add(request, proc (values: JsonNode): string =
        var argSeq = newSeq[PPyObject]()
        if (values.kind == JArray):
          newSeq(argSeq, values.len)
          for i in 0 ..< values.len:
            argSeq[i] = parseAny[string](values[i]).toPyObjectArgument()
        elif (values.kind != JNull):
          argSeq.add(parseAny[string](values).toPyObjectArgument())
        result = callback(argSeq),
      "array")
  
  proc addRequest*(request: string, callback: proc(valuesdef: varargs[PPyObject]): string) {.exportpy.} = 
    ## deprecated: "use 'add' instead".
    add(request, callback)

proc enableRequestLogger*() {.exportpy.} =
  ## Start to log all requests with content, even passwords, into file "requests.log".
  ## The file can be used for automated tests, to archive and replay all actions.
  if nimviewVars.requestLogger.isNil:
    debug "creating request logger, further requests will be logged to file and flushed at application end"
    if not os.fileExists("requests.log"):
      var createFile = system.open("requests.log", system.fmWrite)
      createFile.close()
    var requestLoggerTmp = newFileLogger("requests.log", fmtStr="",bufSize=0)

    nimviewVars.requestLogger.swap(requestLoggerTmp)
  nimviewVars.requestLogger.levelThreshold = log.lvlAll

proc disableRequestLogger*() {.exportpy.} =
  ## Will stop to log to "requests.log" (default)
  if not nimviewVars.requestLogger.isNil:
    nimviewVars.requestLogger.levelThreshold = log.lvlNone

proc setCustomJsEval*(evalFunc: CstringFunc) {.exportc: "nimview_$1".} =
  {.gcsafe.}:
    nimviewVars.customJsEval = evalFunc

proc setUseGlobalToken*(val: bool) {.exportpy.} =
  ## The global token is a weak session-free CSRF check. Still much better than no CSRF protection.
  ## Per default enabled in release mode.
  ## If false, deactivate global token in release mode.
  nimviewSettings.useGlobalToken = val

proc dispatchRequest*(request: string, value: string): string =
  ## Global string dispatcher that will trigger a previously registered functions
  ## Used for testing or Android
  let jsonRequest = parseJson("{\"request\":\"" & request & "\", \"data\": " & value & "}")
  result = dispatchJsonRequest(jsonRequest);

proc dispatchRequest*(request, value: cstring): cstring {.exportc: "nimview_$1".} =
  let stringResult = $dispatchRequest($request, $value)
  result = stringResult.cstring

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
  let stringResult = $dispatchCommandLineArg($escapedArgv)
  result = stringResult.cstring

proc readAndParseJsonCmdFile*(filename: string) {.exportpy.} =
  ## Will open, parse a file of previously logged requests and re-runs those requests.
  if (os.fileExists(filename)):
    debug "opening file for parsing: " & filename
    let file = system.open(filename, system.FileMode.fmRead)
    var line: string
    while (file.readLine(line)):
      # TODO: escape line if source file cannot be trusted
      let retVal = dispatchCommandLineArg(line)
      debug retVal
    close(file)
  else:
    log.error "File does not exist: " & filename

proc readAndParseJsonCmdFile*(filename: cstring) {.exportc: "nimview_$1".} =
  readAndParseJsonCmdFile($filename)
      
when not defined(release):
  proc checkFileExists(filePath: string, message: string) =
    if not os.fileExists(filePath):
      raise newException(IOError, message)

proc updateIndexContent(indexHtmlFile: string) =
  if not nimviewSettings.useStaticIndexContent:
    if os.fileExists(indexHtmlFile):
      if (not indexHtmlFile.contains(defaultSettings.indexHtmlFile.replace("../", "")) or
        (os.getFileSize(indexHtmlFile) != indexContentStatic.len)):
        indexContent = system.readFile(indexHtmlFile)
  if indexContent.isEmptyOrWhitespace:
    debug "Using default " & defaultSettings.indexHtmlFile
    indexContent = indexContentStatic

when not defined(just_core):
  proc run*() {.exportpy, exportc: "nimview_$1".} =
    ## You need to use this function if you started nimview with start(run=false)
    nimviewSettings.run = true
    if nimviewSettings.useHttpServer:
      waitFor serve()
    else:
      when compileWithWebview:
        nimviewSettings.run = true
        runWebview()
        waitForThreads()
        
  proc startHttpServer*(indexHtmlFile: string = nimviewSettings.indexHtmlFile, 
      port: int = nimviewSettings.port,
      bindAddr: string = nimviewSettings.bindAddr,
      run: bool = nimviewSettings.run) {.exportpy.} =
    ## Start Http server in blocking mode. indexHtmlFile will displayed for "/".
    ## Files in parent folder or sub folders may be accessed without further check. Will run forever.
    nimviewSettings.port = port
    nimviewSettings.bindAddr = bindAddr
    nimviewSettings.run = run
    nimviewSettings.useHttpServer = true
    let (indexHtmlPath, parameter) = getAbsPath(indexHtmlFile)
    updateIndexContent(indexHtmlPath)
    discard parameter # needs to be inserted into url manually
    when not defined(release):
      if indexContent.isEmptyOrWhitespace():
        checkFileExists(indexHtmlPath, "Required file index not found at " & indexHtmlPath & 
          "; cannot start UI; the UI folder needs to be relative to the binary")
    debug "Starting internal webserver on http://" & bindAddr & ":" & $port
    when not defined(release):
      echo "To develop javascript, run 'npm run dev' or 'npm run dev-ie'"
      echo "Check the output, as some frontend dev environments prefer a proxy"
    var origin = "http://" & bindAddr
    if (bindAddr == "0.0.0.0"):
      origin = "*"
    nimviewVars.responseHttpHeader = @[("Access-Control-Allow-Origin", origin)]
    nimviewVars.staticDir = indexHtmlPath.parentDir()
    if run:
      nimview.run()

  proc startHttpServer*(indexHtmlFile: cstring, 
      port: cint = nimviewSettings.port.cint,
      bindAddr: cstring = nimviewSettings.bindAddr.cstring,
      run: cint = nimviewSettings.run.cint) {.exportc: "nimview_$1".} =
    let indexFileString: string = $indexHtmlFile
    let bindAddrString: string = $bindAddr
    startHttpServer(indexFileString, int(port), bindAddrString, bool(run))

  proc stopHttpServer*() {.exportpy, exportc: "nimview_$1".} =
    ## Will stop the Http server async - will not wait for stop
    nimviewSettings.run = false     

  proc stop*() {.exportpy, exportc: "nimview_$1".} =
    ## Will stop the Http server - will not wait for stop
    stopHttpServer()
    when compileWithWebview:
      stopDesktop()

  proc toDataUrl(stream: string): string {.used.} =
    ## creates a dada url and escapes %
    ## encoding all or using base64 would be correct, but IE is super slow when doing so
    if stream.startsWith("data:"):
      return stream
    if (system.hostOS == "windows"): 
      result = "data:text/html, " & stream.replace("%", uri.encodeUrl("%")) 
    else:
      result = "data:text/html;base64, " & base64.encode(stream)

  proc startDesktop*(indexHtmlFile: string = nimviewSettings.indexHtmlFile, 
        title: string = nimviewSettings.title,
        width: int = nimviewSettings.width, 
        height: int = nimviewSettings.height, 
        resizable: bool = nimviewSettings.resizable,
        debug: bool = nimviewSettings.debug,
        run: bool = nimviewSettings.run) {.exportpy.} = 
    ## Will start Webview Desktop UI to display the index.hmtl file in blocking mode.
    when compileWithWebview:
      nimviewSettings.useHttpServer = false
      let (indexHtmlPath, parameter) = getAbsPath(indexHtmlFile)
      discard parameter
      updateIndexContent(indexHtmlPath)
      when not defined(release):
        checkFileExists(indexHtmlPath, "Required file index.html not found at " & indexHtmlPath & 
          "; cannot start UI; the UI folder needs to be relative to the binary")
      var url: string
      if parameter.isEmptyOrWhitespace() and 
        (indexHtmlFile.contains("inlined.html") or indexHtmlPath.startsWith("data:")):
        debug "Starting desktop with data url"
        url = toDataUrl(indexContent)
      else:
        debug "Starting desktop with file url"
        url = "file://" & indexHtmlPath & parameter
      when useWebviewInThread:
        spawnDesktopThread(url, title, width, height, resizable, debug, run)
      else:
        runDesktop(url, title, width, height, resizable, debug, run)
      if run:
        nimview.run()

  proc startDesktop*(indexHtmlFile: cstring, 
        title: cstring = nimviewSettings.title.cstring,
        width: cint = nimviewSettings.width.cint, 
        height: cint = nimviewSettings.height.cint, 
        resizable: cint = nimviewSettings.resizable.cint,
        debug: cint = nimviewSettings.debug.cint,
        run: cint = nimviewSettings.run.cint) {.exportc: "nimview_$1".} = 
      startDesktop($indexHtmlFile, $title, width.int, height.int,
        cast[bool](resizable), cast[bool](debug), cast[bool](run))

  proc start*(indexHtmlFile: string = nimviewSettings.indexHtmlFile, port: int = nimviewSettings.port, 
        bindAddr: string = nimviewSettings.bindAddr, title: string = nimviewSettings.title,
        width: int = nimviewSettings.width, height: int = nimviewSettings.height, 
        resizable: bool = nimviewSettings.resizable,
        debug: bool = nimviewSettings.debug,
        run: bool = nimviewSettings.run) {.exportpy.} =
    ## Tries to automatically select the Http server in debug mode or when no UI available
    ## and the Webview Desktop App in Release mode, if UI available.
    ## The debug mode information will not be available for python or dll.
    if nimviewSettings.useHttpServer:
      startHttpServer(indexHtmlFile, port, bindAddr, run=run)
    else:
      startDesktop(indexHtmlFile, title, width, height, resizable=resizable, debug=debug, run=run)

  proc start*(indexHtmlFile: cstring, port: cint = nimviewSettings.port.cint, 
        bindAddr: cstring = nimviewSettings.bindAddr, title: cstring = nimviewSettings.title,
        width: cint = nimviewSettings.width.cint, height: cint = nimviewSettings.width.cint, 
        resizable: cint = nimviewSettings.resizable.cint,
        debug: cint = nimviewSettings.debug.cint,
        run: cint = nimviewSettings.run.cint) {.exportc: "nimview_$1".} =
      start($indexHtmlFile, port, $bindAddr, $title, width, height, 
        resizable=cast[bool](resizable), debug=cast[bool](debug), run=cast[bool](run))

  proc init*(indexHtmlFile: string = nimviewSettings.indexHtmlFile, port: int = nimviewSettings.port, 
        bindAddr: string = nimviewSettings.bindAddr, title: string = nimviewSettings.title,
        width: int = nimviewSettings.width, height: int = nimviewSettings.height, 
        resizable: bool = nimviewSettings.resizable,
        debug: bool = nimviewSettings.debug,
        run: bool = false) {.exportpy.} =
      start(indexHtmlFile, port, bindAddr, title, width, height, 
        resizable, run = false)

when isMainModule:
  proc main() =
    when not defined(noMain):
      echo "starting nim main"
      when system.appType != "lib" and not defined(just_core):
        echo "main app"
  main()

when defined(nimHasUsed):
  # 'import nimview' is already doing stuff, so
  # that Nim shouldn't produce a warning for that import,
  # even if currently unused:
  {.used.}