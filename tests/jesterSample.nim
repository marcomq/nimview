import ../nimvue

nimvue.addRequest("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Jester Backend")
nimvue.startJester("vue/dist/index.html")