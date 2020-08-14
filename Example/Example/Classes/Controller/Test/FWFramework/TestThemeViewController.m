//
//  TestThemeViewController.m
//  Example
//
//  Created by wuyong on 2020/8/14.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestThemeViewController.h"

@interface TestThemeViewController ()

@end

@implementation TestThemeViewController

- (void)renderView
{
    self.view.backgroundColor = [UIColor fwThemeLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    [self.view addSubview:colorView];
    
    colorView = [[UIView alloc] initWithFrame:CGRectMake(90, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
    }];
    [self.view addSubview:colorView];
    
    colorView = [[UIView alloc] initWithFrame:CGRectMake(160, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeNamed:@"theme_color"];
    [self.view addSubview:colorView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    imageView.image = [UIImage fwThemeLight:[UIImage imageNamed:@"theme_image_light"] dark:[UIImage imageNamed:@"theme_image_dark"]];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(90, 90, 50, 50)];
    imageView.image = [UIImage fwThemeImage:^UIImage * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIImage imageNamed:@"theme_image_dark"] : [UIImage imageNamed:@"theme_image_light"];
    }];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 90, 50, 50)];
    imageView.image = [UIImage fwThemeNamed:@"theme_image"];
    [self.view addSubview:imageView];
    
    CALayer *layer = [CALayer new];
    layer.frame = CGRectMake(20, 160, 50, 50);
    layer.backgroundColor = [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]].CGColor;
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(90, 160, 50, 50);
    layer.backgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
    }].CGColor;
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(160, 160, 50, 50);
    layer.backgroundColor = [UIColor fwThemeNamed:@"theme_color"].CGColor;
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(20, 230, 50, 50);
    layer.contents = (id)[UIImage fwThemeLight:[UIImage imageNamed:@"theme_image_light"] dark:[UIImage imageNamed:@"theme_image_dark"]].CGImage;
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(90, 230, 50, 50);
    layer.contents = (id)[UIImage fwThemeImage:^UIImage * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIImage imageNamed:@"theme_image_dark"] : [UIImage imageNamed:@"theme_image_light"];
    }].CGImage;
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(160, 230, 50, 50);
    layer.contents = (id)[UIImage fwThemeNamed:@"theme_image"].CGImage;
    [self.view.layer addSublayer:layer];
}

@end
