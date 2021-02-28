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

# create another nimview subfolder as setup.py is much friendlier if you do so
rmtree(targetDir, ignore_errors=True)
os.makedirs(targetDir, exist_ok=True)

libFiles = [ "out/nimview.so", "out/nimview.pyd"]
for fileName in libFiles:
    fullFileName = os.path.join(this_directory, fileName)
    if os.path.isfile(fullFileName):
        print("copy " + fullFileName + " => " + targetDir)
        copy(fullFileName, targetDir)

class BinaryDistribution(Distribution):
    """Distribution which always forces a binary package with platform name"""
    def has_ext_modules(self):
        return False

setup(
    distclass=BinaryDistribution,
    package_data={
    	"nimview": ["nimview.so", "nimview.pyd"]
    }
)
