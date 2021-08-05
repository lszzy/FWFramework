//
//  TestThemeExtensionViewController.m
//  Example
//
//  Created by wuyong on 2020/9/16.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestThemeExtensionViewController.h"
#import "TestTabBarViewController.h"

static const FWThemeStyle FWThemeStyleRed = 3;

@interface TestThemeExtensionViewController ()

@end

@implementation TestThemeExtensionViewController

- (void)renderView
{
    self.fwView.backgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        if (style == FWThemeStyleDark) {
            return [UIColor blackColor];
        } else if (style == FWThemeStyleLight) {
            return [UIColor whiteColor];
        } else {
            return [UIColor whiteColor];
        }
    }];
    
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        if (style == FWThemeStyleDark) {
            return [UIColor whiteColor];
        } else if (style == FWThemeStyleLight) {
            return [UIColor blackColor];
        } else {
            return [UIColor redColor];
        }
    }];
    [self.fwView addSubview:colorView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    imageView.fwThemeImage = [UIImage fwThemeImage:^UIImage *(FWThemeStyle style) {
        if (style == FWThemeStyleDark) {
            return [TestBundle imageNamed:@"theme_image_dark"];
        } else if (style == FWThemeStyleLight) {
            return [TestBundle imageNamed:@"theme_image_light"];
        } else {
            return [[TestBundle imageNamed:@"theme_image_dark"] fwImageWithTintColor:[UIColor redColor]];
        }
    }];
    [self.fwView addSubview:imageView];
    
    CALayer *layer = [CALayer new];
    layer.frame = CGRectMake(20, 160, 50, 50);
    layer.fwThemeContext = self.view;
    layer.fwThemeBackgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        if (style == FWThemeStyleDark) {
            return [UIColor whiteColor];
        } else if (style == FWThemeStyleLight) {
            return [UIColor blackColor];
        } else {
            return [UIColor redColor];
        }
    }];
    [self.fwView.layer addSublayer:layer];
    
    UILabel *themeLabel = [UILabel new];
    themeLabel.frame = CGRectMake(20, 230, FWScreenWidth, 50);
    UIColor *textColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        if (style == FWThemeStyleDark) {
            return [UIColor whiteColor];
        } else if (style == FWThemeStyleLight) {
            return [UIColor blackColor];
        } else {
            return [UIColor redColor];
        }
    }];
    themeLabel.attributedText = [NSAttributedString fwAttributedString:@"我是AttributedString" withFont:FWFontSize(16).fwBoldFont textColor:textColor];
    [self.fwView addSubview:themeLabel];
}

- (void)renderModel
{
    FWThemeMode mode = FWThemeManager.sharedInstance.mode;
    NSMutableArray *themes = [NSMutableArray arrayWithArray:@[@"系统", @"浅色"]];
    if (@available(iOS 13, *)) {
        [themes addObject:@"深色"];
    }
    NSString *title = [themes fwObjectAtIndex:mode] ?: @"红色";
    [themes addObject:@"红色"];
    FWWeakifySelf();
    [self fwSetRightBarItem:title block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:themes actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            FWThemeManager.sharedInstance.mode = (index == themes.count - 1) ? FWThemeStyleRed : index;
            [self renderModel];
            [TestTabBarViewController refreshController];
        }];
    }];
}

@end
