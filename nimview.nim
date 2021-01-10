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

# nim c -r --threads:on -d:debug --debuginfo  --debugger:native -d:useStdLib --verbosity:2 nimview.nim
# cp .\generated_c\nimview.h .
# nim c --verbosity:2 -d:release -d:useStdLib --header:nimview.h --app:lib --out:nimview.dll --nimcache=./tmp_c nimview.nim
# nim c --verbosity:2 -d:release -d:useStdLib --header:nimview.h --nimcache=./tmp_c nimview.nim
# nim c --verbosity:2 -d:release -d:useStdLib --noMain:on --noLinking:on  --compileOnly:on --header:nimview.h --gc:arc --nimcache=./tmp_c nimview.nim
# nim c --verbosity:2 -d:release -d:useStdLib --noMain:on -d:noMain --noLinking:on  --header:nimview.h --nimcache=./tmp_c --gc:arc nimview.nim    
# gcc -c -w -o tmp_c/c_sample.o -fmax-errors=3 -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -IC:\Users\Mmengelkoch\.nimble\pkgs\webview-0.1.0\webview -DWEBVIEW_WINAPI=1 -O3 -fno-strict-aliasing -fno-ident -IC:\Users\Mmengelkoch\.choosenim\toolchains\nim-1.4.2\lib -Itmp_c tests/c_sample.c
# gcc -w -o tests/c_sample.exe tmp_c/*.o -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32 -Itmp_c 
# python
# >>> import nimview
# >>> nimview.startWebview("E:/apps/nimview/ui/dist/index.html")
# >>> nimview.startJester("E:/apps/nimview/ui/dist/index.html")

#when (querySetting(backend) == "c"):
#  proc NimMain() {.importc.}
  
#elif (querySetting(backend) == "cpp"):
#  proc NimMain() {.importcpp.}

#else:
#  proc NimMain() =
 #   discard

type ReqUnknownException* = object of CatchableError
type RequestCallbacks* = ref object of RootObj
  map: Table[string, proc(value: string): string ]
  
var t_req* : RequestCallbacks

proc addRequest*(request: string, callback: proc(value: string): string ) {.exportpy.} = 
  if (isNil(t_req)):
    t_req = new RequestCallbacks
    echo "new map created"
  t_req.map[request] = callback

proc free_c(somePtr: pointer) {.cdecl,importc: "free".}

proc nimview_addRequest*(request: cstring, callback: proc(value: cstring): cstring {.cdecl.}, freeFunc: proc(value: pointer) {.cdecl.} = free_c) {.exportc.} = 
# proc nimview_addRequest*(request: cstring,  callback: proc(value: cstring): cstring {.cdecl.}) {.exportc.} = 
  
  nimview.addRequest($request, proc (nvalue: string): string =
    echo "b " & nvalue
    let resultPtr = callback(nvalue)
    result = $resultPtr
    free_c(resultPtr)
  )

# macro backendRequest*(nameOrProc: untyped): untyped =  
#  expectKind(nameOrProc, {nnkProcDef, nnkFuncDef, nnkIteratorDef})
  # echo nameOrProc.name
  #quote do:
  #  echo `nameOrProc`

proc initRequestFunctions*() = 
  nimview.addRequest("ping", proc (value: string): string {.noSideEffect, gcsafe.} = result = value)

proc dispatchRequest*(request, value: string): string {.gcsafe, exportpy.} = 
  {.cast(gcsafe).}:
    if t_req.map.hasKey(request):
      let callbackFunc = t_req.map[request]
      result = callbackFunc(value) 
    else :
      raise newException(ReqUnknownException, "404 - Request unknown")

proc nimview_dispatchRequest*(request, value: cstring): cstring {.gcsafe, exportc.} = 
  result = $dispatchRequest($request, $value)

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

proc nimview_dispatchCommandLineArg*(escapedArgv: cstring): cstring {.exportc.} = 
  result = $dispatchCommandLineArg($escapedArgv)

proc readAndParseJsonCmdFile*(filename: string) = 
  if (os.fileExists(filename)):
    echo "opening file for parsing: " & filename
    let file = system.open(filename, system.FileMode.fmRead)
    var line: TaintedString
    while (file.readLine(line)):
      # TODO: escape line if source file cannot be trusted
      echo nimview.dispatchCommandLineArg(line.string)
    close(file)
  else:
    echo "File does not exist: " & filename

proc nimview_readAndParseJsonCmdFile*(filename: cstring) {.exportc.} = 
  readAndParseJsonCmdFile($filename)

when not defined(just_core):
  const backendHelperJs = system.staticRead("backend-helper.js")
  proc dispatchHttpRequest*(jsonMessage: JsonNode, headers: HttpHeaders): string {.gcsafe.} = 
    # optional - check credentials from header
    result = dispatchJsonRequest(jsonMessage)

  template corsResp(code, message: untyped): untyped =
    mixin resp
    resp code, {"Access-Control-Allow-Origin": "*"}, message

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
          corsResp Http200, backendHelperJs
        var potentialFilename = request.getStaticDir() & "/" & requestContent.replace("..", "")
        if fileExists(potentialFilename):
          echo "Sending " & potentialFilename
          # jester.sendFile(potentialFilename)
          corsResp Http200, system.readFile(potentialFilename)
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
            corsResp Http404, $errorResponse
          except:
            var errorResponse =  %* { "error":"500", "value":"internal error", "resultId": $jsonMessage["responseId"] } 
            corsResp Http200, $errorResponse
          let jsonResponse = %* { ($jsonMessage["responseKey"]).unescape(): response }
          corsResp Http200, $jsonResponse
      except ReqUnknownException:
        corsResp Http404, "File not found"
      except:
        echo "Error " & getCurrentExceptionMsg()
        var errorResponse =  %* { "error":"500", "value":"request doesn't contain valid json", "resultId": 0 } 
        corsResp Http500, $errorResponse

    post re"^\/(.*)$":
      try:
        # post data is always asumed to be a request
        var jsonMessage = parseJson(request.body)
        let response = dispatchHttpRequest(jsonMessage, request.headers)
        let jsonResponse = %* { ($jsonMessage["responseKey"]).unescape(): response }
        corsResp Http200, $jsonResponse
      except ReqUnknownException:
        corsResp Http404, "Request not found"
      except:
        var errorResponse =  %* { "error":"500", "value":"request doesn't contain valid json", "resultId": 0 } 
        corsResp Http500, $errorResponse
    options re"^\/(.*)$":
      corsResp Http404, "404 not found!!"
    error Http404:
      corsResp Http404, "404 not found!"

  proc copyBackendHelper (folder: string) =
    let targetJs =  folder.parentDir() / "backend-helper.js"
    try:
      when (system.hostOS == "windows"):
        if (not os.fileExists(targetJs) or defined(debug)):
            echo "writing to " & targetJs
            system.writeFile(targetJs, backendHelperJs)
      else:
        if (not os.fileExists(targetJs)):
            echo "symlinking to " & targetJs
            os.createSymlink(system.currentSourcePath.parentDir() / "backend-helper.js", target)
    except:
      echo "backend-helper.js not copied" 
    echo "backend-helper.js finalized" 

  proc startJester*(folder: string, port: int = 8000, bindAddr: string = "localhost") {.exportpy.} =
    var absFolder = folder
    if (not os.isAbsolute(folder)): 
      if (os.getAppFilename().startsWith("python")):
        absFolder = os.getCurrentDir() / folder
      else:
        absFolder = os.getAppDir() / folder
    copyBackendHelper(absFolder)
    let settings = jester.newSettings(port=Port(port), bindAddr=bindAddr, staticDir = absFolder.parentDir())
    var jester = jester.initJester(myrouter, settings=settings)
    jester.serve()
    
  proc nimview_startJester*(folder: cstring, port: cint = 8000, bindAddr: cstring = "localhost") {.exportc.} =
    # NimMain()
    startJester($folder, int(port), $bindAddr)

  proc startWebview*(folder: string) {.exportpy.} =
    var absFolder = folder
    if (not os.isAbsolute(folder)):
      echo os.getAppFilename().extractFilename()
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

  proc nimview_startWebview*(folder: cstring) {.exportc.} = 
    # NimMain()
    echo "starting C webview"
    let cFolder = $folder
    startWebview(cFolder)
    echo "leaving C webview"

  when declared(Thread):
    proc startJesterThread(folder: string) {.thread.} =
      var thread: Thread[string]
      # TODO: initRequestFunctions()
      # createThread(thread, startJester, folder, 8000)

#proc startWebviewThread(folder: string) {.thread.} =
#  startWebview(folder)

proc main() =
  echo "starting nim main"
  let argv = os.commandLineParams()
  for arg in argv:
    readAndParseJsonCmdFile(arg)
  when system.appType != "lib" and not defined(just_core):
    let folder = os.getCurrentDir() / "tests/vue/dist/index.html"
    # startJester(folder)
    addRequest("appendSomething", proc (value: string): string =
      result = "'" & value & "' modified by Nim Backend")
    startWebview(folder)

when isMainModule and not defined(noMain):
  initRequestFunctions() 
  main()
else: 
  initRequestFunctions() 