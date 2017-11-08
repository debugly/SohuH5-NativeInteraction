//
//  SHWebViewHeader.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#ifndef SHWebViewHeader_h
#define SHWebViewHeader_h

#import <Foundation/Foundation.h>

#ifndef _weakSelf_SH
#define _weakSelf_SH     __weak   __typeof(self) $weakself = self;
#endif

#ifndef _strongSelf_SH
#define _strongSelf_SH   __strong __typeof($weakself) self = $weakself;
#endif


typedef void(^SHWebResponeCallback)(NSDictionary *ps);
typedef void(^SHWebNativeHandler)(NSDictionary *ps,SHWebResponeCallback callback);

@protocol SHWebViewProtocol <NSObject>

- (void)loadURL:(NSURL *)url;

/**
 注册要处理的事件
 
 @param method H5调用的方法名
 @param handler 接收到H5的参数,在主线程回调
 */
- (void)registerMethod:(NSString *)method handler:(SHWebNativeHandler)handler;


/**
 调用 H5 的方法
 
 @param method 方法名
 @param ps 参数
 @param responseCallback H5的回调
 */
- (void)callH5Method:(NSString*)method data:(NSDictionary *)ps responseCallback:(SHWebResponeCallback)responseCallback;

@end


#endif /* SHWebViewHeader_h */
