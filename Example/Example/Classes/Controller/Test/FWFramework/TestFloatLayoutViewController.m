//
//  TestFloatLayoutViewController.m
//  Example
//
//  Created by wuyong on 2020/9/3.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestFloatLayoutViewController.h"

@interface TestFloatLayoutViewController ()

@property(nonatomic, strong) FWFloatLayoutView *floatLayoutView;

@end

@implementation TestFloatLayoutViewController

- (void)renderView
{
    self.floatLayoutView = [[FWFloatLayoutView alloc] init];
    self.floatLayoutView.padding = UIEdgeInsetsMake(12, 12, 12, 12);
    self.floatLayoutView.itemMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    self.floatLayoutView.minimumItemSize = CGSizeMake(69, 29);// 以2个字的按钮作为最小宽度
    self.floatLayoutView.layer.borderWidth = 0.5;
    self.floatLayoutView.layer.borderColor = [UIColor appColorBorder].CGColor;
    [self.view addSubview:self.floatLayoutView];
    
    NSArray<NSString *> *suggestions = @[@"东野圭吾\n多行文本", @"三体", @"爱", @"红楼梦", @"理智与情感\n多行文本", @"读书热榜", @"免费榜"];
    for (NSInteger i = 0; i < suggestions.count; i++) {
        if (i < 3) {
            UILabel *label = [[UILabel alloc] init];
            label.textColor = [UIColor appColorBlackOpacityHuge];
            label.numberOfLines = 0;
            label.text = suggestions[i];
            label.font = FWFontRegular(14);
            [label fwSetBorderColor:[UIColor appColorBorder] width:0.5 cornerRadius:10];
            label.fwContentInset = UIEdgeInsetsMake(6, 20, 6, 20);
            [self.floatLayoutView addSubview:label];
        } else {
            UIButton *button = [[UIButton alloc] init];
            [button setTitleColor:[UIColor appColorBlackOpacityHuge] forState:UIControlStateNormal];
            [button fwSetBorderColor:[UIColor appColorBorder] width:0.5 cornerRadius:10];
            [button setTitle:suggestions[i] forState:UIControlStateNormal];
            button.titleLabel.font = FWFontRegular(14);
            button.titleLabel.numberOfLines = 0;
            button.contentEdgeInsets = UIEdgeInsetsMake(6, 20, 6, 20);
            [self.floatLayoutView addSubview:button];
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets padding = UIEdgeInsetsMake(36, 24, 36, 24);
    self.floatLayoutView.fwFitFrame = CGRectMake(padding.left, padding.top, CGRectGetWidth(self.view.bounds) - (padding.left + padding.right), INFINITY);
}

@end
