discard """
  action: "compile"
"""
import macros

block:
    proc hello() =
        echo "nice to see youi"

proc defInBlock[T, U](a:T, b:U) = echo a, b

macro defInBlock(a, s: string, n: untyped): untyped =
    expectKind(n, nnkStmtList)
    let body = n
    body.add(newCall("hello2"))
    result = newBlockStmt(body)
    echo repr result

defInBlock("waht", "api"):
    proc hello2() =
        echo "echo hello2"

# hello2()