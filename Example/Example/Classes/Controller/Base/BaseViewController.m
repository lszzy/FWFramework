/*!
 @header     BaseViewController.m
 @indexgroup Example
 @brief      BaseViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "BaseViewController.h"

@implementation BaseViewController

#pragma mark - Lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // 默认关闭视图延伸Bar布局
        [self fwSetBarExtendEdge:UIRectEdgeNone];
        
        // 默认push时隐藏TabBar，TabBar初始化控制器时设置为NO
        self.hidesBottomBarWhenPushed = YES;
        
        // 渲染初始化
        [self renderInit];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    // 统一设置背景色
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化内部视图
    [self setupView];
    
    // 渲染当前视图
    [self renderView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 通用导航栏样式
    [self fwSetBackBarImage:[UIImage imageNamed:@"public_back"]];
    
    // 渲染当前模型
    [self renderModel];
    
    // 渲染当前数据
    [self renderData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 通用导航栏样式
    [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
    [self.navigationController.navigationBar fwSetLineHidden:YES];
}

- (void)dealloc
{
    // 自动移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 打印被释放日志，防止内存泄露
    NSLog(@"%@ did dealloc", NSStringFromClass(self.class));
}

#pragma mark - Protect

- (void)setupView
{
    // 子类重写
}

#pragma mark - Render

- (void)renderInit
{
    // 子类重写
}

- (void)renderView
{
    // 子类重写
}

- (void)renderModel
{
    // 子类重写
}

- (void)renderData
{
    // 子类重写
}

@end
