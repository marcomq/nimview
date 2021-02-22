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

let vueDir = "examples/vue"
let svelteDir = "examples/svelte"
let mainApp = application & ".nim"
let libraryFile =  application & "_c.nim"
let buildDir = "build"
mkdir "build"

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

var extraParameter = "" # TODO: remove; syntax is nimble <compiler parameter> <task>
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

proc buildAllPythonLibs () = 
  rmDir(buildDir / "tmp_py_windows")
  rmDir(buildDir / "tmp_py_linux")
  rmDir(buildDir / "tmp_py_macos")

proc buildLibs() = 
  ## creates python and C/C++ libraries
  rmDir(buildDir / "tmp_py")
  rmDir(buildDir / "tmp_dll")
  let pyDllExtension = when defined(windows): "pyd" else: "so"
  let cDllExtension = when defined(windows): "dll" else: "c.so"

  execNim "c -d:release -d:useStdLib -d:noMain --nimcache=./" & buildDir & "/tmp_py --out:" & buildDir & "/"  & 
    application & "." & pyDllExtension & " --app:lib " & " "  & mainApp & " " # creates python lib, header file not usable
  execNim "c --passC:-fpic -d:release -d:useStdLib --noMain:on -d:noMain --nimcache=./" & buildDir & "/tmp_dll" & 
    " --app:lib --noLinking:on --header:" &  application & ".h --compileOnly:off " & " " & libraryFile # creates header and compiled .o files

  cpFile(thisDir() / buildDir / "tmp_dll" / application & ".h", thisDir() / application & ".h")
  let minGwSymbols = when defined(windows): 
    " -Wl,--out-implib," & buildDir & "/lib" & application & 
    ".a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive " & buildDir & "/tmp_dll/*.o -Wl,--no-whole-archive " 
  elif defined(linux):
    " -Wl,--out-implib," & buildDir & "/lib" & application & ".a -Wl,--whole-archive " & buildDir & "/tmp_dll/*.o -Wl,--no-whole-archive "
  else: 
    " " & buildDir & "/tmp_dll/*.o "
  execCmd "gcc -shared -o " & buildDir / application & "." & cDllExtension & " " & minGwSymbols & webviewlLibs # generate .dll and .a
  echo "Python and shared C libraries build completed. Files have been created in build folder."

proc buildRelease() =
  execNim "c --app:gui -d:release -d:useStdLib --out:" & application & " " & " " & mainApp

proc buildDebug() =
  execNim "c --verbosity:2 --app:console -d:debug --debuginfo --debugger:native -d:useStdLib --out:" & application & "_debug  " & " " & mainApp

proc buildCSample() = 
  execCmd "gcc -c -w -o " & buildDir & "/tmp_o/c_sample.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION  -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -I" & buildDir & "/tmp_c examples/c_sample.c"
  execCmd "gcc -w -o " & buildDir & "/c_sample.exe " & buildDir & "/tmp_c/*.o " & buildDir & "/tmp_o/c_sample.o " & webviewlLibs
  
proc buildCppSample() = 
  execCmd "g++ -c -w -std=c++17 -o " & buildDir & "/tmp_o/cpp_sample.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -I" & buildDir & "/tmp_c examples/cpp_sample.cpp"
  execCmd "g++ -w -o " & buildDir & "/cpp_sample.exe " & buildDir & "/tmp_c/*.o " & buildDir & "/tmp_o/cpp_sample.o " & webviewlLibs

proc buildCTest() = 
  execCmd "gcc -c -w -o " & buildDir & "/tmp_o/c_test.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION  -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -I" & buildDir & "/tmp_c tests/c_test.c"
  execCmd "gcc -w -o " & buildDir & "/c_test.exe " & buildDir & "/tmp_c/*.o " & buildDir & "/tmp_o/c_test.o " & webviewlLibs

proc buildGenericObjects() = 
  rmDir(buildDir / "tmp_c")
  rmDir(buildDir / "tmp_o")
  mkdir "build/tmp_o"
  execNim "c -d:release -d:useStdLib --noMain:on -d:noMain --noLinking --header:nimview.h --nimcache=./" & buildDir & 
    "/tmp_c --app:staticLib --out:" & application & " " & " " & libraryFile # create g

proc runTests() =
  buildLibs()
  buildGenericObjects()
  buildCSample()
  if not defined(macosx):
    buildCppSample()
  buildCTest()
  execCmd system.getCurrentDir() / buildDir / "c_test.exe"
  execCmd "python tests/pyTest.py"

proc generateDocs() = 
  execNim "doc -d:useStdLib -o:docs/nimview.html nimview.nim"

task libs, "Build Libs":
  buildLibs()

task dev, "Serve NPM":
  execCmd("npm run dev --prefix " & svelteDir)

task debug, "Build nimview debug":
  buildDebug()
  # exec "./" & application & "_debug & npm run serve --prefix " & uiDir

task svelte, "build svelte example in release mode":
  execCmd "npm run build --prefix " & svelteDir
  execNim "c -r --app:gui -d:release -d:useStdLib --out:build/svelte.exe examples/svelte.nim"

task vue, "build vue example in release mode":
  execCmd "npm run build --prefix " & vueDir
  execNim "c -r --app:gui -d:release -d:useStdLib --out:build/vue.exe examples/svelte.nim"
    
task release, "Build npm and Run with webview":
  buildRelease()

task docs, "Generate doc":
  generateDocs()

task test, "Run tests":
  runTests()
  # generateDocs()
  # execCmd "npm run build --prefix " & svelteDir
