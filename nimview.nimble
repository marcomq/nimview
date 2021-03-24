version     = "0.1.2"
author      = "Marco Mengelkoch"
description = "Nim / Python / C library to run webview with HTML/JS as UI"
license     = "MIT"
bin         = @["nimview"]
srcDir      = "src"

import os, strutils
# Dependencies
# you may skip jester, nimpy and webview when compiling with nim c -d:just_core
# Currently, Webview requires gcc and doesn't work with vcc or clang

when system.NimMinor > 2:
  requires "nim >= 1.0.0", "jester >= 0.5.0", "nimpy >= 0.1.1", "webview == 0.1.0", "nake >= 1.9.0"
else:
  echo "####-----------------------------------------------------####"
  echo "You probably need to run "
  echo "'sudo apt install libwebkit2gtk-4.0-dev'" 
  echo "'nimble install jester && nimble install nimpy && nimble install webview@0.1.0'" 
  echo "first. Older nimble versions didn't install dependencies."
  echo "Ignore this text if these packages already have been installed."
  echo "####-----------------------------------------------------####"
  requires "nim >= 0.17.0", "jester >= 0.5.0", "nimpy >= 0.1.1", "webview >= 0.1.0", "nake >= 1.9.0"

when defined(nimdistros):
  import distros
  # no foreignDep required for Windows 
  if detectOs(Ubuntu):
    foreignDep "libwebkit2gtk-4.0-dev"
  elif detectOs(CentOS) or detectOs(RedHat) or detectOs(Fedora):
    foreignDep "webkitgtk4-devel"
  if not detectOs(Windows):
    echo "In case of trouble, you may need to install following dependencies:"
    echo ""
    echoForeignDeps()
    echo ""
else:
  echo "no nimdistros"

task test, "Run tests":
  let nake = system.findExe("nake")
  exec  nake & " test"