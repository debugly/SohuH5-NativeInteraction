//
//  SHWebViewJSBridge+JS.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/11/14.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

/*
 H5 使用 SDK 在 window 上挂载 shJSBridge 对象调用Native的方法；
 shJSBridge 是 SHJSBridge 的 js '对象'， SHJSBridge 是对方法参数等交互细节的封装，最终会调用 SDK 注入的交互对象 shNativeObject ！
 */
#import "SHWebViewJSBridge.h"

///定义H5需要使用的对象名字
#define __h5BridgeName__ @"shJSBridge"
///定义H5-Native通信时绑定的对象名字
#define __h5NativeMapBridgeName__ @"shNativeObject"

@implementation SHWebViewJSBridge (js)

+ (NSString *)h5NativeMapBridgeName
{
    return __h5NativeMapBridgeName__ ;
}

+ (NSString *)h5BridgeObjectName
{
    return __h5BridgeName__ ;
}

+ (NSString *)jsBridgeReadyIdentity
{
    return [[__h5BridgeName__ stringByAppendingString:@"://iamready"] lowercaseString];
}

+ (NSString *)makeInvokeH5Cmd:(NSString *)jsonText
{
    return [NSString stringWithFormat:@"window.%@.invokeH5(%@)",__h5BridgeName__, jsonText];
}

///以下为JS执行代码，在合适时机注入WebView中
+ (NSString *)javasctipt4Inject
{
#define __js_func__(x) #x
    NSString *js = @__js_func__(
                                ;(function(){
        var SHJSBridge = {
            
            createNew : function(){
                
                var jsBridge = {};
                ///存储 H5 注册的方法；
                jsBridge.methodHandler = {};
                ///存储 H5 方法的回调callback，即H5调用Native后，通过此callback收到响应；
                jsBridge.responseCallbacks = {};
                ///方法标识，为设计一对一回调而加；
                jsBridge.mid = 1;
                
                //----------------------H5 register method--------------------//
                
                jsBridge.registerMethod = function(handlerName, handler) {
                    if (handler) {
                        this.methodHandler[handlerName] = handler;
                    } else {
                        delete this.methodHandler[handlerName];
                    }
                };
                
                ///之前叫这个名字；兼容老版本而已；
                jsBridge.registerHandler = function(handlerName, handler) {
                    this.registerMethod(handlerName, handler);
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
                    if(window.__h5NativeMapBridgeName__){
                        window.__h5NativeMapBridgeName__.h5InvokeNative(str);
                    }
                    //ios/macos WKWebView
                    else if(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.__h5NativeMapBridgeName__){
                        window.webkit.messageHandlers.__h5NativeMapBridgeName__.postMessage(str);
                    }else{
                        //alert
                    }
                };
                
                jsBridge.doSend = function(message, responseCallback) {
                    ///需要Native的回调,那么就把回调保存下
                    if (responseCallback) {
                        var key = message['method'];
                        if (message['once']) {
                            this.mid ++;
                            key += this.mid;
                            message['mid'] = this.mid;
                        }
                        this.responseCallbacks[key] = responseCallback;
                    }
                    this.doInvokeNative('method',message);
                };
                
                jsBridge._invokeNative = function(handlerName, once, data, responseCallback){
                    var args = arguments.length;
                    if(args == 2){
                        this.doSend({ method:handlerName, data:{}, once:once });
                    }else if (args == 3) {
                        if(typeof data == 'function'){
                            this.doSend({ method:handlerName, data:{}, once:once },data);
                        }else{
                            this.doSend({ method:handlerName, data:data, once:once });
                        }
                    }else if(args == 4){
                        this.doSend({ method:handlerName, data:data, once:once }, responseCallback);
                    }
                };
                
                ///支持可选参数
                jsBridge.invokeNative = function(handlerName, data, responseCallback){
                    this._invokeNative(handlerName,0,data,responseCallback);
                };
                
                ///支持可选参数
                jsBridge.invokeNativeOnce = function(handlerName, data, responseCallback){
                    this._invokeNative(handlerName,1,data,responseCallback);
                };
                
                ///H5 试探方法能否被调用
                jsBridge.canInvokeNative = function(method,responseCallback){
                    
                    var m = {};
                    m['method'] = method;
                    m['data'] = {};
                    if (responseCallback) {
                        this.responseCallbacks[method] = responseCallback;
                        this.doInvokeNative('invokeTest',m);
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
                    var clean = 0;
                    if (message['mid']) {
                        handlerName += message['mid'];
                        clean = 1;
                    }
                    var json = message['data'];
                    var callback = this.responseCallbacks[handlerName];
                    
                    if(callback){
                        callback(json);
                        ///对于 once 类型，把 callback 回调清理掉；
                        if (clean) {
                            delete this.responseCallbacks[handlerName];
                        }
                    }
                };
                
                ///调用注册的H5方法
                jsBridge.invokeH5Method = function(message){
                    
                    var method = message['method'];
                    
                    ///寻找下H5有没有注册这个方法
                    var callback = this.methodHandler[method];
                    if(callback){
                        
                        var json = message['data'];
                        var mid  = message['mid'];
                        var self = this;
                        callback(json,function(data){
                            ///H5给Native一个回调；
                            var m = {};
                            m['method'] = method;
                            m['data'] = data ? data : {};
                            if (mid) {
                                m['mid'] = mid;
                                m['once'] = 1;
                            }
                            this.doInvokeNative('handler',m);
                        }.bind(this));
                    }
                };
                
                //----------------------Native invoke H5 end--------------------//
                
                return jsBridge;
            }
        };
        
        function _handleLastH5Callers() {
            var callers = window.__h5BridgeName__Callers;
            if(callers){
                for (var i = 0; i < callers.length; i++) {
                    callers[i](window.__h5BridgeName__);
                }
            }
            delete window.__h5BridgeName__Callers;
        }
        
        ///向 window 上挂载 __h5BridgeName__ 对象;并处理bridge准备好之前的H5调用
        if(!window.__h5BridgeName__){
            window.__h5BridgeName__ = SHJSBridge.createNew();
            setTimeout(_handleLastH5Callers, 0);
        }
        
    })();
                                );
#undef __js_func__
    
    js = [js stringByReplacingOccurrencesOfString:@"__h5BridgeName__" withString:[[self class]h5BridgeObjectName]];

    js = [js stringByReplacingOccurrencesOfString:@"__h5NativeMapBridgeName__" withString:[[self class]h5NativeMapBridgeName]];

    return js;
}

@end
