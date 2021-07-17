//
//  TestGridViewController.m
//  Example
//
//  Created by wuyong on 2020/9/3.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestGridViewController.h"

@interface TestGridViewController ()

@property(nonatomic, strong) FWGridView *gridView;
@property(nonatomic, strong) UILabel *tipsLabel;

@end

@implementation TestGridViewController

- (void)renderView
{
    self.gridView = [[FWGridView alloc] init];
    self.gridView.columnCount = 3;
    self.gridView.rowHeight = 60;
    self.gridView.separatorWidth = 0.5;
    self.gridView.separatorColor = [Theme borderColor];
    self.gridView.separatorDashed = NO;
    [self.fwView addSubview:self.gridView];
    self.gridView.fwLayoutChain.edgesWithInsetsExcludingEdge(UIEdgeInsetsMake(24, 24, 24, 24), NSLayoutAttributeBottom);
    
    // 将要布局的 item 以 addSubview: 的方式添加进去即可自动布局
    NSArray<UIColor *> *themeColors = @[UIColor.fwRandomColor, UIColor.fwRandomColor, UIColor.fwRandomColor, UIColor.fwRandomColor, UIColor.fwRandomColor, UIColor.fwRandomColor, UIColor.fwRandomColor, UIColor.fwRandomColor];
    for (NSInteger i = 0; i < themeColors.count; i++) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [themeColors[i] colorWithAlphaComponent:.7];
        [self.gridView addSubview:view];
    }
    
    /*
    [self.gridView setNeedsLayout];
    [self.gridView layoutIfNeeded];
    [self.gridView invalidateIntrinsicContentSize];
    */
    
    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.attributedText = [[NSAttributedString alloc] initWithString:@"适用于那种要将若干个 UIView 以九宫格的布局摆放的情况，支持显示 item 之间的分隔线。\n注意当 QMUIGridView 宽度发生较大变化时（例如横屏旋转），并不会自动增加列数，这种场景要么自己重新设置 columnCount，要么改为用 UICollectionView 实现。" attributes:@{NSFontAttributeName: FWFontRegular(12), NSForegroundColorAttributeName: [Theme textColor]}];
    self.tipsLabel.numberOfLines = 0;
    [self.fwView addSubview:self.tipsLabel];
    self.tipsLabel.fwLayoutChain.leftWithInset(24).rightWithInset(24).topToBottomOfViewWithOffset(self.gridView, 16);
}

/*
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets padding = UIEdgeInsetsMake(24, 24, 24, 24);
    CGFloat contentWidth = CGRectGetWidth(self.view.bounds) - (padding.left + padding.right);
    self.gridView.fwFitFrame = CGRectMake(padding.left, padding.right, contentWidth, INFINITY);
    
    self.tipsLabel.fwFitFrame = CGRectMake(padding.left, CGRectGetMaxY(self.gridView.frame) + 16, contentWidth, INFINITY);
}*/

@end
