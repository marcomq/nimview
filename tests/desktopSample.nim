discard """
  action: "compile"
  cmd: "nim $target -f --hints:on -d:testing $file"
"""
import ../src/nimview
import os

proc main() =
  nimview.addRequest("echoAndModify", proc (value: string): string =
      echo value
      ## just simulating progress
      for i in 0..100: 
        callFrontendJs("applyProgress", $(i) & "%")
        os.sleep(20)
      result = "'" & value & "' modified by Webview Backend")

  nimview.startDesktop("../examples/minimal2/dist/index.html", run=false)
  nimview.setBorderless()
  nimview.setFullscreen()
  nimview.setColor(1,2,3,50)
  nimviewSettings.width = 600
  nimview.enableStorage()
  nimview.enableRequestLogger()
  nimview.disableRequestLogger()
  nimview.addRequest("callJsProgress", proc () = 
    echo nimview.selectFolderDialog("")
  )
  nimview.setUseServer(false)
  nimview.setUseGlobalToken(false)
  nimview.run()

when isMainModule:
  main()