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
// #define addRequest(...) addRequestImpl(__VA_ARGS__) 
// #define addRequest(...) addRequestImpl<__COUNTER__, std::string>(__VA_ARGS__) 

typedef std::function<char*(int argc, char** argv)> requestFunction;
std::map<std::string, requestFunction> requestMap;

template<typename Lambda>
union FunctionStorage {
    FunctionStorage() {};
    std::decay_t<Lambda> lambdaFunction;
    ~FunctionStorage() {};
};


template<const char* PLACEHOLDER, typename Lambda, typename Result, typename... Args>
auto functionPointerWrapper(Lambda&& callback, Result(*)(Args...)) {
    static FunctionStorage<Lambda> storage;
    using type = decltype(storage.lambdaFunction);

    static bool used = false;
    if (used) {
        storage.lambdaFunction.~type(); // overwrite
    }
    new (&storage.lambdaFunction) type(std::forward<Lambda>(callback));
    used = true;

    return [](Args... args)->Result {
        return Result(storage.lambdaFunction(std::forward<Args>(args)...));
    };
}

template<const char* PLACEHOLDER, typename Fn = char* (int argc, char** argv), typename Lambda>
Fn* castToFunction(Lambda&& memberFunction) {
    return functionPointerWrapper<PLACEHOLDER>(std::forward<Lambda>(memberFunction), (Fn*)nullptr);
}

namespace nimview {
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

    
    template<size_t pos = 1, typename R, typename T>
    char* callFunction(R(*callback)(T), char** argv) {
        return strToNewCharPtr(callback(lexicalCast<T>(argv[1])));
    }

    template <typename R, typename ... Types> 
    constexpr size_t getArgumentCount(R(*f)(Types ...)) {
        return sizeof...(Types);
    }

    template<typename T1, typename T2, typename T3, typename T4> 
    void addRequest(const std::string &request, const std::function<std::string(T1, T2, T3, T4)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 4) {
                throw std::runtime_error("Less than 4 arguments");
            }
            auto result = callback(lexicalCast<T1>(argv[1]), lexicalCast<T2>(argv[2]), lexicalCast<T3>(argv[3]), lexicalCast<T4>(argv[4]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        nimview_addRequest_argc_argv_rstr(const_cast<char*>(request.c_str()), findAndCall, free);
    }
    
    template<typename T1, typename T2, typename T3> 
    void addRequest(const std::string &request, const std::function<std::string(T1, T2, T3)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 3) {
                throw std::runtime_error("Less than 3 arguments");
            }
            auto result = callback(lexicalCast<T1>(argv[1]), lexicalCast<T2>(argv[2]), lexicalCast<T3>(argv[3]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        nimview_addRequest_argc_argv_rstr(const_cast<char*>(request.c_str()), findAndCall, free);
    }
    
    template<typename T1, typename T2> 
    void addRequest(const std::string &request, const std::function<std::string(T1, T2)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 2) {
                throw std::runtime_error("Less than 2 arguments");
            }
            auto result = callback(lexicalCast<T1>(argv[1]), lexicalCast<T2>(argv[2]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        nimview_addRequest_argc_argv_rstr(const_cast<char*>(request.c_str()), findAndCall, free);
    }  

    template<typename T1> 
    void addRequest(const std::string &request, const std::function<std::string(T1)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            if (argc <= 1) {
                throw std::runtime_error("Less than 1 argument");
            }
            auto result = callback(lexicalCast<T1>(argv[1]));
            return strToNewCharPtr(result);
        };
        requestMap.insert(std::make_pair(request, lambda));
        nimview_addRequest_argc_argv_rstr(const_cast<char*>(request.c_str()), findAndCall, free);
    }

    void addRequest(const std::string &request, const std::function<std::string(void)> &callback) {
        requestFunction lambda = [&, callback](int argc, char** argv) {
            return strToNewCharPtr(callback());
        };
        requestMap.insert(std::make_pair(request, lambda));
        nimview_addRequest_argc_argv_rstr(const_cast<char*>(request.c_str()), findAndCall, free);
    }

#ifndef JUST_CORE
    void startDesktop(const char* folder, const char* title = "nimview", int width = 640, int height = 480, bool resizable = true, bool debug = false)  {
        nimMain();
        ::nimview_startDesktop(const_cast<char*>(folder), const_cast<char*>(title), width, height, resizable, debug);
    };
    void startHttpServer(const char* folder, int port = 8000, const char* bindAddr = "localhost")  { 
        nimMain();
        ::nimview_startHttpServer(const_cast<char*>(folder), port, const_cast<char*>(bindAddr));
    };
    void start(const char* folder, int port = 8000, const char* bindAddr = "localhost", const char* title = "nimview", int width = 640, int height = 480, bool resizable = true)  {
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
            nimview::startDesktop(folder, title, width, height, resizable, false);
        }
        else {
            nimview::startHttpServer(folder, port, bindAddr);
        }
    }
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
    auto enableStorage = ::nimview_enableStorage;
    auto stopHttpServer = ::nimview_stopHttpServer;
    auto stopDesktop = ::nimview_stopDesktop;
    auto addRequest_void = ::nimview_addRequest;
    auto addRequest_rstr = ::nimview_addRequest_rstr;
    auto addRequest_cstring = ::nimview_addRequest_cstring;
    auto addRequest_cstring_rstr = ::nimview_addRequest_cstring_rstr;
    auto addRequest_clonglong = ::nimview_addRequest_clonglong;
    auto addRequest_clonglong_rstr = ::nimview_addRequest_clonglong_rstr;
    auto addRequest_cdouble = ::nimview_addRequest_cdouble;
    auto addRequest_cdouble_rstr = ::nimview_addRequest_cdouble_rstr;    
    auto addRequest_argc_argv_rstr = ::nimview_addRequest_argc_argv_rstr;    
}
