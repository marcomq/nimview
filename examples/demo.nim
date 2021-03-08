import os
import ../src/nimview
# start with "nimble svelte" from parent directory

proc appendSomething(value: string): string =
  nimview.enableRequestLogger()  # this will skip the first request, but log all further ones
  result = "'" & value & "' modified by svelte sample"

proc main() =
  nimview.addRequest("appendSomething", appendSomething)
  let argv = os.commandLineParams()
  for arg in argv:
    nimview.readAndParseJsonCmdFile(arg)
  nimview.start("ui/index.html")
  
when isMainModule:
  main()