//
//  TestGradientViewController.m
//  Example
//
//  Created by wuyong on 2019/3/21.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestGradientViewController.h"

@interface TestGradientViewController ()

@end

@implementation TestGradientViewController

- (void)renderView
{
    NSArray *colors = @[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor greenColor].CGColor, (__bridge id)[UIColor blueColor].CGColor];
    CGFloat locations[] = {0.0, 0.5, 1.0};
    CGSize size = CGSizeMake(FWScreenWidth - 40, 50);
    
    UIView *view1 = [[UIView alloc] initWithFrame:CGRectMake(20, 20, size.width, size.height)];
    view1.backgroundColor = [UIColor fwGradientColorWithSize:CGSizeMake(size.width, 1) colors:colors locations:locations direction:UISwipeGestureRecognizerDirectionRight];
    [self.view addSubview:view1];
    
    UIImageView *view2 = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, size.width, size.height)];
    view2.image = [UIImage fwGradientImageWithSize:size colors:colors locations:locations direction:UISwipeGestureRecognizerDirectionRight];
    [self.view addSubview:view2];
    
    FWGradientView *view3 = [[FWGradientView alloc] initWithFrame:CGRectMake(20, 160, size.width, size.height)];
    NSArray *uiColors = @[[UIColor redColor], [UIColor greenColor], [UIColor blueColor]];
    [view3 setColors:uiColors locations:@[@0.0, @0.5, @1.0] startPoint:CGPointMake(0, 0) endPoint:CGPointMake(1, 0)];
    [self.view addSubview:view3];
    
    UIView *view4 = [[UIView alloc] initWithFrame:CGRectMake(20, 230, size.width, size.height)];
    [view4 fwAddGradientLayer:CGRectMake(0, 0, size.width, size.height) colors:colors locations:@[@0.0, @0.5, @1.0] startPoint:CGPointMake(0, 0) endPoint:CGPointMake(1, 0)];
    [self.view addSubview:view4];
}

@end
