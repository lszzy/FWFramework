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
    view.backgroundColor = Theme.textColor;
    [self.view addSubview:view];
    view.fwLayoutChain.remake().topWithInset(20).leftWithInset(20).size(CGSizeMake(100, 100)).width(50).height(50);
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"text";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = Theme.textColor;
    label.backgroundColor = Theme.backgroundColor;
    label.fwContentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    [label fwSetCornerRadius:5];
    [self.view addSubview:label];
    [label fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.widthToView(view).centerYToView(view).leftToRightOfViewWithOffset(view, 20);
    }];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [button setTitle:@"btn" forState:UIControlStateNormal];
    [self.view addSubview:button];
    button.fwLayoutChain.widthToView(view).heightToView(view).leftToRightOfViewWithOffset(label, 20).topToViewWithOffset(view, 0);
    
    UIImageView *image = [UIImageView new];
    image.image = [UIImage fwImageWithAppIcon];
    [self.view addSubview:image];
    image.fwLayoutChain.attribute(NSLayoutAttributeWidth, NSLayoutAttributeWidth, view).attribute(NSLayoutAttributeHeight, NSLayoutAttributeHeight, view).centerYToView(view).attributeWithOffset(NSLayoutAttributeLeft, NSLayoutAttributeRight, button, 20);
    
    FWAttributedLabel *attr = [[FWAttributedLabel alloc] init];
    attr.text = @"attr";
    attr.backgroundColor = Theme.backgroundColor;
    attr.textAlignment = kCTTextAlignmentCenter;
    [self.view addSubview:attr];
    [attr fwLayoutMaker:^(FWLayoutChain *  _Nonnull make) {
        make.leftToView(view).topToBottomOfViewWithOffset(view, 20);
    }];
    [attr appendImage:[UIImage fwImageWithAppIcon:CGSizeMake(40, 40)]];
    
    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.textColor = Theme.textColor;
    emptyLabel.backgroundColor = Theme.backgroundColor;
    [self.view addSubview:emptyLabel];
    [emptyLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftToRightOfViewWithOffset(attr, 20);
        make.centerYToView(attr);
    }];
    
    UILabel *emptyLabel2 = [[UILabel alloc] init];
    emptyLabel2.textAlignment = NSTextAlignmentCenter;
    emptyLabel2.textColor = Theme.textColor;
    emptyLabel2.backgroundColor = Theme.backgroundColor;
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
    resultLabel.textColor = Theme.textColor;
    [self.view addSubview:resultLabel];
    [resultLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftToRightOfViewWithOffset(emptyLabel2, 20);
        make.centerYToView(emptyLabel2);
    }];
    
    UILabel *numberLabel = [UILabel new];
    numberLabel.textAlignment = NSTextAlignmentCenter;
    numberLabel.numberOfLines = 0;
    numberLabel.textColor = Theme.textColor;
    numberLabel.text = [self numberString];
    [self.view addSubview:numberLabel];
    [numberLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
        make.leftWithInset(20).rightWithInset(20)
            .topToBottomOfViewWithOffset(attr, 50);
    }];
}

- (NSString *)numberString
{
    NSNumber *number = [NSNumber numberWithDouble:12345.6789];
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"number: %@\n\n", number];
    [string appendFormat:@"round: %@\n", [number fwRoundString:2]];
    [string appendFormat:@"ceil: %@\n", [number fwCeilString:2]];
    [string appendFormat:@"floor: %@\n", [number fwFloorString:2]];
    [string appendFormat:@"round: %@\n", [number fwRoundNumber:2]];
    [string appendFormat:@"ceil: %@\n", [number fwCeilNumber:2]];
    [string appendFormat:@"floor: %@\n\n", [number fwFloorNumber:2]];
    
    number = [NSNumber numberWithDouble:0.6049];
    [string appendFormat:@"number: %@\n\n", number];
    [string appendFormat:@"round: %@\n", [number fwRoundString:2]];
    [string appendFormat:@"ceil: %@\n", [number fwCeilString:2]];
    [string appendFormat:@"floor: %@\n", [number fwFloorString:2]];
    [string appendFormat:@"round: %@\n", [number fwRoundNumber:2]];
    [string appendFormat:@"ceil: %@\n", [number fwCeilNumber:2]];
    [string appendFormat:@"floor: %@\n", [number fwFloorNumber:2]];
    return string;
}

@end
