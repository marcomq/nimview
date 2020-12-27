#!/usr/bin/env python3
import nimvue
import os 
dirPath = os.path.dirname(os.path.realpath(__file__))
nimvue.startWebview(dirPath + "/../ui/dist/index.html")