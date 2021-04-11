# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details

# pylint: disable=import-error
import __init__, nimview
def echoAndModify(value):
    print (value)
    return (value + " appended by python")

def echoAndModify2():
    print ("received")
    return (" appended by python")

def stopNimview(value):
    nimview.stopDesktop()
    return ""

nimview.addRequest("echoAndModify", echoAndModify)
nimview.addRequest("echoAndModify2", echoAndModify2)
nimview.addRequest("stopNimview", stopNimview)

nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"value\":\"this is a test\",\"responseId\":0}")
nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"responseId\":4}")
nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify2\",\"value\":\"\",\"responseId\":2}") ## will cause a warning
nimview.dispatchCommandLineArg("{\"request\":\"stopNimview\",\"value\":\"\",\"responseId\":1}")
print ("all tests passed")
# nimview.startDesktop("tests/minimal_ui_sample/index.html")
