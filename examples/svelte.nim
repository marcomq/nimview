import os
import ../src/nimview
# start with "nimble svelte" from parent directory

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by svelte sample"

proc main() =
  nimview.addRequest("appendSomething", appendSomething)
  let argv = os.commandLineParams()
  for arg in argv:
    nimview.readAndParseJsonCmdFile(arg)
  nimview.start("examples/svelte/public/index.html")
  
when isMainModule:
  main()