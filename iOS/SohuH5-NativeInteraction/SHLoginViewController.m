//
//  SHLoginViewController.m
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import "SHLoginViewController.h"

@interface SHLoginViewController ()

@property (nonatomic, copy) void(^completion)(NSString *uid);

@end

@implementation SHLoginViewController

- (instancetype)initWithFrom:(NSString *)from comletion:(void(^)(NSString *uid))completion
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        ////send log with from.
        self.completion = completion;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setBackgroundColor:[UIColor orangeColor]];
    [btn setTitle:@"点击登录" forState:UIControlStateNormal];
    btn.frame = CGRectMake((self.view.bounds.size.width - 120)/2.0, 80, 120, 40);
    [btn addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)done:(UIButton *)sender
{
    self.completion(@"qianlongxu@gmail.com");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
