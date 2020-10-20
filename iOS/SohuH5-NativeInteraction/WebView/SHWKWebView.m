//
//  SHWKWebView.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import "SHWKWebView.h"

#ifndef _weakSelf_SH
#define _weakSelf_SH     __weak   __typeof(self) $weakself = self;
#endif

#ifndef _strongSelf_SH
#define _strongSelf_SH   __strong __typeof($weakself) self = $weakself;
#endif

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 80000)

#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#import "SHWebViewJSBridge.h"
#import "SHWeakProxy.h"

@interface SHWKWebView ()<WKNavigationDelegate,WKScriptMessageHandler>

@property (nonatomic, weak) WKWebView *wkWebView;
@property (nonatomic, strong) SHWebViewJSBridge *jsBridge;
@property (nonatomic, strong) NSURL *currentUrl;

@end


@implementation SHWKWebView

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
    [self.wkWebView stopLoading];
}

- (void)prepareWebView
{
    WKWebView *wkWebView = [self createSharableWKWebView];

    [self addSubview:wkWebView];
    wkWebView.frame = self.bounds;
    wkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    wkWebView.navigationDelegate = self;
    wkWebView.backgroundColor = [UIColor clearColor];
    wkWebView.opaque = NO;
    
    self.wkWebView = wkWebView;
}

- (WKWebView *)createSharableWKWebView
{
    WKUserContentController* userContentController = [WKUserContentController new];
    
    //增加messageHandler对象
    SHWeakProxy *proxy = [SHWeakProxy weakProxyWithTarget:self];
    NSString *nativeName = [SHWebViewJSBridge h5NativeMapBridgeName];
    NSAssert(nativeName, @"SHWebViewJSBridge h5NativeMapBridgeName can't be nil");
    [userContentController addScriptMessageHandler:(id <WKScriptMessageHandler>)proxy
                                              name:nativeName];
    
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;
    
    //注入js脚本
    NSString *js = [SHWebViewJSBridge javasctipt4Inject];
    WKUserScript * injectScript = [[WKUserScript alloc] initWithSource:js
                                                         injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                      forMainFrameOnly:NO];
    [userContentController addUserScript:injectScript];
    
    WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    
    return wkWebView;
}

- (void)loadURL:(NSURL *)url
{
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.wkWebView loadRequest:requestObj];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{

}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    //处理错误；
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    NSString *scheme = navigationAction.request.URL.scheme;
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if(navigationAction.targetFrame){
            policy = WKNavigationActionPolicyAllow;
        }else{
            //nil if this is a new window navigation
            policy = WKNavigationActionPolicyCancel;
            //target="_blank"浏览器上新开window；
            dispatch_async(dispatch_get_main_queue(), ^{
                [webView loadRequest:navigationAction.request];
            });
        }
    } else if ([scheme hasPrefix:@"http"]) {
        policy = WKNavigationActionPolicyAllow;
    } else if ([scheme hasPrefix:@"file"]) {
        policy = WKNavigationActionPolicyAllow;
    } else{
        NSLog(@"PolicyCancel URL:%@",navigationAction.request.URL);
        policy = WKNavigationActionPolicyCancel;
    }
    decisionHandler(policy);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"Alert:%@",message);
    completionHandler();
    //    NSAlert *alert = [[NSAlert alloc] init];
    //    [alert setMessageText:message];
    //    [alert addButtonWithTitle:@"知道了"];
    //    [alert runModal];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)h5message
{
    id body = [h5message body];
    _weakSelf_SH
    [self.jsBridge handleH5Message:body callBack:^(NSString *jsCmd) {
        _strongSelf_SH
        if(jsCmd.length > 0){
            [self.wkWebView evaluateJavaScript:jsCmd completionHandler:^(id obj, NSError * error) {
                if(error){
                    
                }
            }];
        }
    }];
}

- (void)registerMethod:(NSString *)method handler:(SHJSBridgeOnH5Message)handler
{
    [self.jsBridge registerMethod:method handler:handler];
}

- (void)invokeH5:(NSString *)method data:(NSDictionary *)data responseCallback:(SHJSBridgeOnH5Response)responseCallback
{
    /// 构造 js 脚本
    NSString *jsCmd = [self.jsBridge makeInvokeH5Cmd:method data:data callBack:responseCallback once:NO];
    /// 通过 webView 执行 js 脚本
    [self.wkWebView evaluateJavaScript:jsCmd completionHandler:^(id obj, NSError * error) {
        if(error){
            
        }
    }];
}

- (void)invokeH5Once:(NSString *)method data:(NSDictionary *)data responseCallback:(SHJSBridgeOnH5Response)responseCallback
{
    /// 构造 js 脚本
    NSString *jsCmd = [self.jsBridge makeInvokeH5Cmd:method data:data callBack:responseCallback once:YES];
    /// 通过 webView 执行 js 脚本
    [self.wkWebView evaluateJavaScript:jsCmd completionHandler:^(id obj, NSError * error) {
        if(error){
            
        }
    }];
}

- (SHWebViewJSBridge *)jsBridge
{
    if (!_jsBridge) {
        _jsBridge = [[SHWebViewJSBridge alloc]init];
    }
    return _jsBridge;
}

@end

#endif
