import nake
import os, strutils, system

let application = "nimview"
let srcDir = "src"
let vueDir = "examples/vue"
let svelteDir = "examples/svelte"
let mainApp = srcDir / application & ".nim"
let libraryFile =  srcDir / application & "_c.nim"
let srcFiles = [mainApp, libraryFile]
let buildDir = "out"
let thisDir = system.currentSourcePath().parentDir() 

os.createDir buildDir

var nimbleDir = parentDir(parentDir(os.findExe("nimble")))
var nimbaseDir = parentDir(nimbleDir) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(os.findExe("makelink"))) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(parentDir(parentDir(os.findExe("gcc"))))) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(nimbleDir) & "/.choosenim/toolchains/nim-" & system.NimVersion & "/lib"

const webviewlLibs = when defined(windows): 
  "-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32" 
elif defined(macosx):
  "-framework Cocoa -framework WebKit"
else:
  system.staticExec("pkg-config --libs gtk+-3.0 webkit2gtk-4.0") & " -ldl"

const webviewIncludes = when defined(windows): 
  "-DWEBVIEW_WINAPI=1 -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN " 
elif defined(macosx):
  "-DWEBVIEW_COCOA=1 -x objective-c"
else:
  "-DWEBVIEW_GTK=1 " & staticExec("pkg-config --cflags gtk+-3.0 webkit2gtk-4.0")

proc execCmd(command: string) = 
  echo "running: " & command
  doAssert 0 == os.execShellCmd(command)

proc execNim(command: string) = 
  echo "running: nim " & command
  execCmd nimexe & " " & command

proc buildPyLib() = 
  ## creates python lib
  let pyDllExtension = when defined(windows): "pyd" else: "so"
  let outputLib = buildDir / application & "." & pyDllExtension
  if outputLib.needsRefresh(srcFiles):
    os.removeDir(buildDir / "tmp_py")
    execNim "c -d:release -d:useStdLib -d:noMain --nimcache=./" & buildDir & "/tmp_py --out:" & outputLib & 
      " --app:lib " & " "  & mainApp & " " # creates python lib, header file not usable

proc buildLibs() = 
  ## C/C++ libraries
  buildPyLib()
  let cDllExtension = when defined(windows): "dll" else: "c.so"
  let headerFile = thisDir / buildDir / "tmp_dll" / application & ".h"
  let outputLib = buildDir / application & "." & cDllExtension
  if headerFile.needsRefresh(srcFiles):
    os.removeDir(buildDir / "tmp_dll")
    execNim "c --passC:-fpic -d:release -d:useStdLib --noMain:on -d:noMain --nimcache=./" & buildDir & "/tmp_dll" & 
      " --app:lib --noLinking:on --header:" &  application & ".h --compileOnly:off " & " " & libraryFile # creates header and compiled .o files
    os.copyFile(headerFile, thisDir / srcDir / application & ".h")

    let minGwSymbols = when defined(windows): 
      " -Wl,--out-implib," & buildDir & "/lib" & application & 
      ".a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive " & buildDir & "/tmp_dll/*.o -Wl,--no-whole-archive " 
    elif defined(linux):
      " -Wl,--out-implib," & buildDir & "/lib" & application & ".a -Wl,--whole-archive " & buildDir & "/tmp_dll/*.o -Wl,--no-whole-archive "
    else: 
      " " & buildDir & "/tmp_dll/*.o "
    execCmd "gcc -shared -o " & outputLib & " -I" & buildDir & "/tmp_dll/" & " " & minGwSymbols & webviewlLibs # generate .dll and .a
    echo "Python and shared C libraries build completed. Files have been created in build folder."

proc buildRelease() =
  execNim "c --app:gui -d:release -d:useStdLib --out:"  & buildDir / application & " " & " " & mainApp

proc buildDebug() =
  execNim "c --verbosity:2 --app:console -d:debug --debuginfo --debugger:native --out:"  & buildDir / application & "_debug  " & " " & mainApp

  
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
  os.removeDir(buildDir / "tmp_o")
  os.createDir(buildDir / "tmp_o")
  let headerFile = thisDir / buildDir / "tmp_c" / application & ".h"
  if headerFile.needsRefresh(srcFiles):
    os.removeDir(buildDir / "tmp_c")
    execNim "c -d:release -d:useStdLib --noMain:on -d:noMain --noLinking --header:" & application & ".h --nimcache=./" & buildDir & 
      "/tmp_c --app:staticLib --out:"  & buildDir / application & " " & " " & libraryFile 

proc runTests() =
  buildLibs()
  buildGenericObjects()
  buildCSample()
  if not defined(macosx):
    buildCppSample()
  buildCTest()
  execCmd os.getCurrentDir() / buildDir / "c_test.exe"
  execCmd "python tests/pyTest.py"
  execCmd "nimble install -y"

proc generateDocs() = 
  execNim "doc -d:useStdLib -o:docs/" & application & ".html " & mainApp
  
task "libs", "Build Libs":
  buildLibs()

task "pyLib", "Build python lib":
  buildPyLib()

task "dev", "Serve NPM":
  execCmd("npm run dev --prefix " & svelteDir)

task "debug", "Build " & application & " debug":
  buildDebug()
  # exec "./" & application & "_debug & npm run serve --prefix " & uiDir

task "svelte", "build svelte example in release mode":
  execCmd "npm run build --prefix " & svelteDir
  execNim "c -r --app:gui -d:release -d:useStdLib --out:svelte.exe examples/svelte.nim"

task "demo", "build svelte example in release mode":
  os.removeDir(buildDir / "demo")
  os.createDir(buildDir / "demo/ui")
  execCmd "npm run build --prefix " & svelteDir
  os.copyDir(svelteDir / "public", buildDir / "demo/ui")
  execNim "c --app:console -d:useServer -d:release -d:useStdLib --out:"  & buildDir / "demo/server_demo.exe examples/demo.nim"
  execNim "c -r --app:gui -d:release -d:useStdLib --out:"  & buildDir / "demo/desktop_demo.exe examples/demo.nim"

task "vue", "build vue example in release mode":
  execCmd "npm run build --prefix " & vueDir
  execNim "c -r --app:gui -d:release -d:useStdLib --out:vue.exe examples/svelte.nim"
    
task "release", "Build npm and Run with webview":
  buildRelease()

task "docs", "Generate doc":
  generateDocs()

task "test", "Run tests":
  runTests()
  echo "all tests passed"
  # generateDocs()
  # execCmd "npm run build --prefix " & svelteDir