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

- (void)handleH5Message:(id)data callBack:(void(^)(NSString *jsonText))callBackBlock
{
    NSDictionary *body = nil;
    
    if([data isKindOfClass:[NSString class]]){
        body = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        NSAssert(body, @"无法解析通信通道数据:%@",data);
        
    }else if([data isKindOfClass:[NSDictionary class]]){
        body = (NSDictionary *)data;
    }else{
        NSAssert(NO, @"通信通道数据不合法:%@",data);
    }
    
    NSString *type = body[@"type"];
    NSDictionary *message = body[@"message"];
    NSString *method = message[@"method"];
    NSDictionary *ps = message[@"ps"];
    
    if([type isEqualToString:@"Method"]){
        SHWebNativeHandler handler = self.methodHandler[method];
        if (handler) {
            SHWebResponeCallback callBack = ^(NSDictionary *ps){
                if (callBackBlock) {
                    
                    NSMutableDictionary *m = [NSMutableDictionary dictionary];
                    [m setValue:@"handler" forKey:@"type"];
                    
                    NSMutableDictionary *message = [NSMutableDictionary dictionary];
                    [message setObject:method forKey:@"method"];
                    
                    if (ps) {
                        [message setObject:ps forKey:@"data"];
                    }
                    [m setValue:message forKey:@"message"];
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:m options:NSJSONWritingPrettyPrinted error:nil];
                    NSString *josnText = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
                    
                    callBackBlock(josnText);
                }
            };
            handler(ps,callBack);
        }
    }
    ///Native调用了h5之后，h5回调Native的handle方法
    else if([type isEqualToString:@"Handler"]){
        void (^handler)(NSDictionary *json) = self.callbacks[method];
        if (handler) {
            handler(ps);
        }
    }else if ([type isEqualToString:@"invokeTest"]){
        
        NSMutableDictionary *m = [NSMutableDictionary dictionary];
        [m setValue:@"handler" forKey:@"type"];
        
        NSMutableDictionary *message = [NSMutableDictionary dictionary];
        [message setObject:method forKey:@"method"];
        
        if ([[self.methodHandler allKeys]containsObject:method]) {
            [message setObject:@"1" forKey:@"data"];
        }else{
            [message setObject:@"0" forKey:@"data"];
        }
        [m setValue:message forKey:@"message"];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:m options:NSJSONWritingPrettyPrinted error:nil];
        NSString *josnText = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        callBackBlock(josnText);
    }
}

@end
