//
//  Navigator.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 控制器导航选项定义
///
/// @const __FWNavigatorOptionEmbedInNavigation 嵌入导航控制器并使用present转场方式
///
/// @const __FWNavigatorOptionTransitionAutomatic 自动判断转场方式，默认
/// @const __FWNavigatorOptionTransitionPush 指定push转场方式，仅open生效
/// @const __FWNavigatorOptionTransitionPresent 指定present转场方式，仅open生效
/// @const __FWNavigatorOptionTransitionPop 指定pop转场方式，仅close生效
/// @const __FWNavigatorOptionTransitionDismiss 指定dismiss转场方式，仅close生效
///
/// @const __FWNavigatorOptionPopNone 不pop控制器，默认
/// @const __FWNavigatorOptionPopToRoot 同时pop到根控制器，仅push|pop生效
/// @const __FWNavigatorOptionPopTop 同时pop顶部控制器，仅push|pop生效
/// @const __FWNavigatorOptionPopTop2 同时pop顶部2个控制器，仅push|pop生效
/// @const __FWNavigatorOptionPopTop3 同时pop顶部3个控制器，仅push|pop生效
/// @const __FWNavigatorOptionPopTop4 同时pop顶部4个控制器，仅push|pop生效
/// @const __FWNavigatorOptionPopTop5 同时pop顶部5个控制器，仅push|pop生效
/// @const __FWNavigatorOptionPopTop6 同时pop顶部6个控制器，仅push|pop生效
///
/// @const __FWNavigatorOptionStyleAutomatic 自动使用系统present样式，默认
/// @const __FWNavigatorOptionStyleFullScreen 指定present样式为ullScreen，仅present生效
/// @const __FWNavigatorOptionStylePageSheet 指定present样式为pageSheet，仅present生效
typedef NS_OPTIONS(NSInteger, __FWNavigatorOptions) {
    __FWNavigatorOptionEmbedInNavigation   = 1 << 0,
    
    __FWNavigatorOptionTransitionAutomatic = 0 << 16, // default
    __FWNavigatorOptionTransitionPush      = 1 << 16,
    __FWNavigatorOptionTransitionPresent   = 2 << 16,
    __FWNavigatorOptionTransitionPop       = 3 << 16,
    __FWNavigatorOptionTransitionDismiss   = 4 << 16,
    
    __FWNavigatorOptionPopNone             = 0 << 20, // default
    __FWNavigatorOptionPopTop              = 1 << 20,
    __FWNavigatorOptionPopTop2             = 2 << 20,
    __FWNavigatorOptionPopTop3             = 3 << 20,
    __FWNavigatorOptionPopTop4             = 4 << 20,
    __FWNavigatorOptionPopTop5             = 5 << 20,
    __FWNavigatorOptionPopTop6             = 6 << 20,
    __FWNavigatorOptionPopToRoot           = 7 << 20,
    
    __FWNavigatorOptionStyleAutomatic      = 0 << 24, // default
    __FWNavigatorOptionStyleFullScreen     = 1 << 24,
    __FWNavigatorOptionStylePageSheet      = 2 << 24,
} NS_SWIFT_NAME(NavigatorOptions);

NS_ASSUME_NONNULL_END
