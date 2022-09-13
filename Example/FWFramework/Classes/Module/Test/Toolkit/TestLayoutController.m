//
//  TestLayoutController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestLayoutController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestLayoutController () <FWViewController>

@property (nonatomic, strong) FWAttributedLabel *attributedLabel;
@property (nonatomic, assign) CGFloat buttonWidth;

@end

@implementation TestLayoutController

- (void)setupSubviews
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = AppTheme.textColor;
    [self.view addSubview:view];
    view.fw_layoutChain.remake()
        .topToSafeAreaWithInset(20)
        .leftWithInset(20)
        .size(CGSizeMake(100, 100))
        .width(50)
        .height(50)
        .priority(UILayoutPriorityDefaultHigh);
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"text";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = AppTheme.textColor;
    label.backgroundColor = AppTheme.backgroundColor;
    label.fw_contentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    [label fw_setCornerRadius:5];
    [self.view addSubview:label];
    [label fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.widthToView(view)
            .centerYToView(view)
            .leftToViewRightWithOffset(view, 20);
    }];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitleColor:[AppTheme textColor] forState:UIControlStateNormal];
    [button setTitle:@"btn" forState:UIControlStateNormal];
    [self.view addSubview:button];
    button.fw_layoutChain
        .widthToView(view)
        .heightToView(view)
        .leftToViewRightWithOffset(label, 20)
        .topToViewWithOffset(view, 0);
    
    UIImageView *image = [UIImageView new];
    image.image = [UIImage fw_appIconImage];
    [self.view addSubview:image];
    image.fw_layoutChain
        .attribute(NSLayoutAttributeWidth, NSLayoutAttributeWidth, view)
        .heightToWidth(1.0)
        .centerYToView(view)
        .attributeWithOffset(NSLayoutAttributeLeft, NSLayoutAttributeRight, button, 20);
    
    CGFloat lineHeight = ceil(FWFontRegular(16).lineHeight);
    NSString *moreText = @"点击展开";
    self.buttonWidth = [moreText fw_sizeWithFont:FWFontRegular(16)].width + 20;
    FWAttributedLabel *attr = [[FWAttributedLabel alloc] init];
    _attributedLabel = attr;
    attr.clipsToBounds = YES;
    attr.numberOfLines = 2;
    attr.lineBreakMode = kCTLineBreakByTruncatingTail;
    attr.lineTruncatingSpacing = self.buttonWidth;
    attr.backgroundColor = AppTheme.backgroundColor;
    attr.font = FWFontRegular(16);
    attr.textColor = AppTheme.textColor;
    attr.textAlignment = kCTTextAlignmentLeft;
    [self.view addSubview:attr];
    attr.fw_layoutChain
        .leftWithInset(20)
        .rightWithInset(20)
        .topToViewBottomWithOffset(view, 20);
    
    [self.attributedLabel setText:@"我是非常长的文本，要多长有多长，我会自动截断，再附加视图，不信你看嘛，我是显示不下了的文本，我是更多文本，我是更多更多的文本，我又要换行了"];
    UILabel *collapseLabel = [UILabel fw_labelWithFont:FWFontRegular(16) textColor:UIColor.blueColor text:@"点击收起"];
    collapseLabel.textAlignment = NSTextAlignmentCenter;
    collapseLabel.frame = CGRectMake(0, 0, self.buttonWidth, ceil(FWFontRegular(16).lineHeight));
    collapseLabel.userInteractionEnabled = YES;
    FWWeakifySelf();
    [collapseLabel fw_addTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.attributedLabel.lineTruncatingSpacing = self.buttonWidth;
        self.attributedLabel.numberOfLines = 2;
        self.attributedLabel.lineBreakMode = kCTLineBreakByTruncatingTail;
    }];
    [self.attributedLabel appendView:collapseLabel];
    
    UILabel *expandLabel = [UILabel fw_labelWithFont:FWFontRegular(16) textColor:UIColor.blueColor text:moreText];
    expandLabel.textAlignment = NSTextAlignmentCenter;
    expandLabel.frame = CGRectMake(0, 0, self.buttonWidth, lineHeight);
    expandLabel.userInteractionEnabled = YES;
    [expandLabel fw_addTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.attributedLabel.lineTruncatingSpacing = 0;
        self.attributedLabel.numberOfLines = 0;
        self.attributedLabel.lineBreakMode = kCTLineBreakByWordWrapping;
    }];
    self.attributedLabel.lineTruncatingAttachment = [FWAttributedLabelAttachment attachmentWith:expandLabel margin:UIEdgeInsetsZero alignment:FWAttributedAlignmentCenter maxSize:CGSizeZero];
    
    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.textColor = AppTheme.textColor;
    emptyLabel.backgroundColor = AppTheme.backgroundColor;
    [self.view addSubview:emptyLabel];
    [emptyLabel fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.topToViewBottomWithOffset(attr, 20);
        make.leftWithInset(20);
    }];
    
    UILabel *emptyLabel2 = [[UILabel alloc] init];
    emptyLabel2.textAlignment = NSTextAlignmentCenter;
    emptyLabel2.textColor = AppTheme.textColor;
    emptyLabel2.backgroundColor = AppTheme.backgroundColor;
    emptyLabel2.fw_contentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    [self.view addSubview:emptyLabel2];
    [emptyLabel2 fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftToViewRightWithOffset(emptyLabel, 20);
        make.centerYToView(emptyLabel);
    }];
    
    UILabel *resultLabel = [[UILabel alloc] init];
    CGSize emptySize = [emptyLabel sizeThatFits:CGSizeMake(1, 1)];
    CGSize emptySize2 = [emptyLabel2 sizeThatFits:CGSizeMake(1, 1)];
    resultLabel.text = [NSString stringWithFormat:@"%@ <=> %@", NSStringFromCGSize(emptySize), NSStringFromCGSize(emptySize2)];
    resultLabel.textAlignment = NSTextAlignmentCenter;
    resultLabel.textColor = AppTheme.textColor;
    [self.view addSubview:resultLabel];
    [resultLabel fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.centerX();
        make.centerYToView(emptyLabel2);
    }];
    
    UILabel *numberLabel = [UILabel new];
    numberLabel.textAlignment = NSTextAlignmentCenter;
    numberLabel.numberOfLines = 0;
    numberLabel.textColor = AppTheme.textColor;
    numberLabel.text = [self numberString];
    [self.view addSubview:numberLabel];
    [numberLabel fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftWithInset(20)
            .width((FWScreenWidth - 60) / 2.0)
            .topToViewBottomWithOffset(attr, 50);
    }];
    
    UILabel *number2Label = [UILabel new];
    number2Label.textAlignment = NSTextAlignmentCenter;
    number2Label.numberOfLines = 0;
    number2Label.textColor = AppTheme.textColor;
    number2Label.text = [self number2String];
    [self.view addSubview:number2Label];
    [number2Label fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.rightWithInset(20)
            .width((FWScreenWidth - 60) / 2.0)
            .topToViewBottomWithOffset(attr, 50);
    }];
}

- (NSString *)numberString
{
    NSNumber *number = [NSNumber numberWithDouble:45.6789];
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"number: %@\n\n", number];
    [string appendFormat:@"round: %@\n", [number fw_roundString:2]];
    [string appendFormat:@"ceil: %@\n", [number fw_ceilString:2]];
    [string appendFormat:@"floor: %@\n", [number fw_floorString:2]];
    [string appendFormat:@"round: %@\n", [number fw_roundNumber:2]];
    [string appendFormat:@"ceil: %@\n", [number fw_ceilNumber:2]];
    [string appendFormat:@"floor: %@\n\n", [number fw_floorNumber:2]];
    return string;
}

- (NSString *)number2String
{
    NSNumber *number = [NSNumber numberWithDouble:0.6049];
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"number: %@\n\n", number];
    [string appendFormat:@"round: %@\n", [number fw_roundString:2]];
    [string appendFormat:@"ceil: %@\n", [number fw_ceilString:2]];
    [string appendFormat:@"floor: %@\n", [number fw_floorString:2]];
    [string appendFormat:@"round: %@\n", [number fw_roundNumber:2]];
    [string appendFormat:@"ceil: %@\n", [number fw_ceilNumber:2]];
    [string appendFormat:@"floor: %@\n", [number fw_floorNumber:2]];
    return string;
}

@end
