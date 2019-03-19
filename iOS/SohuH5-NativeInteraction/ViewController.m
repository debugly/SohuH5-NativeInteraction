//
//  ViewController.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "ViewController.h"
#import "SHWebView.h"
#import "SHLoginViewController.h"

#ifndef _weakSelf_SH
#define _weakSelf_SH     __weak   __typeof(self) $weakself = self;
#endif

#ifndef _strongSelf_SH
#define _strongSelf_SH   __strong __typeof($weakself) self = $weakself;
#endif

@interface ViewController ()

@property (nonatomic, weak) SHWebView *webView;
@property (nonatomic, weak) UILabel *info;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    {
        CGRect rect = self.view.bounds;
        rect.origin.y = 64;
        rect.size.height -= 64 + 44;
        SHWebView *webView = [[SHWebView alloc]initWithFrame:rect];
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:webView];
        self.webView = webView;
    
        ///注册H5将要调用的Native方法；
        [self registerNativeSupportMethod];
        
        [webView loadURL:[self h5_url]];
    }
    
    {
        UILabel *info = [[UILabel alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44)];
        info.numberOfLines = 0;
        info.textColor = [UIColor whiteColor];
        [self.view addSubview:info];
        info.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        self.info = info;
    }
}

- (NSURL *)h5_url
{
    NSString *path = [[NSBundle mainBundle]pathForResource:@"ExampleApp" ofType:@"html"];
    return [NSURL fileURLWithPath:path];
}

#pragma mark - 刷新

- (IBAction)callH5Method:(UIBarButtonItem *)sender
{
    int random = arc4random() % 1000;
    NSString *uid = [NSString stringWithFormat:@"sohu-%d",random];
    _weakSelf_SH
    ///登录完毕之后，把uid更新给H5页面
    [self.webView invokeH5:@"updateInfo" data:@{@"uid":uid} responseCallback:^(NSDictionary *ps) {
        
        _strongSelf_SH
        //ps 则是H5收到Native调用之后回调回来的参数；
        self.info.text = [NSString stringWithFormat:@"H5收到uid之后给了一个回执：%@",ps[@"text"]];
        
        UIColor *randomColor = [UIColor colorWithRed:arc4random() % 256/255.0 green:arc4random() % 256/255.0 blue:arc4random() % 256/255.0 alpha:1];
        self.info.backgroundColor = randomColor;
    }];
}

#pragma mark - 刷新页面

- (IBAction)refresh:(UIBarButtonItem *)sender
{
    self.info.text = nil;
    [self.webView loadURL:[self h5_url]];
    self.info.backgroundColor = [UIColor clearColor];
}

#pragma mark -

- (void)registerNativeSupportMethod
{
    _weakSelf_SH
    ///H5可调用showMsg方法，并接收传过来参数: text
    [self.webView registerMethod:@"showMsg" handler:^(NSDictionary *ps, SHWebSendH5Response callback) {
        _strongSelf_SH
        self.info.text = ps[@"text"];
        UIColor *randomColor = [UIColor colorWithRed:arc4random() % 256/255.0 green:arc4random() % 256/255.0 blue:arc4random() % 256/255.0 alpha:1];
        self.info.backgroundColor = randomColor;
        ///处理完消息后，给H5一个回调
        callback(@{@"status":@(200)});
    }];
    
    ///H5可调用openLoginPage方法，并接收传过来参数: from
    [self.webView registerMethod:@"openLoginPage" handler:^(NSDictionary *ps, SHWebSendH5Response callback) {
        
        _strongSelf_SH
        
        ///把H5传过来的 from，传给登录页面
        NSString *from = ps[@"from"];
        SHLoginViewController *loginVC = [[SHLoginViewController alloc]initWithFrom:from comletion:^(NSString *uid) {
            
            ///登录完毕之后，把 uid 回调给H5！
            callback(@{@"uid":uid});
            
            _strongSelf_SH
            [self.navigationController popViewControllerAnimated:YES];
        }];
        
        [self.navigationController pushViewController:loginVC animated:YES];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
