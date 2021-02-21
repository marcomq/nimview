# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details

# pylint: disable=import-error
import __init__, nimview
def echoAndModify(value):
    print (value)
    return (value + " appended by python")

def stopNimview(value):
    nimview.stopDesktop()
    return ""

nimview.addRequest("echoAndModify", echoAndModify)
nimview.addRequest("stopNimview", stopNimview)

nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"value\":\"this is a test\",\"responseId\":0,\"responseKey\":\"test\"}")
nimview.dispatchCommandLineArg("{\"request\":\"stopNimview\",\"value\":\"\",\"responseId\":1,\"responseKey\":\"test\"}")
# nimview.startDesktop("tests/minimal_ui_sample/index.html")
