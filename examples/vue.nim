import os
import ../nimview

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by vue sample"

proc main() =
  nimview.addRequest("appendSomething", appendSomething)
  let argv = os.commandLineParams()
  for arg in argv:
    nimview.readAndParseJsonCmdFile(arg)
  nimview.start("vue/dist/index.html")
  
when isMainModule:
  main()