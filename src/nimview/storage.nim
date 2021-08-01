# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

## Implements a simple key / value store that can be used to store preferences
import strutils, os
import std/[json, jsonutils]
import tables, locks

var storageLock: Lock
initLock storageLock
var storage {.guard: storageLock.} = Table[string, string]()
var storageFile: string = "storage.json"

proc initStorage*(fileName: string = "") =
  try:
    if fileName != "":
      storageFile = fileName
    if os.fileExists(storageFile):
      var storageString = system.readFile(storageFile)
      if not storageString.isEmptyOrWhitespace():
        withLock storageLock:
          storage = storageString.parseJson().jsonTo(typeof storage)
          echo storageString
  except:
    echo "Couldn't read storage"

proc getStoredVal*(key: string): string =
  try:
    withLock storageLock:
      result = storage[key]
  except KeyError:
    discard

proc setStoredVal*(key, value: string): string = 
  withLock storageLock:
    if value == "":
      storage.del(key)
    else:
      storage[key] = value 
  try:
    var storageCopy: Table[string, string]
    withLock storageLock:
      {.gcsafe.}:
        storageCopy = deepCopy(storage)
    let jsonOutput: JsonNode = storageCopy.toJson()
    system.writeFile(storageFile, $jsonOutput)
  except:
    echo "error setting storage key '" & key & "': " & getCurrentExceptionMsg()
