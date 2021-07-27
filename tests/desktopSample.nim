# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

discard """
  action: "compile"
"""
import ../src/nimview

nimview.addRequest("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Webview Backend")
nimview.startDesktop("../examples/minimal/dist/index.html")