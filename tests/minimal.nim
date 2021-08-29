discard """
  action: "compile"
"""
import webview

let w = newWebView(title="Minimal example", url="https://www.bing.com", 
    width=480, height=320, resizable=true)
w.run()
