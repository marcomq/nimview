#include <jni.h>
#include <string>
#include <string.h>
#include "App.h"
#include "nimview.hpp"
#include <android/log.h>

jint myJniVersion;
JavaVM* myJvm = NULL;
jobject* myCppWrapper = NULL;
jmethodID myEvaljsFunc;

#define THIS_PROJECT_PREFIX Java_com_nimviewAndroid
extern "C" JNIEXPORT jstring JNICALL
Java_com_nimviewAndroid_CppWrapper_callNim(
        JNIEnv* env,
        jobject self,
        jstring request, jstring value) {
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
    // this doesn't seem to call javascript for some reason and crashes on 2nd call
    return;
    JNIEnv* env = NULL;
    jint rs = myJvm->GetEnv((void **)&env, myJniVersion);
    assert (rs == JNI_OK);
    jstring jstr = env->NewStringUTF(js);
    env->CallVoidMethod(*myCppWrapper, myEvaljsFunc, jstr);
    env->DeleteLocalRef(jstr);
};

extern "C" JNIEXPORT void JNICALL
Java_com_nimviewAndroid_CppWrapper_initCallFrontentJs(JNIEnv* env, jobject self) {
    nimview::setCustomJsEval(webviewEvalJs);
    myCppWrapper = &self;
    myJniVersion = env->GetVersion();
    jclass javaClass = env->FindClass("com/nimviewAndroid/CppWrapper");
    myEvaljsFunc = env->GetMethodID(javaClass, "evaluateJavascript",
                                            "(Ljava/lang/String;)V");
    jint rs = env->GetJavaVM(&myJvm);
    assert (rs == JNI_OK);
}
