//
//  SHWebViewJSBridgeHeader.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#ifndef SHWebViewJSBridgeHeader_h
#define SHWebViewJSBridgeHeader_h

#import <Foundation/Foundation.h>

/*
 * 消息类型
 * method： 表示主动调用
 * handler：表示主动调用的响应（回执）
 * */
typedef enum : NSUInteger {
    SHWebViewJSBridgeMessageTypeMethod,
    SHWebViewJSBridgeMessageTypeHandler
} SHWebViewJSBridgeMessageType;

// 通用Block
typedef void(^SHJSBridgeCommonBlock)(NSDictionary *ps);

/*
 * H5 调用了 Native，Native 通过该 Block 向 H5 发送回执
 * */
typedef SHJSBridgeCommonBlock SHJSBridgeSendResponse;

/*
 * Native 调用了 H5 之后，H5 通过该 Block 向 Native 发送回执
 * */
typedef SHJSBridgeCommonBlock SHJSBridgeOnH5Response;

/*
 * Native 注册方法的回调，当 H5 调用了 Native 之后，这个回调就会走；
 * 可以使用 callback 发给 H5 一个回执
 * */
typedef void(^SHJSBridgeOnH5Message)(NSDictionary *ps,SHJSBridgeSendResponse callback);

#endif /* SHWebViewJSBridgeHeader_h */
