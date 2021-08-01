discard """
  action: "compile"
"""
import ../src/nimview

nimview.addRequest("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Web Backend")
nimview.startHttpServer("../examples/minimal/dist/index.html")