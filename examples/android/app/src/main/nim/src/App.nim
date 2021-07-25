import nimview, os

var storageFile = "storage.json"

when defined androidNDK:
  let sdCard = os.getenv("EXTERNAL_STORAGE", "/sdcard")
  storageFile = sdCard & "/storage.json"
  
enableStorage(storageFile) # adds getStoredVal and setStoredVal
when not defined(just_core):
  start()