//
//  SHLoginViewController.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHLoginViewController : UIViewController

/**
 模拟登录页面

 @param from 用于统计入口
 @param completion 登录完毕后回调 uid
 */
- (instancetype)initWithFrom:(NSString *)from comletion:(void(^)(NSString *uid))completion;

@end
