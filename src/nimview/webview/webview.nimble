# Package

version       = "0.1.0"
author        = "oskca"
description   = "Nim bindings for zserge\'s webview"
license       = "MIT"
skipDirs      = @["tests"]

# Dependencies

requires "nim >= 0.17.2"

task test, "a simple test case":
    exec "testament pattern \"tests/*.nim\""

task docs, "generate doc":
    exec "nim doc2 -o:docs/webview.html webview.nim"

task sync, "update webview.h":
    exec "wget -O webview/webview.h https://raw.githubusercontent.com/wailsapp/wails/master/lib/renderer/webview/webview.h"
    exec "wget -O webview/webview.go https://raw.githubusercontent.com/wailsapp/wails/master/lib/renderer/webview/webview.go"
    exec "wget -O webview/LICENSE https://raw.githubusercontent.com/wailsapp/wails/master/lib/renderer/webview/LICENSE"

task clean, "clean tmp files":
    exec "rm -rf nimcache"
    exec "rm -rf tests/nimcache"
