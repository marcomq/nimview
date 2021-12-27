import nimview
import os

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by react sample"

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
  start()
  
when isMainModule:
  main()