package com.sohu.h5nativeinteraction.library;

import android.content.Context;
import android.os.Build;
import android.util.AttributeSet;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebSettings;
import android.webkit.WebView;

import org.json.JSONObject;
import java.util.HashMap;

/**
 * Created by qianlongxu on 2017/11/10.
 */

public class SHWebView extends WebView {

    private HashMap<String, SHWebNativeHandler> methodHandlerMap = new HashMap<>();
    private HashMap<String, SHWebResponseCallback> callbackMap = new HashMap<>();

    public SHWebView(Context context) {
        super(context);
        this.init();
    }

    public SHWebView(Context context, AttributeSet attrs) {
        super(context, attrs);
        this.init();
    }

    private void init() {
        this.initWebSettings();
//        this.addJavascriptInterface(this,"shNativeObject");
        this.setWebViewClient(new SHWebViewClient(this.getContext()));
//        this.setWebChromeClient(new SHWebViewClient(this.getContext()));
    }

    private void initWebSettings() {
        WebSettings settings = this.getSettings();
        try {
            settings.setSupportZoom(false);
            settings.setBuiltInZoomControls(false);
            settings.setDefaultTextEncodingName("utf-8");
            settings.setDomStorageEnabled(true);
            settings.setJavaScriptCanOpenWindowsAutomatically(true);
            settings.setJavaScriptEnabled(true);
            ///....
        } catch (Exception e) {

        }
    }


    private void invokeH5(final String jsq){
        post(new Runnable() {
            @Override
            public void run() {
                try {
                    //在4.4以前使用“.loadUrl”，4.4之后使用“.evaluateJavascript”
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        evaluateJavascript("javascript:window.shJSBridge.invokeH5(" + jsq + ")", new
                                ValueCallback<String>() {
                                    @Override
                                    public void onReceiveValue(String value) {

                                    }
                                });
                    } else {
                        loadUrl("javascript:window.shJSBridge.invokeH5(" +
                                jsq + ")");
                    }
                } catch (Exception e) {

                }
            }
        });
    }

    @JavascriptInterface
    public void h5InvokeNative(String jsonString){
        if (null != jsonString && !jsonString.isEmpty()){
            try {
                JSONObject jsonObject = new JSONObject(jsonString);
                final String type = jsonObject.optString("type");
                JSONObject jsonMessage = jsonObject.optJSONObject("message");
                final String methodName = jsonMessage.optString("method");
                JSONObject ps = jsonMessage.optJSONObject("data");

                if ("method".equals(type)) {
                    SHWebNativeHandler handler = methodHandlerMap.get(methodName);
                    if (null != handler){

                        SHWebResponseCallback callBack = new SHWebResponseCallback() {
                            @Override
                            public void send(JSONObject ps) {

                                try {
                                    JSONObject result = new JSONObject();

                                    JSONObject message = new JSONObject();
                                    message.put("method", methodName);
                                    message.put("data", ps);

                                    result.put("message", message);
                                    result.put("type", "handler");
                                    final String jsq = result.toString();
                                    invokeH5(jsq);
                                }catch (Exception e){

                                }

                            }
                        };

                        handler.on(ps,callBack);
                    }
                } else if ("handler".equals(type)) {

                    SHWebResponseCallback handler = callbackMap.get(methodName);

                    if (null != handler){
                        handler.send(ps);
                    }
                } else if ("invokeTest".equals(type)) {

                    final String data = methodHandlerMap.containsKey(methodName) ? "1" : "0";
                    try {
                        JSONObject result = new JSONObject();

                        JSONObject message = new JSONObject();
                        message.put("method", methodName);
                        message.put("data", data);

                        result.put("message", message);
                        result.put("type", "handler");
                        final String jsq = result.toString();
                        invokeH5(jsq);
                    }catch (Exception e){

                    }

                }
            }catch (Exception e){

            }
        }
    }

    /**
     * @param method H5调用的方法名
     * @param handler 接收到H5的参数,在主线程回调
     */
    public void registerMethod(String method,SHWebNativeHandler handler) {
        if ((method.length() > 0) && (null != handler)) {
            this.methodHandlerMap.put(method,handler);
        }
    }

    public void callH5Method(String method,JSONObject data,SHWebResponseCallback responseCallback){
        if ((method.length() > 0) && (null != responseCallback)){
            this.callbackMap.put(method,responseCallback);
            try {
                JSONObject result = new JSONObject();

                JSONObject message = new JSONObject();
                message.put("method", method);
                message.put("data", data);

                result.put("message", message);
                result.put("type", "method");
                final String jsq = result.toString();
                invokeH5(jsq);
            }catch (Exception e){

            }
        }
    }

    public interface SHWebResponseCallback{
        void send(JSONObject ps);
    }

    public interface SHWebNativeHandler{
        void on(JSONObject ps,SHWebResponseCallback callback);
    }

}