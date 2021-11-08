# Nimview UI Library 
# © Copyright 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import asynchttpserver, json, httpcore, asyncdispatch, os, strutils, sequtils
import ws
import globalToken
import globals
import sharedTypes
import logging as log
import dispatchJsonRequest

type HttpRenderer* = object
  connections: seq[WebSocket] # old ws are not removed
  globalTokens: GlobalTokens

proc getInstance: ptr HttpRenderer =
  {.gcsafe.}:
    if nimviewVars.httpRenderer.isNil:
      var newObj {.global.} = createShared(HttpRenderer)
      nimviewVars.httpRenderer = newObj
    return cast[ptr HttpRenderer](nimviewVars.httpRenderer)

proc callFrontendJsEscapedHttp*(functionName: string, params: string) =
  ## "params" should be JS escaped values, separated by commas with surrounding quotes for string values
  var deletable = newSeq[int]()
  for idx, wsCon in getInstance().connections:
      if wsCon.readyState == ReadyState.Open:
        try:
            asynccheck wsCon.send("{\"function\":\"" & functionName & "\",\"args\":[" & params & "]}")
        except WebSocketProtocolMismatchError:
            log.info "Call frontend socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
        except CatchableError:
            log.error "Call frontend error: ", getCurrentExceptionMsg()
      else:
        deletable.add(idx)
  for idx in deletable:
    when NimMinor >= 6 or NimMajor > 1:
      getInstance().connections.delete(idx..idx)
    else:
      getInstance().connections.delete(idx, idx)

proc getCurrentAppDir(): string =
    let applicationName = os.getAppFilename().extractFilename()
    # debug applicationName
    if (applicationName.startsWith("python") or applicationName.startsWith("platform-python")):
      result = os.getCurrentDir()
    else:
      result = os.getAppDir()

proc getAbsPath*(indexHtmlFile: string): (string, string) =
  let separatorFound = indexHtmlFile.rfind({'#', '?'})
  if separatorFound == -1:
    result[0] = indexHtmlFile
  else:
    result[0] = indexHtmlFile[0 ..< separatorFound]
    result[1] = indexHtmlFile[separatorFound .. ^1]
  if (not os.isAbsolute(result[0])):
    result[0] = getCurrentAppDir() & "/" & indexHtmlFile

proc dispatchHttpRequest*(jsonMessage: JsonNode, headers: HttpHeaders): string =
  ## Modify this, if you want to add some authentication, input format validation
  ## or if you want to process HttpHeaders.
  if not nimviewSettings.useGlobalToken or getInstance().globalTokens.checkToken(headers):
      return dispatchJsonRequest(jsonMessage)
  else:
      let request = jsonMessage["request"].getStr()
      if request == "getGlobalToken":
        return $ %* {"useGlobalToken": nimviewSettings.useGlobalToken}
      else:
        raise newException(ReqDeniedException, "403 - Token expired")

proc handleRequest(request: Request): Future[void] {.async.} =
  ## used by HttpServer
  var response: string
  var requestPath: string = request.url.path
  var header = @[("Content-Type", "application/javascript")]
  {.gcsafe.}:
    let defaultHeader = nimviewVars.responseHttpHeader
  let separatorFound = requestPath.rfind({'#', '?'})
  if separatorFound != -1:
    requestPath = requestPath[0 ..< separatorFound]
  if requestPath == "/":
    requestPath = "/index.html"
  if requestPath == "/index.html":
    when defined(release):
      if not indexContent.isEmptyOrWhitespace() and indexContent == indexContentStatic:
        header = @[("Content-Type", "text/html;charset=utf-8")]
        header.add(defaultHeader)
        await request.respond(Http200, indexContent, newHttpHeaders(header))
        return
        
  try:
    {.gcsafe.}:
      let potentialFilename = nimviewVars.staticDir &
          requestPath.replace("../", "").replace("..", "")
    if os.fileExists(potentialFilename):
      debug "Sending " & potentialFilename
      let fileData = splitFile(potentialFilename)
      let contentType = case fileData.ext:
        of ".json": "application/json;charset=utf-8"
        of ".js": "text/javascript;charset=utf-8"
        of ".css": "text/css;charset=utf-8"
        of ".jpg": "image/jpeg"
        of ".txt": "text/plain;charset=utf-8"
        of ".map": "application/octet-stream"
        else: "text/html;charset=utf-8"
      header = @[("Content-Type", contentType)]
      header.add(defaultHeader)
      await request.respond(Http200, system.readFile(potentialFilename), newHttpHeaders(header))
    elif requestPath == "/ws":
      when not defined(just_core):
        try:
          var ws = await newWebSocket(request)
          getInstance().connections.add(ws)
          while ws.readyState == ReadyState.Open:
            let packet = await ws.receiveStrPacket()
            info "Received packet: " & packet
        except WebSocketProtocolMismatchError:
          echo "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
        except WebSocketError:
          echo "Socket error: ", getCurrentExceptionMsg()
    elif (request.body == ""):
        raise newException(ReqUnknownException, "404 - File not found")
    else:
      # if not a file, assume this is a json request
      var jsonMessage: JsonNode
      debug request.body
      # if unlikely(request.body == ""):
      #   jsonMessage = parseJson(uri.decodeUrl(requestPath))
      # else:
      jsonMessage = parseJson(request.body)
      {.gcsafe.}:
        response = dispatchHttpRequest(jsonMessage, request.headers)
        let byteToken = getInstance().globalTokens.getFreshToken()
        let currentToken = globalToken.byteToString(byteToken)
        let header = @{"global-token": currentToken}
        await request.respond(Http200, response, newHttpHeaders(header))

  except ReqUnknownException: 
    await request.respond(Http404, 
      $ %* {"error": "404", "value": getCurrentExceptionMsg()}, 
      newHttpHeaders(defaultHeader))
  except ReqDeniedException:
    await request.respond(Http403, 
      $ %* {"error": "403", "value": getCurrentExceptionMsg()}, 
      newHttpHeaders(defaultHeader))
  except ServerException:        
    await request.respond(Http500, 
      $ %* {"error": "500", "value": getCurrentExceptionMsg()}, 
      newHttpHeaders(defaultHeader))
  except JsonParsingError, KeyError:
    await request.respond(Http500, 
      $ %* {"error": "500", "value": "request doesn't contain valid json"}, 
      newHttpHeaders(defaultHeader))
  except:
    await request.respond(Http500, 
      $ %* {"error": "500", "value": "server error: " & getCurrentExceptionMsg()}, 
      newHttpHeaders(defaultHeader))
      
    
proc serve*() {.async.} = 
  var server = newAsyncHttpServer()
  getInstance().globalTokens = globalToken.init()
  listen(server, Port(nimviewSettings.port), nimviewSettings.bindAddr)
  while nimviewSettings.run:
    if server.shouldAcceptRequest():
      await server.acceptRequest(handleRequest)
    else:
      poll()