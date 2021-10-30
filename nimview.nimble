version     = "0.3.3"
author      = "Marco Mengelkoch"
description = "Nim / Python / C library to run webview with HTML/JS as UI"
license     = "MIT"
srcDir      = "src"

import os, strutils
# Dependencies
# you may skip nimpy and webview when compiling with nim c -d:just_core
# Currently, Webview requires gcc and doesn't work with vcc or clang

requires "nim >= 1.4.8", "nimpy >= 0.1.1", "nake >= 1.9.0", "ws >= 0.4.4"

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

proc execSh(cmd: string) =
  if detectOs(Windows):
    exec "cmd /C " & cmd
  else:
    exec "bash -c '" & cmd & "'"

proc builDemoBinaries() = 
  let baseDir = thisDir()
  cd baseDir / "examples/svelte_todo"
  exec "nim c -f -d:release -d:useServer --out:" & baseDir & "/demo/httpTodo.exe src/App.nim"
  exec "nim c -f -d:release --app:gui --out:" & baseDir & "/demo/appTodo.exe src/App.nim"
  cd baseDir

proc builDemoJs() = 
  let baseDir = thisDir()
  cd baseDir / "examples/svelte_todo"
  execSh "npm install"
  execSh "npm run build"
  cd baseDir

task docs, "Generate doc":
  exec "nim doc -o:docs/theindex.html src/nimview.nim "
  exec "nim doc -o:docs/webviewRenderer.html src/nimview/webviewRenderer.nim"
  exec "nim doc -o:docs/httpRenderer.html src/nimview/httpRenderer.nim"
  exec "nim doc -o:docs/storage.html src/nimview/storage.nim"
  exec "nim doc -o:docs/sharedTypes.html src/nimview/sharedTypes.nim"
  exec "nim doc -o:docs/requestMap.html src/nimview/requestMap.nim"
  exec "nim doc -o:docs/globals.html src/nimview/globals.nim"
  # let cmd = "inliner -n --preserve-comments --iesafe --inlinemin docs/nimview_tmp.html > docs/nimview.html"
  # execSh cmd

task demo, "Generate demo files":
  builDemoJs()
  builDemoBinaries()

task test, "Run tests":
  builDemoBinaries()
  let baseDir = thisDir()
  cd baseDir / "examples/c_cpp"
  let nake = system.findExe("nake")
  exec nake & " test"
  cd baseDir / "examples/python"
  exec nake & " test"
  cd baseDir
  exec "testament pattern \"tests/*.nim\""
  echo "All tests passed"