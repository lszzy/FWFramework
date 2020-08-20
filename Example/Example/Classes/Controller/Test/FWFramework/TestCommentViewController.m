//
//  TestCommentViewController.m
//  Example
//
//  Created by wuyong on 2020/8/20.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestCommentViewController.h"

@interface TestCommentViewController ()

FWPropertyStrong(UIView *, inputView);

FWPropertyStrong(UITextField *, textField);

FWPropertyStrong(NSString *, replyComment);

FWPropertyStrong(NSLayoutConstraint *, inputConstraint);

FWPropertyAssign(BOOL, weixinMode);

@end

@implementation TestCommentViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 切换模式
    FWWeakifySelf();
    [self fwSetRightBarItem:@"切换" block:^(id sender) {
        FWStrongifySelf();
        
        // 微信模式
        if (!self.weixinMode) {
            self.inputView.hidden = YES;
            self.inputConstraint.constant = 50;
            self.weixinMode = YES;
        // 默认模式
        } else {
            self.inputView.hidden = NO;
            self.inputConstraint.constant = 0;
            self.weixinMode = NO;
        }
    }];
    
    // 微信模式隐藏输入框
    [self fwObserveNotification:UIKeyboardWillShowNotification block:^(NSNotification *notification) {
        FWStrongifySelf();
        
        if (self.weixinMode) {
            self.inputView.hidden = NO;
        }
    }];
    [self fwObserveNotification:UIKeyboardWillHideNotification block:^(NSNotification *notification) {
        FWStrongifySelf();
        
        if (self.weixinMode) {
            self.inputView.hidden = YES;
        }
    }];
    
    // 自动滚动到回复的评论
    [self fwObserveNotification:UIKeyboardDidShowNotification block:^(NSNotification *notification) {
        FWStrongifySelf();
        
        if (self.replyComment) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.tableData indexOfObject:self.replyComment] inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

#pragma mark - UITableView

- (void)renderTableLayout
{
    // 输入框
    UIView *inputView = [UIView fwAutoLayoutView];
    self.inputView = inputView;
    inputView.backgroundColor = [UIColor appColorWhite];
    [inputView fwSetBorderColor:[UIColor appColorBlackOpacityTiny] width:0.5];
    [self.view addSubview:inputView]; {
        [inputView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
        [inputView fwSetDimension:NSLayoutAttributeHeight toSize:50];
    }
    
    UITextField *textField = [UITextField fwAutoLayoutView];
    self.textField = textField;
    textField.fwKeyboardView = inputView;
    textField.placeholder = @"说点什么吧...";
    [textField fwSetBorderColor:[UIColor appColorBlackOpacityTiny] width:0.5 cornerRadius:kAppCornerRadiusNormal];
    FWWeakifySelf();
    textField.fwReturnBlock = ^(UITextField *textField){
        FWStrongifySelf();
        
        [self onSubmit];
    };
    [inputView addSubview:textField]; {
        [textField fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(kAppPaddingNormal, kAppPaddingLarge, kAppPaddingNormal, 0) excludingEdge:NSLayoutAttributeRight];
        [textField fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:50];
    }
    
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [submitButton setTitle:@"发布" forState:UIControlStateNormal];
    [submitButton fwAddTouchTarget:self action:@selector(onSubmit)];
    [inputView addSubview:submitButton]; {
        [submitButton fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeLeft];
        [submitButton fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:textField];
    }
    
    // 布局
    [self.tableView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
    self.inputConstraint = [self.tableView fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:self.inputView];
}

- (void)renderView
{
    UIView *tableHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 100 + kAppPaddingLarge)];
    self.tableView.tableHeaderView = tableHeader;
    
    UIView *commentView = [UIView fwAutoLayoutView];
    commentView.backgroundColor = [UIColor appColorWhite];
    [tableHeader addSubview:commentView]; {
        [commentView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
        [commentView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    }
    
    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [commentButton setTitle:@"评论" forState:UIControlStateNormal];
    [commentButton fwAddTouchTarget:self action:@selector(onComment)];
    [commentView addSubview:commentButton]; {
        [commentButton fwAlignCenterToSuperview];
    }
}

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSString *comment = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@，点击回复", comment];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSString *comment = [self.tableData objectAtIndex:indexPath.row];
    [self onReply:comment];
}

- (void)renderData
{
    FWWeakifySelf();
    [self.tableView fwAddInfiniteScrollWithBlock:^{
        FWStrongifySelf();
        
        NSInteger count = self.tableData.count;
        for (int i = 1; i <= 10; i++) {
            [self.tableData addObject:[NSString stringWithFormat:@"评论%@", @(count + i)]];
        }
        
        [self.tableView.fwInfiniteScrollView stopAnimating];
        self.tableView.fwShowInfiniteScroll = self.tableData.count < 30;
        [self.tableView reloadData];
    }];
    
    [self.tableView fwTriggerInfiniteScroll];
}

#pragma mark - UIScrollView

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self resetTextField:NO];
}

#pragma mark - Private

- (void)resetTextField:(BOOL)force
{
    [self.textField resignFirstResponder];
    
    if (force || self.textField.text.length <= 0) {
        self.textField.text = @"";
        self.textField.placeholder = @"说点什么吧...";
        self.replyComment = nil;
        self.textField.fwKeyboardView = self.inputView;
    }
}

#pragma mark - Action

- (void)onComment
{
    [self onReply:nil];
}

- (void)onReply:(NSString *)comment
{
    self.replyComment = comment;
    self.textField.fwKeyboardView = self.replyComment ? self.view : self.inputView;
    
    self.textField.text = @"";
    if (comment) {
        self.textField.placeholder = [NSString stringWithFormat:@"回复[%@]", comment];
    } else {
        self.textField.placeholder = @"说点什么吧...";
    }
    
    [self.textField becomeFirstResponder];
}

- (void)onSubmit
{
    NSString *message = [self.textField.text fwTrimString];
    
    if (message.fwUnicodeLength <= 0) {
        [self resetTextField:YES];
        [self fwShowAlertWithTitle:nil message:@"请输入评论内容" cancel:@"确定" cancelBlock:nil];
        return;
    }
    
    if (message.fwUnicodeLength > 200) {
        [self fwShowAlertWithTitle:nil message:@"字数超过限制啦" cancel:@"确定" cancelBlock:nil];
        return;
    }
    
    [self.textField resignFirstResponder];
    
    [self.view fwShowToastWithAttributedText:[[NSAttributedString alloc] initWithString:@"发布成功"]];
    [self.view fwHideToastAfterDelay:2.0 completion:nil];
    
    [self.tableData insertObject:message atIndex:0];
    [self.tableView reloadData];
    [self resetTextField:YES];
}

@end
