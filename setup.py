#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import setuptools
from setuptools import setup, dist, Extension
from setuptools.command.build_ext import build_ext
from subprocess import check_call
import os
from os.path import isfile, join
from shutil import copy, rmtree

with open('README.md', encoding='utf-8') as f:
    long_description = f.read()

this_directory = os.path.abspath(os.path.dirname(__file__))
targetDir = "nimview"

# create another nimview subfolder as setup.py is much friendlier if you do so
try:
    rmtree(targetDir)
except:
    pass
os.makedirs(targetDir, exist_ok=True)
srcFiles = [ "nimview.nim", "nimview.nimble", "backend-helper.js", "LICENSE", "README.md"]
for fileName in srcFiles:
    fullFileName = os.path.join(this_directory, fileName)
    if os.path.isfile(fullFileName):
        copy(fullFileName, targetDir)

# with open(targetDir + "/__init__.py", "w") as text_file:
#    text_file.write("from nimview import nimview")

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
        if not os.path.exists(self.build_temp):
            os.makedirs(self.build_temp)
        
        extdir = self.get_ext_fullpath(ext.name)
        if not os.path.exists(extdir):
            os.makedirs(extdir)

        for fileName in srcFiles:
            fullFileName = os.path.join(this_directory, fileName)
            if os.path.isfile(fullFileName):
                print("copy " + fullFileName + " => " + self.build_temp)
                copy(fullFileName, self.build_temp)

        check_call(['nimble', 'install', '-d'], cwd=self.build_temp)
        check_call(['nimble', 'pyLib'], cwd=self.build_temp)
        libFiles = [ "out/nimview.so", "out/nimview.pyd"]
        install_target = os.path.abspath(os.path.dirname(extdir))

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
    # packages=setuptools.find_packages(exclude=["examples", "tests", "dist", "build", "docs"]),
    # ext_modules=nimporter.build_nim_extensions(exclude_dirs=["tests", "examples"]),
    # include_package_data=True,
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
