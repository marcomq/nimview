package com.nimviewAndroid
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONObject

public class CppWrapper {
private
    var myWebview: WebView? = null
    var myMainActivity: AppCompatActivity? = null
    fun init(appView: WebView?, mainActivity: AppCompatActivity?) {
        this.myWebview = appView
        this.myMainActivity = mainActivity
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
        myMainActivity?.runOnUiThread(Runnable {
            myWebview?.evaluateJavascript(command, null)
        })
        // System.out.println("javscript done..");
        // this.myWebview?.loadUrl("javascript:" + command)
    }

    @SuppressWarnings("unused")
    @android.webkit.JavascriptInterface
    fun call(command: String) {
        try {
            val jsonMessage = JSONObject(command)
            val request = jsonMessage.getString("request")
            var data = jsonMessage.getString("data")
            var requestId = jsonMessage.getInt("requestId")
            myWebview?.post(Runnable {
                var result = this.callNim(request, data)
                evaluateJavascript("window.ui.applyResponse(" + requestId.toString() + ",'"
                 + result.replace("\\", "\\\\").replace("\'", "\\'")
                 + "');")
            })

            // var result = this.callNim(request, data)
            // evaluateJavascript("window.ui.applyResponse(" + requestId.toString() + ",'"
            //        + result.replace("\\", "\\\\").replace("\'", "\\'")
            //        + "');")

        }
        catch (e: Exception) {
            println(e.toString())
        }
    }

}
