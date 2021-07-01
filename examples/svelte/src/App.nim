import nimview

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by svelte sample"

proc main() =
  addRequest("appendSomething", appendSomething)
  start()
  # startHttpServer()
  
when isMainModule:
  main()