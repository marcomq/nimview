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
#include <variant>

#ifdef _MSC_VER 
#define strdup _strdup
#endif
#define addRequest(a,b) addRequestImpl<__COUNTER__>(a,b) 

typedef void (*requestFunction)(const char*);

template<typename Lambda>
union FunctionStorage {
    FunctionStorage() {}
    std::decay_t<Lambda> lambdaFunction = NULL;
    ~FunctionStorage() {}
};


template<size_t COUNTER, typename Lambda, typename Result, typename... Args>
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

template<size_t COUNTER, typename Fn = char* (char*), typename Lambda>
Fn* castToFunction(Lambda&& memberFunction) {
    return FunctionPointerWrapper<COUNTER>(std::forward<Lambda>(memberFunction), (Fn*)nullptr);
}

namespace nimview {
    template<size_t COUNTER>
    void addRequestImpl(const std::string& request, const std::function<std::string(const std::string&)> &callback) {
        auto lambda = [&, callback](char* input) {
            std::string result;
            result.swap(callback(input));
            if (result == "") {
                return const_cast<char*>(result.c_str()); // "" will not be freed
            }
            else {
                return strdup(result.c_str());
            }
        };
        auto cFunc = castToFunction<COUNTER>(lambda);
        nimview_addRequest(const_cast<char*>(request.c_str()), cFunc, free);
    }
    auto nimMain = NimMain;
    auto start = nimview_start;
    auto startJester = nimview_startJester;
    auto startWebview = nimview_startWebview;
    auto dispatchRequest = nimview_dispatchRequest;
    auto dispatchCommandLineArg = nimview_dispatchCommandLineArg;
    auto readAndParseJsonCmdFile = nimview_readAndParseJsonCmdFile;
    
}
