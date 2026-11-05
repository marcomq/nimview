discard """
  action: "run"
  cmd: "nim $target --hints:on -d:testing $file"
  output: ""
"""

include ../src/nimview/httpRenderer

for i in 0 .. 2:
  getInstance().connections.add(WebSocket(readyState: Closed))
callFrontendJsEscapedHttp("someFunction", "1")
doAssert getInstance().connections.len == 0
