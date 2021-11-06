discard """
  action: "run"
  cmd: "nim $target -f --hints:on -d:testing $file"
  output: '''
WARN Error calling function, args: {"request":"echoAndModify","data":[],"responseId":0}
WARN Error calling function, args: {"request":"echoAndModify3","data":["first"],"responseId":2}
'''
"""

import ../src/nimview
import logging

proc echoAndModify(value: string): string =
    return (value & " appended by nim")

proc echoAndModify2(): string =
    return (" appended by python")

proc echoAndModify3(value1, value2: string): string =
    result = value1 & " " & value2 & " both received"

proc echoAndModify4(value1: string, value2: string, value3: int): string =
    result = value1 & " " & value2 & " " & $value3 & " received"

proc stopNimview() =
    nimview.stop()


proc main() =
    logging.getHandlers()[0].levelThreshold = lvlWarn
    nimview.add("echoAndModify", echoAndModify)
    nimview.add("echoAndModify2", echoAndModify2)
    nimview.add("echoAndModify3", echoAndModify3)
    nimview.add("echoAndModify4", echoAndModify4)
    nimview.add("stopNimview", stopNimview)

    discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"data\":[],\"responseId\":0}") # will print warning
    discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify2\",\"data\":[\"unused\"],\"responseId\":1}")  # will currently not print warning
    discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify3\",\"data\":[\"first\"],\"responseId\":2}")  # will print warning
    discard nimview.dispatchCommandLineArg("{\"request\":\"echoAndModify4\",\"data\":[\"first\",2,3],\"responseId\":3}")   # will currently not print warning, as 2 is converted to string
    discard nimview.dispatchCommandLineArg("{\"request\":\"stopNimview\",\"data\":[],\"responseId\":6}") 

when isMainModule:
  main()