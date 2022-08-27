//
//  FWViewController.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 视图控制器挂钩协议，可覆写
 */
NS_SWIFT_NAME(ViewControllerProtocol)
@protocol FWViewController <NSObject>

@optional

/// 初始化完成方法，init自动调用，默认未实现
- (void)didInitialize;

/// 初始化导航栏方法，viewDidLoad自动调用，默认未实现
- (void)setupNavbar;

/// 初始化子视图方法，viewDidLoad自动调用，默认未实现
- (void)setupSubviews;

/// 初始化布局方法，viewDidLoad自动调用，默认未实现
- (void)setupLayout;

@end

/**
 视图控制器拦截器
 */
NS_SWIFT_NAME(ViewControllerIntercepter)
@interface FWViewControllerIntercepter : NSObject

@property (nonatomic, assign, nullable) SEL initIntercepter;
@property (nonatomic, assign, nullable) SEL viewDidLoadIntercepter;
@property (nonatomic, assign, nullable) SEL viewDidLayoutSubviewsIntercepter;

@property (nonatomic, copy, nullable) NSDictionary *forwardSelectors;

@end

@protocol FWScrollViewController;
@protocol FWTableViewController;
@protocol FWCollectionViewController;
@protocol FWWebViewController;

/**
 视图控制器管理器
 @note 框架默认未注册FWViewController协议拦截器，如需全局配置控制器，使用全局自定义block即可
 */
NS_SWIFT_NAME(ViewControllerManager)
@interface FWViewControllerManager : NSObject

/** 单例模式 */
@property (class, nonatomic, readonly) FWViewControllerManager *sharedInstance NS_SWIFT_NAME(shared);

/// 默认全局控制器init钩子句柄，init优先自动调用
@property (nonatomic, copy, nullable) void (^hookInit)(UIViewController *viewController);
/// 默认全局控制器viewDidLoad钩子句柄，viewDidLoad优先自动调用
@property (nonatomic, copy, nullable) void (^hookViewDidLoad)(UIViewController *viewController);
/// 默认全局控制器viewDidLayoutSubviews钩子句柄，viewDidLayoutSubviews优先自动调用
@property (nonatomic, copy, nullable) void (^hookViewDidLayoutSubviews)(UIViewController *viewController);

/// 默认全局scrollViewController钩子句柄，viewDidLoad自动调用，先于setupScrollView
@property (nonatomic, copy, nullable) void (^hookScrollViewController)(UIViewController<FWScrollViewController> *viewController);
/// 默认全局tableViewController钩子句柄，viewDidLoad自动调用，先于setupTableView
@property (nonatomic, copy, nullable) void (^hookTableViewController)(UIViewController<FWTableViewController> *viewController);
/// 默认全局collectionViewController钩子句柄，viewDidLoad自动调用，先于setupCollectionView
@property (nonatomic, copy, nullable) void (^hookCollectionViewController)(UIViewController<FWCollectionViewController> *viewController);
/// 默认全局webViewController钩子句柄，viewDidLoad自动调用，先于setupWebView
@property (nonatomic, copy, nullable) void (^hookWebViewController)(UIViewController<FWWebViewController> *viewController);

/// 注册协议拦截器，提供拦截和跳转方法
- (void)registerProtocol:(Protocol *)protocol withIntercepter:(FWViewControllerIntercepter *)intercepter;

/// 调用控制器拦截方法默认实现并返回(如tableView等)，由于实现机制无法通过super调用原始方法，提供此替代方案。如果未实现该协议或方法，返回nil
- (nullable id)performIntercepter:(SEL)intercepter withObject:(UIViewController *)object;

/// 调用控制器拦截方法默认实现并返回，可携带参数(如setWebRequest:等)，由于实现机制无法通过super调用原始方法，提供此替代方案。如果未实现该协议或方法，返回nil
- (nullable id)performIntercepter:(SEL)intercepter withObject:(UIViewController *)object parameter:(nullable id)parameter;

@end

NS_ASSUME_NONNULL_END
