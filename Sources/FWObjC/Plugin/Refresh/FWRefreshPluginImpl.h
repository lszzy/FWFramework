//
//  FWRefreshPluginImpl.h
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWRefreshPlugin.h"
#import "FWRefreshView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWRefreshPluginImpl

/// 默认刷新插件
NS_SWIFT_NAME(RefreshPluginImpl)
@interface FWRefreshPluginImpl : NSObject <FWRefreshPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWRefreshPluginImpl *sharedInstance;

/// 下拉刷新自定义句柄，开启时自动调用
@property (nonatomic, copy, nullable) void (^pullRefreshBlock)(FWPullRefreshView *pullRefreshView);

/// 上拉追加自定义句柄，开启时自动调用
@property (nonatomic, copy, nullable) void (^infiniteScrollBlock)(FWInfiniteScrollView *infiniteScrollView);

@end

NS_ASSUME_NONNULL_END
