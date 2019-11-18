#include <jni.h>

const char *BITMARK_API_KEY = "bitmark-api-key-to-be-filled";

extern "C"
JNIEXPORT jstring JNICALL
Java_com_bitmark_fbm_keymanagement_ApiKeyManager_getBitmarkApiKey(JNIEnv *env,
                                                                       jobject instance) {
    return env->NewStringUTF(BITMARK_API_KEY);
}