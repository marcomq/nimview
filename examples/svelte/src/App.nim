import nimview

proc appendSomething(value: string): string {.noSideEffect.} =
  result = "'" & value & "' modified by svelte sample"

proc main() =
  addRequest("appendSomething", appendSomething)
  start()
  ## alternative fullscreen mode:
  # start(run=false)
  # setFullscreen(true)
  # run()
  
when isMainModule:
  main()