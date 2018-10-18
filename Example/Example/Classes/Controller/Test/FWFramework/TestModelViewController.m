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

@property(nonatomic, weak) UIScrollView *scrollView;
@property(nonatomic, weak) UIImageView *imageView;
@property(nonatomic, weak) UIView *redView;
@property(nonatomic, weak) UIView *blueView;

@end

@implementation TestModelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 添加scrollView
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.frame = [UIScreen mainScreen].bounds;
    scrollView.delegate = self;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    
    // 添加imageView到scrollView中
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, 140);
    imageView.image = [UIImage imageNamed:@"public_picture"];
    [self.scrollView addSubview:imageView];
    self.imageView = imageView;
    
    // 添加redView到scrollView中
    UIView *redView = [[UIView alloc] init];
    redView.frame = CGRectMake(0, self.imageView.frame.size.height, self.view.frame.size.width, 44);
    redView.backgroundColor = [UIColor redColor];
    [self.scrollView addSubview:redView];
    self.redView = redView;
    
    // 添加blueView到scrollView中
    UIView *blueView = [[UIView alloc] init];
    blueView.frame = CGRectMake(0, CGRectGetMaxY(self.redView.frame), self.view.frame.size.width, 800);
    blueView.backgroundColor = [UIColor blueColor];
    [self.scrollView addSubview:blueView];
    self.blueView = blueView;
    
    // 设置scrollView的contentSize属性
    self.scrollView.contentSize = CGSizeMake(0, CGRectGetMaxY(self.blueView.frame));
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat originY = 140;
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY >= originY) {
        CGRect redFrame = self.redView.frame;
        redFrame.origin.y = 0;
        self.redView.frame = redFrame;
        [self.view addSubview:self.redView];
    }else{
        CGRect redFrame = self.redView.frame;
        redFrame.origin.y = originY;
        self.redView.frame = redFrame;
        [self.scrollView addSubview:self.redView];
    }
}

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
