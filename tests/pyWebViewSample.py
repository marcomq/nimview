#!/usr/bin/env python3
# pylint: disable=no-member
import nimview
import os, time
import threading

def threadedWait1():
    try:
        global thread
        thread = threading.Thread(target = asyncWait1, daemon=None)
        thread.start()
    except:
        print ("some other error")
        raise()
    return ("")

def asyncWait1():
    try:
        print ("wait 1 start")
        time.sleep(1)
        print ("wait 1 running")
        time.sleep(1)
        print ("wait 1 still running")
        time.sleep(1)
        print ("wait 1 still running")
        time.sleep(5)
        print ("wait 1 end")
    except:
        print ("some error")
        raise()
    return ("")

def wait2():
    print ("wait 2 start")
    time.sleep(2)
    print ("wait 2 end")
    return ("")

def wait():
    time.sleep(0.002)
    return ("")

nimview.addRequest("asyncWait1", threadedWait1)
nimview.addRequest("wait2", wait2)
nimview.addRequest("wait", wait)
nimview.startDesktop("asyncPy/index.html")
thread.join()
# threadedWait1()
# asyncWait2()
# time.sleep(29)