# in case of issues with nimporter, just compile nimview manually in parent folder. 
# nimble c --app:lib -d:release -d:noMain --out:tests/nimview.so nimview.nim 
# nimble c --app:lib -d:release -d:noMain --out:tests/nimview.pyd nimview.nim # windows
import nimporter, nimview
def echoAndModify(value):
    print (value)
    return (value + " appended")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("minimal_ui_sample/index.html")