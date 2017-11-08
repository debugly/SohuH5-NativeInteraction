//
//  SHWebViewJS.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

/*
 H5 使用 SDK 在 window 上挂载 shJSBridge 对象调用Native的方法；
 shJSBridge 是 SHJSBridge 的 js '对象'， SHJSBridge 是对方法参数等交互细节的封装，最终会调用 SDK 注入的交互对象 shNativeObject ！
 */

#import "SHWebViewJS.h"

NSString *SHWebView_JS(void){
    #define __js_func__(x) #x
    static NSString *js = @__js_func__(
                                       ;(function(){
        var SHJSBridge = {
            
            createNew : function(){
                
                var jsBridge = {};
                ///存储 H5 注册的方法；
                jsBridge.methodHandler = {};
                ///存储 H5 方法的回调callback，即H5调用Native后，通过此callback收到响应
                jsBridge.responseCallbacks = {};
                
                
                //----------------------H5 register method--------------------//
                
                jsBridge.registerMethod = function(handlerName, handler) {
                    this.methodHandler[handlerName] = handler;
                };
                ///之前叫这个名字；兼容老版本而已；
                jsBridge.registerHandler = function(handlerName, handler) {
                    this.methodHandler[handlerName] = handler;
                };
                //----------------------H5 invoke Native begin--------------------//
                
                jsBridge.doInvokeNative = function(type,message){
                    
                    // 把消息和消息类型封装成结构
                    var m = {};
                    m['type'] = type;
                    m['message'] = message;
                    
                    ///ios 可以接收 json 对象，安卓不行，因此统一传 json 串。
                    var str = JSON.stringify(m);
                    
                    //ios UIWebView and Android WebView
                    if(window.shNativeObject){
                        window.shNativeObject.h5InvokeNative(str);
                    }
                    //ios WKWebView
                    else if(window.webkit.messageHandlers.shNativeObject){
                        window.webkit.messageHandlers.shNativeObject.postMessage(str);
                    }else{
                        //alert
                    }
                };
                
                jsBridge.doSend = function(message, responseCallback) {
                    ///需要Native的回调,那么就把回调保存下
                    if (responseCallback) {
                        var method = message['method'];
                        this.responseCallbacks[method] = responseCallback;
                    }
                    this.doInvokeNative('Method',message);
                };
                
                ///支持可选参数
                jsBridge.invokeNative = function(handlerName, data, responseCallback){
                    var args = arguments.length;
                    if(args == 1){
                        this.doSend({ method:handlerName, ps:{} });
                    }else if (args == 2) {
                        if(typeof data == 'function'){
                            this.doSend({ method:handlerName, ps:{} },data);
                        }else{
                            this.doSend({ method:handlerName, ps:data });
                        }
                    }else if(args == 3){
                        this.doSend({ method:handlerName, ps:data }, responseCallback);
                    }
                };
                
                ///H5 试探方法能否被调用
                jsBridge.canInvokeNative = function(method,responseCallback){
                    
                    var m = {};
                    m['method'] = method;
                    m['ps'] = {};
                    if (responseCallback) {
                        this.responseCallbacks[method] = responseCallback;
                        window.shJSBridge.doInvokeNative('invokeTest',m);
                    }
                };
                
                //----------------------H5 invoke Native end--------------------//
                
                //----------------------Native invoke H5 begin--------------------//
                jsBridge.invokeH5 = function(m){
                    var type = m['type'];
                    var message = m['message'];
                    
                    if (type === 'method') {
                        this.invokeH5Method(message);
                    }else if(type === 'handler'){
                        this.invokeH5Handler(message);
                    }
                };
                
                ///调用注册的回调方法
                jsBridge.invokeH5Handler = function(message){
                    var handlerName = message['method'];
                    var json = message['data'];
                    var callback = this.responseCallbacks[handlerName];
                    
                    if(callback){
                        callback(json);
                    }
                };
                
                ///调用注册的H5方法
                jsBridge.invokeH5Method = function(message){
                    
                    var method = message['method'];
                    
                    ///寻找下H5有没有注册这个方法
                    var callback = this.methodHandler[method];
                    if(callback){
                        
                        var json = message['data'];
                        callback(json,function(data){
                            ///H5给Native一个回调；
                            var m = {};
                            m['method'] = method;
                            m['ps'] = data ? data : {};
                            window.shJSBridge.doInvokeNative('Handler',m);
                        });
                    }
                };
                
                //----------------------Native invoke H5 end--------------------//
                
                return jsBridge;
            }
        };
        
        function _callQFJSCallbacks() {
            var callbacks = window.shJSCallbacks;
            if(callbacks){
                for (var i=0; i<callbacks.length; i++) {
                    callbacks[i](window.shJSBridge);
                }
            }
            delete window.shJSCallbacks;
        }
        ///向 window 上挂载 shJSBridge 对象
        if(!window.shJSBridge){
            window.shJSBridge = SHJSBridge.createNew();
            setTimeout(_callQFJSCallbacks, 0);
        }
})();
    );
    #undef __js_func__
    return js;
}
