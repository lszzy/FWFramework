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
    UIButton *button = [UIButton fwButtonWithFont:[UIFont fwFontOfSize:15] titleColor:[Theme textColor] title:@"Button重复点击"];
    button.frame = CGRectMake(25, 20, 150, 50);
    [button fwAddTouchTarget:self action:@selector(onClick1:)];
    [self.fwView addSubview:button];
    
    UILabel *label = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:@"View重复点击"];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    label.frame = CGRectMake(200, 20, 150, 50);
    [label fwAddTapGestureWithTarget:self action:@selector(onClick2:)];
    [self.fwView addSubview:label];
    
    button = [UIButton fwButtonWithFont:[UIFont fwFontOfSize:15] titleColor:[Theme textColor] title:@"Button不可重复点击"];
    button.frame = CGRectMake(25, 90, 150, 50);
    [button fwAddTouchTarget:self action:@selector(onClick3:)];
    [self.fwView addSubview:button];
    
    label = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:@"View不可重复点击"];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    label.frame = CGRectMake(200, 90, 150, 50);
    [label fwAddTapGestureWithTarget:self action:@selector(onClick4:)];
    [self.fwView addSubview:label];
    
    button = [UIButton fwButtonWithFont:[UIFont fwFontOfSize:15] titleColor:[Theme textColor] title:@"Button1秒内不可重复点击"];
    button.fwTouchEventInterval = 1;
    button.frame = CGRectMake(25, 160, 200, 50);
    [button fwAddTouchTarget:self action:@selector(onClick5:)];
    [self.fwView addSubview:button];
    
    UIView *view = [UIView new];
    view.backgroundColor = [Theme textColor];
    view.frame = CGRectMake(30, 230, 70, 70);
    [self.fwView addSubview:view];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [Theme textColor];
    button.frame = CGRectMake(50, 250, 30, 30);
    button.fwTouchInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    [button fwAddTouchTarget:self action:@selector(onClick6:)];
    [self.fwView addSubview:button];
    
    view = [UIView new];
    view.backgroundColor = [Theme textColor];
    view.frame = CGRectMake(130, 230, 70, 70);
    [self.fwView addSubview:view];
    
    view = [UIView new];
    view.backgroundColor = [Theme textColor];
    view.frame = CGRectMake(150, 250, 30, 30);
    view.fwTouchInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    [view fwAddTapGestureWithTarget:self action:@selector(onClick6:)];
    [self.fwView addSubview:view];
    
    UIButton *timerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton.frame = CGRectMake(30, 300, 80, 30);
    timerButton.titleLabel.font = [UIFont fwFontOfSize:15];
    [timerButton setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [timerButton setTitle:@"=>" forState:UIControlStateNormal];
    [self.fwView addSubview:timerButton];
    
    UIButton *timerButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton1.frame = CGRectMake(120, 300, 80, 30);
    timerButton1.titleLabel.font = [UIFont fwFontOfSize:15];
    [timerButton1 setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [timerButton1 setTitle:@"=>" forState:UIControlStateNormal];
    [self.fwView addSubview:timerButton1];
    
    UIButton *timerButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton2.frame = CGRectMake(220, 300, 80, 30);
    timerButton2.titleLabel.font = [UIFont fwFontOfSize:15];
    [timerButton2 setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [timerButton2 setTitle:@"发送" forState:UIControlStateNormal];
    __block NSTimer *timer1, *timer2;
    [timerButton2 fwAddTouchBlock:^(UIButton *sender) {
        [timerButton fwCountDown:60 title:@"=>" waitTitle:@"%lds"];
        [timer1 invalidate];
        timer1 = [NSTimer fwCommonTimerWithCountDown:60 block:^(NSInteger countDown) {
            NSString *title = countDown > 0 ? [NSString stringWithFormat:@"%lds", countDown] : @"=>";
            [timerButton1 setTitle:title forState:UIControlStateNormal];
        }];
        [timer2 invalidate];
        NSTimeInterval startTime = NSDate.fwCurrentTime;
        timer2 = [NSTimer fwCommonTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            NSInteger countDown = 60 - (NSInteger)(NSDate.fwCurrentTime - startTime);
            if (countDown < 1) [timer2 invalidate];
            NSString *title = countDown > 0 ? [NSString stringWithFormat:@"%lds", countDown] : @"发送";
            [timerButton2 setTitle:title forState:UIControlStateNormal];
        } repeats:YES];
        [timer2 fire];
    }];
    [self.fwView addSubview:timerButton2];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(25, 370, 150, 50);
    button1.enabled = NO;
    [button1 setTitle:@"System不可点" forState:UIControlStateNormal];
    [button1 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button1.backgroundColor = FWColorHex(0xFFDA00);
    [button1 fwSetCornerRadius:5];
    [self.fwView addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(200, 370, 150, 50);
    [button2 setTitle:@"System可点击" forState:UIControlStateNormal];
    [button2 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button2.backgroundColor = FWColorHex(0xFFDA00);
    [button2 fwSetCornerRadius:5];
    [self.fwView addSubview:button2];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    button3.frame = CGRectMake(25, 430, 150, 50);
    button3.enabled = NO;
    [button3 setTitle:@"Custom不可点" forState:UIControlStateNormal];
    [button3 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button3.backgroundColor = FWColorHex(0xFFDA00);
    [button3 fwSetCornerRadius:5];
    [self.fwView addSubview:button3];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeCustom];
    button4.frame = CGRectMake(200, 430, 150, 50);
    [button4 setTitle:@"Custom可点击" forState:UIControlStateNormal];
    [button4 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button4.backgroundColor = FWColorHex(0xFFDA00);
    [button4 fwSetCornerRadius:5];
    [self.fwView addSubview:button4];
    
    button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(25, 500, 150, 50);
    button1.enabled = NO;
    button1.fwDisabledAlpha = 0.5;
    [button1 setTitle:@"System不可点2" forState:UIControlStateNormal];
    [button1 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button1.backgroundColor = FWColorHex(0xFFDA00);
    [button1 fwSetCornerRadius:5];
    [self.fwView addSubview:button1];
    
    button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(200, 500, 150, 50);
    button2.fwHighlightedAlpha = 0.5;
    [button2 setTitle:@"System可点击2" forState:UIControlStateNormal];
    [button2 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button2.backgroundColor = FWColorHex(0xFFDA00);
    [button2 fwSetCornerRadius:5];
    [self.fwView addSubview:button2];
    
    button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    button3.frame = CGRectMake(25, 570, 150, 50);
    button3.enabled = NO;
    button3.fwDisabledAlpha = 0.3;
    button3.fwHighlightedAlpha = 0.5;
    [button3 setTitle:@"Custom不可点2" forState:UIControlStateNormal];
    [button3 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button3.backgroundColor = FWColorHex(0xFFDA00);
    [button3 fwSetCornerRadius:5];
    [self.fwView addSubview:button3];
    
    button4 = [UIButton buttonWithType:UIButtonTypeCustom];
    button4.frame = CGRectMake(200, 570, 150, 50);
    button4.fwDisabledAlpha = 0.3;
    button4.fwHighlightedAlpha = 0.5;
    [button4 setTitle:@"Custom可点击2" forState:UIControlStateNormal];
    [button4 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button4.backgroundColor = FWColorHex(0xFFDA00);
    [button4 fwSetCornerRadius:5];
    [self.fwView addSubview:button4];
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

- (void)onClick6:(id)sender
{
    NSLog(@"触发点击: %@", NSStringFromClass([sender class]));
}

@end
