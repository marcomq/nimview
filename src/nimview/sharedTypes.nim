# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview
import json
type ReqDeniedException* = object of CatchableError
type ServerException* = object of CatchableError
type ReqUnknownException* = object of CatchableError
type ReqFunction* = object
  nimCallback*: proc (values: JsonNode): string
  jsSignature*: string