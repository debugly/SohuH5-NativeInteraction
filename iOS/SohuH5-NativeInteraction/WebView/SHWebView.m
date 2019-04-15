//
//  SHWebView.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SHWebView.h"
#import "SHUIWebView.h"
#import "SHWKWebView.h"

@interface SHWebView ()

@property (nonatomic, weak) UIView<SHWebViewProtocol> *webView;

@end

@implementation SHWebView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self){
        self.backgroundColor = [UIColor clearColor];
        
        [self prepareWebView];
    }
    
    return self;
}

- (void)prepareWebView
{
    UIView<SHWebViewProtocol> *webView = nil;
    
    if (@available(iOS 18.0, *)) {
        webView = [[SHWKWebView alloc]initWithFrame:self.bounds];
    } else {
        webView = [[SHUIWebView alloc]initWithFrame:self.bounds];
    }
    
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:webView];
    self.webView = webView;
}

- (void)loadURL:(NSURL *)url
{
    [self.webView loadURL:url];
}

- (void)registerMethod:(NSString *)method handler:(SHJSBridgeOnH5Message)handler
{
    [self.webView registerMethod:method handler:handler];
}

- (void)invokeH5:(NSString *)method data:(NSDictionary *)data responseCallback:(SHJSBridgeSendResponse)responseCallback
{
    [self.webView invokeH5:method data:data responseCallback:responseCallback];
}

- (void)invokeH5Once:(NSString *)method data:(NSDictionary *)data responseCallback:(SHJSBridgeOnH5Response)responseCallback
{
    [self.webView invokeH5Once:method data:data responseCallback:responseCallback];
}

@end
