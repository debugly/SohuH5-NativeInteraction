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
                
                jsBridge.messageHandlers = {};
                jsBridge.responseCallbacks = {};
                
                jsBridge.registerHandler = function(handlerName, handler) {
                    this.messageHandlers[handlerName] = handler;
                };
                
                jsBridge.doSend = function(message, responseCallback) {
                    var method = message['method'];
                    if (responseCallback) {
                        this.responseCallbacks[method] = responseCallback;
                    }
                    this.doInvokeNative('Method',message);
                };
                
                jsBridge.doInvokeNative = function(type,message){
                    //把消息和消息类型封装成结构
                    var m = {};
                    m['type'] = type;
                    m['message'] = message;
                    
                    //ios UIWebView and Android WebView
                    if(window.shNativeObject){
                        ///ios 可以接收 json 对象，安卓不行，只能传 json 串了。
                        var str = JSON.stringify(m);
                        window.shNativeObject.h5InvokeNative(str);
                        //eval('shNativeObject.'+'h5InvokeNative'+'(str)');
                    }
                    //ios WKWebView
                    else if(window.webkit.messageHandlers.shNativeObject){
                        window.webkit.messageHandlers.shNativeObject.postMessage(m);
                        //eval('window.webkit.messageHandlers.shNativeObject.postMessage'+'(m)');
                    }else{
                        //alert
                    }
                };
                
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
                
                ///调用注册的回调方法
                jsBridge.invokeH5Handler = function(message){
                    var handlerName = message['method'];
                    var json = message['data'];
                    var callback = window.shJSBridge.responseCallbacks[handlerName];
                    
                    if(callback){
                        callback(json);
                    }
                };
                
                ///调用注册的H5方法
                jsBridge.invokeH5Method = function(message){
                    var handlerName = message['method'];
                    var json = message['data'];
                    var callback = window.shJSBridge.messageHandlers[handlerName];
                    
                    if(callback){
                        callback(json,function(data){
                            var m = {};
                            m['method'] = handlerName;
                            m['ps'] = data ? data : {};
                            window.shJSBridge.doInvokeNative('Handler',m);
                        });
                    }
                };
                
                ///H5 测试方法能否被调用
                jsBridge.canInvokeNative = function(handlerName,responseCallback){
                    
                    var m = {};
                    m['method'] = handlerName;
                    m['ps'] = {};
                    if (responseCallback) {
                        this.responseCallbacks[handlerName] = responseCallback;
                        window.shJSBridge.doInvokeNative('invokeTest',m);
                    }
                };
                
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
