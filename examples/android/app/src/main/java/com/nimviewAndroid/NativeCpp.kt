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
            // val responseId = jsonMessage.getInt("responseId")
            val request = jsonMessage.getString("request")
            var value = jsonMessage.getString("value")
            if (value == "") {
                value = jsonMessage.getJSONObject("value").toString()
            }
            var result = this.callNim(request, value)
            // val evalJsCode = "window.ui.applyResponse('" + result.replace("\\", "\\\\").replace("\'", "\\'") + "'," + responseId + ");"
            // this.mAppView?.evaluateJavascript(evalJsCode, null)
            return result // .replace("\\", "\\\\").replace("\'", "\\'")
        }
        catch (e: Exception) {
            // do nothing
        }
        return ""
    }

}
