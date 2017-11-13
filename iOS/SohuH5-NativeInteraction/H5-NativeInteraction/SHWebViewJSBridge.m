//
//  SHWebViewJSBridge.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SHWebViewJSBridge.h"

@interface SHWebViewJSBridge ()

@property (nonatomic, strong) NSMutableDictionary * methodHandlerMap;
@property (nonatomic, strong) NSMutableDictionary * callbackMap;

@end

@implementation SHWebViewJSBridge

- (NSMutableDictionary *)methodHandlerMap
{
    if (!_methodHandlerMap) {
        _methodHandlerMap = [NSMutableDictionary dictionary];
    }
    return _methodHandlerMap;
}

- (NSMutableDictionary *)callbackMap
{
    if (!_callbackMap) {
        _callbackMap = [NSMutableDictionary dictionary];
    }
    return _callbackMap;
}

- (void)registerMethod:(NSString *)method handler:(SHWebNativeHandler)handler
{
    if (method.length > 1 && handler) {
        [self.methodHandlerMap setObject:[handler copy] forKey:method];
    }
}

- (void)registerCallback:(NSString *)name callBack:(SHWebResponseCallback)callback
{
    if (name.length > 1 && callback) {
        [self.callbackMap setObject:[callback copy] forKey:name];
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
    NSDictionary *ps = message[@"data"];
    
    if([type isEqualToString:@"method"]){
        SHWebNativeHandler handler = self.methodHandlerMap[method];
        if (handler) {
            SHWebResponseCallback callBack = ^(NSDictionary *ps){
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
    else if([type isEqualToString:@"handler"]){
        void (^handler)(NSDictionary *json) = self.callbackMap[method];
        if (handler) {
            handler(ps);
        }
    }else if ([type isEqualToString:@"invokeTest"]){
        
        NSMutableDictionary *m = [NSMutableDictionary dictionary];
        [m setValue:@"handler" forKey:@"type"];
        
        NSMutableDictionary *message = [NSMutableDictionary dictionary];
        [message setObject:method forKey:@"method"];
        
        if ([[self.methodHandlerMap allKeys]containsObject:method]) {
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
