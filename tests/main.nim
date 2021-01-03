import os
import ../nimvue

proc appendSomethingNew(value: string): string {.noSideEffect, gcsafe.} =
  result = value & " modified by main"

proc main() =
  nimvue.addRequest("appendSomething", appendSomethingNew)

  let argv = os.commandLineParams()
  for arg in argv:
    nimvue.readAndParseFile(arg)
  let folder = os.getCurrentDir() / "../ui/dist/index.html"
  # nimvue.startWebview(folder)
  nimvue.startJester(folder, 8000)
  
when isMainModule:
  main()