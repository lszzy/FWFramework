/*!
 @header     TestModelViewController.m
 @indexgroup Example
 @brief      TestModelViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/9/26
 */

#import "TestModelViewController.h"

@interface TestModelUser : NSObject

@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, strong) NSNumber *userAge;
@property (nonatomic, strong) NSString *userName;

@end

@implementation TestModelUser

@end

@interface TestModelObj : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) TestModelUser *user;
@property (nonatomic, strong) NSArray *users;

@end

@implementation TestModelObj

+ (NSDictionary *)fwModelClassMapper
{
    return @{
             @"users": [TestModelUser class],
             };
}

@end

@interface TestModelViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *redView;
@property (nonatomic, strong) UIView *hoverView;

@property (nonatomic, assign) BOOL isTop;

@end

@implementation TestModelViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self fwSetBackBarTitle:@""];
    }
    return self;
}

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
    
    FWWeakifySelf();
    [self fwSetRightBarItem:@"切换" block:^(id sender) {
        FWStrongifySelf();
        
        TestModelViewController *viewController = [TestModelViewController new];
        viewController.isTop = !self.isTop;
        [self fwOnOpen:viewController];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar fwSetBackgroundClear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar fwResetBackground];
}

- (void)renderView
{
    self.scrollView.delegate = self;
    
    UIImageView *imageView = [UIImageView fwAutoLayoutView];
    imageView.image = [UIImage imageNamed:@"public_picture"];
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
        CGFloat alpha = [scrollView fwHoverView:self.hoverView fromSuperview:self.redView toSuperview:self.view fromPosition:150 toPosition:(FWStatusBarHeight + FWNavigationBarHeight)];
        if (alpha == 1) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor whiteColor]];
        } else if (alpha >= 0 && alpha < 1) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:alpha]];
        }
    } else {
        [scrollView fwHoverView:self.hoverView fromSuperview:self.redView toSuperview:self.view fromPosition:150 toPosition:0];
    }
}

#pragma mark - Protected

- (void)renderData
{
    NSDictionary *jsonDict = @{
                               @"name": @"name",
                               @"date": @"2018-09-26 11:12:13",
                               @"user": @{
                                       @"userId": @1,
                                       @"userAge": @20,
                                       @"userName": @"userName",
                                       },
                               @"users": @[
                                       @{
                                           @"userId": @2,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           },
                                       @{
                                           @"userId": @3,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           },
                                       @{
                                           @"userId": @4,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           },
                                       ],
                               };
    TestModelObj *obj = [TestModelObj fwModelWithJson:jsonDict];
    NSLog(@"obj: %@", obj);
    NSLog(@"dict: %@", [obj fwModelToJsonObject]);
}

@end
