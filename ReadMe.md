# H5-Native 交互方案

## 特点

- 统一 H5 端与 Native 交互的接口，只需要写一套代码即可与 iOS、Android 两端交互，无需通过UA等方式识别平台！
- 支持双向回调，即 H5 调用了 Native，Native 可以再给 H5 一个回执！
- iOS，Android 均封装了通用的 webview 组件，可以不用关系底层交互通信原理，直接编写上层业务逻辑；并且上层业务逻辑不会跟底层有任务依赖！

## 接入文档

- [iOS 接入文档](/iOS/ReadMe.md)
- [Android 接入文档](/Android/ReadMe.md)
