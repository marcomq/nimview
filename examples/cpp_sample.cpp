/** Nimview UI Library 
 * Copyright (C) 2020, 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/

#include <iostream>
#include "../nimview.hpp"

std::string echoAndModify(const std::string& something) {
    return (std::string(something) + " appended to string");
}

std::string echoAndModify2(const std::string& something) {
    return (std::string(something) + " appended 2 string");
}

int main(int argc, char* argv[]) {
    nimview::nimMain();
    nimview::addRequest("echoAndModify", echoAndModify);
    nimview::addRequest("echoAndModify2", echoAndModify2);
    nimview::addRequest("appendSomething", echoAndModify2);
    // nimview::start("../examples/svelte/public/index.html", 8000, "localhost");
    nimview::start("../examples/minimal_ui_sample/index.html", 8000, "localhost");
}