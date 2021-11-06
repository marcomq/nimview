import nimview

proc echoAndModify(value: string): string =
  result = "'" & value & "' modified by minimal"

when isMainModule:
  add("echoAndModify", echoAndModify)
  start("dist/index.html")