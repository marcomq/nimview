import nake
import os, strutils, system

let library = "nimview"
let headerFile = library & ".h"
let srcDir = "src"
let mainApp = srcDir / "library.nim"
let srcFiles = [mainApp]
let buildDir = "out"
let thisDir = system.currentSourcePath().parentDir() 

os.createDir buildDir

proc execCmd(command: string) = 
  echo "running: " & command
  doAssert 0 == os.execShellCmd(command)

proc execNim(command: string) = 
  echo "running: nim " & command
  execCmd nimexe & " " & command

let pyDllExtension = when defined(windows): "pyd" else: "so"

proc buildPyLib() = 
  ## creates python lib
  let outputLib = buildDir / library & "." & pyDllExtension
  if outputLib.needsRefresh(srcFiles):
    os.removeDir(buildDir / "tmp_py")
    execNim "c -d:release -d:useStdLib -d:noMain --nimcache=./" & buildDir & "/tmp_py --out:" & outputLib & 
      " --app:lib " & " "  & mainApp & " " # creates python lib, header file not usable
    os.copyFile(outputLib, thisDir / "src" / library & "." & pyDllExtension)

proc runTests() =
  buildPyLib()
  try:
    os.copyFile(buildDir / library & "." & pyDllExtension, thisDir / "../../tests" / library & "." & pyDllExtension)
  except:
    discard
  execCmd "python src/pyTest.py"

proc generateDocs() = 
  execNim "doc -d:useStdLib -o:docs/" & library & ".html " & mainApp

task "clean", "clean all files":
  os.removeDir(buildDir)

task "pyLib", "Build python lib":
  buildPyLib()

task "test", "Run tests":
  runTests()
  echo "all python tests passed"