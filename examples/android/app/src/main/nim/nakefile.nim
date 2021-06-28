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

var nimviewPath = thisDir / "../../../../../../src/"
try:
  var nimviewPathTmp = $ osproc.execProcess "nimble path nimview"
  nimviewPathTmp = nimviewPathTmp.replace("\n", "").replace("\\", "/").replace("//", "/")
  if (nimviewPathTmp != ""):
    nimviewPath = nimviewPathTmp
except:
  discard

proc execShCmd(command: string) =
  echo "running: " & command
  doAssert 0 == os.execShellCmd(command)

proc buildCForArch(cpu, path: string) =
  let cppPath = "../cpp" / path 
  let headerFile = cppPath /  application & ".h"
  if (headerfile.needsRefresh(mainApp)):
    os.removeDir(cppPath)
    const stdOptions = "--header:" & application & ".h --app:staticlib -d:just_core -d:noSignalHandler -d:release -d:androidNDK -d:noMain --os:android --threads:on "
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
    src.add(path)
  if ((uiDir / "dist/build/bundle.js").needsRefresh(src)):
    execShCmd("npm install")
    execShCmd("npm run build")
    os.removeDir("../assets")
    os.createDir("../assets")
    os.copyDir(uiDir & "/dist", "../assets") # maybe not required anymore

task "serve", "Serve NPM":
  doAssert 0 == os.execShellCmd("npm run serve")

task defaultTask, "Compiles to C":
  os.copyFile(nimbaseDir / "nimbase.h", thisDir / "../cpp" / "nimbase.h")
  os.copyFile(nimviewPath / "nimview.hpp", thisDir / "../cpp" / "nimview.hpp")
  buildC()
  buildJs()