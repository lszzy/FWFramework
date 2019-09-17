//
//  BaseScrollViewController.m
//  EasiCustomer
//
//  Created by wuyong on 2018/9/21.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "BaseScrollViewController.h"

@interface BaseScrollViewController ()

@end

@implementation BaseScrollViewController

- (UIScrollView *)scrollView
{
    UIScrollView *scrollView = objc_getAssociatedObject(self, _cmd);
    if (!scrollView) {
        scrollView = [[FWViewControllerManager sharedInstance] performIntercepter:_cmd withObject:self];
        // 默认背景色
        scrollView.backgroundColor = [UIColor appColorBg];
        objc_setAssociatedObject(self, _cmd, scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return scrollView;
}

@end
