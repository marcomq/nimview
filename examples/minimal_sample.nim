# Nimview UI Library 
# Copyright (C) 2020, 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import ../nimview

nimview.addRequest("echoAndModify", proc (value: string): string =
  echo "From Frontend: " & value
  result = "'" & value & "' modified by Backend")
nimview.start("../examples/minimal_ui_sample/index.html")