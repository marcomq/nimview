version     = "0.2.3"
author      = "Marco Mengelkoch"
description = "Nim / Python / C library to run webview with HTML/JS as UI"
license     = "MIT"
srcDir      = "src"

import os, strutils
# Dependencies
# you may skip nimpy and webview when compiling with nim c -d:just_core
# Currently, Webview requires gcc and doesn't work with vcc or clang

requires "nim >= 1.2.10", "nimpy >= 0.1.1", "nake >= 1.9.0"

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
  exec "nim c -d:release -d:useServer --out:" & baseDir & "/demo/httpTodo.exe src/App.nim"
  exec "nim c -d:release --app:gui --out:" & baseDir & "/demo/appTodo.exe src/App.nim"
  cd baseDir

proc builDemoJs() = 
  let baseDir = thisDir()
  cd baseDir / "examples/svelte_todo"
  execSh "npm install"
  execSh "npm run build"
  cd baseDir

task docs, "Generate doc":
  exec "nim doc -o:docs/nimview.html src/nimview.nim"
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