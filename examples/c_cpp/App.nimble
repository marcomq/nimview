version     = "0.2.0"
author      = "Marco Mengelkoch"
description = "Nim / Python / C library to run webview with HTML/JS as UI"
license     = "MIT"
bin         = @["App"]
srcDir      = "src"

import os, strutils
# Dependencies

requires "nimview >= 0.2.0", "nake >= 1.9.0"

task test, "Run tests":
  let nake = system.findExe("nake")
  exec  nake & " test"