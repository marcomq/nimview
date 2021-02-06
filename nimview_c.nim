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
# elif (querySetting(backend) == "cpp"):
#   proc NimMain() {.importcpp.}
# else:
#   proc NimMain() =
#     discard

proc free_c(somePtr: pointer) {.cdecl,importc: "free".}

proc nimview_addRequest*(request: cstring, callback: proc(value: cstring): cstring {.cdecl.}, freeFunc: proc(value: pointer) {.cdecl.} = free_c) {.exportc.} = 
  nimview.addRequest($request, proc (nvalue: string): string =
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
  
  proc nimview_startJester*(folder: cstring, port: cint = 8000, bindAddr: cstring = "localhost") {.exportc.} =
    startJester($folder, int(port), $bindAddr)

  proc nimview_startWebview*(folder: cstring) {.exportc.} = 
    # NimMain()
    debug "starting C webview"
    startWebview($folder)
    debug "leaving C webview"

  proc nimview_start*(folder: cstring) {.exportc.} = 
    nimview.start($folder) 
      
initRequestFunctions()

proc main() =
  echo "nimview_c main"
      

when isMainModule and not defined(noMain):
  main()