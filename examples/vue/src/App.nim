import os

import nimview

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by Vue sample"

proc main() =
  addRequest("appendSomething", appendSomething)
  let argv = os.commandLineParams()
  for arg in argv:
    readAndParseJsonCmdFile(arg)
  start("../dist/index.html")
  # nimview.startHttpServer()
  
when isMainModule:
  main()