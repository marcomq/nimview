# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os, macros, json
import logging as log
import requestMap

type CstringFunc* = proc(jsArg: cstring) {.cdecl.}
type RuntimeVars* = object
  requestLogger*: FileLogger
  staticDir*: string
  customJsEval*: pointer
  responseHttpHeader*: seq[tuple[key, val: string]]

type NimviewSettings* = object
  indexHtmlFile*: string
  port*: int
  bindAddr*: string
  title*: string
  width*: int
  height*: int
  resizable*: bool
  debug*: bool
  useHttpServer*: bool
  useGlobalToken*: bool
  useStaticIndexContent*: bool
  run*: bool

const defaultIndex* = 
  when not defined(release):
    "../dist/index.html"
  else:
    "../dist/inlined.html"

const displayAvailable = 
  when (system.hostOS == "windows"): 
    true 
  else: os.getEnv("DISPLAY") != ""

const preferWebview = defined(useWebview) or not defined(useServer)
const compileWithWebview* = not defined(just_core) and preferWebview

proc initSettings*(indexHtmlFile: string = defaultIndex, port: int = 8000, 
        bindAddr: string = "localhost", title: string = "nimview",
        width: int = 640, height: int = 480, resizable: bool = true): NimviewSettings =
        
  var useServer = 
    not compileWithWebview or 
    defined(useServer) or 
    not defined(release) or 
    not displayAvailable or 
    (os.fileExists("/.dockerenv"))
    
  result.indexHtmlFile = indexHtmlFile
  result.port = port
  result.bindAddr = bindAddr
  result.title = title
  result.width = width
  result.height = height
  result.resizable = resizable
  result.debug = not defined release
  result.run = true
  result.useHttpServer = useServer
  result.useGlobalToken = defined(release)
  result.useStaticIndexContent =
    when declared(doNotLoadIndexContent):
      true
    else:
      false

proc initRuntime*(): RuntimeVars =
  result.responseHttpHeader = @[("Access-Control-Allow-Origin", "127.0.0.1")]


const defaultSettings* = initSettings()
var nimviewSettings* = initSettings()
var nimviewVars* = initRuntime()

var indexContent* {.threadVar.}: string
const indexContentStatic* = 
  if fileExists(getProjectPath() & "/" & defaultSettings.indexHtmlFile):
    staticRead(getProjectPath() & "/" & defaultSettings.indexHtmlFile)
  else:
    ""
  
proc dispatchJsonRequest*(jsonMessage: JsonNode): string =
  ## Global json dispatcher that will be called from webview AND httpserver
  ## This will extract specific values that were prepared by nimview.js
  ## and forward those values to the string dispatcher.
  let request = jsonMessage["request"].getStr()
  if request == "getGlobalToken":
    return $ %* {"useGlobalToken": nimviewSettings.useGlobalToken}
  if not nimviewVars.requestLogger.isNil:
    nimviewVars.requestLogger.log(log.lvlInfo, $jsonMessage)
  let callbackFunc = requestMap.getCallbackFunc(request)
  result = callbackFunc(jsonMessage["data"])