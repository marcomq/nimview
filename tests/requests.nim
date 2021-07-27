# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

discard """
  action: "run"
"""
import ../src/nimview

proc echoAndModify(value: string): string =
    return (value & " appended by nim")

proc echoAndModify2(): string =
    return (" appended by python")

proc echoAndModify3(value1, value2: string): string =
    result = value1 & " " & value2 & " both received"

proc echoAndModify4(value1: string, value2: string, value3: int): string =
    result = value1 & " " & value2 & " " & $value3 & " received"

proc stopNimview() =
    nimview.stopDesktop()


nimview.addRequest("echoAndModify", echoAndModify)
nimview.addRequest("echoAndModify2", echoAndModify2)
nimview.addRequest("echoAndModify3", echoAndModify3)
nimview.addRequest("echoAndModify4", echoAndModify4)
nimview.addRequest("stopNimview", stopNimview)

discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"data\":[\"this is a test\"],\"responseId\":0}")
discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"data\":[],\"responseId\":3}") # will cause an error
discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify2\",\"data\":[],\"responseId\":4}") 
discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify3\",\"data\":[\"first\",\"second\"],\"responseId\":5}") 
discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify4\",\"data\":[\"first\",\"second\",3],\"responseId\":7}") 
discard nimview.dispatchCommandLineArg("{\"request\":\"stopNimview\",\"data\":[],\"responseId\":6}")
