import nimview
import os

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by React sample"

proc countDown() =
  callJs("alert", "waiting 6 seconds")
  sleep(2000)
  callJs("alert", "4")
  sleep(3000)
  callJs("alert", "1")
  sleep(1000)

proc main() =
  add("appendSomething", appendSomething)
  add("countDown", countDown)
  let argv = os.commandLineParams()
  for arg in argv:
    readAndParseJsonCmdFile(arg)
  start("../build/index.html")
  
when isMainModule:
  main()