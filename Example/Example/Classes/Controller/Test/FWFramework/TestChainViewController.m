/*!
 @header     TestChainViewController.m
 @indexgroup Example
 @brief      TestChainViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import "TestChainViewController.h"

@implementation TestChainViewController

- (void)renderView
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor redColor];
    [self.view addSubview:view];
    view.fwLayoutChain.remake().topWithInset(20).leftWithInset(20).size(CGSizeMake(100, 100)).width(50).height(50);
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"text";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.appColorBlack;
    label.backgroundColor = UIColor.grayColor;
    label.fwContentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    [label fwSetCornerRadius:5];
    [self.view addSubview:label];
    [label fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.widthToView(view).centerYToView(view).leftToRightOfViewWithOffset(view, 20);
    }];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitleColor:[UIColor appColorBlack] forState:UIControlStateNormal];
    [button setTitle:@"btn" forState:UIControlStateNormal];
    [self.view addSubview:button];
    button.fwLayoutChain.widthToView(view).heightToView(view).leftToRightOfViewWithOffset(label, 20).topToViewWithOffset(view, 0);
    
    UIImageView *image = [UIImageView new];
    image.image = [UIImage fwImageWithAppIcon];
    [self.view addSubview:image];
    image.fwLayoutChain.attribute(NSLayoutAttributeWidth, NSLayoutAttributeWidth, view).attribute(NSLayoutAttributeHeight, NSLayoutAttributeHeight, view).centerYToView(view).attributeWithOffset(NSLayoutAttributeLeft, NSLayoutAttributeRight, button, 20);
    
    FWAttributedLabel *attr = [[FWAttributedLabel alloc] init];
    attr.text = @"attr";
    attr.backgroundColor = [UIColor grayColor];
    attr.textAlignment = kCTTextAlignmentCenter;
    [self.view addSubview:attr];
    [attr fwLayoutMaker:^(FWLayoutChain *  _Nonnull make) {
        make.leftToView(view).topToBottomOfViewWithOffset(view, 20);
    }];
    [attr appendImage:[UIImage fwImageWithAppIcon:CGSizeMake(40, 40)]];
    
    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.textColor = UIColor.appColorBlack;
    emptyLabel.backgroundColor = UIColor.grayColor;
    [self.view addSubview:emptyLabel];
    [emptyLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftToRightOfViewWithOffset(attr, 20);
        make.centerYToView(attr);
    }];
    
    UILabel *emptyLabel2 = [[UILabel alloc] init];
    emptyLabel2.textAlignment = NSTextAlignmentCenter;
    emptyLabel2.textColor = UIColor.appColorBlack;
    emptyLabel2.backgroundColor = UIColor.grayColor;
    emptyLabel2.fwContentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    [self.view addSubview:emptyLabel2];
    [emptyLabel2 fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftToRightOfViewWithOffset(emptyLabel, 20);
        make.centerYToView(emptyLabel);
    }];
    
    UILabel *resultLabel = [[UILabel alloc] init];
    CGSize emptySize = [emptyLabel sizeThatFits:CGSizeMake(1, 1)];
    CGSize emptySize2 = [emptyLabel2 sizeThatFits:CGSizeMake(1, 1)];
    resultLabel.text = [NSString stringWithFormat:@"%@ <=> %@", NSStringFromCGSize(emptySize), NSStringFromCGSize(emptySize2)];
    resultLabel.textAlignment = NSTextAlignmentCenter;
    resultLabel.textColor = UIColor.appColorBlack;
    [self.view addSubview:resultLabel];
    [resultLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftToRightOfViewWithOffset(emptyLabel2, 20);
        make.centerYToView(emptyLabel2);
    }];
}

@end
