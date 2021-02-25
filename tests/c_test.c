/** Nimview UI Library 
 * Copyright (C) 2020, 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/
// Important Notice: You should use --threads:on AND you need to avoid --gc:arc ; I had crashes on windows otherwise with NIM 1.4 when starting webview

#include "../out/tmp_c/nimview.h"
#include <stdio.h>
#include <stdlib.h>

char* echoAndModify(char* something) {
    const char* appendString = " modified by C";
    char* result = malloc(strlen(something) + strlen(appendString) + 1); // +1 for the null-terminator, strlen is unchecked! "something" needs 0 termination
    if (result) {
        strcpy(result, something); // safe, result just created
        strcat(result, appendString); // safe, result just created with len
    }
    else {
        return ""; // "" will not be freed
    }
    return result;
}

char* stopNimview(char* something) {
    nimview_stopDesktop();
    return "";
}
int main(int argc, char* argv[]) {
    printf(" starting c code\n");
    NimMain();
    nimview_addRequest("echoAndModify", echoAndModify, free);
    nimview_addRequest("stopNimview", stopNimview, free);
    
    nimview_dispatchCommandLineArg("{\"request\":\"echoAndModify\",\"value\":\"this is a test\",\"responseId\":0,\"responseKey\":\"test\"}");
    nimview_dispatchCommandLineArg("{\"request\":\"stopNimview\",\"value\":\"\",\"responseId\":1,\"responseKey\":\"test\"}");
    return 0;
}
