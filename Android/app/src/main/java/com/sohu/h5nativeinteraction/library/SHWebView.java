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
    private HashMap<String, SHWebViewOnH5Response> callbackMap = new HashMap<>();

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

    /*
    * H5 调用 Native 的唯一出口，这个方法必须声明为 public 的！
    * "method" ： H5 要调用 Native 的方法
    * "handler" ：H5 发给 Native 的回执
    * "invokeTest" ： 测试下 Native 是否支持了某个方法
    * */
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

                        SHWebSendH5Response callBack = new SHWebSendH5Response() {
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

                    SHWebViewOnH5Response handler = callbackMap.get(methodName);

                    if (null != handler){
                        handler.on(ps);
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
     * @param handler 接收到H5的参数，还有给 H5发送回执的接口
     */
    public void registerMethod(String method,SHWebNativeHandler handler) {
        if ((method.length() > 0) && (null != handler)) {
            this.methodHandlerMap.put(method,handler);
        }
    }

    /**
     * @param method H5调用的方法名
     * @param data 传递给H5的参数
     * @param response 给H5发送回执
     */
    public void callH5Method(String method,JSONObject data,SHWebViewOnH5Response response){
        if ((method.length() > 0) && (null != response)){
            this.callbackMap.put(method,response);
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

    /*
    * 通过该接口向 H5 发送回执
    * */
    public interface SHWebSendH5Response{
        void send(JSONObject ps);
    }

    /*
    * Native 注册方法的回调，当 H5 调用了 Native 之后，这个回调就会走；
    * 可以使用 callback 发给 H5 一个回执
    * */
    public interface SHWebNativeHandler{
        void on(JSONObject ps,SHWebSendH5Response callback);
    }

    /*
    * Native调用H5之后，H5通过这个接口给个回执
    * */
    public interface SHWebViewOnH5Response{
        void on(JSONObject ps);
    }

}