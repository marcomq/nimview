package com.nimviewAndroid
import android.webkit.WebView
import org.json.JSONObject

public class NativeCpp {
private var mAppView: WebView? = null
    fun init(appView: WebView?) {
        this.mAppView = appView
    }
    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    @SuppressWarnings("unused")
    external fun callNim(request: String, value: String): String

    @SuppressWarnings("unused")
    @android.webkit.JavascriptInterface
    fun call(command: String): String {
        try {
            val jsonMessage = JSONObject(command)
            val request = jsonMessage.getString("request")
            var data = jsonMessage.getString("data")
            var result = this.callNim(request, data)
            return result // .replace("\\", "\\\\").replace("\'", "\\'")
        }
        catch (e: Exception) {
            // do nothing
        }
        return ""
    }

}
