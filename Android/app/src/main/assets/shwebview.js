;(function(){
        var SHJSBridge = {
            
            createNew : function(){
                
                var jsBridge = {};
                ///存储 H5 注册的方法；
                jsBridge.methodHandler = {};
                ///存储 H5 方法的回调callback，即H5调用Native后，通过此callback收到响应
                jsBridge.responseCallbacks = {};
                
                //----------------------H5 register method--------------------//
                
                jsBridge.registerMethod = function(method, handler) {
                    this.methodHandler[method] = handler;
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
                    this.doInvokeNative('method',message);
                };
                
                ///支持可选参数
                jsBridge.invokeNative = function(method, data, responseCallback){
                    var args = arguments.length;
                    if(args == 1){
                        this.doSend({ 'method':method, 'data':{} });
                    }else if (args == 2) {
                        if(typeof data == 'function'){
                            this.doSend({ 'method':method, 'data':{} },data);
                        }else{
                            this.doSend({ 'method':method, 'data':data });
                        }
                    }else if(args == 3){
                        this.doSend({ 'method':method, 'data' :data }, responseCallback);
                    }
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
                        _self = this;
                        callback(json,function(data){
                            ///H5给Native一个回调；
                            var m = {};
                            m['method'] = method;
                            m['data'] = data ? data : {};
                            _self.doInvokeNative('handler',m);
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