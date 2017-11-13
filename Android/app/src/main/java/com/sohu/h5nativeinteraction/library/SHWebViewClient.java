package com.sohu.h5nativeinteraction.library;

import android.content.Context;
import android.os.Build;
import android.util.Base64;
import android.util.Log;
import android.webkit.ValueCallback;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.IOException;
import java.io.InputStream;

/**
 * Created by qianlongxu on 2017/11/13.
 */

public class SHWebViewClient extends WebViewClient {

    protected Context mContext;

    public SHWebViewClient(Context context) {
        super();
        mContext = context;
    }

    @Override
    public void onPageFinished(WebView view, String url) {
        this.loadSHJs(view);
        super.onPageFinished(view, url);
    }

    private void loadSHJs(WebView view){
        try {
            if (mContext == null) return;
            InputStream input = mContext.getAssets().open("shwebview.js");
            byte[] buffer = new byte[input.available()];
            input.read(buffer);
            input.close();

            // String-ify the script byte-array using BASE64 encoding !!!
            String encoded = Base64.encodeToString(buffer, Base64.NO_WRAP);

            //注意区分版本.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
                view.evaluateJavascript("javascript:(function() {" + "var parent = document" + ""
                        + ".getElementsByTagName('head').item(0);" + "var script = document" + ""
                        + ".createElement('script');" + "script.type = 'text/javascript';" +
                        // Tell the browser to BASE64-decode the string into your script !!!
                        "script.innerHTML = window.atob('" + encoded + "');" + "parent" + "" + ""
                        + ".appendChild(script)" + "})()", new ValueCallback<String>() {
                    @Override
                    public void onReceiveValue(String value) {
                        //

                    }
                });
            } else {
                view.loadUrl("javascript:(function() {" + "var parent = document" + "" + "" + ""
                        + ".getElementsByTagName('head').item(0);" + "var script = document" + ""
                        + ".createElement('script');" + "script.type = 'text/javascript';" +
                        // Tell the browser to BASE64-decode the string into your script !!!
                        "script.innerHTML = window.atob('" + encoded + "');" + "parent" + "" + ""
                        + ".appendChild(script)" + "})()");
            }
        } catch (IOException e) {

        }
    }
}

