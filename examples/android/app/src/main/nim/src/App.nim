import nimview

when isMainModule:
  enableStorage() # adds getStoredVal and setStoredVal
  when not defined(just_core):
    nimview.start()