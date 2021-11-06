import nimview
import os

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by Vue sample"

proc countDown() =
  callFrontendJs("alert", "waiting 6 seconds")
  sleep(2000)
  callFrontendJs("alert", "4")
  sleep(3000)
  callFrontendJs("alert", "1")
  sleep(1000)

proc main() =
  add("appendSomething", appendSomething)
  add("countDown", countDown)
  let argv = os.commandLineParams()
  for arg in argv:
    readAndParseJsonCmdFile(arg)
  start()
  
when isMainModule:
  main()