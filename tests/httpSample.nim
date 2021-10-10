discard """
  action: "compile"
"""
import ../src/nimview

addRequest("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Web Backend"
)

addRequest("appendSomething2", proc (value: string) =
    echo value
)

addRequest("appendSomething3", proc (value: string, number: int) =
    echo value & $number
)

addRequest("appendSomething4", proc (value: string, number: int): string =
    echo value & $number
    result = "'" & value & $number & "' modified by Web Backend"
)

startHttpServer("../examples/minimal/dist/index.html")