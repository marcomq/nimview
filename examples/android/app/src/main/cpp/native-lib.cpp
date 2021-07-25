#include <jni.h>
#include <string>
#include <string.h>
#include "App.h"
#include "nimview.hpp"
#include <android/log.h>

#define THIS_PROJECT_PREFIX Java_com_nimviewAndroid
extern "C" JNIEXPORT jstring JNICALL
Java_com_nimviewAndroid_NativeCpp_callNim(
        JNIEnv* env,
        jobject /* this */, jstring request, jstring value) {
    const char* cRequest = env->GetStringUTFChars(request, nullptr);
    const char* cValue = env->GetStringUTFChars(value, nullptr);
    std::string result;
    try {
        result = nimview::dispatchRequest(std::string(cRequest), std::string(cValue));
    }
    catch(...) {
        __android_log_write(ANDROID_LOG_ERROR, "Nimview", ("Exception during request " + std::string(cRequest)).c_str());
    }
    env->ReleaseStringUTFChars(request, cRequest);
    env->ReleaseStringUTFChars(value, cValue);
    return env->NewStringUTF(result.c_str());
}
