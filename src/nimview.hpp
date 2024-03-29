/** Nimview UI Library 
 * Copyright (C) 2020, 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/
#pragma once
#ifndef NIMVIEW_CUSTOM_LIB
extern "C" {
#include "nimview.h"
}
#endif
#include <string>
#include <sstream>
#include <iostream>
#include <map>
#include <type_traits>
#include <utility>
#include <functional>
#include <stdlib.h>
#ifdef _MSC_VER 
#include <variant>
#endif


namespace nimview {
    typedef std::function<char*(int argc, char** argv)> requestFunction;
    std::map<std::string, requestFunction> requestMap;

    thread_local bool nimInitialized = false;
    
    void nimMain() {
        if (!nimInitialized) {
            ::NimMain();
            nimInitialized = true;
        }
    }

    template <typename T>
    T lexicalCast(const char* str) {
        T var;
        std::istringstream iss;
        iss.str(str);
        iss >> var;
        return var;
    }

    template <>
    std::string lexicalCast(const char* str) {
        return std::string(str);
    }
    
    template <>
    char* lexicalCast(const char* str) {
        return const_cast<char*>(str);
    }

    template <>
    const char* lexicalCast(const char* str) {
        return str;
    }    
    
    template <typename T>
    std::string typeName() {
        return "value";
    }

    template<> std::string typeName<const char*>() {
        return "cstring";
    }

    template <> std::string typeName<int_least64_t>() {
        return "int";
    }   

    template <> std::string typeName<int>() {
        return "int";
    }   
    
    template <> std::string typeName<std::string>() {
        return "string";
    }

    template <> std::string typeName<double>() {
        return "double";
    }

    char* findAndCall(int argc, char** argv) {
        try {
            if (argc <= 1) {
                throw std::runtime_error("No function arguments");
            }
            auto reqIter = requestMap.find(argv[0]);
            if (reqIter == requestMap.end()) {
                throw std::runtime_error("Request '" + std::string(argv[0]) + "' not found");
            }
            auto foundFunction = reqIter->second;
            return foundFunction(argc, argv);
        }
        catch (std::runtime_error &e) {
            std::cerr << "error in callback: " + std::string(e.what()) << std::endl;
            return "";
        }
    }

    char* strToNewCharPtr(const std::string &strVal) {
        if (strVal == "") {
            return const_cast<char*>(""); // "" will not be freed
        }
        else {
            char* newChars = static_cast<char*>(calloc(strVal.length() + 1, 1));
            strVal.copy(newChars, strVal.length());
            return newChars;
        }
    }

    char* strToNewCharPtr(void) {
        return const_cast<char*>("");
    }

    template <typename R, typename ... Types> 
    constexpr size_t getArgumentCount(R(*f)(Types ...)) {
        return sizeof...(Types);
    }

    template<typename T1, typename T2, typename T3, typename T4> 
    void addt(const std::string &request, const std::function<std::string(T1, T2, T3, T4)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 4) {
                throw std::runtime_error("Less than 4 arguments");
            }
            auto result = callback(lexicalCast<T1>(argv[1]), lexicalCast<T2>(argv[2]), lexicalCast<T3>(argv[3]), lexicalCast<T4>(argv[4]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        std::string signature = typeName<T1>() + ", " + typeName<T2>() + ", " + typeName<T3>() + ", " + typeName<T4>();
        nimview_add_argc_argv_rstr(const_cast<char*>(request.c_str()), 
            findAndCall, free, const_cast<char*>(signature.c_str()));
    }
    
    template<typename T1, typename T2, typename T3> 
    void add(const std::string &request, const std::function<std::string(T1, T2, T3)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 3) {
                throw std::runtime_error("Less than 3 arguments");
            }
            auto result = callback(lexicalCast<T1>(argv[1]), lexicalCast<T2>(argv[2]), lexicalCast<T3>(argv[3]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        std::string signature = typeName<T1>() + ", " + typeName<T2>() + ", " + typeName<T3>();
        nimview_add_argc_argv_rstr(const_cast<char*>(request.c_str()), 
            findAndCall, free, const_cast<char*>(signature.c_str()));
    }
    
    template<typename T1, typename T2> 
    void add(const std::string &request, const std::function<std::string(T1, T2)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 2) {
                throw std::runtime_error("Less than 2 arguments");
            }
            auto result = callback(lexicalCast<T1>(argv[1]), lexicalCast<T2>(argv[2]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        std::string signature = typeName<T1>() + ", " + typeName<T2>();
        nimview_add_argc_argv_rstr(const_cast<char*>(request.c_str()), 
            findAndCall, free, const_cast<char*>(signature.c_str()));
    }  

    template<typename T1> 
    void add(const std::string &request, const std::function<std::string(T1)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 1) {
                throw std::runtime_error("Less than 1 argument");
            }
            auto result = callback(lexicalCast<T1>(argv[1]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        std::string signature = typeName<T1>();
        nimview_add_argc_argv_rstr(const_cast<char*>(request.c_str()), 
            findAndCall, free, const_cast<char*>(signature.c_str()));
    }

    void add(const std::string &request, const std::function<std::string(void)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            return strToNewCharPtr(callback());
        };
        requestMap.insert(std::make_pair(request, lambda));
        nimview_add_argc_argv_rstr(const_cast<char*>(request.c_str()), findAndCall, free, "void");
    }

#ifndef JUST_CORE
    void startDesktop(const char* folder, const char* title = "nimview", int width = 640, int height = 480, bool resizable = true, bool debug = false, bool run = true)  {
        nimMain();
        ::nimview_startDesktop(const_cast<char*>(folder), const_cast<char*>(title), width, height, resizable, debug, run);
    };
    void startHttpServer(const char* folder, int port = 8000, const char* bindAddr = "localhost", bool run = true)  { 
        nimMain();
        ::nimview_startHttpServer(const_cast<char*>(folder), port, const_cast<char*>(bindAddr), run);
    };
    void start(const char* folder, int port = 8000, const char* bindAddr = "localhost", const char* title = "nimview", int width = 640, int height = 480, bool resizable = true, bool debug = false, bool run = true)  {
        nimMain();
        #ifdef _WIN32
            bool runWithGui = true;
        #else
            bool runWithGui = (NULL != getenv("DISPLAY"));
        #endif
        #ifdef _DEBUG
            runWithGui = false;
        #endif
        if (runWithGui) {
            nimview::startDesktop(folder, title, width, height, resizable, debug, run);
        }
        else {
            nimview::startHttpServer(folder, port, bindAddr, run);
        }
    }
    void init(const char* folder, int port = 8000, const char* bindAddr = "localhost", const char* title = "nimview", int width = 640, int height = 480, bool resizable = true, bool debug = false) {
        start(folder, port, bindAddr, title, width, height, resizable, debug);
    }
    auto stopHttpServer = ::nimview_stopHttpServer;
    auto stopDesktop = ::nimview_stopDesktop;
    auto stop = ::nimview_stop;
#endif
    char* dispatchRequest(char* request, char* value) {
        nimMain();
        return ::nimview_dispatchRequest(request, value);
    };
    std::string dispatchRequest(const std::string &request, const std::string &value) {
        nimMain();
        // free of return value should be performed by nim gc
        return ::nimview_dispatchRequest(const_cast<char*>(request.c_str()), const_cast<char*>(value.c_str())); 
    };
    auto dispatchCommandLineArg = ::nimview_dispatchCommandLineArg;
    auto readAndParseJsonCmdFile = ::nimview_readAndParseJsonCmdFile;
    void enableStorage(const std::string &fileName = "storage.js") {
        ::nimview_enableStorage(const_cast<char*>(fileName.c_str()));
    }
    void callJs(const std::string &functionName, const std::string &args) {
        ::nimview_callJs(const_cast<char*>(functionName.c_str()), const_cast<char*>(args.c_str())); 
    }
    auto callFrontendJs = callJs;
    auto setCustomJsEval = ::nimview_setCustomJsEval;
    auto add_void = ::nimview_add;
    auto add_rstr = ::nimview_add_rstr;
    auto add_cstring = ::nimview_add_cstring;
    auto add_cstring_rstr = ::nimview_add_cstring_rstr;
    auto add_clonglong = ::nimview_add_clonglong;
    auto add_clonglong_rstr = ::nimview_add_clonglong_rstr;
    auto add_cdouble = ::nimview_add_cdouble;
    auto add_cdouble_rstr = ::nimview_add_cdouble_rstr;    
    auto add_argc_argv_rstr = ::nimview_add_argc_argv_rstr;  
    // deprecated start
    auto addRequest_void = ::nimview_add;
    auto addRequest_rstr = ::nimview_add_rstr;
    auto addRequest_cstring = ::nimview_add_cstring;
    auto addRequest_cstring_rstr = ::nimview_add_cstring_rstr;
    auto addRequest_clonglong = ::nimview_add_clonglong;
    auto addRequest_clonglong_rstr = ::nimview_add_clonglong_rstr;
    auto addRequest_cdouble = ::nimview_add_cdouble;
    auto addRequest_cdouble_rstr = ::nimview_add_cdouble_rstr;    
    auto addRequest_argc_argv_rstr = ::nimview_add_argc_argv_rstr; 
    // deprecated end     
}
