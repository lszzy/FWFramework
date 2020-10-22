/*!
 @header     FWFloatLayoutView.h
 @indexgroup FWFramework
 @brief      FWFloatLayoutView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 用于属性 maximumItemSize，是它的默认值。表示 item 的最大宽高会自动根据当前 floatLayoutView 的内容大小来调整，从而避免 item 内容过多时可能溢出 floatLayoutView。
extern const CGSize FWFloatLayoutViewAutomaticalMaximumItemSize;

/*!
 @brief 浮动布局视图
 @discussion 做类似 CSS 里的 float:left 的布局，自行使用 addSubview: 将子 View 添加进来即可。
 支持通过 `contentMode` 属性修改子 View 的对齐方式，目前仅支持 `UIViewContentModeLeft` 和 `UIViewContentModeRight`，默认为 `UIViewContentModeLeft`
 
 @see https://github.com/Tencent/QMUI_iOS
 */
@interface FWFloatLayoutView : UIView

/**
 *  QMUIFloatLayoutView 内部的间距，默认为 UIEdgeInsetsZero
 */
@property(nonatomic, assign) UIEdgeInsets padding;

/**
 *  item 的最小宽高，默认为 CGSizeZero，也即不限制。
 */
@property(nonatomic, assign) IBInspectable CGSize minimumItemSize;

/**
 *  item 的最大宽高，默认为 QMUIFloatLayoutViewAutomaticalMaximumItemSize，也即不超过 floatLayoutView 自身最大内容宽高。
 */
@property(nonatomic, assign) IBInspectable CGSize maximumItemSize;

/**
 *  item 之间的间距，默认为 UIEdgeInsetsZero。
 *
 *  @warning 上、下、左、右四个边缘的 item 布局时不会考虑 itemMargins.top/bottom/left/right。
 */
@property(nonatomic, assign) UIEdgeInsets itemMargins;

@end

NS_ASSUME_NONNULL_END
