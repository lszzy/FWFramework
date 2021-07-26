//
//  TestFacesViewController.m
//  Example
//
//  Created by wuyong on 2020/6/24.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestFacesViewController.h"

@interface TestFacesViewController ()

@end

@implementation TestFacesViewController {
    // 图片视图
    UIImageView *imageView1_;
    UIImageView *imageView2_;
    UIImageView *imageView3_;
    UIImageView *imageView4_;
    UIImageView *imageView5_;
    UIImageView *imageView6_;
    UIImageView *imageView11_;
    UIImageView *imageView12_;
    UIImageView *imageView13_;
    UIImageView *imageView14_;
    UIImageView *imageView15_;
    UIImageView *imageView16_;
}

- (void)renderView
{
    imageView1_ = [self addImageView:CGRectMake(20, 20, 80, 80)];
    imageView2_ = [self addImageView:CGRectMake(120, 20, 80, 80)];
    imageView3_ = [self addImageView:CGRectMake(220, 20, 80, 80)];
    
    imageView4_ = [self addImageView:CGRectMake(20, 120, 80, 80)];
    imageView5_ = [self addImageView:CGRectMake(120, 120, 80, 80)];
    imageView6_ = [self addImageView:CGRectMake(220, 120, 80, 80)];
    
    imageView11_ = [self addImageView:CGRectMake(20, 220, 80, 80)];
    imageView12_ = [self addImageView:CGRectMake(120, 220, 80, 80)];
    imageView13_ = [self addImageView:CGRectMake(220, 220, 80, 80)];
    
    imageView14_ = [self addImageView:CGRectMake(20, 320, 80, 80)];
    imageView15_ = [self addImageView:CGRectMake(120, 320, 80, 80)];
    imageView16_ = [self addImageView:CGRectMake(220, 320, 80, 80)];
}

- (UIImageView *)addImageView:(CGRect)frame
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    [imageView fwSetCornerRadius:5];
    imageView.backgroundColor = [Theme backgroundColor];
    [self.fwView addSubview:imageView];
    return imageView;
}

- (void)renderData
{
    imageView1_.contentMode = UIViewContentModeScaleToFill;
    imageView1_.image = [TestBundle imageNamed:@"public_face"];
    
    imageView2_.contentMode = UIViewContentModeScaleAspectFit;
    imageView2_.image = [TestBundle imageNamed:@"public_face"];
    
    imageView3_.contentMode = UIViewContentModeScaleAspectFill;
    imageView3_.image = [TestBundle imageNamed:@"public_face"];
    
    imageView4_.contentMode = UIViewContentModeScaleToFill;
    imageView4_.image = [TestBundle imageNamed:@"public_face"];
    [imageView4_ fwFaceAware];
    
    imageView5_.contentMode = UIViewContentModeScaleAspectFit;
    imageView5_.image = [TestBundle imageNamed:@"public_face"];
    [imageView5_ fwFaceAware];
    
    imageView6_.contentMode = UIViewContentModeScaleAspectFill;
    imageView6_.image = [TestBundle imageNamed:@"public_face"];
    [imageView6_ fwFaceAware];
    
    imageView11_.contentMode = UIViewContentModeScaleToFill;
    [imageView11_ fwSetImage:[TestBundle imageNamed:@"public_test"] watermarkImage:[TestBundle imageNamed:@"public_icon"] inRect:CGRectMake(50, 50, 20, 20)];
    
    imageView12_.contentMode = UIViewContentModeScaleAspectFit;
    NSAttributedString *watermark = [[NSAttributedString alloc] initWithString:@"水印" attributes:@{
                                                                                                  NSFontAttributeName: [UIFont fwFontOfSize:10],
                                                                                                  NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                                  }];
    [imageView12_ fwSetImage:[TestBundle imageNamed:@"public_test"] watermarkString:watermark inRect:CGRectMake(50, 58, 30, 22)];
    
    imageView13_.contentMode = UIViewContentModeScaleAspectFill;
    imageView13_.image = [TestBundle imageNamed:@"public_test"];
    
    imageView14_.contentMode = UIViewContentModeScaleToFill;
    imageView14_.image = [TestBundle imageNamed:@"public_test"];
    [imageView14_ fwFaceAware];
    [imageView14_ fwReflect];
    
    imageView15_.contentMode = UIViewContentModeScaleAspectFit;
    imageView15_.image = [TestBundle imageNamed:@"public_test"];
    [imageView15_ fwFaceAware];
    [imageView15_ fwReflect];
    
    imageView16_.contentMode = UIViewContentModeScaleAspectFill;
    imageView16_.image = [TestBundle imageNamed:@"public_test"];
    [imageView16_ fwFaceAware];
    [imageView16_ fwReflect];
}

@end
