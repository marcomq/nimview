# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details

# pylint: disable=import-error
import __init__, nimview
def echoAndModify(value):
    print (value)
    return (value + " appended by python")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.useServer = True
nimview.start("minimal_ui_sample/index.html") # current dir needs to be relative to this