# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

# in case of issues with nimporter, just compile nimview manually in parent folder. 
# nimble c --app:lib -d:release -d:noMain --out:tests/nimview.so nimview.nim 
# nimble c --app:lib -d:release -d:noMain --out:tests/nimview.pyd nimview.nim # windows
# pylint: disable=no-member
import nimporter, nimview
def echoAndModify(value):
    print (value)
    return (value + " appended by python")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("minimal_ui_sample/index.html")