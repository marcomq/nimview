import os
import ../nimview

proc appendSomethingNew(value: string): string {.noSideEffect, gcsafe.} =
  result = value & " modified by main"

proc main() =
  nimview.addRequest("appendSomething", appendSomethingNew)

  let argv = os.commandLineParams()
  for arg in argv:
    nimview.readAndParseJsonCmdFile(arg)
  let folder = os.getCurrentDir() / "vue/dist/index.html"
  nimview.startWebview(folder)
  # nimview.startJester(folder, 8000)
  
when isMainModule:
  main()