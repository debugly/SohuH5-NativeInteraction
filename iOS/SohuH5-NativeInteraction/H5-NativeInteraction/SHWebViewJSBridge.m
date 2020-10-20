//
//  SHWebViewJSBridge.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 debugly.cn. All rights reserved.
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

- (void)registerMethod:(NSString *)method handler:(SHJSBridgeOnH5Message)handler
{
    if (method.length > 1 && handler) {
        [self.methodHandlerMap setObject:[handler copy] forKey:method];
    }
}

- (void)registerCallback:(NSString *)name callBack:(SHJSBridgeOnH5Response)callback
{
    if (name.length > 1) {
        if (callback) {
            [self.callbackMap setObject:[callback copy] forKey:name];
        } else {
            [self.callbackMap removeObjectForKey:name];
        }
    }
}

- (NSString *)makeInvokeH5Cmd:(NSString *)method data:(NSDictionary *)data callBack:(SHJSBridgeOnH5Response)callback once:(BOOL)once
{
    NSNumber *mid = once ? @(++self.mid) : nil;
    ///保存住该callBack；当H5回调时，调用这个callBack，实现回调
    NSString *key = method;
    if (mid) {
        key = [key stringByAppendingFormat:@"%@",mid];
    }
    [self registerCallback:key callBack:callback];
    NSString *cmd = [self packageCmd:SHWebViewJSBridgeMessageTypeMethod method:method data:data mid:mid];
    return cmd;
}

- (void)invokeNativeMethod:(NSString *)method parameter:(NSDictionary *)ps callBack:(void(^)(NSString *jsonText))callBackBlock mid:(NSNumber *)mid
{
    SHJSBridgeOnH5Message handler = self.methodHandlerMap[method];
    if (handler) {
        SHJSBridgeSendResponse callBack = ^(NSDictionary *data){
            if (callBackBlock) {
                NSString *jsonText = [self packageCmd:SHWebViewJSBridgeMessageTypeHandler
                                               method:method
                                                 data:data
                                                  mid:mid];
                callBackBlock(jsonText);
            }
        };
        handler(ps,callBack);
    }
}

/*
 {
     message =     {
         data = {};
         method = aaa;
     };
     type = invokeTest;
 }
 
 {
     message =     {
         data = {
            text = 438;
         };
         method = updateInfo;
     };
     type = handler;
 }
 
 {
     message =     {
         data = {
            text = "H5\U7ed9Native\U53d1\U6d88\U606f\U4e86570";
         };
         method = showMsg;
     };
     type = method;
 }
 
 {
     "type":"method",
     "message":{
        "method":"sendRequest",
        "data":{"from":"100"},
        "once":1,
        "mid":6
     }
 }
 */
- (void)handleH5Message:(id)json callBack:(void(^)(NSString *cmd))callBackBlock
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
    NSNumber *mid = message[@"mid"];
    
    ///h5调用Native的method方法
    if([type isEqualToString:@"method"]){
        [self invokeNativeMethod:method parameter:data callBack:callBackBlock mid:mid];
    }
    ///Native调用了h5之后，h5回调Native的handle方法
    else if([type isEqualToString:@"handler"]){
        NSString *key = method;
        if (mid) {
            key = [key stringByAppendingFormat:@"%@",mid];
        }
        void (^handler)(NSDictionary *json) = self.callbackMap[key];
        if (handler) {
            handler(data);
            if (mid) {
                self.callbackMap[key] = nil;
            }
        }
    }
    ///测试下 Native 是否支持了某个方法
    else if ([type isEqualToString:@"invokeTest"]){
        
        NSString *data = [[self.methodHandlerMap allKeys]containsObject:method] ? @"1" : @"0";
        
        NSString *cmd = [self packageCmd:SHWebViewJSBridgeMessageTypeHandler
                                  method:method
                                    data:data
                                     mid:mid];
        callBackBlock(cmd);
    }
}

#pragma mark - 构造发送给H5的结构体
////协议相关
- (NSString *)_packageMessage:(SHWebViewJSBridgeMessageType) messageType method:(NSString *)method data:(id)data mid:(NSNumber *)mid
{
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    
    ///1，确定类型
    NSString *messageTypeStr = @"";
    if(messageType == SHWebViewJSBridgeMessageTypeMethod){
        messageTypeStr = @"method";
    }else if(messageType == SHWebViewJSBridgeMessageTypeHandler){
        messageTypeStr = @"handler";
    }
    [m setValue:messageTypeStr forKey:@"type"];
    
    ///2,确定方法名
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    [message setObject:method forKey:@"method"];
    
    ///3,确定消息id参数
    if (mid) {
        [message setObject:@(1) forKey:@"once"];
        [message setObject:mid forKey:@"mid"];
    }

    ///4,确定参数
    if (data) {
        [message setObject:data forKey:@"data"];
    }
    [m setValue:message forKey:@"message"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:m options:NSJSONWritingPrettyPrinted error:nil];
    NSString *josnText = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return josnText;
}

- (NSString *)packageCmd:(SHWebViewJSBridgeMessageType) messageType method:(NSString *)method data:(id)data mid:(NSNumber *)mid
{
    NSString *msg = [self _packageMessage:messageType method:method data:data mid:mid];
    return [[self class] makeInvokeH5Cmd:msg];
}

@end
