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
@property (nonatomic, weak) UILabel *label2;
@property (nonatomic, weak) FWAttributedLabel *attrLabel;
@property (nonatomic, weak) FWAttributedLabel *attrLabel2;
@property (nonatomic, weak) UITextView *textView;
@property (nonatomic, weak) UITextView *textView2;

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
    
    UILabel *label2 = [UILabel new];
    _label2 = label2;
    label2.backgroundColor = [UIColor lightGrayColor];
    label2.numberOfLines = 0;
    label2.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:label2];
    label2.fwLayoutChain.leftToView(label).rightToView(label).topToBottomOfViewWithOffset(label, 10);
    
    FWAttributedLabel *attrLabel = [FWAttributedLabel new];
    _attrLabel = attrLabel;
    attrLabel.backgroundColor = [UIColor lightGrayColor];
    attrLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:attrLabel];
    attrLabel.fwLayoutChain.leftToView(label).rightToView(label).topToBottomOfViewWithOffset(label2, 10);
    
    FWAttributedLabel *attrLabel2 = [FWAttributedLabel new];
    _attrLabel2 = attrLabel2;
    attrLabel2.backgroundColor = [UIColor lightGrayColor];
    attrLabel2.numberOfLines = 0;
    attrLabel2.font = [UIFont systemFontOfSize:16];
    attrLabel2.lineSpacing = 8 - attrLabel.font.fwSpaceHeight * 2;
    [self.view addSubview:attrLabel2];
    attrLabel2.fwLayoutChain.leftToView(label).rightToView(label).topToBottomOfViewWithOffset(attrLabel, 10);
    
    UITextView *textView = [UITextView new];
    _textView = textView;
    textView.editable = NO;
    textView.backgroundColor = [UIColor lightGrayColor];
    textView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:textView];
    textView.fwLayoutChain.leftToView(label).rightToView(label).topToBottomOfViewWithOffset(attrLabel2, 10).height(120);
    
    UITextView *textView2 = [UITextView new];
    _textView2 = textView2;
    textView2.editable = NO;
    textView2.backgroundColor = [UIColor lightGrayColor];
    textView2.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:textView2];
    textView2.fwLayoutChain.leftToView(label).rightToView(label).topToBottomOfViewWithOffset(textView, 10).height(120);
}

- (void)renderData
{
    self.label.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
    self.label2.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
    self.attrLabel.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
    self.attrLabel2.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
    self.textView.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
    self.textView2.text = @"我是很长很长的文本我是很长很长的文本我是很长很长的文本\n我是很长很长的文本我是很长很长的文本我是很长很长的文本";
}

@end
