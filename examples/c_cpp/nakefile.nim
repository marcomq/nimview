import nake
import os, strutils, system, osproc

let library = "nimview"
let headerFile = library & ".h"
let srcDir = "src"
let mainApp = srcDir /   "library.nim"
var srcFiles = @[mainApp]
let buildDir = "out"
let thisDir = system.currentSourcePath().parentDir() 
let cDllExtension = when defined(windows): "dll" else: "so"

os.createDir buildDir

const webviewIncludes = when defined(windows): 
  "-DWEBVIEW_WINAPI=1 -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN " 
elif defined(macosx):
  "-DWEBVIEW_COCOA=1 -x objective-c"
else:
  "-DWEBVIEW_GTK=1 " & staticExec("pkg-config --cflags gtk+-3.0 webkit2gtk-4.0")

const webviewlLibs = when defined(windows): 
  "-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32" 
elif defined(macosx):
  "-framework Cocoa -framework WebKit"
else:
  system.staticExec("pkg-config --libs gtk+-3.0 webkit2gtk-4.0") & " -ldl -pthread"

proc execShCmd(command: string) = 
  echo "running: " & command
  doAssert 0 == os.execShellCmd(command)
  
var nimbleDir = parentDir(parentDir(os.findExe("nimble")))
var nimbaseDir = parentDir(nimbleDir) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(os.findExe("makelink"))) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(parentDir(parentDir(os.findExe("gcc"))))) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(nimbleDir) & "/.choosenim/toolchains/nim-" & system.NimVersion & "/lib"
var nimviewPath = thisDir / "../../src/" 
if not os.dirExists(nimviewPath):
  var nimviewPathTmp = $ osproc.execProcess "nimble path nimview"
  nimviewPathTmp = nimviewPathTmp.replace("\n", "").replace("\\", "/").replace("//", "/")
  if (nimviewPathTmp != "" and os.dirExists(nimviewPathTmp)):
    nimviewPath = nimviewPathTmp

if os.fileExists("dist/inlined.html"):
  srcFiles.add("dist/inlined.html")

proc execNim(command: string) = 
  echo "running: nim " & command
  execShCmd nimexe & " " & command

proc buildGenericObjects() = 
  os.removeDir(buildDir / "tmp_o")
  os.createDir(buildDir / "tmp_o")
  let headerFilePath = thisDir / buildDir / "tmp_c" / headerFile
  if headerFilePath.needsRefresh(srcFiles):
    os.removeDir(buildDir / "tmp_c")
    execNim "c -d:release --noMain:on -d:noMain --noLinking --header: " & headerFilePath & " --nimcache=./" & buildDir & 
      "/tmp_c --app:staticLib --out:"  & buildDir / library & " " & " " & mainApp 
  os.copyFile(nimviewPath / "nimview.hpp", thisDir / buildDir / "tmp_c/nimview.hpp")

proc buildCSample() = 
  execShCmd "gcc -c -w -o " & buildDir & "/tmp_o/c_sample.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -I" & buildDir & "/tmp_c src/c_sample.c"
  execShCmd "gcc -w -o " & buildDir & "/c_sample.exe " & buildDir & "/tmp_c/*.o " & buildDir & "/tmp_o/c_sample.o " & webviewlLibs
  
proc buildCppSample() = 
  execShCmd "g++ -c -w -std=c++17 -o " & buildDir & "/tmp_o/cpp_sample.o -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -O3 -fno-strict-aliasing -fno-ident " & 
    webviewIncludes & " -I" & nimbaseDir & " -I" & nimbleDir & "/pkgs/webview-0.1.0/webview -I. -I" & buildDir & "/tmp_c src/cpp_sample.cpp"
  execShCmd "g++ -w -o " & buildDir & "/cpp_sample.exe " & buildDir & "/tmp_c/*.o " & buildDir & "/tmp_o/cpp_sample.o " & webviewlLibs

proc buildDll() = 
  ## C/C++ libraries
  let outputLib = buildDir / library & "." & cDllExtension
  if (thisDir / buildDir / "tmp_dll" / headerFile).needsRefresh(srcFiles):
    os.removeDir(buildDir / "tmp_dll")
    execNim "c --passC:-fpic -d:release --noMain:on -d:noMain --nimcache=./" & buildDir & "/tmp_dll" & 
      " --app:lib --noLinking:on --header:" &  library & ".h --compileOnly:off " & " " & mainApp # creates header and compiled .o files
    os.copyFile(nimviewPath / "nimview.hpp", thisDir / buildDir / "tmp_dll/nimview.hpp")
    os.copyFile(thisDir / buildDir / "tmp_c" / headerFile,  thisDir / buildDir / "tmp_dll" / headerFile)
    os.copyFile(nimbaseDir / "nimbase.h", thisDir / buildDir / "tmp_dll" / "nimbase.h")

    let minGwSymbols = when defined(windows): 
      " -Wl,--out-implib," & buildDir & "/lib" & library & 
      ".a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive " & buildDir & "/tmp_dll/*.o -Wl,--no-whole-archive " 
    elif defined(linux):
      " -Wl,--out-implib," & buildDir & "/lib" & library & ".a -Wl,--whole-archive " & buildDir & "/tmp_dll/*.o -Wl,--no-whole-archive "
    else: 
      " " & buildDir & "/tmp_dll/*.o "
    execShCmd "gcc -shared -o " & outputLib & " -I" & buildDir & "/tmp_dll/" & " " & minGwSymbols & webviewlLibs # generate .dll and .a
    echo "Shared C libraries build completed. Files have been created in '" & buildDir & "' folder."

proc runTests() =
  buildGenericObjects()
  buildDll()
  buildCSample()
  if not defined(macosx):
    buildCppSample()
    
proc generateDocs() = 
  execNim "doc -o:docs/" & library & ".html " & mainApp
  
task "docs", "Generate doc":
  generateDocs()

task "libs", "Build Libs":
  buildGenericObjects()
  buildDll()

task "c", "Build C sample":
  buildGenericObjects()
  buildCSample()
  
task "cpp", "Build CPP sample":
  buildGenericObjects()
  buildCPPSample()

task "clean", "clean all files":
  os.removeDir(buildDir)

task "test", "Run tests":
  runTests()
  echo "all C/C++ tests passed"