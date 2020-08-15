//
//  TestThemeViewController.m
//  Example
//
//  Created by wuyong on 2020/8/14.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestThemeViewController.h"

@interface TestThemeViewController ()

@property (nonatomic, strong) NSMutableArray *themeViews;

@end

@implementation TestThemeViewController

- (void)renderInit
{
    self.themeViews = [NSMutableArray new];
}

- (void)addView:(id)view
{
    [self.themeViews addObject:view];
    if ([view isKindOfClass:[UIView class]]) {
        [self.view addSubview:view];
    } else {
        [self.view.layer addSublayer:view];
    }
}

- (void)removeViews
{
    [self.themeViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIView class]]) {
            [obj removeFromSuperview];
        } else {
            [obj removeFromSuperlayer];
        }
    }];
}

- (void)renderView
{
    self.view.backgroundColor = [UIColor fwThemeLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    [self addView:colorView];
    
    colorView = [[UIView alloc] initWithFrame:CGRectMake(90, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
    }];
    [self addView:colorView];
    
    colorView = [[UIView alloc] initWithFrame:CGRectMake(160, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeNamed:@"theme_color"];
    [self addView:colorView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    imageView.image = [UIImage fwThemeLight:[UIImage imageNamed:@"theme_image_light"] dark:[UIImage imageNamed:@"theme_image_dark"]];
    [self addView:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(90, 90, 50, 50)];
    imageView.image = [UIImage fwThemeImage:^UIImage *(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIImage imageNamed:@"theme_image_dark"] : [UIImage imageNamed:@"theme_image_light"];
    }];
    [self addView:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 90, 50, 50)];
    imageView.image = [UIImage fwThemeNamed:@"theme_image"];
    [self addView:imageView];
    
    CALayer *layer = [CALayer new];
    layer.frame = CGRectMake(20, 160, 50, 50);
    layer.backgroundColor = [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]].CGColor;
    [self addView:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(90, 160, 50, 50);
    layer.backgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
    }].CGColor;
    [self addView:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(160, 160, 50, 50);
    layer.backgroundColor = [UIColor fwThemeNamed:@"theme_color"].CGColor;
    [self addView:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(20, 230, 50, 50);
    layer.contents = (id)[UIImage fwThemeLight:[UIImage imageNamed:@"theme_image_light"] dark:[UIImage imageNamed:@"theme_image_dark"]].CGImage;
    [self addView:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(90, 230, 50, 50);
    layer.contents = (id)[UIImage fwThemeImage:^UIImage * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIImage imageNamed:@"theme_image_dark"] : [UIImage imageNamed:@"theme_image_light"];
    }].CGImage;
    [self addView:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(160, 230, 50, 50);
    layer.contents = (id)[UIImage fwThemeNamed:@"theme_image"].CGImage;
    [self addView:layer];
}

- (void)renderModel
{
    FWThemeMode mode = FWThemeManager.sharedInstance.mode;
    NSString *title = mode == FWThemeModeSystem ? @"系统" : (mode == FWThemeModeDark ? @"深色" : @"浅色");
    FWWeakifySelf();
    [self fwSetRightBarItem:title block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"系统", @"浅色", @"深色"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            FWThemeManager.sharedInstance.mode = index;
            if (@available(iOS 13, *)) { } else {
                [self removeViews];
                [self renderView];
            }
            [self renderModel];
        }];
    }];
}

@end
