# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details

# pylint: disable=import-error
import __init__, nimview
def echoAndModify(value):
    print (value)
    return (value + " appended by python")

def echoAndModify2():
    print ("received nil")
    return (" appended by python")

def echoAndModify3(value1, value2):
    result = value1 + " "+ value2 + " both received"
    print (result)
    return (result + " by python")

def stopNimview(value):
    nimview.stopDesktop()
    return ""

nimview.addRequest("echoAndModify", echoAndModify)
nimview.addRequest("echoAndModify2", echoAndModify2)
nimview.addRequest("echoAndModify3", echoAndModify3)
nimview.addRequest("stopNimview", stopNimview)

nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"value\":\"this is a test\",\"responseId\":0}")
nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"value\":[],\"responseId\":3}") # will cause an error
nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify2\",\"value\":[],\"responseId\":4}") 
nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify3\",\"value\":[\"first\",\"second\"],\"responseId\":5}") 
nimview.dispatchCommandLineArg("{\"request\":\"stopNimview\",\"value\":\"\",\"responseId\":6}")
print ("python test passed")
# nimview.startDesktop("tests/minimal_ui_sample/index.html")
