//
//  TestLabelViewController.m
//  Example
//
//  Created by wuyong on 2019/8/5.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestLabelViewController.h"

@interface TestLabelViewController ()

@property (nonatomic, weak) UILabel *label;
@property (nonatomic, weak) FWAttributedLabel *attrLabel;
@property (nonatomic, weak) UITextView *textView;

@end

@implementation TestLabelViewController

- (void)renderView
{
    UILabel *label = [UILabel new];
    _label = label;
    label.backgroundColor = [UIColor lightGrayColor];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:label];
    label.fwLayoutChain.leftWithInset(10).rightWithInset(10).topWithInset(10);
    
    FWAttributedLabel *attrLabel = [FWAttributedLabel new];
    _attrLabel = attrLabel;
    attrLabel.backgroundColor = [UIColor lightGrayColor];
    attrLabel.numberOfLines = 0;
    attrLabel.font = [UIFont systemFontOfSize:16];
    attrLabel.lineSpacing = 8 - attrLabel.font.fwSpaceHeight * 2;
    [self.view addSubview:attrLabel];
    attrLabel.fwLayoutChain.leftToView(label).rightToView(label).topToBottomOfViewWithOffset(label, 10);
    
    UITextView *textView = [UITextView new];
    _textView = textView;
    textView.backgroundColor = [UIColor lightGrayColor];
    textView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:textView];
    textView.fwLayoutChain.leftToView(label).rightToView(label).topToBottomOfViewWithOffset(attrLabel, 10).height(150);
}

- (void)renderData
{
    self.label.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
    self.attrLabel.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
    self.textView.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
}

@end
