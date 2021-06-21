import nimview

proc echoAndModify(value: string): string =
  result = "'" & value & "' modified by minimal"

when isMainModule:
  nimview.addRequest("echoAndModify", echoAndModify)
  nimview.start("dist/index.html")