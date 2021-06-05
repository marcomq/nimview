import os

import nimview

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by svelte sample"

proc main() =
  nimview.addRequest("appendSomething", appendSomething)
  nimview.start()
  # nimview.startHttpServer()
  
when isMainModule:
  main()