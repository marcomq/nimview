// Important Notice: You must use --threads:on AND you need to avoid --gc:arc ; I had crashes on windows otherwise with NIM 1.4 when starting webview

// nim c --verbosity:2  --threads:on -d:release -d:useStdLib --noMain --noLinking --header:nimview.h --nimcache=./tmp_c nimview.nim
// gcc -c -w -o tmp_c/c_sample.o -fmax-errors=3 -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -IC:\Users\Mmengelkoch\.nimble\pkgs\webview-0.1.0\webview -DWEBVIEW_WINAPI=1 -O3 -fno-strict-aliasing -fno-ident -IC:\Users\Mmengelkoch\.choosenim\toolchains\nim-1.4.2\lib -Itmp_c tests/c_sample.c
// gcc -w -o tests/c_sample.exe tmp_c/*.o -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32 -Itmp_c
// 
// nim cpp --threads:on --verbosity:2 -d:debug --debuginfo  --debugger:native -d:useStdLib --noMain --noLinking --header:nimview.h --nimcache=./tmp_c nimview.nim

// gcc -c -w -o tests/c_sample.o -c  -w -fmax-errors=3 -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -I/home/marco/.nimble/pkgs/webview-0.1.0/webview -DWEBVIEW_GTK=1 -I/usr/include/gtk-3.0 -I/usr/include/pango-1.0 -I/usr/include/glib-2.0 -I/usr/lib64/glib-2.0/include -I/usr/include/fribidi -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/uuid -I/usr/include/harfbuzz -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/gio-unix-2.0/ -I/usr/include/atk-1.0 -I/usr/include/at-spi2-atk/2.0 -I/usr/include/at-spi-2.0 -I/usr/include/dbus-1.0 -I/usr/lib64/dbus-1.0/include -I/usr/include/webkitgtk-4.0 -I/usr/include/libsoup-2.4 -pthread -I/usr/include/libxml2 -O3 -fno-strict-aliasing -fno-ident   -I/home/marco/.choosenim/toolchains/nim-1.4.2/lib -I/home/marco/apps/nimvue  -Itmp_c tests/c_sample.c
// gcc -w -o tests/c_sample tests/c_sample.o -L. -lnimview -lm -lrt -lwebkit2gtk-4.0 -lgtk-3 -lgdk-3 -lpangocairo-1.0 -lpango-1.0 -latk-1.0 -lcairo-gobject -lcairo -lgdk_pixbuf-2.0 -lsoup-2.4 -lgio-2.0 -ljavascriptcoregtk-4.0 -lgobject-2.0 -lglib-2.0    -ldl -Itmp_c 


// cp .\generated_c\nimview.h . 
// cd tests
// // g++ -o c_sample -Inimcache -IC:/Users/Mmengelkoch/.choosenim/toolchains/nim-1.4.2/lib -L../. -lnimview c_sample.c
// // g++.exe -c -w -o tmp_c/c_sample.o -std=gnu++14 -funsigned-char  -w -fmax-errors=3 -fpermissive -mno-ms-bitfields -DWIN32_LEAN_AND_MEAN -DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -IC:\Users\Mmengelkoch\.nimble\pkgs\webview-0.1.0\webview -DWEBVIEW_WINAPI=1 -g3 -Og   -IC:\Users\Mmengelkoch\.choosenim\toolchains\nim-1.4.2\lib -IE:\apps\nimview -Itmp_c tests/c_sample.cpp
#include "../tmp_c/nimview.h"
#include <stdio.h>
#include <stdlib.h>
// #include <iostream>
// extern void startWebviewC(char*);

char* appendSomething(char* something) {
    const char* appendString = " modified by C";
    char* result = malloc(strlen(something) + strlen(appendString) + 1); // +1 for the null-terminator, strlen is unchecked! "something" needs 0 termination
    if (result) {
        strcpy(result, something); // safe, result just created
        strcat(result, appendString); // safe, result just created with len
    }
    return result;
}
int main(int argc, char* argv[]) {
    printf(" starting c code\n");
    NimMain();
    
    nimview_addRequest("appendSomething", appendSomething, free);
    nimview_start("vue/dist/index.html");
    // nimview_startJester("vue/dist/index.html", 8000, "localhost");
}
