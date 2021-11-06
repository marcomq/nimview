discard """
  matrix: "; -d:just_core; -d:useServer"
  action: "compile"
  cmd: "nim $target -f --hints:on -d:testing $file"
"""
import ../src/nimview

add("appendSomething", proc (value: string): string =
    echo value
    result = "'" & value & "' modified by Web Backend"
)

add("appendSomething2", proc (value: string) =
    echo value
)

add("appendSomething3", proc (value: string, number: int) =
    echo value & $number
)

add("appendSomething4", proc (value: string, number: int): string =
    echo value & $number
    result = "'" & value & $number & "' modified by Web Backend"
)

add("appendSomething5", proc (value: string, number: int, number2: int): string =
    echo value & $number
    result = "'" & value & $number & $number2 & "' modified by Web Backend"
)

add("appendSomething6", proc (value: string, number: int, number2: int) =
    echo value & $number & $number2
)

add("appendSomething7", proc (number: int, number2: int): int =
    echo $number & $number2
    result = number + number2
)

add("appendSomething8", proc (value: string, value2: string, number: int, number2: int): int =
    echo value & $number & $number2 & value2
    result = number + number2
)

proc main() =
    if not defined(just_core):
        startHttpServer("../examples/minimal/dist/index.html")

when isMainModule:
  main()