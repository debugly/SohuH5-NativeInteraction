//
//  SHWebViewJSBridgeHeader.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#ifndef SHWebViewJSBridgeHeader_h
#define SHWebViewJSBridgeHeader_h

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SHWebViewJSBridgeMessageTypeMethod,
    SHWebViewJSBridgeMessageTypeHandler
} SHWebViewJSBridgeMessageType;

/*
 * 通过该接口向 H5 发送回执
 * */
typedef void(^SHWebViewOnH5Response)(NSDictionary *ps);
/*
 * Native调用H5之后，H5通过这个接口给个回执
 * */
typedef void(^SHWebSendH5Response)(NSDictionary *ps);
/*
 * Native 注册方法的回调，当 H5 调用了 Native 之后，这个回调就会走；
 * 可以使用 callback 发给 H5 一个回执
 * */
typedef void(^SHWebNativeHandler)(NSDictionary *ps,SHWebSendH5Response callback);

#endif /* SHWebViewJSBridgeHeader_h */
