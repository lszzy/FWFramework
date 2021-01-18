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
    colorView.backgroundColor = [UIColor fwThemeColor:^UIColor * _Nonnull(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
    }];
    [self.view addSubview:colorView];
    
    colorView = [[UIView alloc] initWithFrame:CGRectMake(160, 20, 50, 50)];
    colorView.backgroundColor = [UIColor fwThemeNamed:@"theme_color" bundle:TestBundle.bundle];
    [self.view addSubview:colorView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    UIImage *themeImage = [UIImage fwThemeLight:[TestBundle imageNamed:@"theme_image_light"] dark:[TestBundle imageNamed:@"theme_image_dark"]];
    imageView.image = themeImage;
    [imageView fwAddThemeListener:^(FWThemeStyle style) {
        imageView.image = themeImage.fwThemeImage;
    }];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(90, 90, 50, 50)];
    imageView.fwThemeImage = [UIImage fwThemeImage:^UIImage *(FWThemeStyle style) {
        return style == FWThemeStyleDark ? [TestBundle imageNamed:@"theme_image_dark"] : [TestBundle imageNamed:@"theme_image_light"];
    }];
    [self.view addSubview:imageView];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 90, 50, 50)];
    imageView.image = [UIImage fwThemeNamed:@"theme_image" bundle:TestBundle.bundle];
    [self.view addSubview:imageView];
    
    CALayer *layer = [CALayer new];
    layer.frame = CGRectMake(20, 160, 50, 50);
    UIColor *themeColor = [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    layer.backgroundColor = [themeColor fwThemeColor:FWThemeManager.sharedInstance.style].CGColor;
    layer.fwThemeContext = self;
    [layer fwAddThemeListener:^(FWThemeStyle style) {
        layer.backgroundColor = [themeColor fwThemeColor:style].CGColor;
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
    layer.contents = (id)layerImage.CGImage;
    layer.fwThemeContext = self.view;
    [layer fwAddThemeListener:^(FWThemeStyle style) {
        layer.contents = (id)layerImage.fwThemeImage.CGImage;
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
    
    UILabel *themeLabel = [UILabel new];
    themeLabel.frame = CGRectMake(0, 300, FWScreenWidth, 50);
    themeLabel.textAlignment = NSTextAlignmentCenter;
    themeLabel.attributedText = [NSAttributedString fwAttributedString:@"我是AttributedString" withFont:FWFontSize(16).fwBoldFont textColor:[UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]]];
    [self.view addSubview:themeLabel];
    
    UIButton *themeButton = [UIButton new];
    themeButton.frame = CGRectMake(0, 370, FWScreenWidth, 50);
    themeButton.titleLabel.font = FWFontRegular(16);
    [themeButton setTitleColor:[UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    UIImage *buttonImage = [UIImage fwThemeLight:(FWThemeManager.sharedInstance.style == FWThemeStyleLight ? nil : [TestBundle imageNamed:@"theme_image_light"]) dark:(FWThemeManager.sharedInstance.style == FWThemeStyleDark ? nil : [TestBundle imageNamed:@"theme_image_dark"])];
    FWThemeObject<NSAttributedString *> *themeString = [NSAttributedString fwThemeObjectWithHtmlString:@"我是<span style='color:red;'>红色</span>字符串" defaultAttributes:@{
        NSFontAttributeName: FWFontBold(16).fwItalicFont,
        NSForegroundColorAttributeName: [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]],
    }];
    
    [themeButton setImage:buttonImage.fwThemeImage forState:UIControlStateNormal];
    [themeButton setAttributedTitle:themeString.object forState:UIControlStateNormal];
    [themeLabel fwAddThemeListener:^(FWThemeStyle style) {
        [themeButton setImage:buttonImage.fwThemeImage forState:UIControlStateNormal];
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
        
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"系统", @"浅色", @"深色"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            FWThemeManager.sharedInstance.mode = index;
            [self renderModel];
            [TestTabBarViewController refreshController];
        }];
    }];
}

@end
