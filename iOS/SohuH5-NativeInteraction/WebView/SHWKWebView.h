//
//  SHWKWebView.h
//  SohuH5-NativeInteraction
//
//  Created by 许乾隆 on 2017/10/26.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHWebViewHeader.h"

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 80000)

API_AVAILABLE(ios(8.0))
@interface SHWKWebView : UIView<SHWebViewProtocol>

@end

#endif
