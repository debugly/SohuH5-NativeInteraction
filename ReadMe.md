# H5-Native 交互方案

一个 Native（iOS/Android）与 H5 交互的解决方案，配套了封装好的 Native 通用组件，无需关心 Native (WKWebViews / UIWebViews / WebView) 跟 H5 的通信过程。


## 特点

- 统一 H5 端与 Native 交互的接口，只需要写一套代码即可与 iOS、Android 两端交互，无需通过UA等方式识别平台！
- H5 端基本是零配置，交互脚本由移动端注入！
- 支持双向回调，即 H5 调用了 Native，Native 可以再给 H5 一个回执！
- iOS，Android 均封装了通用的 webview 组件，可以不用关系底层交互通信原理，直接编写上层业务逻辑；并且上层业务逻辑不会跟底层有任务依赖！


## 如何接入

打开对应的文件夹，可直接运行demo。

- [H5 接入文档](/H5/ReadMe.md)
- [iOS 接入文档](/iOS/ReadMe.md)
- [Android 接入文档](/Android/ReadMe.md)

1. 在阅读完毕各自平台的接入文档之后，你会 get 到如何跟另一端交互
2. 各端人员拉个讨论组，喝着咖啡，根据业务找到需要交互的点，制定下调用方法名，以及参数，把支持的方法名都整理到 wiki 里面
3. 约好联调的时间之后，各自散去看着 wiki 写业务代码吧


## 谁在用

- 千帆直播 SDK
- 搜狐课堂
- 搜狐内部某创业项目

## 对比

跟流行的 [WebViewJavascriptBridge](https://github.com/debugly/WebViewJavascriptBridge) 有何区别？


|  | SohuH5-NativeInteraction | WebViewJavascriptBridge |
| --- | :-------------: |:-------------:|
| iOS 平台 | 支持 | 支持 |
| Android 平台 | 支持 | 不支持 |
| Mac 平台 | 不支持 | 支持 |
| H5 端 | 逻辑统一，不需要区分平台 | 有可能需要判断平台，要看安卓那边选择的方案 |
| 通信方式 | 通过各自平台注入交互对象| 拦截 Request |