// nim c --verbosity:2 -d:release -d:useStdLib --header:nimview.h --app:lib --out:nimview.dll --nimcache=./generated_c nimview.nim
// cp .\generated_c\nimview.h . 
// cd tests
// g++ -o c_sample -Inimcache -IC:/Users/Mmengelkoch/.choosenim/toolchains/nim-1.4.2/lib -L../. -lnimview c_sample.c
// nim cpp --verbosity:2 -d:debug --debuginfo  --debugger:native -d:useStdLib --noMain -d:noMain --noLinking --header:nimview.h --nimcache=./tmp_c --gc:arc nimview.nim
// g++.exe -c -w -o tmp_c/c_sample.o -std=gnu++14 -funsigned-char  -w -fmax-errors=3 -fpermissive -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -IC:\Users\Mmengelkoch\.nimble\pkgs\webview-0.1.0\webview -DWEBVIEW_WINAPI=1 -g3 -Og   -IC:\Users\Mmengelkoch\.choosenim\toolchains\nim-1.4.2\lib -IE:\apps\nimview -Itmp_c tests/c_sample.cpp

// nim c --verbosity:2 -d:release -d:useStdLib --noMain:on -d:noMain --app:staticlib --header:nimview.h --nimcache=./tmp_c nimview.nim
// g++ -c -w -o tests/cpp_sample.o -fmax-errors=3 -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -DWEBVIEW_WINAPI=1 -O3 -fno-strict-aliasing -fno-ident -IC:\Users\Mmengelkoch\.nimble\pkgs\webview-0.1.0\webview -IC:\Users\Mmengelkoch\.choosenim\toolchains\nim-1.4.2\lib -Itmp_c .\tests\cpp_sample.cpp
// g++ -w -o tests/cpp_sample.exe tests/cpp_sample.o -L. -lnimview -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32 -Itmp_c

// nim c --verbosity:2 -d:release -d:useStdLib --noMain:on -d:noMain --noLinking:on --header:nimview.h --nimcache=./tmp_c nimview.nim 
//         gcc -shared -o nimview.dll -Wl,--out-implib,libnimview.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive tmp_c/*.o -Wl,--no-whole-archive -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32 
// cmd /c "gcc -shared -o tests/nimview.dll -Wl,--out-implib,tests/libnimview.a-Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive tmp_c/*.o -Wl,--no-whole-archive -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32"
#include <iostream>
#include <stdio.h>
#include <string.h>

extern "C" {
#include "../tmp_c/nimview.h"
}

#ifdef _MSC_VER 
#define strdup _strdup
#endif

char* echoAndModify(char* something) {
    std::string result = std::string(something) + " appended to string";
    return strdup(result.c_str());
}

int main(int argc, char* argv[]) {
    NimMain();
    nimview_addRequest("echoAndModify", echoAndModify, free);
#ifdef _DEBUG
    nimview_startJester("minimal_ui_sample/index.html", 8000, "localhost");
#else
    $(OutDir)cpp_sample_debug.exe("minimal_ui_sample/index.html");
#endif
}