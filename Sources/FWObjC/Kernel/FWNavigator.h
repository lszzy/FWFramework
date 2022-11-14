//
//  FWNavigator.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 控制器导航选项定义
///
/// @const FWNavigatorOptionEmbedInNavigation 嵌入导航控制器并使用present转场方式
///
/// @const FWNavigatorOptionTransitionAutomatic 自动判断转场方式，默认
/// @const FWNavigatorOptionTransitionPush 指定push转场方式，仅open生效
/// @const FWNavigatorOptionTransitionPresent 指定present转场方式，仅open生效
/// @const FWNavigatorOptionTransitionPop 指定pop转场方式，仅close生效
/// @const FWNavigatorOptionTransitionDismiss 指定dismiss转场方式，仅close生效
///
/// @const FWNavigatorOptionPopNone 不pop控制器，默认
/// @const FWNavigatorOptionPopToRoot 同时pop到根控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop 同时pop顶部控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop2 同时pop顶部2个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop3 同时pop顶部3个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop4 同时pop顶部4个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop5 同时pop顶部5个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop6 同时pop顶部6个控制器，仅push|pop生效
///
/// @const FWNavigatorOptionStyleAutomatic 自动使用系统present样式，默认
/// @const FWNavigatorOptionStyleFullScreen 指定present样式为ullScreen，仅present生效
/// @const FWNavigatorOptionStylePageSheet 指定present样式为pageSheet，仅present生效
typedef NS_OPTIONS(NSInteger, FWNavigatorOptions) {
    FWNavigatorOptionEmbedInNavigation   = 1 << 0,
    
    FWNavigatorOptionTransitionAutomatic = 0 << 16, // default
    FWNavigatorOptionTransitionPush      = 1 << 16,
    FWNavigatorOptionTransitionPresent   = 2 << 16,
    FWNavigatorOptionTransitionPop       = 3 << 16,
    FWNavigatorOptionTransitionDismiss   = 4 << 16,
    
    FWNavigatorOptionPopNone             = 0 << 20, // default
    FWNavigatorOptionPopTop              = 1 << 20,
    FWNavigatorOptionPopTop2             = 2 << 20,
    FWNavigatorOptionPopTop3             = 3 << 20,
    FWNavigatorOptionPopTop4             = 4 << 20,
    FWNavigatorOptionPopTop5             = 5 << 20,
    FWNavigatorOptionPopTop6             = 6 << 20,
    FWNavigatorOptionPopToRoot           = 7 << 20,
    
    FWNavigatorOptionStyleAutomatic      = 0 << 24, // default
    FWNavigatorOptionStyleFullScreen     = 1 << 24,
    FWNavigatorOptionStylePageSheet      = 2 << 24,
} NS_SWIFT_NAME(NavigatorOptions);

NS_ASSUME_NONNULL_END
