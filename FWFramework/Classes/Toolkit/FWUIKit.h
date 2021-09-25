/*!
 @header     FWUIKit.h
 @indexgroup FWFramework
 @brief      FWUIKit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIDevice+FWUIKit

/*!
 @brief UIDevice+FWUIKit
 */
@interface UIDevice (FWUIKit)

/// 设置设备token原始Data，格式化并保存
+ (void)fwSetDeviceTokenData:(nullable NSData *)tokenData;

/// 获取设备Token格式化后的字符串
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceToken;

/// 获取设备模型，格式："iPhone6,1"
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceModel;

/// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceIDFV;

/// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Component_Tracking组件后生效
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceIDFA;

@end

#pragma mark - UIView+FWUIKit

/*!
 @brief UIView+FWUIKit
 */
@interface UIView (FWUIKit)

/// 获取响应的视图控制器
@property (nonatomic, strong, readonly, nullable) __kindof UIViewController *fwViewController;

/// 设置额外热区(点击区域)
@property (nonatomic, assign) UIEdgeInsets fwTouchInsets;

/// 将要设置的frame按照view的anchorPoint(.5, .5)处理后再设置，而系统默认按照(0, 0)方式计算
@property(nonatomic, assign) CGRect fwFrameApplyTransform;

/// 设置阴影颜色、偏移和半径
- (void)fwSetShadowColor:(nullable UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius;

@end

#pragma mark - CAAnimation+FWUIKit

/*!
 @brief CAAnimation+FWUIKit
 */
@interface CAAnimation (FWUIKit)

/// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
@property (nonatomic, copy, nullable) void (^fwStartBlock)(CAAnimation *animation);

/// 设置动画停止回调
@property (nonatomic, copy, nullable) void (^fwStopBlock)(CAAnimation *animation, BOOL finished);

@end

#pragma mark - UILabel+FWUIKit

/*!
 @brief UILabel+FWUIKit
 */
@interface UILabel (FWUIKit)

/// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
@property (nonatomic, assign) UIEdgeInsets fwContentInset;

/// 纵向分布方式，默认居中
@property (nonatomic, assign) UIControlContentVerticalAlignment fwVerticalAlignment;

@end

#pragma mark - UIButton+FWUIKit

/*!
 @brief UIButton+FWUIKit
 */
@interface UIButton (FWUIKit)

/// 自定义按钮禁用时的alpha，如0.5，默认0不生效
@property (nonatomic, assign) CGFloat fwDisabledAlpha;

/// 自定义按钮高亮时的alpha，如0.5，默认0不生效
@property (nonatomic, assign) CGFloat fwHighlightedAlpha;

@end

#pragma mark - UIScrollView+FWUIKit

/*!
 @brief UIScrollView+FWUIKit
 */
@interface UIScrollView (FWUIKit)

/// 判断当前scrollView内容是否足够滚动
@property (nonatomic, assign, readonly) BOOL fwCanScroll;

/// 判断当前的scrollView内容是否足够水平滚动
@property (nonatomic, assign, readonly) BOOL fwCanScrollHorizontal;

/// 判断当前的scrollView内容是否足够纵向滚动
@property (nonatomic, assign, readonly) BOOL fwCanScrollVertical;

/// 当前scrollView滚动到指定边
- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated;

/// 是否已滚动到指定边
- (BOOL)fwIsScrollToEdge:(UIRectEdge)edge;

/// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
- (CGPoint)fwContentOffsetOfEdge:(UIRectEdge)edge;

/// 总页数，自动识别翻页方向
@property (nonatomic, assign, readonly) NSInteger fwTotalPage;

/// 当前页数，不支持动画，自动识别翻页方向
@property (nonatomic, assign) NSInteger fwCurrentPage;

/// 设置当前页数，支持动画，自动识别翻页方向
- (void)fwSetCurrentPage:(NSInteger)page animated:(BOOL)animated;

/// 是否是最后一页，自动识别翻页方向
@property (nonatomic, assign, readonly) BOOL fwIsLastPage;

@end

#pragma mark - UIPageControl+FWUIKit

/*!
 @brief UIPageControl+FWUIKit
 */
@interface UIPageControl (FWUIKit)

/// 自定义圆点大小，默认{10, 10}
@property (nonatomic, assign) CGSize fwPreferredSize;

@end

#pragma mark - UISlider+FWUIKit

/*!
 @brief UISlider+FWUIKit
 */
@interface UISlider (FWUIKit)

/// 中间圆球的大小，默认zero
@property (nonatomic, assign) CGSize fwThumbSize UI_APPEARANCE_SELECTOR;

/// 中间圆球的颜色，默认nil
@property (nonatomic, strong, nullable) UIColor *fwThumbColor UI_APPEARANCE_SELECTOR;

@end

#pragma mark - UISwitch+FWUIKit

/*!
 @brief UISwitch+FWUIKit
 */
@interface UISwitch (FWUIKit)

/// 自定义尺寸大小，默认{51,31}
@property (nonatomic, assign) CGSize fwPreferredSize;

@end

#pragma mark - UITextField+FWUIKit

/*!
 @brief UITextField+FWUIKit
 */
@interface UITextField (FWUIKit)

/// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxLength;

/// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxUnicodeLength;

/// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
- (void)fwTextLengthChanged;

/// 设置自动完成时间间隔，默认1秒，和fwAutoCompleteBlock配套使用
@property (nonatomic, assign) NSTimeInterval fwAutoCompleteInterval UI_APPEARANCE_SELECTOR;

/// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
@property (nullable, nonatomic, copy) void (^fwAutoCompleteBlock)(NSString *text);

@end

#pragma mark - UITextView+FWUIKit

/*!
 @brief UITextView+FWUIKit
 */
@interface UITextView (FWUIKit)

/// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxLength;

/// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxUnicodeLength;

/// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
- (void)fwTextLengthChanged;

/// 设置自动完成时间间隔，默认1秒，和fwAutoCompleteBlock配套使用
@property (nonatomic, assign) NSTimeInterval fwAutoCompleteInterval UI_APPEARANCE_SELECTOR;

/// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
@property (nullable, nonatomic, copy) void (^fwAutoCompleteBlock)(NSString *text);

/// 占位文本，默认nil
@property (nullable, nonatomic, strong) NSString *fwPlaceholder;

/// 占位颜色，默认系统颜色
@property (nullable, nonatomic, strong) UIColor *fwPlaceholderColor;

/// 带属性占位文本，默认nil
@property (nullable, nonatomic, strong) NSAttributedString *fwAttributedPlaceholder;

/// 自定义占位文本内间距，默认zero与内容一致
@property (nonatomic, assign) UIEdgeInsets fwPlaceholderInset;

/// 自定义垂直分布方式，会自动修改contentInset，默认Top与系统一致
@property (nonatomic, assign) UIControlContentVerticalAlignment fwVerticalAlignment;

/// 是否启用自动高度功能，随文字改变高度
@property (nonatomic, assign) BOOL fwAutoHeightEnabled;

/// 最大高度，默认CGFLOAT_MAX，启用自动高度后生效
@property (nonatomic, assign) CGFloat fwMaxHeight;

/// 最小高度，默认0，启用自动高度后生效
@property (nonatomic, assign) CGFloat fwMinHeight;

/// 高度改变回调句柄，默认nil，启用自动高度后生效
@property (nullable, nonatomic, copy) void (^fwHeightDidChange)(CGFloat height);

/// 快捷启用自动高度，并设置最大高度和回调句柄
- (void)fwAutoHeightWithMaxHeight:(CGFloat)maxHeight didChange:(nullable void (^)(CGFloat height))didChange;

@end

#pragma mark - UIViewController+FWUIKit

/*!
 @brief UIViewController+FWUIKit
 */
@interface UIViewController (FWUIKit)

/// 判断当前控制器是否是根控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
@property (nonatomic, assign, readonly) BOOL fwIsRoot;

/// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
@property (nonatomic, assign, readonly) BOOL fwIsChild;

/// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
@property (nonatomic, assign, readonly) BOOL fwIsPresented;

/// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
@property (nonatomic, assign, readonly) BOOL fwIsPageSheet;

/// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
@property (nonatomic, assign, readonly) BOOL fwIsViewVisible;

/// 是否已经加载完，默认NO，加载完成后可标记为YES，可用于第一次加载时显示loading等判断
@property (nonatomic, assign) BOOL fwIsLoaded;

@end

NS_ASSUME_NONNULL_END
