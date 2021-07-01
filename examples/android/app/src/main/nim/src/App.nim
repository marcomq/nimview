import nimview, os

when isMainModule:
  var sdCard = os.getenv("EXTERNAL_STORAGE", "/sdcard")
  enableStorage(sdCard & "/storage.json") # adds getStoredVal and setStoredVal
  when not defined(just_core):
    start()