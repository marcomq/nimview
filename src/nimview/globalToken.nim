# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import times, asynchttpserver, std/sysrand, base64
when compileOption("threads"):
    import locks

type Token = object 
    token: array[32, byte]
    generated: times.DateTime

type GlobalTokens* = object
    ## 3 tokens that rotate
    tokens*: array[3, Token]
    when compileOption("threads"):
        tokensLock*: Lock

proc init*(): GlobalTokens =
    var self: GlobalTokens
    when compileOption("threads"):
        initLock(self.tokensLock)
    for i in 0 ..< self.tokens.len:
        self.tokens[i].generated = times.now() - 5.minutes

proc checkIfTokenExists(self: GlobalTokens, token: array[32, byte]): bool =
    # Very unlikely, but it may be necessary to also lock here
    for i in 0 ..< self.tokens.len:
        if token == self.tokens[i].token:
            return true
    return false

proc byteToString*(token: array[32, byte]): string = 
    result = base64.encode(token)

func stringToByte*(token: string): array[32, byte] = 
    let tokenString = base64.decode(token)
    if (tokenString.len > 31):
        system.copyMem(result[0].addr, tokenString[0].unsafeAddr, 32)
    else: 
        raise newException(CatchableError, "token too short")

proc checkToken*(self: GlobalTokens, headers: HttpHeaders): bool = 
    var headerToken: string 
    if headers.hasKey("global-token"):
        headerToken = $headers["global-token"]
    if headerToken.len > 31:
        var headerGlobalTokens = globalToken.stringToByte(headerToken)
        return self.checkIfTokenExists(headerGlobalTokens)
    return false

proc getFreshToken*(self: var GlobalTokens): array[32, byte] =
    var currentTime = times.now()
    const interval = 60
    let frame = (currentTime.minute * 60 + currentTime.second).div(interval) mod self.tokens.len # a new token every interval seconds
    var currentToken = addr self.tokens[frame]
    var tokenPlusInterval = currentTime - interval.seconds
    try:
        if currentToken[].generated.isInitialized():
            tokenPlusInterval = currentToken[].generated + interval.seconds
    except:
        discard
    when compileOption("threads"):
        acquire(self.tokensLock)
    try:    
        if tokenPlusInterval < currentTime: 
            let randomValue = sysrand.urandom(32)
            for i in 0 ..< randomValue.len:
                result[i] = randomValue[i]
            currentToken[].generated = currentTime
            currentToken[].token = result
        result = currentToken[].token
    finally:
        when compileOption("threads"):
            release(self.tokensLock)