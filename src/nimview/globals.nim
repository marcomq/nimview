# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import os, macros, tables
from sharedTypes import ReqFunction
import logging as log

type CstringFunc* = proc(jsArg: cstring) {.cdecl.}
type RuntimeVars* = ref object
  requestLogger*: FileLogger
  staticDir*: string
  reqMapStore*: Table[string, ReqFunction]
  responseHttpHeader*: seq[tuple[key, val: string]]
  storage*: Table[string, string]
  storageFile*: string 
  customJsEval*: pointer
  httpRenderer*: pointer
  webviewRenderer*: pointer

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

proc newRuntime*(): RuntimeVars =
  new result
  GC_ref(result)
  result.responseHttpHeader = @[("Access-Control-Allow-Origin", "127.0.0.1")]
  result.reqMapStore = initTable[string, ReqFunction]()
  result.storageFile = "storage.json"
  result.storage = initTable[string, string]()

const defaultSettings* :NimviewSettings = initSettings()
var nimviewSettings* {.global.} :NimviewSettings = initSettings()
var nimviewVars* {.global.} :RuntimeVars = newRuntime()


var indexContent* {.threadVar.}: string
const indexContentStatic* = 
  if fileExists(getProjectPath() & "/" & defaultSettings.indexHtmlFile):
    staticRead(getProjectPath() & "/" & defaultSettings.indexHtmlFile)
  else:
    ""