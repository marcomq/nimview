# in case of issues with nimporter, just compile nimvue manually in parent folder. 
# On Windows, use --out:nimvue.pyd instead:
# nimble c --app:lib -d:release --out:nimvue.so nimvue.nim
import nimporter, nimvue
import os 
def test(value):
    print (value)
    return (value + " appended")

nimvue.addRequest("echoAndModify", test)
dirPath = os.path.dirname(os.path.realpath(__file__))
nimvue.startWebviewExt(dirPath + "/tests/minimal_ui_sample/index.html")
nimvue.startWebviewExt("E:/apps/nimvue/tests/minimal_ui_sample/index.html")
nimvue.startJesterExt(dirPath + "/tests/minimal_ui_sample/index.html")