//
//  TestStateController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestStateController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestStateController () <FWViewController>

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UIButton *button;

@property (nonatomic, assign, getter=isLock) BOOL lock;

@property (nonatomic, strong) FWStateMachine *machine;

@end

@implementation TestStateController

- (void)setupSubviews
{
    UILabel *label = [UILabel new];
    self.label = label;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label]; {
        [label fw_pinHorizontalToSuperviewWithInset:10];
        [label fw_pinEdgeToSafeArea:NSLayoutAttributeTop withInset:10];
    }
    
    UIButton *button = [AppTheme largeButton];
    self.button = button;
    [button fw_addTouchTarget:self action:@selector(onClick:)];
    [self.view addSubview:button]; {
        [button fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:label withOffset:10];
        [button fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
    }
}

- (void)setupLayout
{
    // 添加状态
    FWStateObject *unread = [FWStateObject stateWithName:@"unread"];
    FWWeakifySelf();
    [unread setDidEnterBlock:^(FWStateTransition *transition) {
        FWStrongifySelf();
        
        self.label.text = @"状态：未读";
        [self.button setTitle:@"已读" forState:UIControlStateNormal];
        self.button.tag = 1;
    }];
    FWStateObject *read = [FWStateObject stateWithName:@"read"];
    [read setDidEnterBlock:^(FWStateTransition *transition) {
        FWStrongifySelf();
        
        self.label.text = @"状态：已读";
        [self.button setTitle:@"删除" forState:UIControlStateNormal];
        self.button.tag = 2;
    }];
    FWStateObject *delete = [FWStateObject stateWithName:@"delete"];
    [delete setDidEnterBlock:^(FWStateTransition *transition) {
        FWStrongifySelf();
        
        self.label.text = @"状态：删除";
        [self.button setTitle:@"恢复" forState:UIControlStateNormal];
        self.button.tag = 3;
    }];
    
    FWStateMachine *machine = [[FWStateMachine alloc] init];
    self.machine = machine;
    [machine addStates:@[unread, read, delete]];
    machine.initialState = unread;
    
    // 添加事件
    FWStateEvent *viewEvent = [FWStateEvent eventWithName:@"view" fromStates:@[unread] toState:read];
    viewEvent.fireBlock = ^(FWStateTransition *transition, void (^completion)(BOOL finished)){
        FWStrongifySelf();
        
        [self fw_showLoadingWithText:@"正在请求"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fw_hideLoading];
            
            if (![[@[@1, @2, @3, @4] fw_randomObject] isEqual:@3]) {
                completion(YES);
            } else {
                [self fw_showMessageWithText:@"请求失败"];
                completion(NO);
            }
        });
    };
    FWStateEvent *deleteEvent = [FWStateEvent eventWithName:@"trash" fromStates:@[read, unread] toState:delete];
    deleteEvent.shouldFireBlock = ^BOOL(FWStateTransition *transition){
        FWStrongifySelf();
        
        if (self.isLock) {
            [self fw_showMessageWithText:@"已锁定，不能删除"];
            return NO;
        }
        return YES;
    };
    deleteEvent.fireBlock = ^(FWStateTransition *transition, void (^completion)(BOOL finished)){
        FWStrongifySelf();
        
        [self fw_showLoadingWithText:@"正在请求"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fw_hideLoading];
            
            if (![[@[@1, @2, @3, @4] fw_randomObject] isEqual:@3]) {
                completion(YES);
            } else {
                [self fw_showMessageWithText:@"请求失败"];
                completion(NO);
            }
        });
    };
    FWStateEvent *unreadEvent = [FWStateEvent eventWithName:@"restore" fromStates:@[read, delete] toState:unread];
    unreadEvent.shouldFireBlock = ^BOOL(FWStateTransition *transition){
        FWStrongifySelf();
        
        if (self.isLock) {
            [self fw_showMessageWithText:@"已锁定，不能恢复"];
            return NO;
        }
        return YES;
    };
    unreadEvent.fireBlock = ^(FWStateTransition *transition, void (^completion)(BOOL finished)){
        FWStrongifySelf();
        
        [self fw_showLoadingWithText:@"正在请求"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fw_hideLoading];
            
            if (![[@[@1, @2, @3, @4] fw_randomObject] isEqual:@3]) {
                completion(YES);
            } else {
                [self fw_showMessageWithText:@"请求失败"];
                completion(NO);
            }
        });
    };
    [machine addEvents:@[viewEvent, deleteEvent, unreadEvent]];
    
    // 激活事件
    [machine activate];
}

- (void)setupNavbar
{
    FWWeakifySelf();
    [self fw_setRightBarItem:@"锁定" block:^(UIBarButtonItem *sender) {
        FWStrongifySelf();
        
        self.lock = !self.lock;
        sender.title = self.isLock ? @"解锁" : @"锁定";
    }];
}

- (void)onClick:(UIButton *)button
{
    NSInteger type = button.tag;
    NSString *event = nil;
    if (type == 1) {
        event = @"view";
    } else if (type == 2) {
        event = @"trash";
    } else if (type == 3) {
        event = @"restore";
    }
    
    [self.machine fireEvent:event];
}

@end
