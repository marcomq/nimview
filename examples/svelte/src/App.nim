import nimview
import os

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by svelte sample"

proc countDown() =
  callFrontendJs("alert", "waiting 6 seconds")
  sleep(2000)
  callFrontendJs("alert", "4")
  sleep(3000)
  callFrontendJs("alert", "1")
  sleep(1000)

proc main() =
  addRequest("appendSomething", appendSomething)
  addRequest("countDown", countDown)
  start()
  ## alternative fullscreen mode:
  # start(run=false)
  # setFullscreen(true)
  # run()
  
when isMainModule:
  main()