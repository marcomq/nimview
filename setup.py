#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import setuptools
from setuptools import setup, dist, Extension
from setuptools.command.install import install
from subprocess import check_call
import os
from os.path import isfile, join
from shutil import copy

with open('README.md', encoding='utf-8') as f:
    long_description = f.read()

this_directory = os.path.abspath(os.path.dirname(__file__))
targetDir = "nimview"


class PostInstallCommand(install):
    """Pre-installation for installation mode."""
    def run(self):
        check_call("nimble pyLib".split())
        print("install")
        
        libFiles = [ "out/nimview.so", "out/nimview.pyd"]
        for fileName in libFiles:
            fullFileName = os.path.join(this_directory, fileName)
            if os.path.isfile(fullFileName):
                copy(fullFileName, targetDir)

        install.run(self)

# create another nimview subfolder as setup.py is much friendlier if you do so
os.makedirs("nimview", exist_ok=True)
srcFiles = [ "nimview.nim", "nimview.nimble", "backend-helper.js", "LICENSE", "README.md"]
for fileName in srcFiles:
    fullFileName = os.path.join(this_directory, fileName)
    if os.path.isfile(fullFileName):
        copy(fullFileName, "nimview")

with open("nimview/__init__.py", "w") as text_file:
    text_file.write("from nimview import nimview")

setup(
    name="nimview",
    author="Marco Mengelkoch",
    description = "A lightwight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of Desktop applications based on a HTML/CSS/JS layer that is displayed with Webview.",
    long_description = long_description,
    long_description_content_type='text/markdown',
    version="0.1.0",
    url="https://github.com/marcomq/nimview",
    license='MIT',
    classifiers=[
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
    ],
    # include_package_data=True,
    # distclass = BinaryDistribution,
    cmdclass={
        'install': PostInstallCommand,
    },
    packages=["nimview"],
    # ext_modules=nimporter.build_nim_extensions(exclude_dirs=["tests", "examples"]),

    package_data={
    	"nimview": ["*.nim*", "*.so", "*.pyd", "nimview.nimble", "backend-helper.js", "LICENSE"]
    },
    install_requires=[
        "choosenim_install"  # Auto-installs Nim compiler
    ]
)
