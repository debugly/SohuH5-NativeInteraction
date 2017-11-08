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
    id body = [h5message body];
    _weakSelf_SH
    [self.jsBridge handleH5Message:body callBack:^(NSString *jsonText) {
        _strongSelf_SH
        [self invokeH5:jsonText];
    }];
}

- (void)invokeH5:(NSString *)jsonText
{
    NSString *js = [NSString stringWithFormat:@"window.shJSBridge.invokeH5(%@)",jsonText];
    
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
    
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    [m setValue:@"method" forKey:@"type"];
    
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    [message setObject:method forKey:@"method"];
    
    if (data) {
        [message setObject:data forKey:@"data"];
    }
    [m setValue:message forKey:@"message"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:m options:NSJSONWritingPrettyPrinted error:nil];
    NSString *josnText = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self invokeH5:josnText];
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
