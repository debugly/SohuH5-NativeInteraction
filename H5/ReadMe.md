# H5 端交互文档

以下操作**H5均无需任何配置**，直接使用 Native 挂载到 window上的 shJSBridge 对象，调用该对象的方法即可！ 

### 0、判断 Native 是否支持某个方法

有的是时候需要知道 Native 有没有实现某个方法可以这么做：

```js
window.shJSBridge.canInvokeNative(method, callback);
```

- method : Native 的方法名
- callback : 接收 Native 的回调，回调参数是字符串;
	-  '1' 代表Native实现了这个方法
	-  '0' 代表Native没有实现这个方法

### 1、H5 调用 Native 的方法
```js
window.shJSBridge.invokeNative(method,parameter, callback);
```
- method : Native 的方法名- parameter : 给 Native 传递的参数，json 类型，【可选】
- callback : 接收 Native 的回调，回调参数是 json 类型，【可选】有可选参数，因此支持以下四种调用方式:

```window.shJSBridge.invokeNative("showMsg"); 

window.shJSBridge.invokeNative("showMsg",{"text":"中 奖 "}); 

window.shJSBridge.invokeNative("showMsg",function(json){                 var testjs = document.getElementById('testjs');                 testjs.innerHTML += json['text'];               });
               window.shJSBridge.invokeNative("showMsg",{"text":"中 奖 "},function(json){ 
				 var testjs = document.getElementById('testjs');              testjs.innerHTML += json['text'];        });
```
### 2、如何支持 Native 调用 H5 的方法
使用 window.shJSBridge.registerMethod(method,handler) 注册 Native 将要调用的方法;- method : Native 将要调用的方法名- handler : Native 调用该方法后回调，回调 json 类型参数和回应 Native 的 callback	- data : Native 传给 H5 的参数	- responseCallback : 必要时可用该 callback 回调 Native		- responseData : 回调 Native 时带的参数，json 类型，【可选】```
///由于 Native 是在页面加载完毕后才注入的，当注入完毕后，该方法的 callback 就会回调，然后 H5 可以使用 bridge 对象注册方法，或者调用 Native 的方法了；
function setupshJSBridge(callback) {
        if (window.shJSBridge) { return callback(shJSBridge); }
        if (window.shJSCallbacks) { return window.shJSCallbacks.push(callback); }
        window.shJSCallbacks = [callback];
}
    
setupshJSBridge(function(bridge){
        bridge.registerHandler('updateInfo',function(data, responseCallback) {
                                            var random = Math.floor(Math.random() * 1000);
                                            var testjs = document.getElementById('testjs');
                                            testjs.innerHTML = data['text'] +':'+ random;
                                            var responseData = { "text":random+''}
                                            responseCallback(responseData)
                                           });
})
```

### 问题

H5 端为何要写个 setupshJSBridge 方法，从这个方法里拿到 bridge 对像，而不是直接使用 window.shJSBridge 对象呢？

### 解答

如果你阅读了方案原理的话就会知道，交互脚本是移动端注入的，只有注入了脚本，才会在 window 上挂载 shJSBridge 这个对象！ 

H5是零配置的，那么H5并无法知道移动端何时注入脚本，何时才能拿到 shJSBridge 对象，因此保险起见，H5端应当写一个 setupshJSBridge 的方法，通过这个方法 获取 shJSBridge 对象！

原理是当移动端还没注入脚本的时候，就把回调先存起来，存在数组里，当移动端注入的时候，会检查这个数组里是否存在回调，若存在就进行回调，然后清空数组！因此，移动端不要改 **shJSCallbacks** 这个变量名，除非跟移动端一起都改！！