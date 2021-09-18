#include <jni.h>
#include <string>
#include <string.h>
#include "App.h"
#include "nimview.hpp"
#include <android/log.h>

JNIEnv* myEnv = NULL;
jobject* myCppWrapper = NULL;

#define THIS_PROJECT_PREFIX Java_com_nimviewAndroid
extern "C" JNIEXPORT jstring JNICALL
Java_com_nimviewAndroid_CppWrapper_callNim(
        JNIEnv* env,
        jobject self,
        jstring request, jstring value) {
    myEnv = env;
    myCppWrapper = &self;
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

void webviewEvalJs(char* js) {
    jclass javaClass = myEnv->FindClass("com/nimviewAndroid/CppWrapper");
    jmethodID evaluateJavascript = myEnv->GetMethodID(javaClass, "evaluateJavascript",
                                              "(Ljava/lang/String;)V");
    jstring jstr = myEnv->NewStringUTF(js);
    myEnv->CallVoidMethod(*myCppWrapper, evaluateJavascript, jstr);
    myEnv->DeleteLocalRef(jstr);
};

extern "C" JNIEXPORT void JNICALL
Java_com_nimviewAndroid_CppWrapper_initCallFrontentJs(JNIEnv* env, jobject self) {
    nimview::setCustomJsEval(webviewEvalJs);
    myEnv = env;
    myCppWrapper = &self;
}
