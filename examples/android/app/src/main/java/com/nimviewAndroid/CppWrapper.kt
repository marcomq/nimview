package com.nimviewAndroid
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import java.util.concurrent.Executors
import org.json.JSONObject

public class CppWrapper {
private
    var myWebview: WebView
    var myMainActivity: AppCompatActivity
    val myNimThread = Executors.newFixedThreadPool(1) // always use the same thread for nim
    constructor(appView: WebView, mainActivity: AppCompatActivity) {
        this.myWebview = appView
        this.myMainActivity = mainActivity
        this.myNimThread.execute({
            this.initCallFrontentJs()
        })
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
        this.myMainActivity.runOnUiThread(Runnable {
            this.myWebview.evaluateJavascript(command, null)
        })
    }

    @SuppressWarnings("unused")
    @android.webkit.JavascriptInterface
    fun call(command: String) {
        try {
            val jsonMessage = JSONObject(command)
            val request = jsonMessage.getString("request")
            var data = jsonMessage.getString("data")
            var requestId = jsonMessage.getInt("requestId")
            this.myNimThread.execute({
                var result = this.callNim(request, data)
                this.evaluateJavascript("window.ui.applyResponse(" + requestId.toString() + ",'"
                 + result.replace("\\", "\\\\").replace("\'", "\\'")
                 + "');")
            })
        }
        catch (e: Exception) {
            println(e.toString())
        }
    }

}
