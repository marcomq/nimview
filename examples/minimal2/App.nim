import nimview
import os

proc callJsProgress() =
  ## just simulating progress
  for i in 0..100: 
    callJs("applyProgress", $(i) & "%")
    os.sleep(20)

proc echoAndModify(value: string): string =
  result = "'" & value & "' modified by minimal"

when isMainModule:
  add("callJsProgress", callJsProgress)
  add("echoAndModify", echoAndModify)
  startDesktop("dist/index.html", debug=true)
  