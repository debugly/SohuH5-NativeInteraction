//
//  SHWebViewJSBridge.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHWebViewJSBridgeHeader.h"

@interface SHWebViewJSBridge : NSObject

/**
 注册方法，等待H5端调用
 
 @param method H5调用的方法名
 @param handler 接收到H5的参数,在主线程回调
 */
- (void)registerMethod:(NSString *)method handler:(SHJSBridgeOnH5Message)handler;

/**
 构造调用 H5 方法的 js 脚本

 @param method 方法名
 @param data 参数
 @return 构造好的完整的js语句，接下来可交给 webview 控件发送出去！
 */
- (NSString *)makeInvokeH5Cmd:(NSString *)method data:(NSDictionary *)data callBack:(SHJSBridgeOnH5Response)callback;

/**
 统一处理消息通道发来的消息

 @param body H5发来的消息结构体
 @param callBackBlock 内部需要给H5回执时，就会回调给上层，然后上层执行jsText即可
 */
- (void)handleH5Message:(id)body callBack:(void(^)(NSString *cmd))callBackBlock;

@end

@interface SHWebViewJSBridge(js)

/**
 实现了交互通信的js脚本，需要在恰当的时机注入到 webview！
 @return JavaScript string
 */
+ (NSString *)javasctipt4Inject;


/**
 跟H5交互的对像名，需要做个映射！

 @return a string name
 */
+ (NSString *)h5NativeMapBridgeName;


/**
 H5 端需要使用的对象名
 such as: window.shJSBridge
 @return a h5 bridge name
 */
+ (NSString *)h5BridgeObjectName;


/**
 只有 UIWebView 才会用到，是一个优化机制！

 @return a ready identity string
 */
+ (NSString *)jsBridgeReadyIdentity;


/**
 构造用于调用H5的消息命令

 @param jsonText h5消息结构体
 @return JavaScript cmd
 */
+ (NSString *)makeInvokeH5Cmd:(NSString *)jsonText;

@end
