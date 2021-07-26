//
//  TestAttributedStringViewController.m
//  Example
//
//  Created by wuyong on 2019/8/22.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestAttributedStringViewController.h"

@interface TestAttributedStringViewController ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) NSInteger count;

@end

@implementation TestAttributedStringViewController

- (void)renderView
{
    UILabel *label = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:nil];
    _label = label;
    label.backgroundColor = [Theme cellColor];
    label.numberOfLines = 0;
    [self.fwView addSubview:label];
    [label fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(15, 15, 15, 15) excludingEdge:NSLayoutAttributeBottom];
}

- (void)renderData
{
    FWAttributedOption *appearance = [FWAttributedOption appearance];
    appearance.lineHeightMultiplier = 1.5;
    appearance.font = [UIFont fwFontOfSize:16];
    appearance.paragraphStyle = [NSMutableParagraphStyle new];
    
    NSMutableAttributedString *attrString = [NSMutableAttributedString new];
    FWAttributedOption *option = [FWAttributedOption new];
    [attrString appendAttributedString:[self renderString:option]];
    
    option = [FWAttributedOption new];
    option.lineHeightMultiplier = 2;
    [attrString appendAttributedString:[self renderString:option]];
    
    option = [FWAttributedOption new];
    [attrString appendAttributedString:[self renderString:option]];
    
    option = [FWAttributedOption new];
    option.lineHeightMultiplier = 0;
    option.lineSpacingMultiplier = 1;
    [attrString appendAttributedString:[self renderString:option]];
    self.label.attributedText = attrString;
}

- (NSAttributedString *)renderString:(FWAttributedOption *)option
{
    NSString *string = @"我是很长很长很长很长很长很长很长很长的文本，我是很长很长很长很长很长很长很长很长的文本。";
    if (self.count ++ != 0) {
        string = [@"\n" stringByAppendingString:string];
    }
    return [NSAttributedString fwAttributedString:string withOption:option];
}

@end
