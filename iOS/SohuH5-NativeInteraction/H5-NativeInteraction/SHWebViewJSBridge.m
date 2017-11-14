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

- (void)registerCallback:(NSString *)name callBack:(SHWebViewOnH5Response)callback
{
    if (name.length > 1 && callback) {
        [self.callbackMap setObject:[callback copy] forKey:name];
    }
}

- (void)callH5Method:(NSString *)method data:(NSDictionary *)data cookedJSStruct:(void (^)(NSString *))cookie callBack:(SHWebViewOnH5Response)callback
{
    if (cookie) {
        [self registerCallback:method callBack:callback];
        
        NSString *js = [self makeCallH5Struct:method data:data];
        cookie(js);
    }
}

/*
 H5 调用 Native 的唯一出口
 * "json" ： H5 发来的机构体
 * "method" ： H5 要调用 Native 的方法
 * "handler" ：H5 发给 Native 的回执
 * "invokeTest" ： 测试下 Native 是否支持了某个方法
 */
- (void)handleH5Message:(id)json callBack:(void(^)(NSString *jsText))callBackBlock
{
    NSDictionary *body = nil;
    
    if([json isKindOfClass:[NSString class]]){
        body = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        NSAssert(body, @"无法解析通信通道数据:%@",json);
        
    }else if([json isKindOfClass:[NSDictionary class]]){
        body = (NSDictionary *)json;
    }else{
        NSAssert(NO, @"通信通道数据不合法:%@",json);
    }
    
    NSString *type = body[@"type"];
    NSDictionary *message = body[@"message"];
    NSString *method = message[@"method"];
    NSDictionary *data = message[@"data"];
    
    if([type isEqualToString:@"method"]){
        SHWebNativeHandler handler = self.methodHandlerMap[method];
        if (handler) {
            SHWebSendH5Response callBack = ^(NSDictionary *ps){
                if (callBackBlock) {
                    NSString * josnText = [self makeResponseToH5Struct:method data:ps];
                    callBackBlock(josnText);
                }
            };
            handler(data,callBack);
        }
    }
    ///Native调用了h5之后，h5回调Native的handle方法
    else if([type isEqualToString:@"handler"]){
        void (^handler)(NSDictionary *json) = self.callbackMap[method];
        if (handler) {
            handler(data);
        }
    }else if ([type isEqualToString:@"invokeTest"]){
        
        NSString *result = [[self.methodHandlerMap allKeys]containsObject:method] ? @"1" : @"0";
        NSString * josnText = [self makeResponseToH5Struct:method data:result];
        
        callBackBlock(josnText);
    }
}

#pragma mark - 构造发送给H5的结构体

- (NSString *)makeCallH5Struct:(NSString *)method data:(id)data
{
    return [self makeInteractionStruct:@"method" method:method data:data];
}

- (NSString *)makeResponseToH5Struct:(NSString *)method data:(id)data
{
    return [self makeInteractionStruct:@"handler" method:method data:data];
}

- (NSString *)makeInteractionStruct:(NSString *)type method:(NSString *)method data:(id)data
{
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    [m setValue:type forKey:@"type"];
    
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    [message setObject:method forKey:@"method"];
    
    if (data) {
        [message setObject:data forKey:@"data"];
    }
    [m setValue:message forKey:@"message"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:m options:NSJSONWritingPrettyPrinted error:nil];
    NSString *josnText = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    return josnText;
}

@end
