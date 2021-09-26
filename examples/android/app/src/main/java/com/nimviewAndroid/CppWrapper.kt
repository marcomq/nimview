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
    fun evaluateJavascript(command: String) {
        this.myWebview?.post(Runnable {
            this.myWebview?.evaluateJavascript(command, null)
        })
        // System.out.println("javscript done..");
        // this.myWebview?.loadUrl("javascript:" + command)
    }

    @SuppressWarnings("unused")
    @android.webkit.JavascriptInterface
    fun call(command: String): String {
        try {
            val jsonMessage = JSONObject(command)
            val request = jsonMessage.getString("request")
            var data = jsonMessage.getString("data")
            var requestId = jsonMessage.getInt("requestId")
            var result = this.callNim(request, data)
            // evaluateJavascript("window.ui.applyResponse(" + requestId.toString() + ",'"
            //        + result.replace("\\", "\\\\").replace("\'", "\\'")
            //        + "');")
            return result
        }
        catch (e: Exception) {
            return e.toString();
        }
        return ""
    }

}
