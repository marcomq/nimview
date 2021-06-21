# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import times, asynchttpserver, std/sysrand, base64, locks

var L: Lock
initLock(L)

type GlobalToken = object 
    token: array[32, byte]
    generated: times.DateTime


# generate 3 tokens that rotate
var tokens: array[3, GlobalToken]

for i in 0..<tokens.len:
    tokens[i].generated = times.now() - 5.minutes

proc checkIfTokenExists(token: array[32, byte]): bool =
    # Very unlikely, but it may be necessary to also lock here
    for i in 0 ..< globalToken.tokens.len:
        if token == globalToken.tokens[i].token:
            return true
    return false

proc byteToString*(token: array[32, byte]): string = 
    result = base64.encode(token)

proc stringToByte*(token: string): array[32, byte] = 
    let tokenString = base64.decode(token)
    if (tokenString.len > 31):
        system.copyMem(result[0].addr, tokenString[0].unsafeAddr, 32)
    else: 
        raise newException(CatchableError, "token too short")

proc checkToken*(headers: HttpHeaders): bool = 
    var headerToken: string 
    if headers.hasKey("global-token"):
        headerToken = $headers["global-token"]
    if headerToken.len > 31:
        var headerTokenArray = globalToken.stringToByte(headerToken)
        return globalToken.checkIfTokenExists(headerTokenArray)
    return false

proc getFreshToken*(): array[32, byte] =
    var currentTime = times.now()
    const interval = 60
    let frame = (currentTime.minute * 60 + currentTime.second).div(interval) mod tokens.len # a new token every interval seconds
    var currentToken = addr globalToken.tokens[frame]
    var tokenPlusInterval = currentTime - interval.seconds
    try:
        if currentToken[].generated.isInitialized():
            tokenPlusInterval = currentToken[].generated + interval.seconds
    except:
        discard
    withLock(L):    
        if tokenPlusInterval < currentTime: 
            let randomValue = sysrand.urandom(32)
            for i in 0 ..< randomValue.len:
                result[i] = randomValue[i]
            currentToken[].generated = currentTime
            currentToken[].token = result
        result = currentToken[].token
