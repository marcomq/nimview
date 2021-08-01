discard """
  action: "compile"
"""
import ../src/nimview

nimview.addRequest("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Webview Backend")
nimview.startDesktop("../examples/minimal/dist/index.html")