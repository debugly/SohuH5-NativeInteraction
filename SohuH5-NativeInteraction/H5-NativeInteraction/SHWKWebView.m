//
//  SHWKWebView.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SHWKWebView.h"

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 80000)

#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#import "SHWebViewJSBridge.h"
#import "SHWebViewJS.h"
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
    [userContentController addScriptMessageHandler:(id <WKScriptMessageHandler>)proxy name:@"shNativeObject"];
    
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;
    
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
    ///注入js调用native的函数
    NSString *js =  SHWebView_JS();
    [self.wkWebView evaluateJavaScript:js completionHandler:^(id obj, NSError * error) {
        if(error){
            NSLog(@"注入失败");
        }
    }];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    //处理错误；
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    
    decisionHandler(policy);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)h5message
{
    NSDictionary *body = [h5message body];
    _weakSelf_SH
    [self.jsBridge handleH5Message:body callBack:^(NSDictionary *body) {
        _strongSelf_SH
        [self invokeH5Handler:body];
    }];
}

- (void)invokeH5Handler:(NSDictionary *)body
{
    if (!body) {
        return;
    }
    [self executeH5Method:@"invokeH5Handler" ps:body];
}

- (void)executeH5Method:(NSString *)method ps:(NSDictionary *)ps
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:ps options:NSJSONWritingPrettyPrinted error:nil];
    NSString *psString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *js = [NSString stringWithFormat:@"window.shJSBridge.%@(%@)",method,psString];
    
    [self.wkWebView evaluateJavaScript:js completionHandler:^(id obj, NSError * error) {
        if(error){
            
        }
    }];
}

- (void)registerMethod:(NSString *)method handler:(SHWebNativeHandler)handler
{
    [self.jsBridge registerMethod:method handler:handler];
}

- (void)callH5Method:(NSString *)method data:(NSDictionary *)data responseCallback:(SHWebResponeCallback)responseCallback
{
    ///保存住该callBack；当H5回调时，调用这个callBack，实现回调
    [self.jsBridge registerCallback:method callBack:responseCallback];
    
    NSDictionary *ps = @{@"method":method,@"data":data};
    
    [self executeH5Method:@"invokeH5Method" ps:ps];
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
