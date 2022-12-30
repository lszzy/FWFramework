//
//  BadgeView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWBadgeView

/// 自带提醒灯样式
typedef NS_ENUM(NSInteger, __FWBadgeStyle) {
    /// 小红点，(10)*(10)
    __FWBadgeStyleDot = 1,
    /// 小提醒灯，同系统标签，(18+)*(18)，12号字体
    __FWBadgeStyleSmall,
    /// 大提醒灯，同系统桌面，(24+)*(24)，14号字体
    __FWBadgeStyleBig,
} NS_SWIFT_NAME(BadgeStyle);

/// 提醒灯视图，默认禁用userInteractionEnabled
NS_SWIFT_NAME(BadgeView)
@interface __FWBadgeView : UIView

/// 提醒灯样式，默认0自定义
@property (nonatomic, readonly) __FWBadgeStyle badgeStyle;
/// 提醒灯文本标签。可自定义样式
@property (nullable, nonatomic, readonly) UILabel *badgeLabel;
/// 提醒灯右上偏移值
@property (nonatomic, readonly) CGPoint badgeOffset;

/// 初始化自带样式提醒灯。宽高自动布局，其它手工布局
- (instancetype)initWithBadgeStyle:(__FWBadgeStyle)badgeStyle;

/// 初始化自定义提醒灯。宽高自动布局，其它手工布局
- (instancetype)initWithBadgeHeight:(CGFloat)badgeHeight
                        badgeOffset:(CGPoint)badgeOffset
                          textInset:(CGFloat)textInset
                           fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
