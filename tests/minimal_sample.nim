import ../nimvue
import os

nimvue.addRequest("echoAndModify", proc (value: string): string =
  echo "From Frontend: " & value
  result = "'" & value & "' modified by Backend")
nimvue.startJester(system.currentSourcePath.parentDir() / "minimal_ui_sample/index.html")
nimvue.startWebview(system.currentSourcePath.parentDir() / "minimal_ui_sample/index.html")