/** Nimview UI Library 
 * Copyright (C) 2020, 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/

#include <iostream>
#include <string>
#include "nimview.hpp"

std::string echoAndModify2(const std::string &something) {
    return (something + " appended to string");
}

std::string echoAndModify(const std::string& something) {
    return (something + " appended 2 string");
}

std::string echoAndModify3(std::string something) {
    std::cout << (something + " appended 2 string") << std::endl;
}


void echoAndModify4(const std::string& something) {
    std::cout << (something + " appended 2 string") << std::endl;
}


int main(int argc, char* argv[]) {
    nimview::nimMain();
    nimview::enableStorage();
    nimview::addRequest<std::string>("echoAndModify", echoAndModify2);
    // nimview::addRequest<std::string>("echoAndModify2", echoAndModify2);
    // nimview::addRequest<std::string>("appendSomething", echoAndModify2);
    // nimview::start(("../dist/index.html", 8000, "localhost");
    nimview::startDesktop("../dist/index.html");
    // nimview::startHttpServer("../dist/index.html", 8000, "localhost");
}