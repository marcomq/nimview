# Nimview UI Library 
# Copyright (C) 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview

import times, jester, std/sysrand, base64, locks

var L: Lock
initLock(L)
# generate 5 tokens that rotate
var tokens: array[5, tuple[
    token: array[32, byte], 
    generated: times.DateTime]]

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
    let frame = (currentTime.minute * 60 + currentTime.second).div(interval) mod 5 # a new token every interval seconds
    var currentToken = addr globalToken.tokens[frame]
    var tokenPlusInterval = currentTime - interval.seconds
    try:
        tokenPlusInterval = currentToken[].generated + interval.seconds
    except:
        discard
    withLock(L):    
        if tokenPlusInterval < currentTime: 
            let randomValue = sysrand.urandom(32)
            for i in 0 ..< randomValue.len:
                result[i] = randomValue[i]
            currentToken[].generated.swap(currentTime)
            currentToken[].token.swap(result)
        result = currentToken[].token
