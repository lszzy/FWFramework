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
    [self.view addSubview:label];
    [label fwLayoutMaker:^(id<FWLayoutChainProtocol> make) {
        make.sizeToView(view).topToView(view).leftToRightOfViewWithOffset(view, 20);
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
    [attr fwLayoutMaker:^(id<FWLayoutChainProtocol>  _Nonnull make) {
        make.leftToView(view).topToBottomOfViewWithOffset(view, 20);
    }];
    [attr appendImage:[UIImage fwImageWithAppIcon:CGSizeMake(40, 40)]];
}

@end
