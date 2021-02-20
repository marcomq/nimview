# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details

# pylint: disable=import-error
import nimview
def echoAndModify(value):
    print (value)
    return (value + " appended by python")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("tests/minimal_ui_sample/index.html")