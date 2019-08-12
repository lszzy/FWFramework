//
//  UIView+FWBadge.h
//  FWFramework
//
//  Created by wuyong on 2017/4/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWBadgeView

// 自带提醒灯样式
typedef NS_ENUM(NSInteger, FWBadgeStyle) {
    // 小红点
    FWBadgeStyleDot = 1,
    // 小提醒灯，同系统标签，(18+)*(18)，12号字体
    FWBadgeStyleSmall,
    // 大提醒灯，同系统桌面，(24+)*(24)，14号字体
    FWBadgeStyleBig,
};

// 提醒灯视图，默认禁用userInteractionEnabled
@interface FWBadgeView : UIView

// 提醒灯样式，默认0自定义
@property (nonatomic, readonly) FWBadgeStyle badgeStyle;
// 提醒灯文本标签。可自定义样式
@property (nullable, nonatomic, readonly) UILabel *badgeLabel;
// 提醒灯右上偏移值
@property (nonatomic, readonly) CGPoint badgeOffset;

// 初始化自带样式提醒灯。宽高自动布局，其它手工布局
- (instancetype)initWithBadgeStyle:(FWBadgeStyle)badgeStyle;

// 初始化自定义提醒灯。宽高自动布局，其它手工布局
- (instancetype)initWithBadgeHeight:(CGFloat)badgeHeight
                        badgeOffset:(CGPoint)badgeOffset
                          textInset:(CGFloat)textInset
                           fontSize:(CGFloat)fontSize;

@end

#pragma mark - UIView+FWBadge

// 视图提醒灯分类
@interface UIView (FWBadge)

// 显示右上角提醒灯，上右偏移指定距离
- (void)fwShowBadgeView:(FWBadgeView *)badgeView badgeValue:(nullable NSString *)badgeValue;

// 隐藏提醒灯
- (void)fwHideBadgeView;

@end

#pragma mark - UIBarButtonItem+FWBadge

// 导航栏项提醒灯分类
@interface UIBarButtonItem (FWBadge)

// 显示右上角提醒灯，上右偏移指定距离
- (void)fwShowBadgeView:(FWBadgeView *)badgeView badgeValue:(nullable NSString *)badgeValue;

// 隐藏提醒灯
- (void)fwHideBadgeView;

@end

#pragma mark - UITabBarItem+FWBadge

// 标签栏项提醒灯分类
@interface UITabBarItem (FWBadge)

// 显示右上角提醒灯，上右偏移指定距离
- (void)fwShowBadgeView:(FWBadgeView *)badgeView badgeValue:(nullable NSString *)badgeValue;

// 隐藏提醒灯
- (void)fwHideBadgeView;

@end

NS_ASSUME_NONNULL_END
