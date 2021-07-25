import nake
import os, strutils, system, osproc

const application = "App"
const uiDir = "src"
const mainApp = "src" / application & ".nim"
const libraryFile =  mainApp


let thisDir = system.currentSourcePath().parentDir()
let nimbleDir = parentDir(parentDir(os.findExe("nimble")))
var nimbaseDir = parentDir(nimbleDir) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(os.findExe("makelink"))) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(parentDir(parentDir(parentDir(os.findExe("gcc"))))) & "/lib"
if (not os.fileExists(nimbaseDir & "/nimbase.h")):
  nimbaseDir = parentDir(nimbleDir) & "/.choosenim/toolchains/nim-" & system.NimVersion & "/lib"

var nimviewPath = thisDir.parentDir().parentDir().parentDir().parentDir().parentDir().parentDir() / "src" # only used for nimview.hpp
if not os.dirExists(nimviewPath):
  var nimviewPathTmp = $ osproc.execProcess "nimble path nimview"
  nimviewPathTmp = nimviewPathTmp.replace("\n", "").replace("\\", "/").replace("//", "/")
  if (nimviewPathTmp != "" and os.dirExists(nimviewPathTmp)):
    nimviewPath = nimviewPathTmp

proc execShCmd(command: string) =
  echo "running: " & command
  doAssert 0 == os.execShellCmd(command)

proc buildCForArch(cpu, path: string) =
  let cppPath = "../cpp" / path 
  let headerFile = cppPath /  application & ".h"
  if (headerfile.needsRefresh(mainApp)):
    os.removeDir(cppPath)
    var stdOptions = "--header:" & application & ".h --app:staticlib -d:just_core -d:noSignalHandler -d:release -d:androidNDK -d:noMain --os:android --threads:on "
    execShCmd(nimexe & " cpp -c " & stdOptions & "--cpu:" & cpu & " --nimcache:" & cppPath & " " & mainApp)

proc buildC() =
  ## creates python and C/C++ libraries
  buildCForArch("arm64", "arm64-v8a")
  buildCForArch("arm", "armeabi-v7a")
  buildCForArch("i386", "x86")
  buildCForArch("amd64", "x86_64")

proc buildJs() =
  var src: seq[string] = @[]
  for path in walkDirRec(uiDir):
    if path.endsWith("js") or path.endsWith("svelte") or path.endsWith("jsx")  or path.endsWith("vue"):
      src.add(path)
  if ((thisDir / "dist/build/bundle.js").needsRefresh(src)):
    execShCmd("npm install")
    execShCmd("npm run build")
    os.removeDir("../assets")
    os.createDir("../assets")
    os.copyDir(thisDir & "/dist", "../assets") # maybe not required anymore

task "serve", "Serve NPM":
  doAssert 0 == os.execShellCmd("npm run serve")

task "clean", "cleanup files":
  os.removeFile(thisDir / "dist/build/bundle.js")
  os.removeDir("../assets")
  os.removeDir("../cpp/arm64-v8a")
  os.removeDir("../cpp/armeabi-v7a")
  os.removeDir("../cpp/x86")
  os.removeDir("../cpp/x86_64")

task defaultTask, "Compiles to C":
  os.copyFile(nimbaseDir / "nimbase.h", thisDir / "../cpp" / "nimbase.h")
  os.copyFile(nimviewPath / "nimview.hpp", thisDir / "../cpp" / "nimview.hpp")
  buildJs()
  buildC()