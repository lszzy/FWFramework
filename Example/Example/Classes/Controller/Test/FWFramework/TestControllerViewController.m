/*!
 @header     TestControllerViewController.m
 @indexgroup Example
 @brief      TestControllerViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "TestControllerViewController.h"

@interface TestControllerViewController () <FWScrollViewController, UIScrollViewDelegate>

@property (nonatomic, strong) UIView *redView;
@property (nonatomic, strong) UIView *hoverView;

@property (nonatomic, assign) BOOL isTop;

@end

@implementation TestControllerViewController

- (void)setIsTop:(BOOL)isTop
{
    _isTop = isTop;
    
    if (isTop) {
        [self fwSetBarExtendEdge:UIRectEdgeTop];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar fwSetBackgroundClear];
    
    FWWeakifySelf();
    [self fwSetRightBarItem:@"切换" block:^(id sender) {
        FWStrongifySelf();
        
        TestControllerViewController *viewController = [TestControllerViewController new];
        viewController.isTop = !self.isTop;
        [self fwOpenViewController:viewController animated:YES];
    }];
}

- (void)fwRenderInit
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self fwSetBackBarTitle:@""];
}

- (void)fwRenderView
{
    self.fwScrollView.delegate = self;
    
    UIImageView *imageView = [UIImageView fwAutoLayoutView];
    imageView.image = [UIImage imageNamed:@"public_picture"];
    [self.fwContentView addSubview:imageView]; {
        [imageView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
        [imageView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
        [imageView fwSetDimension:NSLayoutAttributeHeight toSize:150];
    }
    
    UIView *redView = [UIView fwAutoLayoutView];
    _redView = redView;
    redView.backgroundColor = [UIColor redColor];
    [self.fwContentView addSubview:redView]; {
        [redView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
        [redView fwPinEdgeToSuperview:NSLayoutAttributeRight];
        [redView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:imageView];
        [redView fwSetDimension:NSLayoutAttributeHeight toSize:50];
    }
    
    UIView *hoverView = [UIView fwAutoLayoutView];
    _hoverView = hoverView;
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isTop) {
        CGFloat distance = [scrollView fwHoverView:self.hoverView fromSuperview:self.redView toSuperview:self.view toPosition:FWTopBarHeight];
        if (distance <= 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor whiteColor]];
        } else if (distance <= FWTopBarHeight) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:1 - distance / FWTopBarHeight]];
        }
    } else {
        [scrollView fwHoverView:self.hoverView fromSuperview:self.redView toSuperview:self.view toPosition:0];
    }
}

@end
