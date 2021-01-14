import ../nimview

nimview.addRequest("echoAndModify", proc (value: string): string =
  echo "From Frontend: " & value
  result = "'" & value & "' modified by Backend")
nimview.start("minimal_ui_sample/index.html")