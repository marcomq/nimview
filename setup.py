#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# python setup.py sdist
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from subprocess import check_call
import os
from shutil import copy, rmtree
this_directory = os.path.abspath(os.path.dirname(__file__))
targetDir = "nimview"

# create another nimview subfolder as setup.py is much friendlier if you do so
rmtree(targetDir, ignore_errors=True)
os.makedirs(targetDir, exist_ok=True)
os.makedirs(targetDir + "/src", exist_ok=True)
srcFiles = [ "src/nimview.nim", "src/backend-helper.js", "nimview.nimble", "LICENSE", "README.md"]
for index, fileName in enumerate(srcFiles):
    fullFileName = os.path.join(this_directory, fileName)
    if os.path.isfile(fullFileName):
        copy(fullFileName, targetDir + "/" + fileName)

    
class NimExtension(Extension):
    def __init__(self, name, sourcedir=''):
        Extension.__init__(self, name, sources=[])
        self.sourcedir = os.path.abspath(sourcedir)

class NimBuild(build_ext):
    def run(self):
        for ext in self.extensions:
            self.build_extension(ext)

    def build_extension(self, ext):
        print("=> build_extension")
        os.makedirs(self.build_temp, exist_ok=True)
        os.makedirs(self.build_temp + "/src", exist_ok=True)
        
        extdir = self.get_ext_fullpath(ext.name)
        os.makedirs(extdir + "/src", exist_ok=True)

        for fileName in srcFiles:
            fullFileName = os.path.join(targetDir, fileName)
            if os.path.isfile(fullFileName):
                target = self.build_temp + "/" + fileName
                print("copy " + fullFileName + " => " + target)
                copy(fullFileName, target)

        check_call(['nimble', 'install', '-d -y --noSSLCheck '], cwd=self.build_temp)
        check_call(['nimble', 'pyLib'], cwd=self.build_temp)
        libFiles = [ "out/nimview.so", "out/nimview.pyd"]
        install_target = os.path.abspath(os.path.dirname(extdir))
        os.makedirs(install_target + "/src", exist_ok=True)

        for fileName in libFiles:
            fullFileName = os.path.join(self.build_temp, fileName)
            if os.path.isfile(fullFileName):
                print("copy " + fullFileName + " => " + install_target)
                copy(fullFileName, install_target)

setup(
    ext_modules=[NimExtension('.')],
    cmdclass={
        'build_ext': NimBuild,
    },
    package_data={
    	"nimview": srcFiles + ["nimview.so", "nimview.pyd"]
    },
    install_requires=[
        "choosenim_install"  # Auto-installs Nim compiler
    ]
)
