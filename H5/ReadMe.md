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
window.shJSBridge.registerHandler('updateInfo',function(data, responseCallback) {
    var random = Math.floor(Math.random() * 1000);
    var testjs = document.getElementById('testjs');
    testjs.innerHTML = data['text'] +':'+ random;
    var responseData = { "text":random+''}
    responseCallback(responseData)
 });
 
```

## 存在问题??

当页面没有加载完毕的时候，H5端就调用Native的方法会有问题吗？

**会的！**


如果你阅读过本方案原理的话就会知道，交互脚本是移动端注入的，H5是零配置的！只有注入了脚本，才会在 window 上挂载 shJSBridge 这个对象！所以页面没有加载完毕的时候，是获取不到 shJSBridge 对象的，这么写会出 bug 的！那问题是 H5 并不知道移动端何时注入脚本，何时才能拿到 shJSBridge 对象？怎么解决这个问题呢？


## 解决方案

H5 调用 Native 的时机是不确定的，保险起见，我们应当想办法让 H5 端总是能够拿到 shJSBridge 对象跟Native交互！因此需要 H5端写个类似 setupshJSBridge 的方法，H5 端总是通过这个方法的回调获取 shJSBridge 对象！

```js

function setupshJSBridge(callback) {

    if (window.shJSBridge) {
        ///Native已经挂载了，直接返回就行了
        callback(window.shJSBridge);
    }else if (window.shJSCallbacks) {
        ///Native还没挂载，callback数组已经创建好了，先把回调存储起来
        window.shJSCallbacks.push(callback);
    }else{
        ///Native还没挂载，callback数组还没创建，那么创建带存储
        window.shJSCallbacks = [callback];
    }
}

```

> 这个逻辑跟移动端脚本配合使用的，移动端注入脚本后，会去判断shJSCallbacks是否存储了回调，如果存了就回调下，因此这就确保了 H5 端总是能够拿到 shJSBridge 对象！因此，H5 端不要改 **shJSCallbacks** 这个变量名，除非跟移动端一起都改！！

所以上面的示例方法建议改成如下形式：


```js
///调用Native的showMsg方法
setupSHJSBridge(function(bridge){
    bridge.invokeNative("showMsg",function(json){                 var testjs = document.getElementById('testjs');                 testjs.innerHTML += json['text'];               });
});
```

```js
setupSHJSBridge(function(bridge){
    bridge.registerHandler('updateInfo',function(data, responseCallback) {
        var random = Math.floor(Math.random() * 1000);
        var testjs = document.getElementById('testjs');
        testjs.innerHTML = data['text'] +':'+ random;
        var responseData = { "text":random+''}
        responseCallback(responseData)
     });
});
```