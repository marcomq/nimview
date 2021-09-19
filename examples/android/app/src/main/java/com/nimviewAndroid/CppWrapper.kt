package com.nimviewAndroid
import android.webkit.WebView
import org.json.JSONObject

public class CppWrapper {
private var myWebview: WebView? = null
    fun init(appView: WebView?) {
        this.myWebview = appView
        this.initCallFrontentJs()
    }
    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    @SuppressWarnings("unused")
    external fun callNim(request: String, value: String): String

    external fun initCallFrontentJs()

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

    fun evaluateJavascript(command: String) {
        this.myWebview?.evaluateJavascript(command, null)
        // this.myWebview?.loadUrl("javascript:" + command)
        // this.myWebview?.evaluateJavascript("alert(9)", null)
    }

}
