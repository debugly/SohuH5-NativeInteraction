//
//  SHWebViewJSBridge.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SHWebResponseCallback)(NSDictionary *ps);
typedef void(^SHWebNativeHandler)(NSDictionary *ps,SHWebResponseCallback callback);

@interface SHWebViewJSBridge : NSObject

- (void)registerMethod:(NSString *)handlerName handler:(SHWebNativeHandler)handler;

- (void)registerCallback:(NSString *)name callBack:(SHWebResponseCallback)callback;

- (void)handleH5Message:(id)body callBack:(void(^)(NSString *jsonText))callBackBlock;

@end
