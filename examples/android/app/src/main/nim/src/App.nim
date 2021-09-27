import nimview, os

var storageFile = "storage.json"
var sdCard = os.getenv("EXTERNAL_STORAGE", "/sdcard")

enableStorage(sdCard / storageFile) # adds getStoredVal and setStoredVal

proc countDown() =
  callFrontendJs("alert", "waiting 6 seconds")
  sleep(2000)
  callFrontendJs("alert", "4")
  sleep(3000)
  callFrontendJs("alert", "1")
  sleep(1000)

addRequest("countDown", countDown)

when not defined(just_core):
  start()