# 效果

![](./H5-Native.gif)

# iOS 端交互文档

### 1、调用 H5 提供的方法
使用 SHWebView 对象调用 **callH5Method:
data:
responseCallback:** 方法即可。```
/**
 调用 H5 的方法
 
 @param method 方法名
 @param ps 参数
 @param responseCallback H5的回调
 */
- (void)callH5Method:(NSString*)method data:(NSDictionary *)ps responseCallback:(SHWebResponeCallback)responseCallback;
```
ps : 如果 H5 没有注册名为 method 的处理，也不会导致崩溃!
### 2、支持 H5 调用 iOS跟 H5 支持 Native 调用是一个道理，iOS 需要注册下 H5 需要调用的方法！

```objc
/**
 注册要处理的事件
 
 @param method H5调用的方法名
 @param handler 接收到H5的参数,在主线程回调
 */
- (void)registerMethod:(NSString *)method handler:(SHWebNativeHandler)handler;
```

举例说明：

```objc
///注册了一个 showMsg 方法，H5 就可调用showMsg方法了，ps 是 H5 传过来参数
[self.webView registerMethod:@"showMsg" handler:^(NSDictionary *ps, SHWebResponeCallback callback) {
    _strongSelf_SH
    self.info.text = ps[@"text"];
    self.info.backgroundColor = [UIColor blackColor];
    ///处理完消息后，给H5一个回调
    callback(@{@"status":@(200)});
}];
    
```