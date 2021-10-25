# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import strformat, typetraits
import logging
import json, macros, tables, strutils
import sharedTypes

type ReqFunction* = object
  nimCallback: proc (values: JsonNode): string
  jsSignature: string

var reqMapStore : Table[string, ReqFunction]

proc fromStr[T](value: string): T =
  when T is string:
    result = value
  elif T is JsonNode:
    result = json.parseJsonvalue(value)
  elif T is bool:
    result = strUtils.parseBool(value)
  elif T is enum:
    result = strUtils.parseEnum(value)
  elif T is (uint or cuint or csize_t):
    result = cast[T](strUtils.parseUInt(value))
  elif T is (int or cint or clonglong):
    result = cast[T](strUtils.parseInt(value))
  elif T is (float or cfloat or cdouble):
    result = cast[T](strUtils.parseFloat(value))
  # when T is array:
  #   result = strUtils.parseEnum(value)

template withStringFailover[T](value: JsonNode, jsonType: JsonNodeKind, body: untyped) =
    if value.kind == jsonType:
      body
    elif value.kind == JString:
      result = fromStr[T](getStr(value))
    else: 
      result = fromStr[T]($value)

proc parseAny*[T](value: JsonNode): T =
  when T is JsonNode:
    result = value
  elif T is (int or uint or cint or clonglong):
    withStringFailover[T](value, Jint):
      result = cast[T](value.getInt())
  elif T is (float or  cfloat or cdouble):
    withStringFailover[T](value, JFloat):
      result = value.getFloat()
  elif T is bool:
    withStringFailover[T](value, JBool):
      result = value.getBool()
  elif T is (string):
    if value.kind == JString:
      result = value.getStr()
    else: 
      result = $value
  elif T is (cstring):
    if value.kind == JString:
      result = value.getstr().cstring
    else: 
      result = ($value).cstring
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
    reqMapStore[request] = ReqFunction(nimCallback: callback, jsSignature: jsSignature)
    info "Adding request " & request

proc free_c(somePtr: pointer) {.cdecl, importc: "free".}

proc addRequest_argc_argv_rstr*(crequest: cstring, 
      callback: proc(argc: cint, argv: cstringArray): cstring {.cdecl.},
      freeFunc: proc(value: pointer) {.cdecl.} = free_c,
      signature: cstring = "argc, array") {.exportc: "nimview_$1".} =
    let request = $crequest
    addRequest(request, proc (values: JsonNode): string =
        var params = newSeq[string](values.len + 1)
        params[0] = request
        for i in 0 ..< values.len: 
          params[i + 1] = parseAny[string](values[i])
        var cParams = alloccstringArray(params)
        try:
          let resultPtr = callback((values.len + 1).cint, cParams)
          result = $resultPtr
          if resultPtr != "":
            freeFunc(resultPtr)
        except:
          logging.error "Internal error calling '" & request & "'"
        finally:
          deallocCStringArray(cParams)
      ,
      $signature)

macro generateCExportsForParams(exportParams: typed): untyped =
  ## Will create C functions addRequest... for given type
  result = newStmtList()
  let exportC = "{.exportc: \"nimview_$1\".}"
  let cdecl = "{.cdecl.}"
  var functionName = "addRequest"
  var functionParams = ""
  var callbackParams = ""
  var signature = ""
  for i, myType in exportParams:
    if i != 0:
      functionParams &= ","
      callbackParams &= ","
      signature &= ","
    functionName &= "_" & myType.strVal
    functionParams &= fmt"val{i}: {myType.strVal}"
    callbackParams &= fmt"parseAny[{myType.strVal}](values[{i}])"
    signature &= fmt"name({myType.strVal})"
  var procString: string 
  procString = &"""
    proc {functionName}(request: cstring, callback: proc({functionParams}) {cdecl}) {exportC} =
      addRequest($request, proc (values: JsonNode): string = 
          if values.len >= {exportParams.len}:
            callback({callbackParams})
          else:
            raise newException(ServerException, "Called request '" & $request & "' needs to contain at least {exportParams.len} arguments"),
        "{signature}")
    """
  result.add(parseStmt(procString))
  
  procString = &"""
    proc {functionName}_rstr(
        request: cstring, 
        callback: proc({functionParams}): cstring {cdecl}, 
        freeFunc: proc(value: pointer) {cdecl} = free_c) {exportC} =
      addRequest($request, proc (values: JsonNode): string = 
          if values.len >= {exportParams.len}:
            var resultPtr: cstring = ""
            try:
              resultPtr = callback({callbackParams})
              result = $resultPtr
            finally:
              if (resultPtr != ""):
                freeFunc(resultPtr)
          else:
            raise newException(ServerException, "Called request '" & $request & "' needs to contain at least {exportParams.len} arguments"),
        "{signature}")
    """
  result.add(parseStmt(procString))

macro generateCExports(exportParams: typed): untyped =
  ## factory to create C functions addRequest... for specific types
  result = newStmtList()
  var procString: string = "generateCExportsForParams([])"
  result.add(parseStmt(procString))
  for i in  0 ..< exportParams.len:
    procString = &"""
      generateCExportsForParams([{exportParams[i]}])
      """
    result.add(parseStmt(procString))
    for j in  0 ..< exportParams.len:
      procString = &"""
        generateCExportsForParams([{exportParams[i]}, {exportParams[j]}])
        """
      result.add(parseStmt(procString))

generateCExports([cstring, clonglong, cdouble])

# generateCExportsForParams([cint, cstring, cfloat])

#addRequestcintcstringcfloat("test", proc(val1: cint, val2: cstring, val3: cfloat) {.cdecl.} = echo "42")

proc addRequest*[T1, R](request: string, callback: proc(value1: T1): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 0:
        $callback(parseAny[T1](values[0]))
      else:
        raise newException(ServerException, "Called request '" & request & "' needs to contain at least 1 argument"),
      name(T1))

proc addRequest*[T1](request: string, callback: proc(value1: T1): void) =
  addRequest[T1, string](request, proc(val1: T1): string = callback(val1))

proc addRequest*[T1, T2, R](request: string, callback: proc(value1: T1, value2: T2): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 1:
        $callback(parseAny[T1](values[0]), parseAny[T2](values[1]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 2 arguments"),
      name(T1) & ", " & name(T2))

proc addRequest*[T1, T2](request: string, callback: proc(value1: T1, value2: T2): void) =
  addRequest[T1, T2, string](request, proc(val1: T1, val2: T2): string = callback(val1, val2))

proc addRequest*[T1, T2, T3, R](request: string, callback: proc(value1: T1, value2: T2, value3: T3): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 2:
        $callback(parseAny[T1](values[0]), parseAny[T2](values[1]), parseAny[T3](values[2]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 3 arguments"),
      name(T1) & ", " & name(T2) & ", " & name(T3))

proc addRequest*[T1, T2, T3](request: string, callback: proc(value1: T1, value2: T2, value3: T3): void) =
  addRequest[T1, T2, T3, string](request, proc(val1: T1, val2: T2, val3: T3): string = callback(val1, val2, val3))

proc addRequest*[T1, T2, T3, T4, R](request: string, callback: proc(value1: T1, value2: T2, value3: T3, value4: T4): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 3:
        $callback(parseAny[T1](values[0]), parseAny[T2](values[1]), parseAny[T3](values[2]), parseAny[T4](values[3]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 4 arguments"),
      name(T1) & ", " & name(T2) & ", " & name(T3) & ", " & name(T4))

proc addRequest*[T1, T2, T3, T4](request: string, callback: proc(value1: T1, value2: T2, value3: T3, value4: T4): void) =
  addRequest[T1, T2, T3, T4, string](request, proc(val1: T1, val2: T2, val3: T3, val4: T4): string = callback(val1, val2, val3, val4))

proc addRequest*[T1, T2, T3, T4, T5, R](request: string, callback: proc(value1: T1, value2: T2, value3: T4, value4: T4, value5: T5): R) =
    addRequest(request, proc (values: JsonNode): string = 
      if values.len > 4:
        $callback(parseAny[T1](values[0]), parseAny[T2](values[1]), parseAny[T3](values[2]), parseAny[T4](values[3]), parseAny[T5](values[4]))
      else:
        raise newException(ServerException, "Called request '" & request & "' contains less than 5 arguments"),
      name(T1) & ", " & name(T2) & ", " & name(T3) & ", " & name(T4) & ", " & name(T5))

proc addRequest*[T1, T2, T3, T4, T5](request: string, callback: proc(value1: T1, value2: T2, value3: T3, value4: T4, value5: T5): void) =
  addRequest[T1, T2, T3, T4, T5, string](request, proc(val1: T1, val2: T2, val3: T3, val4: T4, val5: T5): string = callback(val1, val2, val3, val4, val5))

proc addRequest*(request: string, callback: proc(): string) =
  addRequest(request, proc (values: JsonNode): string = callback(), "")
  
proc addRequest*(request: string, callback: proc(): void) =
  addRequest(request, proc (values: JsonNode): string = callback(), "")

proc init*()
proc getRequests*(): string

proc getRequests*(): string =
  {.gcsafe.}:
    init()
    var requestSeq = newJArray()
    for key, value in reqMapStore:
      requestSeq.add(%* [key, value.jsSignature])
    return $requestSeq

proc getCallbackFunc*(request: string): proc(values: JsonNode): string =
  reqMapStore.withValue(request, callbackFunc) do: # if request available, run request callbackFunc
    try:
      result = callbackFunc[].nimCallback
    except:
      raise newException(ServerException, "Server error calling request '" & 
        request & "': " & getCurrentExceptionMsg())
  do:
    raise newException(ReqUnknownException, "404 - Request unknown")

proc init*() =
  if reqMapStore.len == 0:
    reqMapStore = Table[string, ReqFunction]()
    addRequest("getRequests", getRequests)
