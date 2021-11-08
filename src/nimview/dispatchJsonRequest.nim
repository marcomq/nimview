import json
import logging as log
import globals
import requestMap

proc dispatchJsonRequest*(jsonMessage: JsonNode): string =
  ## Global json dispatcher that will be called from webview AND httpserver
  ## This will extract specific values that were prepared by nimview.js
  ## and forward those values to the string dispatcher.
  let request = jsonMessage["request"].getStr()
  if request == "getGlobalToken":
    return $ %* {"useGlobalToken": nimviewSettings.useGlobalToken}
  if not nimviewVars.requestLogger.isNil:
    nimviewVars.requestLogger.log(log.lvlInfo, $jsonMessage)
  let callbackFunc = requestMap.getCallbackFunc(request)
  result = callbackFunc(jsonMessage["data"])
