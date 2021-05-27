# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import tables, json, os, strformat, macros
import nimview, typetraits

type ReqFunction* = object
  nimCallback: proc (values: JsonNode): string
  jsSignature: string

var reqMapStore = cast[ptr Table[string, ReqFunction]](allocShared0(sizeof(Table[string, ReqFunction])))

proc parseAny[T](value: string): T =
  when T is string:
    result = value
  elif T is JsonNode:
    result = json.parseJsonvalue(value)
  elif T is bool:
    result = strUtils.parseBool(value)
  elif T is enum:
    result = strUtils.parseEnum(value)
  elif T is uint:
    result = strUtils.parseUInt(value)
  elif T is int:
    result = strUtils.parseInt(value)
  elif T is float:
    result = strUtils.parseFloat(value)
  # when T is array:
  #   result = strUtils.parseEnum(value)

template withStringFailover[T](value: JsonNode, jsonType: JsonNodeKind, body: untyped) =
    if value.kind == jsonType:
      body
    elif value.kind == JString:
      result = parseAny[T](value.getStr())
    else: 
      result = parseAny[T]($value)

proc parseAny*[T](value: JsonNode): T =
  when T is JsonNode:
    result = value
  elif T is (int or uint):
    withStringFailover[T](value, Jint):
      result = value.getInt()
  elif T is float:
    withStringFailover[T](value, JFloat):
      result = value.getFloat()
  elif T is bool:
    withStringFailover[T](value, JBool):
      result = value.getBool()
  elif T is string:
    if value.kind == JString:
      result = value.getStr()
    else: 
      result = parseAny[T]($value)
  elif T is varargs[string]:
    if (value.kind == JArray):
      newSeq(result, value.len)
      for i in value.len:
        result[i] = parseAny[string](value[i])
    else:
      result = value.to(T)
  else: 
    result = value.to(T)

proc addRequest*(request: string, callback: proc(values: JsonNode): string, jsSignature = "value") =
  ## This will register a function "callback" that can run on back-end.
  ## "addRequest" will be performed with "value" each time the javascript client calls:
  ## `window.ui.backend(request, value, function(response) {...})`
  ## with the specific "request" value.
  ## There are also overloaded functions for less or additional parameters
  ## There is a wrapper for python, C and C++ to handle strings in each specific programming language
  ## Notice for python: There is no check for correct function signature!
  {.gcsafe.}:
    reqMapStore[][request] = ReqFunction(nimCallback: callback, jsSignature: jsSignature)
    echo "Adding request " & request

proc addRequest*[T1, R](request: string, callback: proc(value1: T1): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 0:
        callback(parseAny[T1](values[0]))
      else:
        raise newException(ServerException, "Called request '" & request & "' needs to contain at least 1 argument"),
      name(T1))

proc addRequest*[T1, T2, R](request: string, callback: proc(value1: T1, value2: T2): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 1:
        callback(parseAny[T1](values[0]), parseAny[T2](values[1]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 2 arguments"),
      name(T1) & ", " & name(T2))

proc addRequest*[T1, T2, T3, R](request: string, callback: proc(value1: T1, value2: T2, value3: T3): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 2:
        callback(parseAny[T1](values[0]), parseAny[T2](values[1]), parseAny[T3](values[3]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 3 arguments"),
      name(T1) & ", " & name(T2) & ", " & name(T3))

proc addRequest*[T1, T2, T3, T4, R](request: string, callback: proc(value1: T1, value2: T2, value3: T4, value4: T4): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 3:
        callback(parseAny[T1](values[0]), parseAny[T2](values[1]), parseAny[T3](values[3]), parseAny[T4](values[4]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 4 arguments"),
      name(T1) & ", " & name(T2) & ", " & name(T3)", " & name(T4))

proc addRequest*(request: string, callback: proc(): string|void) =
  addRequest(request, proc (values: JsonNode): string = callback(), "")
  
#proc addRequest*(request: string, callback: proc(value: string): string|void) =
#  addRequest(request, proc (values: JsonNode): string = callback(parseAny[string](values[0])), "")

proc getRequests(): string =
  {.gcsafe.}:
    var requestSeq = newJArray()
    for key in reqMapStore[].keys:
      requestSeq.add(newJString(key))
      # result &= "window.backend[\"" & key & "\"] = function(" & value.jsSignature & "){};\n"
    return $requestSeq

proc getCallbackFunc*(request: string): proc(values: JsonNode): string =
  reqMapStore[].withValue(request, callbackFunc) do: # if request available, run request callbackFunc
    try:
      result = callbackFunc[].nimCallback
    except:
      raise newException(ServerException, "Server error calling request '" & 
        request & "': " & getCurrentExceptionMsg())
  do:
    raise newException(ReqUnknownException, "404 - Request unknown")

addRequest("getRequests", getRequests)