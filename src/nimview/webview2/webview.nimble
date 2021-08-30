# Package

version       = "0.2.0"
author        = "konradmb, marcomq"
description   = "Nim bindings for webview https://github.com/webview/webview"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"

task test, "run basic test":
    exec "testament pattern tests/*.nim"
    
task update_webview, "update webview":
    exec "git subtree pull --prefix src/webview/webview  https://github.com/webview/webview.git master --squash"

task docs, "generate doc":
    exec "nim doc2 -o:docs/webview.html src/webview.nim"

task run_example, "running minimal example":
    exec "nim cpp --run tests/minimal.nim"

task clean, "clean tmp files":
    exec "rm -rf nimcache"
    exec "rm -rf tests/nimcache"
