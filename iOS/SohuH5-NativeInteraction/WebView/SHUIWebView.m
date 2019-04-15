//
//  SHUIWebView.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

#import "SHUIWebView.h"
#import "SHWebViewJSBridge.h"
#import "SHWeakProxy.h"

#ifndef _weakSelf_SH
#define _weakSelf_SH     __weak   __typeof(self) $weakself = self;
#endif

#ifndef _strongSelf_SH
#define _strongSelf_SH   __strong __typeof($weakself) self = $weakself;
#endif

@protocol SHUIWebViewJSExport <JSExport>

JSExportAs(h5InvokeNative, - (void)h5InvokeNative:(NSString *)json);

@end

@interface SHUIWebView ()<UIWebViewDelegate,SHUIWebViewJSExport>

@property (nonatomic, weak) UIWebView *uiWebView;
@property (nonatomic, strong) JSContext *context;
@property (nonatomic, strong) SHWebViewJSBridge *jsBridge;
@property (nonatomic, strong) NSURL *currentUrl;

@end

@implementation SHUIWebView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self){
        self.backgroundColor = [UIColor clearColor];
        
        [self prepareWebView];
    }
    
    return self;
}

- (void)dealloc
{
    [self.uiWebView stopLoading];
}

- (void)prepareWebView
{
    UIWebView *webview = [[UIWebView alloc]initWithFrame:self.bounds];
    webview.delegate = self;
    webview.backgroundColor = [UIColor clearColor];
    webview.opaque = NO;
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 110000)
    if (@available(iOS 11.0, *)) {
        webview.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
#endif
    
    [self addSubview:webview];
    self.uiWebView = webview;
}

- (void)h5InvokeNative:(NSString *)body
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _weakSelf_SH
        [self.jsBridge handleH5Message:body callBack:^(NSString *jsCmd) {
            _strongSelf_SH
            if(jsCmd.length > 0){
                [self.uiWebView stringByEvaluatingJavaScriptFromString:jsCmd];
            }
        }];
    });
}

- (void)injectJSBridge
{
    [self setupJSContext:self.uiWebView];
    //注入js调用native的函数
    NSString *js = [SHWebViewJSBridge javasctipt4Inject];
    [self.uiWebView stringByEvaluatingJavaScriptFromString:js];
}

//屏蔽后端发起jsbridge://访问，避免提示错误
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *target = request.URL.absoluteString;
    NSString *identity = [SHWebViewJSBridge jsBridgeReadyIdentity];
    if (target && [identity isEqualToString:target]) {
        [self injectJSBridge];
        return false;
    }else{
        return YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self injectJSBridge];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //处理错误
}

- (void)setupJSContext:(UIView *)webView
{
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    // 打印异常
    self.context.exceptionHandler =
    ^(JSContext *context, JSValue *exceptionValue)
    {
        context.exception = exceptionValue;
    };
    
    /// 以 JSExport 协议关联shNativeObject的方法
    SHWeakProxy *proxy = [SHWeakProxy weakProxyWithTarget:self];
    NSString *nativeName = [SHWebViewJSBridge h5NativeMapBridgeName];
    NSAssert(nativeName, @"SHWebViewJSBridge h5NativeMapBridgeName can't be nil");
    self.context[nativeName] = proxy;
}

- (void)loadRequest:(NSURLRequest *)request
{
    [self.uiWebView loadRequest:request];
}

- (void)loadURL:(NSURL *)url
{
    self.currentUrl = url;
    [self loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)registerMethod:(NSString *)method handler:(SHJSBridgeOnH5Message)handler
{
    [self.jsBridge registerMethod:method handler:handler];
}

- (void)invokeH5:(NSString *)method data:(NSDictionary *)data responseCallback:(SHJSBridgeOnH5Response)responseCallback
{
    NSString *jsCmd = [self.jsBridge makeInvokeH5Cmd:method data:data callBack:responseCallback once:NO];
    [self.uiWebView stringByEvaluatingJavaScriptFromString:jsCmd];
}

- (void)invokeH5Once:(NSString *)method data:(NSDictionary *)data responseCallback:(SHJSBridgeOnH5Response)responseCallback
{
    /// 构造 js 脚本
    NSString *jsCmd = [self.jsBridge makeInvokeH5Cmd:method data:data callBack:responseCallback once:YES];
    /// 通过 webView 执行 js 脚本
    [self.uiWebView stringByEvaluatingJavaScriptFromString:jsCmd];
}

- (SHWebViewJSBridge *)jsBridge
{
    if (!_jsBridge) {
        _jsBridge = [[SHWebViewJSBridge alloc]init];
    }
    return _jsBridge;
}

@end

