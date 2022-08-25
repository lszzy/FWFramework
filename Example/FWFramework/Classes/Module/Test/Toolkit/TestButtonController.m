//
//  TestButtonController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestButtonController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestButtonController () <FWViewController>

FWPropertyAssign(NSInteger, count);

@end

@implementation TestButtonController

- (void)setupNavbar
{
    self.fw_extendedLayoutEdge = UIRectEdgeBottom;
}

- (void)setupSubviews
{
    UIButton *button = [UIButton fw_buttonWithTitle:@"Button重复点击" font:[UIFont fw_fontOfSize:15] titleColor:[AppTheme textColor]];
    button.frame = CGRectMake(25, 15, 150, 30);
    [button fw_addTouchTarget:self action:@selector(onClick1:)];
    [self.view addSubview:button];
    
    UILabel *label = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor] text:@"View重复点击"];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    label.frame = CGRectMake(200, 15, 150, 30);
    [label fw_addTapGestureWithTarget:self action:@selector(onClick2:)];
    [self.view addSubview:label];
    
    button = [UIButton fw_buttonWithTitle:@"Button不可重复点击" font:[UIFont fw_fontOfSize:15] titleColor:[AppTheme textColor]];
    button.frame = CGRectMake(25, 60, 150, 30);
    [button fw_addTouchTarget:self action:@selector(onClick3:)];
    [self.view addSubview:button];
    
    label = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor] text:@"View不可重复点击"];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    label.frame = CGRectMake(200, 60, 150, 30);
    [label fw_addTapGestureWithTarget:self action:@selector(onClick4:)];
    [self.view addSubview:label];
    
    button = [UIButton fw_buttonWithTitle:@"Button1秒内不可重复点击" font:[UIFont fw_fontOfSize:15] titleColor:[AppTheme textColor]];
    button.fw_touchEventInterval = 1;
    button.frame = CGRectMake(25, 105, 200, 30);
    [button fw_addTouchTarget:self action:@selector(onClick5:)];
    [self.view addSubview:button];
    
    UIButton *timerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton.frame = CGRectMake(30, 160, 80, 30);
    timerButton.titleLabel.font = [UIFont fw_fontOfSize:15];
    [timerButton setTitleColor:[AppTheme textColor] forState:UIControlStateNormal];
    [timerButton setTitle:@"=>" forState:UIControlStateNormal];
    [self.view addSubview:timerButton];
    
    UIButton *timerButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton1.frame = CGRectMake(120, 160, 80, 30);
    timerButton1.titleLabel.font = [UIFont fw_fontOfSize:15];
    [timerButton1 setTitleColor:[AppTheme textColor] forState:UIControlStateNormal];
    [timerButton1 setTitle:@"=>" forState:UIControlStateNormal];
    [self.view addSubview:timerButton1];
    
    UIButton *timerButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton2.frame = CGRectMake(220, 160, 80, 30);
    timerButton2.titleLabel.font = [UIFont fw_fontOfSize:15];
    [timerButton2 setTitleColor:[AppTheme textColor] forState:UIControlStateNormal];
    [timerButton2 setTitle:@"发送" forState:UIControlStateNormal];
    __block NSTimer *timer1, *timer2;
    [timerButton2  fw_addTouchBlock:^(UIButton *sender) {
        [timerButton fw_startCountDown:60 title:@"=>" waitTitle:@"%lds"];
        [timer1 invalidate];
        timer1 = [NSTimer fw_commonTimerWithCountDown:60 block:^(NSInteger countDown) {
            NSString *title = countDown > 0 ? [NSString stringWithFormat:@"%lds", countDown] : @"=>";
            [timerButton1 setTitle:title forState:UIControlStateNormal];
        }];
        [timer2 invalidate];
        NSTimeInterval startTime = NSDate.fw_currentTime;
        timer2 = [NSTimer fw_commonTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            NSInteger countDown = 60 - (NSInteger)round(NSDate.fw_currentTime - startTime);
            if (countDown < 1) [timer2 invalidate];
            NSString *title = countDown > 0 ? [NSString stringWithFormat:@"%lds", countDown] : @"发送";
            [timerButton2 setTitle:title forState:UIControlStateNormal];
            timerButton2.enabled = countDown < 1;
        } repeats:YES];
        [timer2 fire];
    }];
    [self.view addSubview:timerButton2];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(25, 205, 150, 50);
    button1.enabled = NO;
    [button1 setTitle:@"System不可点" forState:UIControlStateNormal];
    [button1 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button1.backgroundColor = FWColorHex(0xFFDA00);
    [button1 fw_setCornerRadius:5];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(200, 205, 150, 50);
    [button2 setTitle:@"System可点击" forState:UIControlStateNormal];
    [button2 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button2.backgroundColor = FWColorHex(0xFFDA00);
    [button2 fw_setCornerRadius:5];
    [self.view addSubview:button2];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    button3.frame = CGRectMake(25, 270, 150, 50);
    button3.enabled = NO;
    [button3 setTitle:@"Custom不可点" forState:UIControlStateNormal];
    [button3 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button3.backgroundColor = FWColorHex(0xFFDA00);
    [button3 fw_setCornerRadius:5];
    [self.view addSubview:button3];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeCustom];
    button4.frame = CGRectMake(200, 270, 150, 50);
    [button4 setTitle:@"Custom可点击" forState:UIControlStateNormal];
    [button4 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button4.backgroundColor = FWColorHex(0xFFDA00);
    [button4 fw_setCornerRadius:5];
    [self.view addSubview:button4];
    
    button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(25, 335, 150, 50);
    button1.enabled = NO;
    button1.fw_disabledAlpha = 0.5;
    [button1 setTitle:@"System不可点2" forState:UIControlStateNormal];
    [button1 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button1.backgroundColor = FWColorHex(0xFFDA00);
    [button1 fw_setCornerRadius:5];
    [self.view addSubview:button1];
    
    button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(200, 335, 150, 50);
    button2.fw_highlightedAlpha = 0.5;
    [button2 setTitle:@"System可点击2" forState:UIControlStateNormal];
    [button2 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button2.backgroundColor = FWColorHex(0xFFDA00);
    [button2 fw_setCornerRadius:5];
    [self.view addSubview:button2];
    
    button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    button3.frame = CGRectMake(25, 400, 150, 50);
    button3.enabled = NO;
    button3.fw_disabledAlpha = 0.3;
    button3.fw_highlightedAlpha = 0.5;
    [button3 setTitle:@"Custom不可点2" forState:UIControlStateNormal];
    [button3 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button3.backgroundColor = FWColorHex(0xFFDA00);
    [button3 fw_setCornerRadius:5];
    [self.view addSubview:button3];
    
    button4 = [UIButton buttonWithType:UIButtonTypeCustom];
    button4.frame = CGRectMake(200, 400, 150, 50);
    button4.fw_disabledAlpha = 0.3;
    button4.fw_highlightedAlpha = 0.5;
    [button4 setTitle:@"Custom可点击2" forState:UIControlStateNormal];
    [button4 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button4.backgroundColor = FWColorHex(0xFFDA00);
    [button4 fw_setCornerRadius:5];
    [self.view addSubview:button4];
    
    button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.frame = CGRectMake(25, 465, 150, 50);
    button1.backgroundColor = FWColorHex(0xFFDA00);
    [button1 fw_setCornerRadius:5];
    button1.fw_disabledAlpha = 0.3;
    button1.fw_highlightedAlpha = 0.5;
    [button1 fw_setTitle:@"按钮文字" font:FWFontSize(10) titleColor:UIColor.blackColor];
    [button1 fw_setImage:[UIImage.fw_appIconImage fw_imageWithScaleSize:CGSizeMake(24, 24)]];
    [button1 fw_setImageEdge:UIRectEdgeTop spacing:4];
    [self.view addSubview:button1];
    
    button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake(200, 465, 150, 50);
    button2.backgroundColor = FWColorHex(0xFFDA00);
    [button2 fw_setCornerRadius:5];
    button2.fw_disabledAlpha = 0.3;
    button2.fw_highlightedAlpha = 0.5;
    [button2 fw_setTitle:@"按钮文字" font:FWFontSize(10) titleColor:UIColor.blackColor];
    [button2 fw_setImage:[UIImage.fw_appIconImage fw_imageWithScaleSize:CGSizeMake(24, 24)]];
    [button2 fw_setImageEdge:UIRectEdgeLeft spacing:4];
    [self.view addSubview:button2];
    
    button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    button3.frame = CGRectMake(25, 530, 150, 50);
    button3.backgroundColor = FWColorHex(0xFFDA00);
    [button3 fw_setCornerRadius:5];
    button3.fw_disabledAlpha = 0.3;
    button3.fw_highlightedAlpha = 0.5;
    [button3 fw_setTitle:@"按钮文字" font:FWFontSize(10) titleColor:UIColor.blackColor];
    [button3 fw_setImage:[UIImage.fw_appIconImage fw_imageWithScaleSize:CGSizeMake(24, 24)]];
    [button3 fw_setImageEdge:UIRectEdgeBottom spacing:4];
    [self.view addSubview:button3];
    
    button4 = [UIButton buttonWithType:UIButtonTypeCustom];
    button4.frame = CGRectMake(200, 530, 150, 50);
    button4.backgroundColor = FWColorHex(0xFFDA00);
    [button4 fw_setCornerRadius:5];
    button4.fw_disabledAlpha = 0.3;
    button4.fw_highlightedAlpha = 0.5;
    [button4 fw_setTitle:@"按钮文字" font:FWFontSize(10) titleColor:UIColor.blackColor];
    [button4 fw_setImage:[UIImage.fw_appIconImage fw_imageWithScaleSize:CGSizeMake(24, 24)]];
    [button4 fw_setImageEdge:UIRectEdgeRight spacing:4];
    [self.view addSubview:button4];
}

#pragma mark - Action

- (void)onClick1:(UIButton *)sender
{
    self.count += 1;
    [self showCount];
}

- (void)onClick2:(UITapGestureRecognizer *)sender
{
    self.count += 1;
    [self showCount];
}

- (void)onClick3:(UIButton *)sender
{
    self.count += 1;
    [self showCount];
    
    sender.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
    });
}

- (void)onClick4:(UITapGestureRecognizer *)gesture
{
    self.count += 1;
    [self showCount];
    
    gesture.view.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        gesture.view.userInteractionEnabled = YES;
    });
}

- (void)onClick5:(UIButton *)sender
{
    self.count += 1;
    [self showCount];
}

- (void)showCount
{
    [UIWindow fw_showMessageWithText:[NSString stringWithFormat:@"点击计数：%@", @(self.count)]];
}

@end
