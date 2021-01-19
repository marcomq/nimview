
extern "C" {
#include "nimview.h"
}
#include <string>
#include<type_traits>
#include<utility>
#include<functional>

#ifdef _MSC_VER 
#define strdup _strdup
#endif
#define addRequest(a,b) addRequestImpl<__COUNTER__>(a,b) 

typedef void (*requestFunction)(const char*);

template<typename Lambda>
union FunctionStorage {
    FunctionStorage() {}
    std::decay_t<Lambda> lambdaFunction = NULL;
};

template<size_t COUNTER, typename Lambda, typename Result, typename... Args>
auto FunctionPointerWrapper(Lambda&& c, Result(*)(Args...)) {
    static bool used = false;
    static FunctionStorage<Lambda> storage;
    using type = decltype(storage.lambdaFunction);

    if (used) {
        storage.lambdaFunction.~type();
    }
    new (&storage.lambdaFunction) type(std::forward<Lambda>(c));
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
    void addRequestImpl(const std::string& request, std::string(callback)(const std::string&)) {
        auto i = 1;
        auto lambda = [&, callback](char* input) {
            return strdup(callback(input).c_str());
        };
        auto cFunc = castToFunction<COUNTER>(lambda);
        nimview_addRequest(const_cast<char*>(request.c_str()), cFunc, free);
    }
    auto startJester = nimview_startJester;
    auto startWebview = nimview_startWebview;
    auto initGc = NimMain;
}
