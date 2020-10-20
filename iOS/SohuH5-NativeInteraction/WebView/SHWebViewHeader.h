//
//  SHWebViewHeader.h
//  SohuH5-NativeInteraction
//
//  Created by Matt Reach on 2019/3/19.
//  Copyright © 2019 debugly.cn. All rights reserved.
//

#ifndef SHWebViewHeader_h
#define SHWebViewHeader_h

#import "SHWebViewJSBridgeHeader.h"

@protocol SHWebViewProtocol <NSObject>

/**
 加载URL
 */
- (void)loadURL:(NSURL *)url;

/**
注册方法，等待H5端调用

@param method H5调用的方法名
@param handler 接收到H5的参数,在主线程回调
*/
- (void)registerMethod:(NSString *)method handler:(SHJSBridgeOnH5Message)handler;

/**
 调用 H5 的方法
 
 @param method 方法名
 @param ps 参数
 @param responseCallback H5的回调
 */
- (void)invokeH5:(NSString*)method data:(NSDictionary *)ps responseCallback:(SHJSBridgeOnH5Response)responseCallback;

/**
 一次性调用 H5 的方法
 
 @param method 方法名
 @param ps 参数
 @param responseCallback H5的回调
 */
- (void)invokeH5Once:(NSString*)method data:(NSDictionary *)ps responseCallback:(SHJSBridgeOnH5Response)responseCallback;


@end

#endif /* SHWebViewHeader_h */
