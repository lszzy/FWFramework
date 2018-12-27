/*!
 @header     TestControllerViewController.m
 @indexgroup Example
 @brief      TestControllerViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "TestControllerViewController.h"

@interface TestControllerViewController () <FWScrollViewController>

@end

@implementation TestControllerViewController

- (void)fwRenderView
{
    self.view.backgroundColor = [UIColor redColor];
    
    UIImageView *imageView = [UIImageView fwAutoLayoutView];
    imageView.image = [UIImage imageNamed:@"public_picture"];
    [self.fwContentView addSubview:imageView]; {
        [imageView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
        [imageView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
        [imageView fwSetDimension:NSLayoutAttributeHeight toSize:150];
    }
    
    UIView *redView = [UIView fwAutoLayoutView];
    redView.backgroundColor = [UIColor redColor];
    [self.fwContentView addSubview:redView]; {
        [redView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
        [redView fwPinEdgeToSuperview:NSLayoutAttributeRight];
        [redView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:imageView];
        [redView fwSetDimension:NSLayoutAttributeHeight toSize:50];
    }
    
    UIView *hoverView = [UIView fwAutoLayoutView];
    hoverView.backgroundColor = [UIColor redColor];
    [redView addSubview:hoverView]; {
        [hoverView fwPinEdgesToSuperview];
    }
    
    UIView *blueView = [UIView fwAutoLayoutView];
    blueView.backgroundColor = [UIColor blueColor];
    [self.fwContentView addSubview:blueView]; {
        [blueView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
        [blueView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:redView];
        [blueView fwSetDimension:NSLayoutAttributeHeight toSize:FWScreenHeight];
    }
}

@end
