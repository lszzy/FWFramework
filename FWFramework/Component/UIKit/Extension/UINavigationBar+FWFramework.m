//
//  UINavigationBar+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UINavigationBar+FWFramework.h"
#import "FWImage.h"
#import "FWTheme.h"
#import <objc/runtime.h>

#pragma mark - UINavigationBar+FWFramework

@implementation UINavigationBar (FWFramework)

- (UIColor *)fwTextColor
{
    return self.tintColor;
}

- (void)setFwTextColor:(UIColor *)color
{
    self.tintColor = color;
    self.titleTextAttributes = color ? @{NSForegroundColorAttributeName: color} : nil;
    if (@available(iOS 11.0, *)) {
        self.largeTitleTextAttributes = color ? @{NSForegroundColorAttributeName: color} : nil;
    }
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = [UIImage fwImageWithColor:color] ?: [UIImage new];
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (UIColor *)fwThemeBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBackgroundColor));
}

- (void)setFwThemeBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwThemeBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = [UIImage fwImageWithColor:color] ?: [UIImage new];
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeBackgroundColor != nil) {
        UIImage *image = [UIImage fwImageWithColor:self.fwThemeBackgroundColor] ?: [UIImage new];
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        [self setShadowImage:[UIImage new]];
    }
}

- (void)fwSetBackgroundTransparent
{
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

@end

#pragma mark - UITabBar+FWFramework

@implementation UITabBar (FWFramework)

- (UIColor *)fwTextColor
{
    return self.tintColor;
}

- (void)setFwTextColor:(UIColor *)color
{
    self.tintColor = color;
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.backgroundImage = [UIImage fwImageWithColor:color];
    self.shadowImage = [UIImage new];
}

- (UIColor *)fwThemeBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBackgroundColor));
}

- (void)setFwThemeBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwThemeBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.backgroundImage = [UIImage fwImageWithColor:color];
    self.shadowImage = [UIImage new];
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeBackgroundColor != nil) {
        self.backgroundImage = [UIImage fwImageWithColor:self.fwThemeBackgroundColor];
        self.shadowImage = [UIImage new];
    }
}

@end
