# This specific file is based on https://github.com/yglukhov/nimpy/blob/master/nimpy.nimble

version     = "0.1.0"
author      = "Marco Mengelkoch"
description = "Nim / Python / C library to run webview with HTML/JS as UI"
license     = "MIT"

# Dependencies
# you may skip jester, nimpy and webview when compiling with nim c -d:just_core

# Currently, Webview requires gcc and doesn't work with vcc or clang

requires "nim >= 0.17.0", "jester >= 0.5.0", "nimpy >= 0.1.1", "webview >= 0.1.0"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libwebkit2gtk-4.0-dev"
  elif detectOs(CentOS) or detectOs(RedHat) or detectOs(Fedora):
    foreignDep "webkit2gtk3-devel"

import oswalkdir, os, strutils

proc buildLibs() = 
  let pyDllExtension = when defined(windows): "pyd" else: "so"
  let cDllExtension = when defined(windows): "dll" else: "so"
  let externalLibs = when defined(windows): 
    "-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32" 
  else: 
    " -lnimview -lm -lrt -lwebkit2gtk-4.0 -lgtk-3 -lgdk-3 -lpangocairo-1.0 -lpango-1.0 -latk-1.0 -lcairo-gobject -lcairo -lgdk_pixbuf-2.0 -lsoup-2.4 -lgio-2.0 -ljavascriptcoregtk-4.0 -lgobject-2.0 -lglib-2.0"
  exec "nim c -d:release -d:useStdLib --noMain:on -d:noMain --out:tests/nimview." & pyDllExtension & " --nimcache=./tmp_c --app:lib nimview.nim"
  exec "nim c -d:release -d:useStdLib --noMain:on -d:noMain --noLinking:on --header:nimview.h --nimcache=./tmp_c nimview.nim"
  exec "gcc -shared -o tests/nimview." & cDllExtension & " -Wl,--out-implib,tests/libnimview.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive tmp_c/*.o -Wl,--no-whole-archive " & externalLibs
  when defined(windows): 
    exec "cmd /c \"copy /Y tmp_c\\nimview.h tests\\msvc \""
  else:
    exec "cp tmp_c/nimview.h tests/msvc/"



proc calcPythonExecutables() : seq[string] =
  ## Calculates which Python executables to use for testing
  ## The default is to use "python2" and "python3"
  ##
  ## You can override this by setting the environment
  ## variable `NIMPY_PY_EXES` to a comma separated list
  ## of Python executables to invoke. For example, to test
  ## with Python 2 from the system PATH and multiple versions
  ## of Python 3, you might invoke something like
  ##
  ## `NIMPY_PY_EXES="python2:/usr/local/bin/python3.7:/usr/local/bin/python3.8" nimble test`
  ##
  ## These are launched via a shell so they can be scripts
  ## as well as actual Python executables

  let pyExes = getEnv("NIMPY_PY_EXES", "python2:python3")
  result = pyExes.split(":")

proc calcLibPythons() : seq[string] =
  ## Calculates which libpython modules to use for testing
  ## The default is to use whichever libpython is found
  ## by `pythonLibHandleFromExternalLib()` in py_lib.nim
  ##
  ## You can override this by setting the environment
  ## variable `NIMPY_LIBPYTHONS` to a comma separated list
  ## of libpython modules to load. For example, you might
  ## invoke something like
  ##
  ## `NIMPY_LIBPYTHONS="/usr/lib/x86_64-linux-gnu/libpython2.7.so:/usr/lib/x86_64-linux-gnu/libpython3.8.so" nimble test`
  ##
  let libPythons = getEnv("NIMPY_LIBPYTHONS", "")
  result = libPythons.split(":")

proc runTests(nimFlags = "") =
  let pluginExtension = when defined(windows): "pyd" else: "so"

  for f in oswalkdir.walkDir("tests"):
    # Compile all nim modules, except those starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".nim" and not sf.name.startsWith("t"):
      # exec "nim c --app:lib " & nimFlags & " --out:" & f.path.changeFileExt(pluginExtension) & " " & f.path
      exec "nim c --threads:on --app:lib " & nimFlags & " --out:" & f.path.changeFileExt(pluginExtension) & " " & f.path

  let
    pythonExes = calcPythonExecutables()
    libPythons = calcLibPythons()

  for f in oswalkdir.walkDir("tests"):
    # Run all python modules starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".py" and sf.name.startsWith("t"):
      for pythonExe in pythonExes:
        echo "Testing Python executable: ", pythonExe
        exec pythonExe & " " & f.path

  for f in oswalkdir.walkDir("tests"):
    # Run all nim modules starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".nim" and sf.name.startsWith("t"):
      for libPython in libPythons:
        exec "nim c -d:nimpyTestLibPython=" & libPython & " -r " & nimFlags & " " & f.path

task buildLibs, "Build Libs":
  buildLibs()

task test, "Run tests":
  runTests()
  runTests("--gc:arc --passc:-g") # Arc
  exec "npm run build --prefix tests/vue"

task test_arc, "Run tests with --gc:arc":
  runTests("--gc:arc --passc:-g")