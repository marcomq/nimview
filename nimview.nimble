# This specific file is based on https://github.com/yglukhov/nimpy/blob/master/nimpy.nimble

version     = "0.1.0"
author      = "Marco Mengelkoch"
description = "Nim / Python / C library to run webview with HTML/JS as UI"
license     = "MIT"
let application = "nimview"
bin         = @[application]

# Dependencies
# you may skip jester, nimpy and webview when compiling with nim c -d:just_core
# Currently, Webview requires gcc and doesn't work with vcc or clang

when system.NimMinor >= 2:
  requires "nim >= 0.17.0", "jester >= 0.5.0", "nimpy >= 0.1.1", "webview == 0.1.0"
else:
  echo "####-----------------------------------------------------####"
  echo "You probably need to run "
  echo "'sudo apt install libwebkit2gtk-4.0-dev'" 
  echo "'nimble install jester && nimble install nimpy && nimble install webview@0.1.0'" 
  echo "first. Older nimble versions didn't install dependencies."
  echo "Ignore this text if these packages already have been installed."
  echo "####-----------------------------------------------------####"
  requires "nim >= 0.17.0", "jester >= 0.5.0", "nimpy >= 0.1.1", "webview >= 0.1.0"

import os, strutils

let vueDir = "tests/vue"
let svelteDir = "tests/svelte"
let mainApp = application & ".nim"
let libraryFile =  application & "_c.nim"

let nimbleDir = parentDir(parentDir(system.findExe("nimble")))
var nimbaseDir = parentDir(nimbleDir) & "/lib"
if (not system.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(system.findExe("makelink"))) & "/lib"
if (not system.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(parentDir(parentDir(system.findExe("gcc"))))) & "/lib"
if (not system.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(nimbleDir) & "/.choosenim/toolchains/nim-" & system.NimVersion & "/lib"

let webviewlLibs = when defined(windows): 
  "-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32" 
elif defined(macosx):
  "-framework Cocoa -framework WebKit"
else:
  system.staticExec("pkg-config --libs gtk+-3.0 webkit2gtk-4.0") & " -ldl"

let webviewIncludes = when defined(windows): 
  "-DWEBVIEW_WINAPI=1 -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN " 
elif defined(macosx):
  "-DWEBVIEW_COCOA=1 -x objective-c"
else:
  "-DWEBVIEW_GTK=1 " & staticExec("pkg-config --cflags gtk+-3.0 webkit2gtk-4.0")

when defined(nimdistros):
  import distros
  # no foreignDep required for Windows 
  if detectOs(Ubuntu):
    foreignDep "libwebkit2gtk-4.0-dev"
  elif detectOs(CentOS) or detectOs(RedHat) or detectOs(Fedora):
    foreignDep "webkit2gtk3-devel"
  echo "You need to install following dependencies:"
  echo ""
  echoForeignDeps()
  echo ""
else:
  echo "no nimdistros"

var extraParameter = ""
if (system.paramCount() > 8):
  for i in 9..system.paramCount():
    extraParameter = extraParameter & " " & system.paramStr(i) 

proc execCmd(command: string) = 
  echo "running: " & command
  when defined(windows): 
    exec "cmd /c \"" & command & "\""
  else:
    exec command
    
proc execNim(command: string) = 
  let commandWithExtra = extraParameter & " " & command  
  echo "running: nim " & commandWithExtra
  selfExec(commandWithExtra)

proc calcPythonExecutables() : seq[string] =
  let pyExes = getEnv("NIMPY_PY_EXES", "python:python3")
  result = pyExes.split(":")

proc buildLibs(nimFlags = "") = 
  ## creates python and C/C++ libraries
  rmDir("tmp_py")
  rmDir("tmp_c")
  let pyDllExtension = when defined(windows): "pyd" else: "so"
  let cDllExtension = when defined(windows): "dll" else: "so"
  execNim "c -d:release -d:useStdLib -d:noMain --nimcache=./tmp_py --out:tests/"  & 
    application & "." & pyDllExtension & " --app:lib " & nimFlags & " "  & mainApp & " " # creates python lib, header file not usable


# nimble c --app:lib -d:release -d:noMain --out:tests/nimview.so nimview.nim 
# nimble c --app:lib -d:release -d:noMain --out:tests/nimview.pyd nimview.nim # windows

  execNim "c --passC:-fpic -d:release -d:useStdLib --noMain:on -d:noMain --nimcache=./tmp_c --app:lib --noLinking:on " & 
    nimFlags & " " & libraryFile  # header not usable, but this creates .o files we need
  execNim "c --passC:-fpic -d:release -d:useStdLib --noMain:on -d:noMain --noLinking:on --header:" & 
    application & ".h --compileOnly:off --nimcache=./tmp_c " & nimFlags & " " & libraryFile # just to create usable header file, doesn't create .o files
  cpFile(thisDir() & "/tmp_c/" & application & ".h", thisDir() & "/" & application & ".h")
  let minGwSymbols = when defined(windows): "-Wl,--export-all-symbols -Wl,--enable-auto-import " else: ""
  exec "gcc -shared -o tests/" & application & "." & cDllExtension & " -Wl,--out-implib,tests/lib" & 
    application & ".a -Wl,--whole-archive tmp_c/*.o -Wl,--no-whole-archive " & minGwSymbols & webviewlLibs # -Wl,--export-all-symbols -Wl,--enable-auto-import
  echo "Python and shared C libraries build completed. Files have been created in tests folder."

proc buildRelease(nimFlags = "") =
  execNim "c --app:gui -d:release -d:useStdLib --out:" & application & " " & nimFlags & " " & mainApp

proc buildDebug(nimFlags = "") =
  execNim "c --verbosity:2 --app:console -d:debug --debuginfo --debugger:native -d:useStdLib --out:" & application & "_debug  " & nimFlags & " " & mainApp

proc buildCSample(nimFlags = "") = 
  rmDir("tmp_c")
  execNim "c -d:release -d:useStdLib --noMain:on -d:noMain --noLinking --header:nimview.h --nimcache=./tmp_c --app:staticLib --out:" & 
    application & " " & nimFlags & " " & libraryFile # to debug nim lib paths, add --genScript:on
  execCmd "gcc -c -w -o tmp_c/c_sample.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION  -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -Itmp_c tests/c_sample.c"
  execCmd "gcc -w -o tests/c_sample.exe tmp_c/*.o " & webviewlLibs
  
proc buildCTest(nimFlags = "") = 
  rmDir("tmp_c_test")
  execNim "c -d:release -d:useStdLib --noMain:on -d:noMain --noLinking --header:nimview.h --nimcache=./tmp_c_test --app:staticLib --out:" & 
    application & " " & nimFlags & " " & libraryFile
  execCmd "gcc -c -w -o tmp_c_test/c_test.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION  -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -Itmp_c_test tests/c_test.c"
  execCmd "gcc -w -o tests/c_test.exe tmp_c_test/*.o " & webviewlLibs

proc buildCppSample(nimFlags = "") = 
  rmDir("tmp_cpp")
  execNim "c -d:release -d:useStdLib --noMain:on -d:noMain --noLinking --header:nimview.h --nimcache=./tmp_cpp --app:staticLib " & 
    nimFlags & " " & libraryFile # target cpp would require a different nimview.hpp
  execCmd "g++ -c -w -std=c++17 -o tmp_cpp/cpp_sample.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -Itmp_cpp tests/cpp_sample.cpp"
  execCmd "g++ -w -o tests/cpp_sample.exe tmp_cpp/*.o " & webviewlLibs

proc runTests() =
  buildCSample()
  buildCppSample()
  buildLibs()
  buildCTest()
  execCmd getCurrentDir() & "/tests/c_test.exe"
  execCmd "python tests/pyTest.py"


task libs, "Build Libs":
  buildLibs()

task dev, "Serve NPM":
  execCmd("npm run dev --prefix " & svelteDir)

task debug, "Build nimview debug":
  buildDebug()
  # exec "./" & application & "_debug & npm run serve --prefix " & uiDir

    
task release, "Build npm and Run with webview":
  buildRelease()

task test, "Run tests":
  runTests()
  # execCmd "npm run build --prefix " & svelteDir
