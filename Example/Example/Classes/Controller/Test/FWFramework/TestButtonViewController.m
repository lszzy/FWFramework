/*!
 @header     TestButtonViewController.m
 @indexgroup Example
 @brief      TestButtonViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/20
 */

#import "TestButtonViewController.h"

@implementation TestButtonViewController

- (void)renderView
{
    UIButton *button = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorBlack] title:@"Button重复点击"];
    button.frame = CGRectMake(20, 20, 200, 50);
    [button fwAddTouchTarget:self action:@selector(onClick1:)];
    [self.view addSubview:button];
    
    UILabel *label = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlack] text:@"View重复点击"];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    label.frame = CGRectMake(20, 90, 200, 50);
    [label fwAddTapGestureWithTarget:self action:@selector(onClick2:)];
    [self.view addSubview:label];
    
    button = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorBlack] title:@"Button不可重复点击"];
    button.frame = CGRectMake(20, 160, 200, 50);
    [button fwAddTouchTarget:self action:@selector(onClick3:)];
    [self.view addSubview:button];
    
    label = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlack] text:@"View不可重复点击"];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    label.frame = CGRectMake(20, 230, 200, 50);
    [label fwAddTapGestureWithTarget:self action:@selector(onClick4:)];
    [self.view addSubview:label];
    
    button = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorBlack] title:@"Button1秒内不可重复点击"];
    button.fwTouchEventInterval = 1;
    button.frame = CGRectMake(20, 300, 200, 50);
    [button fwAddTouchTarget:self action:@selector(onClick5:)];
    [self.view addSubview:button];
}

#pragma mark - Action

- (void)onClick1:(UIButton *)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Button重复点击触发事件");
    });
}

- (void)onClick2:(UITapGestureRecognizer *)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Label重复点击触发事件");
    });
}

- (void)onClick3:(UIButton *)sender
{
    sender.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Button不可重复点击触发事件");
        sender.enabled = YES;
    });
}

- (void)onClick4:(UITapGestureRecognizer *)gesture
{
    gesture.view.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Label不可重复点击触发事件");
        gesture.view.userInteractionEnabled = YES;
    });
}

- (void)onClick5:(UIButton *)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Button1秒内不可重复点击触发事件");
    });
}

@end
