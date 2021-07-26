import nimview, os

var storageFile = "storage.json"

enableStorage(storageFile) # adds getStoredVal and setStoredVal
when not defined(just_core):
  start()