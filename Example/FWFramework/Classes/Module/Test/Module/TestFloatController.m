//
//  TestFloatController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestFloatController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestFloatController () <FWViewController>

@property(nonatomic, strong) FWFloatLayoutView *floatLayoutView;

@end

@implementation TestFloatController

- (void)setupSubviews
{
    self.floatLayoutView = [[FWFloatLayoutView alloc] init];
    self.floatLayoutView.padding = UIEdgeInsetsMake(12, 12, 12, 12);
    self.floatLayoutView.itemMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    self.floatLayoutView.minimumItemSize = CGSizeMake(69, 29);// 以2个字的按钮作为最小宽度
    self.floatLayoutView.layer.borderWidth = 0.5;
    self.floatLayoutView.layer.borderColor = [AppTheme textColor].CGColor;
    [self.view addSubview:self.floatLayoutView];
    self.floatLayoutView.fw_layoutChain.leftWithInset(24).rightWithInset(24).topToSafeAreaWithInset(36);
    
    NSArray<NSString *> *suggestions = @[@"东野圭吾\n多行文本", @"三体", @"爱", @"红楼梦", @"", @"理智与情感\n多行文本", @"读书热榜", @"免费榜"];
    for (NSInteger i = 0; i < suggestions.count; i++) {
        if (i < 3) {
            UILabel *label = [[UILabel alloc] init];
            label.textColor = AppTheme.textColor;
            label.numberOfLines = 0;
            label.text = suggestions[i];
            label.font = FWFontRegular(14);
            [label fw_setBorderColor:[AppTheme textColor] width:0.5 cornerRadius:10];
            label.fw_contentInset = UIEdgeInsetsMake(6, 20, 6, 20);
            [self.floatLayoutView addSubview:label];
        } else {
            UIButton *button = [[UIButton alloc] init];
            [button setTitleColor:[AppTheme textColor] forState:UIControlStateNormal];
            [button fw_setBorderColor:[AppTheme textColor] width:0.5 cornerRadius:10];
            [button setTitle:suggestions[i] forState:UIControlStateNormal];
            button.titleLabel.font = FWFontRegular(14);
            button.titleLabel.numberOfLines = 0;
            button.contentEdgeInsets = UIEdgeInsetsMake(6, 20, 6, 20);
            button.hidden = suggestions[i].length <= 0;
            [self.floatLayoutView addSubview:button];
        }
    }
    
    [self.floatLayoutView setNeedsLayout];
    [self.floatLayoutView layoutIfNeeded];
    [self.floatLayoutView invalidateIntrinsicContentSize];
}

@end
