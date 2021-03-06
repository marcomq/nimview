#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# nimble pyLib
# python bdist_wheel.py  bdist_wheel --plat-name win-amd64
# python bdist_wheel.py  bdist_wheel --plat-name linux-x86_64
from setuptools import setup, Distribution
import os
from shutil import copy, rmtree

this_directory = os.path.abspath(os.path.dirname(__file__))
targetDir = "nimview"
rmtree(targetDir, ignore_errors=True)
os.makedirs(targetDir, exist_ok=True)
if os.name == 'nt':
    fileName = "out/nimview.pyd"
    package = ["nimview.pyd"]
else:
    fileName = "out/nimview.so"
    package = ["nimview.so"]
fullFileName = os.path.join(this_directory, fileName)
if os.path.isfile(fullFileName):
    print("copy " + fullFileName + " => " + targetDir)
    copy(fullFileName, targetDir)

with open(targetDir + "/__init__.py", "w") as text_file:
    text_file.write("from nimview.nimview import *")

class BinaryDistribution(Distribution):
    """Distribution which always forces a binary package with platform name"""
    def has_ext_modules(self):
        return False

setup(
    distclass=BinaryDistribution,
    package_data={
    	"nimview": package
    }
)

