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
        self.fwNavigationBarStyle = FWNavigationBarStyleTransparent;
        self.fwExtendedLayoutEdge = UIRectEdgeTop;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fwSetRightBarItem:@"切换" block:^(id sender) {
        FWStrongifySelf();
        
        TestControllerViewController *viewController = [TestControllerViewController new];
        viewController.isTop = !self.isTop;
        [self fwOpenViewController:viewController animated:YES];
    }];
}

- (void)renderInit
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.fwNavigationBarStyle = FWNavigationBarStyleDefault;
}

- (void)renderView
{
    self.scrollView.delegate = self;
    
    UIImageView *imageView = [UIImageView fwAutoLayoutView];
    imageView.image = [TestBundle imageNamed:@"public_picture"];
    [self.contentView addSubview:imageView]; {
        [imageView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
        [imageView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
        [imageView fwSetDimension:NSLayoutAttributeHeight toSize:150];
    }
    
    UIView *redView = [UIView fwAutoLayoutView];
    _redView = redView;
    redView.backgroundColor = [UIColor redColor];
    [self.contentView addSubview:redView]; {
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
    [self.contentView addSubview:blueView]; {
        [blueView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
        [blueView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:redView];
        [blueView fwSetDimension:NSLayoutAttributeHeight toSize:FWScreenHeight];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isTop) {
        CGFloat distance = [scrollView fwHoverView:self.hoverView fromSuperview:self.redView toSuperview:self.fwView toPosition:FWTopBarHeight];
        if (distance <= 0) {
            self.fwNavigationBar.fwBackgroundColor = [UIColor whiteColor];
        } else if (distance <= FWTopBarHeight) {
            self.fwNavigationBar.fwBackgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:1 - distance / FWTopBarHeight];
        }
    } else {
        [scrollView fwHoverView:self.hoverView fromSuperview:self.redView toSuperview:self.fwView toPosition:0];
    }
}

@end
