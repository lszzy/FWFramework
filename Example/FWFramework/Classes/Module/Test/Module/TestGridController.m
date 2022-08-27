//
//  TestGridController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestGridController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestGridController () <FWViewController>

@property(nonatomic, strong) FWGridView *gridView;
@property(nonatomic, strong) UILabel *tipsLabel;

@end

@implementation TestGridController

- (void)setupSubviews
{
    self.gridView = [[FWGridView alloc] init];
    self.gridView.columnCount = 3;
    self.gridView.rowHeight = 60;
    self.gridView.separatorWidth = 0.5;
    self.gridView.separatorColor = [AppTheme borderColor];
    self.gridView.separatorDashed = NO;
    [self.view addSubview:self.gridView];
    self.gridView.fw_layoutChain.edgesToSafeAreaWithInsetsExcludingEdge(UIEdgeInsetsMake(24, 24, 24, 24), NSLayoutAttributeBottom);
    
    // 将要布局的 item 以 addSubview: 的方式添加进去即可自动布局
    NSArray<UIColor *> *themeColors = @[UIColor.fw_randomColor, UIColor.fw_randomColor, UIColor.fw_randomColor, UIColor.fw_randomColor, UIColor.fw_randomColor, UIColor.fw_randomColor, UIColor.fw_randomColor, UIColor.fw_randomColor];
    for (NSInteger i = 0; i < themeColors.count; i++) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [themeColors[i] colorWithAlphaComponent:.7];
        [self.gridView addSubview:view];
    }
    
    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.attributedText = [[NSAttributedString alloc] initWithString:@"适用于那种要将若干个 UIView 以九宫格的布局摆放的情况，支持显示 item 之间的分隔线。\n注意当宽度发生较大变化时（例如横屏旋转），并不会自动增加列数，这种场景要么自己重新设置 columnCount，要么改为用 UICollectionView 实现。" attributes:@{NSFontAttributeName: FWFontRegular(12), NSForegroundColorAttributeName: [AppTheme textColor]}];
    self.tipsLabel.numberOfLines = 0;
    [self.view addSubview:self.tipsLabel];
    self.tipsLabel.fw_layoutChain.leftWithInset(24).rightWithInset(24).topToViewBottomWithOffset(self.gridView, 16);
}

@end
