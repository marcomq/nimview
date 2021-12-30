import nake
import os, strutils, system

let library = "nimview"
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
    execNim "c -d:release -d:noMain --threads:on --gc:orc --deepCopy:on --nimcache=./" & buildDir & "/tmp_py --out:" & outputLib & 
      " --app:lib " & " "  & mainApp & " " # creates python lib, header file not usable
    os.copyFile(outputLib, thisDir / "src" / library & "." & pyDllExtension)

proc runTests() =
  buildPyLib()
  try:
    os.copyFile(buildDir / library & "." & pyDllExtension, thisDir / "../../tests" / library & "." & pyDllExtension)
  except:
    discard
  execCmd "python src/pyTest.py"

proc cleanUp() =
  os.removeDir(buildDir)

task "clean", "clean all files":
  cleanUp()

task "pyLib", "Build python lib":
  buildPyLib()

task "test", "Run tests":
  cleanUp()
  runTests()
  echo "all python tests passed"