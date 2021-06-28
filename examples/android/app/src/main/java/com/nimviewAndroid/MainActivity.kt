package com.nimviewAndroid

import android.os.Bundle
import android.view.Window
import android.webkit.JsResult
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.annotation.NonNull
import androidx.appcompat.app.AppCompatActivity


class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    override fun onCreate(savedInstanceState: Bundle?) {
        this.requestWindowFeature(Window.FEATURE_NO_TITLE)
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        this.getSupportActionBar()?.hide()

        webView = findViewById(R.id.webview)
        /* webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                if(Uri.parse(url).getHost().isNullOrEmpty()) {
                    return false;
                }
                view?.loadUrl(url)
                return true
            }
        }*/
        val settings = webView.getSettings()
        settings.setJavaScriptEnabled(true)
        settings.setDomStorageEnabled(true)
        var nativeCpp = NativeCpp()
        webView.addJavascriptInterface(nativeCpp, "backend")
        webView.webChromeClient = object : WebChromeClient() {
            //Other methods for your WebChromeClient here, if needed..
            override fun onJsAlert(
                view: WebView,
                url: String,
                message: String,
                result: JsResult
            ): Boolean {
                return super.onJsAlert(view, url, message, result)
            }
        }
        nativeCpp.init(webView)
        webView.loadUrl("file:///android_asset/index.html");

    }

    companion object {
        // Used to load the 'native-lib' library on application startup.
        init {
            System.loadLibrary("native-lib")
        }
    }
}
