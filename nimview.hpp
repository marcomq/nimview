/** Nimview UI Library 
 * Copyright (C) 2020, 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/

extern "C" {
#include "nimview.h"
}
#include <string>
#include<type_traits>
#include<utility>
#include<functional>
#include <stdlib.h>
#ifdef _MSC_VER 
#include <variant>
#endif
#define addRequest(a,b) addRequestImpl<__COUNTER__>(a,b) 

typedef void (*requestFunction)(const char*);

template<typename Lambda>
union FunctionStorage {
    FunctionStorage() {};
    std::decay_t<Lambda> lambdaFunction;
    ~FunctionStorage() {};
};


template<unsigned int COUNTER, typename Lambda, typename Result, typename... Args>
auto FunctionPointerWrapper(Lambda&& callback, Result(*)(Args...)) {
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

template<unsigned int COUNTER, typename Fn = char* (char*), typename Lambda>
Fn* castToFunction(Lambda&& memberFunction) {
    return FunctionPointerWrapper<COUNTER>(std::forward<Lambda>(memberFunction), (Fn*)nullptr);
}

namespace nimview {
    template<unsigned int COUNTER>
    void addRequestImpl(const std::string& request, const std::function<std::string(const std::string&)> &callback) {
        auto lambda = [&, callback](char* input) {
            std::string result = callback(input);
            if (result == "") {
                return const_cast<char*>(""); // "" will not be freed
            }
            else {
                char* newChars = static_cast<char*>(calloc(result.length() + 1, 1));
                result.copy(newChars, result.length());
                return newChars;
            }
        };
        auto cFunc = castToFunction<COUNTER>(lambda);
        nimview_addRequest(const_cast<char*>(request.c_str()), cFunc, free);
    }
    void start(const char* folder, int port = 8000, const char* bindAddr = "localhost", const char* title = "nimview", int width = 640, int height = 480, bool resizable = true)  {
        #ifdef _WIN32
            bool runWithGui = true;
        #else
            bool runWithGui = (NULL != getenv("DISPLAY"));
        #endif
        #ifdef _DEBUG
            runWithGui = false;
        #endif
        if (runWithGui) {
            nimview_startDesktop(const_cast<char*>(folder), const_cast<char*>(title), width, height, resizable, false);
        }
        else {
            nimview_startHttpServer(const_cast<char*>(folder), port, const_cast<char*>(bindAddr));
        }
    }
    void startDesktop(const char* folder, const char* title = "nimview", int width = 640, int height = 480, bool resizable = true, bool debug = false)  { 
        nimview_startDesktop(const_cast<char*>(folder), const_cast<char*>(title), width, height, resizable, debug);
    };
    void startHttpServer(const char* folder, int port = 8000, const char* bindAddr = "localhost")  { 
        nimview_startHttpServer(const_cast<char*>(folder), port, const_cast<char*>(bindAddr));
    };
    auto nimMain = NimMain;
    auto dispatchRequest = nimview_dispatchRequest;
    auto dispatchCommandLineArg = nimview_dispatchCommandLineArg;
    auto readAndParseJsonCmdFile = nimview_readAndParseJsonCmdFile;
    
}
