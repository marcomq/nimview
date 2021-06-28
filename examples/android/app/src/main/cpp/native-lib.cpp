#include <jni.h>
#include <string>
#include <string.h>
#include "custom_nimview.h"
#include "nimview.hpp"

#define THIS_PROJECT_PREFIX Java_com_nimviewAndroid
extern "C" JNIEXPORT jstring JNICALL
Java_com_nimviewAndroid_NativeCpp_callNim(
        JNIEnv* env,
        jobject /* this */, jstring request, jstring value) {
    char* cRequest = const_cast<char*>(env->GetStringUTFChars(request, nullptr));
    char* cValue = const_cast<char*>(env->GetStringUTFChars(value, nullptr));
    std::string result(nimview::dispatchRequest(cRequest, cValue));
    env->ReleaseStringUTFChars(request, cRequest);
    env->ReleaseStringUTFChars(value, cValue);
    return env->NewStringUTF(result.c_str());
}
