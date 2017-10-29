//
//  SHWebViewJSBridge.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SHWebViewJSBridge.h"

@interface SHWebViewJSBridge ()

@property (nonatomic, strong) NSMutableDictionary * methodHandler;
@property (nonatomic, strong) NSMutableDictionary * callbacks;

@end

@implementation SHWebViewJSBridge

- (NSMutableDictionary *)methodHandler
{
    if (!_methodHandler) {
        _methodHandler = [NSMutableDictionary dictionary];
    }
    return _methodHandler;
}

- (NSMutableDictionary *)callbacks
{
    if (!_callbacks) {
        _callbacks = [NSMutableDictionary dictionary];
    }
    return _callbacks;
}

- (void)registerMethod:(NSString *)method handler:(SHWebNativeHandler)handler
{
    if (method.length > 1 && handler) {
        [self.methodHandler setObject:[handler copy] forKey:method];
    }
}

- (void)registerCallback:(NSString *)name callBack:(SHWebResponeCallback)callback
{
    if (name.length > 1 && callback) {
        [self.callbacks setObject:[callback copy] forKey:name];
    }
}

- (void)handleH5Message:(NSDictionary *)body callBack:(void(^)(NSDictionary *body))callBackBlock
{
    NSString *type = body[@"type"];
    NSDictionary *message = body[@"message"];
    NSString *method = message[@"method"];
    NSDictionary *ps = message[@"ps"];
    
    if([type isEqualToString:@"Method"]){
        SHWebNativeHandler handler = self.methodHandler[method];
        if (handler) {
            SHWebResponeCallback callBack = ^(NSDictionary *ps){
                if (callBackBlock) {
                    NSDictionary *json = @{@"method":method,@"data":ps};
                    callBackBlock(json);
                }
            };
            handler(ps,callBack);
        }
    }
    ///Native调用了h5之后，h5回调Native的handle方法
    else if([type isEqualToString:@"Handler"]){
        void (^handler)(NSDictionary *json) = self.callbacks[method];
        if (handler) {
            if (ps.count == 0) {
                handler(nil);
            }else{
                handler(ps);
            }
        }
    }else if ([type isEqualToString:@"invokeTest"]){
        if ([[self.methodHandler allKeys]containsObject:method]) {
            NSDictionary *json = @{@"method":method,@"data":@"1"};
            callBackBlock(json);
        }else{
            NSDictionary *json = @{@"method":method,@"data":@"0"};
            callBackBlock(json);
        }
    }
}

@end
