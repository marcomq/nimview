import nimview
import os

proc callJsProgress() =
  ## just simulating progress
  for i in 0..100: 
    callFrontendJs("applyProgress", $(i) & "%")
    os.sleep(20)

proc echoAndModify(value: string): string =
  result = "'" & value & "' modified by minimal"

when isMainModule:
  addRequest("callJsProgress", callJsProgress)
  addRequest("echoAndModify", echoAndModify)
  startDesktop("dist/index.html", debug=true)