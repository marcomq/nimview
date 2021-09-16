version     = "0.2.0"
author      = "Marco Mengelkoch"
description = "Nim / C library to run webview with HTML/JS as UI"
license     = "MIT"
srcDir      = "src"

# Dependencies
# you may skip jester, nimpy and webview when compiling with nim c -d:just_core
# alternatively, you still can just skip webkit by compiling with -d:useServer

# Currently, Webview requires gcc and doesn't work with vcc or clang

requires "nimview >= 0.3.0", "nake >= 1.9.0"

