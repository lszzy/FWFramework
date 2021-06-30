//
//  TestThemeViewController.m
//  Example
//
//  Created by wuyong on 2020/8/14.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestThemeViewController.h"
#import "TestTabBarViewController.h"

@implementation TestThemeViewController

/*
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            FWThemeManager.sharedInstance.overrideWindow = YES;
        });
    });
}
*/

- (void)renderInit
{
    [self fwObserveNotification:FWThemeChangedNotification block:^(NSNotification * _Nonnull notification) {
        NSLog(@"主题改变通知：%@", @(FWThemeManager.sharedInstance.style));
    }];
    
    // iOS13以下named方式不支持动态颜色和图像，可手工注册之
    if (@available(iOS 13.0, *)) { } else {
        [UIColor fwSetThemeColor:[UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]] forName:@"theme_color"];
        [UIImage fwSetThemeImage:[UIImage fwThemeLight:[TestBundle imageNamed:@"theme_image_light"] dark:[TestBundle imageNamed:@"theme_image_dark"]] forName:@"theme_image"];
    }
}

- (void)renderView
{
    self.view.backgroundColor = [UIColor fwThemeLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    [self.view addSubview:colorView];
    
    colorView = [[UIView alloc] initWithFrame:CGRectMake(90, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeNamed:@"theme_color" bundle:TestBundle.bundle];
    [self.view addSubview:colorView];
    
    colorView = [[UIView alloc] initWithFrame:CGRectMake(160, 20, 50, 50)];
    [UIColor fwSetThemeColor:[UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]] forName:@"dynamic_color"];
    UIColor *dynamicColor = [UIColor fwThemeNamed:@"dynamic_color"];
    colorView.backgroundColor = [dynamicColor fwColorForStyle:FWThemeManager.sharedInstance.style];
    [colorView fwAddThemeListener:^(FWThemeStyle style) {
        colorView.backgroundColor = [dynamicColor fwColorForStyle:style];
    }];
    [self.view addSubview:colorView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    UIImage *themeImage = [UIImage fwThemeLight:[TestBundle imageNamed:@"theme_image_light"] dark:[TestBundle imageNamed:@"theme_image_dark"]];
    imageView.image = themeImage.fwImage;
    [imageView fwAddThemeListener:^(FWThemeStyle style) {
        imageView.image = themeImage.fwImage;
    }];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(90, 90, 50, 50)];
    imageView.fwThemeImage = [UIImage fwThemeNamed:@"theme_image" bundle:TestBundle.bundle];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 90, 50, 50)];
    UIImage *reverseImage = [UIImage fwThemeNamed:@"theme_image" bundle:TestBundle.bundle];
    imageView.image = [reverseImage fwImageForStyle:FWThemeManager.sharedInstance.style];
    [imageView fwAddThemeListener:^(FWThemeStyle style) {
        imageView.image = [reverseImage fwImageForStyle:style];
    }];
    [self.view addSubview:imageView];
    
    CALayer *layer = [CALayer new];
    layer.frame = CGRectMake(20, 160, 50, 50);
    UIColor *themeColor = [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    layer.backgroundColor = [themeColor fwColorForStyle:FWThemeManager.sharedInstance.style].CGColor;
    layer.fwThemeContext = self;
    [layer fwAddThemeListener:^(FWThemeStyle style) {
        layer.backgroundColor = [themeColor fwColorForStyle:style].CGColor;
    }];
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(90, 160, 50, 50);
    layer.fwThemeContext = self.view;
    layer.fwThemeBackgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
    }];
    [self.view.layer addSublayer:layer];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer new];
    gradientLayer.frame = CGRectMake(160, 160, 50, 50);
    gradientLayer.fwThemeContext = self;
    gradientLayer.fwThemeColors = @[[UIColor fwThemeNamed:@"theme_color" bundle:TestBundle.bundle], [UIColor fwThemeNamed:@"theme_color" bundle:TestBundle.bundle]];
    [self.view.layer addSublayer:gradientLayer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(20, 230, 50, 50);
    UIImage *layerImage = [UIImage fwThemeLight:[TestBundle imageNamed:@"theme_image_light"] dark:[TestBundle imageNamed:@"theme_image_dark"]];
    layer.contents = (id)layerImage.fwImage.CGImage;
    layer.fwThemeContext = self.view;
    [layer fwAddThemeListener:^(FWThemeStyle style) {
        layer.contents = (id)layerImage.fwImage.CGImage;
    }];
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(90, 230, 50, 50);
    layer.fwThemeContext = self;
    layer.fwThemeContents = [UIImage fwThemeImage:^UIImage * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [TestBundle imageNamed:@"theme_image_dark"] : [TestBundle imageNamed:@"theme_image_light"];
    }];
    [self.view.layer addSublayer:layer];
    
    layer = [CALayer new];
    layer.frame = CGRectMake(160, 230, 50, 50);
    layer.fwThemeContext = self.view;
    layer.fwThemeContents = [UIImage fwThemeNamed:@"theme_image" bundle:TestBundle.bundle];
    [self.view.layer addSublayer:layer];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 300, 50, 50)];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIImage.fwThemeImageColor = Theme.textColor;
    });
    imageView.fwThemeImage = [TestBundle imageNamed:@"close.svg"].fwThemeImage;
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(90, 300, 50, 50)];
    UIImage *colorImage = [UIImage fwThemeLight:[TestBundle imageNamed:@"tabbar_settings"] dark:[TestBundle imageNamed:@"tabbar_test"]];
    imageView.fwThemeImage = [colorImage fwThemeImageWithColor:Theme.textColor];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 300, 50, 50)];
    imageView.fwThemeImage = [[TestBundle imageNamed:@"close.svg"] fwThemeImageWithColor:[UIColor redColor]];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 370, 50, 50)];
    imageView.fwThemeImage = [UIImage fwThemeLight:[TestBundle imageNamed:@"tabbar_settings"] dark:[[TestBundle imageNamed:@"tabbar_settings"] fwImageWithTintColor:[UIColor whiteColor]]];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(90, 370, 50, 50)];
    imageView.fwThemeImage = [UIImage fwThemeLight:[TestBundle imageNamed:@"tabbar_settings"] dark:[[TestBundle imageNamed:@"tabbar_settings"] fwImageWithTintColor:[UIColor yellowColor]]];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 370, 50, 50)];
    [UIImage fwSetThemeImage:[UIImage fwThemeLight:[TestBundle imageNamed:@"tabbar_settings"] dark:[[TestBundle imageNamed:@"tabbar_settings"] fwImageWithTintColor:[UIColor redColor]]] forName:@"dynamic_image"];
    UIImage *dynamicImage = [UIImage fwThemeNamed:@"dynamic_image"];
    imageView.image = [dynamicImage fwImageForStyle:FWThemeManager.sharedInstance.style];
    [imageView fwAddThemeListener:^(FWThemeStyle style) {
        imageView.image = [dynamicImage fwImageForStyle:style];
    }];
    [self.view addSubview:imageView];
    
    UILabel *themeLabel = [UILabel new];
    themeLabel.frame = CGRectMake(0, 440, FWScreenWidth, 50);
    themeLabel.textAlignment = NSTextAlignmentCenter;
    themeLabel.attributedText = [NSAttributedString fwAttributedString:@"我是AttributedString" withFont:FWFontSize(16).fwBoldFont textColor:[UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]]];
    [self.view addSubview:themeLabel];
    
    UIButton *themeButton = [UIButton new];
    themeButton.frame = CGRectMake(0, 510, FWScreenWidth, 50);
    themeButton.titleLabel.font = FWFontRegular(16);
    [themeButton setTitleColor:[UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    UIImage *buttonImage = [UIImage fwThemeLight:(FWThemeManager.sharedInstance.style == FWThemeStyleLight ? nil : [TestBundle imageNamed:@"theme_image_light"]) dark:(FWThemeManager.sharedInstance.style == FWThemeStyleDark ? nil : [TestBundle imageNamed:@"theme_image_dark"])];
    FWThemeObject<NSAttributedString *> *themeString = [NSAttributedString fwThemeObjectWithHtmlString:@"我是<span style='color:red;'>红色</span>AttributedString" defaultAttributes:@{
        NSFontAttributeName: FWFontBold(16),
        NSForegroundColorAttributeName: [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]],
    }];
    
    [themeButton setImage:buttonImage.fwImage forState:UIControlStateNormal];
    [themeButton setAttributedTitle:themeString.object forState:UIControlStateNormal];
    [themeLabel fwAddThemeListener:^(FWThemeStyle style) {
        [themeButton setImage:buttonImage.fwImage forState:UIControlStateNormal];
        [themeButton setAttributedTitle:themeString.object forState:UIControlStateNormal];
    }];
    [self.view addSubview:themeButton];
}

- (void)renderModel
{
    FWThemeMode mode = FWThemeManager.sharedInstance.mode;
    NSString *title = mode == FWThemeModeSystem ? @"系统" : (mode == FWThemeModeDark ? @"深色" : @"浅色");
    FWWeakifySelf();
    [self fwSetRightBarItem:title block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        
        NSMutableArray *actions = [NSMutableArray arrayWithArray:@[@"系统", @"浅色"]];
        if (@available(iOS 13.0, *)) {
            [actions addObject:@"深色"];
        }
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:actions actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            FWThemeManager.sharedInstance.mode = index;
            [self renderModel];
            [TestTabBarViewController refreshController];
        }];
    }];
}

@end
