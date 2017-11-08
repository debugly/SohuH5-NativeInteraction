//
//  SHWeakProxy.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//
// 傀儡代理，防止持有target；内部做消息转发；常结合NSTimer使用；

#import <Foundation/Foundation.h>

@interface SHWeakProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;

+ (instancetype)weakProxyWithTarget:(id)target;

@end
