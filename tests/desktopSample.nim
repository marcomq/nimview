discard """
  action: "compile"
"""
import ../src/nimview

nimview.addRequest("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Webview Backend")
nimview.setBorderless()
nimview.setFullscreen()
nimview.setColor(1,2,3,50)
nimviewSettings.width = 600
nimview.enableStorage()
nimview.enableRequestLogger()
nimview.disableRequestLogger()
nimview.setUseServer(false)
nimview.setUseGlobalToken(false)
nimview.startDesktop("../examples/minimal/dist/index.html")