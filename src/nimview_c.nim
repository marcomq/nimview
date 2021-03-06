# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import logging

import nimview
export nimview
# in case you need to create your own C library with custom code,
# just add import nimview_c to your custom module

# import std/compilesettings
# when (querySetting(backend) == "c"):
#   proc NimMain() {.importc.}
# when (querySetting(backend) == "cpp"):
#  proc NimMain() {.importcpp.}
# else:
#   proc NimMain() =
#     discard

proc free_c(somePtr: pointer) {.cdecl, importc: "free".}

proc nimview_addRequest*(request: cstring, callback: proc(
  value: cstring): cstring {.cdecl.}, 
  freeFunc: proc(value: pointer) {.cdecl.} = free_c) {.exportc.} =
  nimview.addRequest($request, proc (nvalue: string): string =
    {.gcsafe.}:
      debug "calling nim from c interface with: " & nvalue
      var resultPtr: cstring = ""
      try:
        resultPtr = callback(nvalue)
        result = $resultPtr
      finally:
        if (resultPtr != ""):
          freeFunc(resultPtr)
    )

proc nimview_dispatchRequest*(request, value: cstring): cstring {.exportc.} =
  result = $dispatchRequest($request, $value)

proc nimview_dispatchCommandLineArg*(escapedArgv: cstring): cstring {.exportc.} =
  result = $dispatchCommandLineArg($escapedArgv)

proc nimview_readAndParseJsonCmdFile*(filename: cstring) {.exportc.} =
  readAndParseJsonCmdFile($filename)

when not defined(just_core):

  proc nimview_startHttpServer*(folder: cstring, port: cint = 8000,
      bindAddr: cstring = "localhost") {.exportc.} =
    startHttpServer($folder, int(port), $bindAddr)

  proc nimview_startDesktop*(folder: cstring, title: cstring = "nimview",
      width: cint = 640, height: cint = 480, resizable: bool = true,
      debug: bool = false) {.exportc.} =
    # NimMain()
    debug "starting C webview"
    startDesktop($folder, $title, width, height, resizable, debug)
    debug "leaving C webview"

  proc nimview_stopDesktop*() {.exportc.} = nimview.stopDesktop()

  proc nimview_start*(folder: cstring, port: cint = 8000,
      bindAddr: cstring = "localhost", title: cstring = "nimview",
      width: cint = 640, height: cint = 480, resizable: bool = true) {.exportc.} =
    nimview.start($folder, port, $bindAddr, $title, width, height, resizable)

proc myMain() {.exportc.} =
  echo "starting nim"

when isMainModule:
  myMain()
