#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from subprocess import check_call
import os
from shutil import copy, rmtree

with open('README.md', encoding='utf-8') as f:
    long_description = f.read()

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

classifiers = [
        "Development Status :: 4 - Beta",
        "Natural Language :: English",
        "Operating System :: OS Independent",
        "Operating System :: POSIX :: Linux",
        "Operating System :: Microsoft :: Windows",
        "Operating System :: MacOS :: MacOS X",
        "Environment :: Console",
        "Environment :: Other Environment",
        "Intended Audience :: Developers",
        "Intended Audience :: Other Audience",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: Implementation :: CPython",
        "Topic :: Software Development"
    ]
    
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
    name="nimview",
    version="0.1.0",
    author="Marco Mengelkoch",
    description = "A lightwight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of Desktop applications based on a HTML/CSS/JS layer that is displayed with Webview.",
    long_description = long_description,
    long_description_content_type='text/markdown',
    url="https://github.com/marcomq/nimview",
    license='MIT',
    classifiers=classifiers,
    packages=["nimview"],
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
