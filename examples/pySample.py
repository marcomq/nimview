# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details

# pylint: disable=import-error
import __init__, nimview, json
def echoAndModify(value):
    print (value)
    return json.dumps({"val": value + " appended by python"})

nimview.setUseServer(True)
nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("minimal_ui_sample/index.html") # current dir needs to be relative to this