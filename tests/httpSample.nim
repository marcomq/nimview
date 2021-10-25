discard """
  action: "compile"
  cmd: "nim $target -f --hints:on -d:testing $file"
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

addRequest("appendSomething5", proc (value: string, number: int, number2: int): string =
    echo value & $number
    result = "'" & value & $number & $number2 & "' modified by Web Backend"
)

addRequest("appendSomething6", proc (value: string, number: int, number2: int) =
    echo value & $number & $number2
)

addRequest("appendSomething7", proc (number: int, number2: int): int =
    echo $number & $number2
    result = number + number2
)

addRequest("appendSomething8", proc (value: string, value2: string, number: int, number2: int): int =
    echo value & $number & $number2 & value2
    result = number + number2
)

proc main() =
    startHttpServer("../examples/minimal/dist/index.html")

when isMainModule:
  main()