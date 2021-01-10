# in case of issues with nimporter, just compile nimvue manually in parent folder. 
# nimble c --app:lib -d:release -d:noMain --out:tests/nimvue.so nimvue.nim 
# nimble c --app:lib -d:release -d:noMain --out:tests/nimvue.pyd nimvue.nim # windows
import nimporter, nimvue
def echoAndModify(value):
    print (value)
    return (value + " appended")

nimvue.addRequest("echoAndModify", echoAndModify)
nimvue.startWebview("minimal_ui_sample/index.html")
nimvue.startJester("minimal_ui_sample/index.html")