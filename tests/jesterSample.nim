import ../nimview

nimview.addRequest("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Jester Backend")
nimview.startJester("vue/dist/index.html")