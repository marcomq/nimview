/** Nimview UI Library 
 * Copyright (C) 2020, 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/

#include <iostream>
#include <string>
#include "nimview.hpp"


std::string echoAndModify(const std::string& something) {
    return (something + " appended to string");
}

int main(int argc, char* argv[]) {
    nimview::nimMain();
    nimview::addRequest<std::string>("echoAndModify", echoAndModify);
    nimview::start("../dist/index.html", 8000, "localhost");
}