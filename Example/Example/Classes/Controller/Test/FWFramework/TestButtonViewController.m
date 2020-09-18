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
    
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor appColorFill];
    view.frame = CGRectMake(30, 370, 70, 70);
    [self.view addSubview:view];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor grayColor];
    button.frame = CGRectMake(50, 390, 30, 30);
    button.fwTouchInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    [button fwAddTouchTarget:self action:@selector(onClick6:)];
    [self.view addSubview:button];
    
    view = [UIView new];
    view.backgroundColor = [UIColor appColorFill];
    view.frame = CGRectMake(130, 370, 70, 70);
    [self.view addSubview:view];
    
    view = [UIView new];
    view.backgroundColor = [UIColor grayColor];
    view.frame = CGRectMake(150, 390, 30, 30);
    view.fwTouchInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    [view fwAddTapGestureWithTarget:self action:@selector(onClick6:)];
    [self.view addSubview:view];
    
    UIButton *timerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton.frame = CGRectMake(30, 460, 80, 30);
    timerButton.titleLabel.font = [UIFont appFontNormal];
    [timerButton setTitleColor:[UIColor appColorBlack] forState:UIControlStateNormal];
    [timerButton setTitle:@"=>" forState:UIControlStateNormal];
    [self.view addSubview:timerButton];
    
    UIButton *timerButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton1.frame = CGRectMake(120, 460, 80, 30);
    timerButton1.titleLabel.font = [UIFont appFontNormal];
    [timerButton1 setTitleColor:[UIColor appColorBlack] forState:UIControlStateNormal];
    [timerButton1 setTitle:@"=>" forState:UIControlStateNormal];
    [self.view addSubview:timerButton1];
    
    UIButton *timerButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
    timerButton2.frame = CGRectMake(220, 460, 80, 30);
    timerButton2.titleLabel.font = [UIFont appFontNormal];
    [timerButton2 setTitleColor:[UIColor appColorBlack] forState:UIControlStateNormal];
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
    [self.view addSubview:timerButton2];
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
