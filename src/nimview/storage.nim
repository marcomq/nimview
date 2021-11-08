# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

## Implements a simple key / value store that can be used to store preferences
import strutils, os
import std/[json, jsonutils]
import tables, locks
import globals

proc initStorage*(fileName: string = "") =
  try:
    if fileName != "":
      nimviewVars.storageFile = fileName
    if os.fileExists(nimviewVars.storageFile):
      var storageString = system.readFile(nimviewVars.storageFile)
      if not storageString.isEmptyOrWhitespace():
        nimviewVars.storage = storageString.parseJson().jsonTo(typeof nimviewVars.storage)
        echo storageString
  except:
    echo "Couldn't read storage"

proc getStoredVal*(key: string): string =
  try:
    result = nimviewVars.storage[key]
  except KeyError:
    discard

proc setStoredVal*(key, value: string): string = 
  if value == "":
    nimviewVars.storage.del(key)
  else:
    nimviewVars.storage[key] = value 
  try:
    var jsonOutput: JsonNode
    jsonOutput = nimviewVars.storage.toJson()
    system.writeFile(nimviewVars.storageFile, $jsonOutput)
  except:
    echo "error setting storage key '" & key & "': " & getCurrentExceptionMsg()
