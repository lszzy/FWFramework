//
//  TestEmptyViewController.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestEmptyViewController.h"

@interface TestEmptyViewController () {
    FWEmptyView *_emptyView;
}

/**
 *  空列表控件，支持显示提示文字、loading、操作按钮，该属性懒加载
 */
@property(nullable, nonatomic, strong) FWEmptyView *emptyView;

/// 当前self.emptyView是否显示
@property(nonatomic, assign, readonly, getter = isEmptyViewShowing) BOOL emptyViewShowing;

/**
 *  显示emptyView
 *  emptyView 的以下系列接口可以按需进行重写
 *
 *  @see QMUIEmptyView
 */
- (void)showEmptyView;

/**
 *  显示loading的emptyView
 */
- (void)showEmptyViewWithLoading;

/**
 *  显示带text、detailText、button的emptyView
 */
- (void)showEmptyViewWithText:(nullable NSString *)text
                   detailText:(nullable NSString *)detailText
                  buttonTitle:(nullable NSString *)buttonTitle
                 buttonAction:(nullable SEL)action;

/**
 *  显示带image、text、detailText、button的emptyView
 */
- (void)showEmptyViewWithImage:(nullable UIImage *)image
                          text:(nullable NSString *)text
                    detailText:(nullable NSString *)detailText
                   buttonTitle:(nullable NSString *)buttonTitle
                  buttonAction:(nullable SEL)action;

/**
 *  显示带loading、image、text、detailText、button的emptyView
 */
- (void)showEmptyViewWithLoading:(BOOL)showLoading
                           image:(nullable UIImage *)image
                            text:(nullable NSString *)text
                      detailText:(nullable NSString *)detailText
                     buttonTitle:(nullable NSString *)buttonTitle
                    buttonAction:(nullable SEL)action;

/**
 *  隐藏emptyView
 */
- (void)hideEmptyView;

/**
 *  布局emptyView，如果emptyView没有被初始化或者没被添加到界面上，则直接忽略掉。
 *
 *  如果有特殊的情况，子类可以重写，实现自己的样式
 *
 *  @return YES表示成功进行一次布局，NO表示本次调用并没有进行布局操作（例如emptyView还没被初始化）
 */
- (BOOL)layoutEmptyView;

@end

@implementation TestEmptyViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutEmptyView];
}

@synthesize emptyView = _emptyView;

- (FWEmptyView *)emptyView {
    if (!_emptyView && self.isViewLoaded) {
        _emptyView = [[FWEmptyView alloc] initWithFrame:self.view.bounds];
    }
    return _emptyView;
}

- (void)showEmptyView {
    [self.view addSubview:self.emptyView];
}

- (void)hideEmptyView {
    [_emptyView removeFromSuperview];
}

- (BOOL)isEmptyViewShowing {
    return _emptyView && _emptyView.superview;
}

- (void)showEmptyViewWithLoading {
    [self showEmptyView];
    [self.emptyView setImage:nil];
    [self.emptyView setLoadingViewHidden:NO];
    [self.emptyView setTextLabelText:nil];
    [self.emptyView setDetailTextLabelText:nil];
    [self.emptyView setActionButtonTitle:nil];
}

- (void)showEmptyViewWithText:(NSString *)text
                   detailText:(NSString *)detailText
                  buttonTitle:(NSString *)buttonTitle
                 buttonAction:(SEL)action {
    [self showEmptyViewWithLoading:NO image:nil text:text detailText:detailText buttonTitle:buttonTitle buttonAction:action];
}

- (void)showEmptyViewWithImage:(UIImage *)image
                          text:(NSString *)text
                    detailText:(NSString *)detailText
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(SEL)action {
    [self showEmptyViewWithLoading:NO image:image text:text detailText:detailText buttonTitle:buttonTitle buttonAction:action];
}

- (void)showEmptyViewWithLoading:(BOOL)showLoading
                           image:(UIImage *)image
                            text:(NSString *)text
                      detailText:(NSString *)detailText
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(SEL)action {
    [self showEmptyView];
    [self.emptyView setLoadingViewHidden:!showLoading];
    [self.emptyView setImage:image];
    [self.emptyView setTextLabelText:text];
    [self.emptyView setDetailTextLabelText:detailText];
    [self.emptyView setActionButtonTitle:buttonTitle];
    [self.emptyView.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.emptyView.actionButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
}

- (BOOL)layoutEmptyView {
    if (_emptyView) {
        // 由于为self.emptyView设置frame时会调用到self.view，为了避免导致viewDidLoad提前触发，这里需要判断一下self.view是否已经被初始化
        BOOL viewDidLoad = self.emptyView.superview && [self isViewLoaded];
        if (viewDidLoad) {
            CGSize newEmptyViewSize = self.emptyView.superview.bounds.size;
            CGSize oldEmptyViewSize = self.emptyView.frame.size;
            if (!CGSizeEqualToSize(newEmptyViewSize, oldEmptyViewSize)) {
                self.emptyView.frame = CGRectMake(CGRectGetMinX(self.emptyView.frame), CGRectGetMinY(self.emptyView.frame), newEmptyViewSize.width, newEmptyViewSize.height);
            }
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - 工具方法

- (void)reload:(id)sender {
    [self hideEmptyView];
    [self.tableView reloadData];
}

- (void)renderModel
{
    [self fwSetRightBarItem:@(UIBarButtonSystemItemRefresh) target:self action:@selector(reload:)];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.emptyViewShowing ? 0 : 4;
}

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if (row == 0) {
        cell.textLabel.text = @"显示loading";
    } else if (row == 1) {
        cell.textLabel.text = @"显示提示语";
    } else if (row == 2) {
        cell.textLabel.text = @"显示提示语及操作按钮";
    } else if (row == 3) {
        cell.textLabel.text = @"显示占位图及文字";
    }
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if (row == 0) {
        [self showEmptyViewWithLoading];
    } else if (row == 1) {
        [self showEmptyViewWithText:@"联系人为空" detailText:@"请到设置-隐私查看你的联系人权限设置" buttonTitle:nil buttonAction:NULL];
    } else if (row == 2) {
        [self showEmptyViewWithText:@"请求失败" detailText:@"请检查网络连接" buttonTitle:@"重试" buttonAction:@selector(reload:)];
    } else if (row == 3) {
        [self showEmptyViewWithImage:[UIImage fwImageWithAppIcon] text:nil detailText:@"图片间距可通过imageInsets来调整" buttonTitle:nil buttonAction:NULL];
    }
    [self.tableView reloadData];
}

@end
