discard """
  action: "run"
  cmd: "nim $target --hints:on -d:testing -d:useMalloc $file"
  output: ""
"""
# Use-after-free is only detected reliably with AddressSanitizer:
# nim c -r --cc:clang -d:useMalloc -d:noSignalHandler --passC:-fsanitize=address --passL:-fsanitize=address memorySafety.nim

import ../src/nimview
import logging
logging.getHandlers()[0].levelThreshold = lvlWarn

proc churnHeap() =
  var junk = newSeq[string]()
  for i in 0 .. 100:
    junk.add("overwrite overwrite overwrite overwrite overwrite " & $i)

nimview.add("echo", proc(value: string): string = value & " appended by nim")
nimview.add("echoCstring", proc(value: cstring): string =
  churnHeap()
  result = $value)

let response = nimview.dispatchRequest("echo".cstring, "[\"hello\"]".cstring)
churnHeap()
doAssert $response == "hello appended by nim"

let longValue = "a heap allocated json string value"
doAssert nimview.dispatchRequest("echoCstring", "[\"" & longValue & "\"]") == longValue
doAssert nimview.dispatchRequest("echoCstring", "[42]") == "42"
