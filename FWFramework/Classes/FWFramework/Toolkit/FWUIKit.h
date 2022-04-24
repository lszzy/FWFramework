/**
 @header     FWUIKit.h
 @indexgroup FWFramework
      FWUIKit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWDeviceClassWrapper+FWUIKit

@interface FWDeviceClassWrapper (FWUIKit)

/// 设置设备token原始Data，格式化并保存
- (void)setDeviceTokenData:(nullable NSData *)tokenData;

/// 获取设备Token格式化后的字符串
@property (nonatomic, copy, readonly, nullable) NSString *deviceToken;

/// 获取设备模型，格式："iPhone6,1"
@property (nonatomic, copy, readonly, nullable) NSString *deviceModel;

/// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
@property (nonatomic, copy, readonly, nullable) NSString *deviceIDFV;

@end

#pragma mark - FWViewWrapper+FWUIKit

@interface FWViewWrapper (FWUIKit)

/// 视图是否可见，视图hidden为NO、alpha>0.01、window存在且size不为0才认为可见
@property (nonatomic, assign, readonly) BOOL isViewVisible;

/// 获取响应的视图控制器
@property (nonatomic, strong, readonly, nullable) __kindof UIViewController *viewController;

/// 设置额外热区(点击区域)
@property (nonatomic, assign) UIEdgeInsets touchInsets;

/// 设置阴影颜色、偏移和半径
- (void)setShadowColor:(nullable UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius;

/// 绘制四边边框
- (void)setBorderColor:(nullable UIColor *)color width:(CGFloat)width;

/// 绘制四边边框和四角圆角
- (void)setBorderColor:(nullable UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius;

/// 绘制四角圆角
- (void)setCornerRadius:(CGFloat)radius;

/// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)setBorderLayer:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width;

/// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)setBorderLayer:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset;

/// 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius;

/// 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius borderColor:(nullable UIColor *)color width:(CGFloat)width;

/// 绘制单边或多边边框视图。使用AutoLayout
- (void)setBorderView:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width;

/// 绘制单边或多边边框。使用AutoLayout
- (void)setBorderView:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset;

@end

#pragma mark - FWLabelWrapper+FWUIKit

@interface FWLabelWrapper (FWUIKit)

/// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *textAttributes;

/// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于0时恢复默认行高
@property (nonatomic, assign) CGFloat lineHeight;

/// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
@property (nonatomic, assign) UIEdgeInsets contentInset;

/// 纵向分布方式，默认居中
@property (nonatomic, assign) UIControlContentVerticalAlignment verticalAlignment;

/// 快速设置标签
- (void)setFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor;

/// 快速设置标签并指定文本
- (void)setFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor text:(nullable NSString *)text;

@end

@interface FWLabelClassWrapper (FWUIKit)

/// 快速创建标签
- (__kindof UILabel *)labelWithFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor;

/// 快速创建标签并指定文本
- (__kindof UILabel *)labelWithFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor text:(nullable NSString *)text;

@end

#pragma mark - FWButtonWrapper+FWUIKit

@interface FWButtonWrapper (FWUIKit)

/// 自定义按钮禁用时的alpha，如0.5，默认0不生效
@property (nonatomic, assign) CGFloat disabledAlpha;

/// 自定义按钮高亮时的alpha，如0.5，默认0不生效
@property (nonatomic, assign) CGFloat highlightedAlpha;

/// 快速设置文本按钮
- (void)setTitle:(nullable NSString *)title font:(nullable UIFont *)font titleColor:(nullable UIColor *)titleColor;

/// 快速设置文本
- (void)setTitle:(nullable NSString *)title;

/// 快速设置图片
- (void)setImage:(nullable UIImage *)image;

/// 设置图片的居中边位置，需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距
///
/// imageEdgeInsets: 仅有image时相对于button，都有时上左下相对于button，右相对于title
/// titleEdgeInsets: 仅有title时相对于button，都有时上右下相对于button，左相对于image
- (void)setImageEdge:(UIRectEdge)edge spacing:(CGFloat)spacing;

@end

@interface FWButtonClassWrapper (FWUIKit)

/// 快速创建文本按钮
- (__kindof UIButton *)buttonWithTitle:(nullable NSString *)title font:(nullable UIFont *)font titleColor:(nullable UIColor *)titleColor;

/// 快速创建图片按钮
- (__kindof UIButton *)buttonWithImage:(nullable UIImage *)image;

@end

#pragma mark - FWScrollViewWrapper+FWUIKit

@interface FWScrollViewWrapper (FWUIKit)

/// 判断当前scrollView内容是否足够滚动
@property (nonatomic, assign, readonly) BOOL canScroll;

/// 判断当前的scrollView内容是否足够水平滚动
@property (nonatomic, assign, readonly) BOOL canScrollHorizontal;

/// 判断当前的scrollView内容是否足够纵向滚动
@property (nonatomic, assign, readonly) BOOL canScrollVertical;

/// 当前scrollView滚动到指定边
- (void)scrollToEdge:(UIRectEdge)edge animated:(BOOL)animated;

/// 是否已滚动到指定边
- (BOOL)isScrollToEdge:(UIRectEdge)edge;

/// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
- (CGPoint)contentOffsetOfEdge:(UIRectEdge)edge;

/// 总页数，自动识别翻页方向
@property (nonatomic, assign, readonly) NSInteger totalPage;

/// 当前页数，不支持动画，自动识别翻页方向
@property (nonatomic, assign) NSInteger currentPage;

/// 设置当前页数，支持动画，自动识别翻页方向
- (void)setCurrentPage:(NSInteger)page animated:(BOOL)animated;

/// 是否是最后一页，自动识别翻页方向
@property (nonatomic, assign, readonly) BOOL isLastPage;

@end

#pragma mark - FWPageControlWrapper+FWUIKit

@interface FWPageControlWrapper (FWUIKit)

/// 自定义圆点大小，默认{10, 10}
@property (nonatomic, assign) CGSize preferredSize;

@end

#pragma mark - FWSliderWrapper+FWUIKit

@interface FWSliderWrapper (FWUIKit)

/// 中间圆球的大小，默认zero
@property (nonatomic, assign) CGSize thumbSize;

/// 中间圆球的颜色，默认nil
@property (nonatomic, strong, nullable) UIColor *thumbColor;

@end

#pragma mark - FWSwitchWrapper+FWUIKit

@interface FWSwitchWrapper (FWUIKit)

/// 自定义尺寸大小，默认{51,31}
@property (nonatomic, assign) CGSize preferredSize;

@end

#pragma mark - FWTextFieldWrapper+FWUIKit

@interface FWTextFieldWrapper (FWUIKit)

/// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger maxLength;

/// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger maxUnicodeLength;

/// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
- (void)textLengthChanged;

/// 设置自动完成时间间隔，默认1秒，和fwAutoCompleteBlock配套使用
@property (nonatomic, assign) NSTimeInterval autoCompleteInterval;

/// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
@property (nullable, nonatomic, copy) void (^autoCompleteBlock)(NSString *text);

@end

#pragma mark - FWTextViewWrapper+FWUIKit

@interface FWTextViewWrapper (FWUIKit)

/// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger maxLength;

/// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger maxUnicodeLength;

/// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
- (void)textLengthChanged;

/// 设置自动完成时间间隔，默认1秒，和fwAutoCompleteBlock配套使用
@property (nonatomic, assign) NSTimeInterval autoCompleteInterval;

/// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
@property (nullable, nonatomic, copy) void (^autoCompleteBlock)(NSString *text);

@end

#pragma mark - FWViewControllerWrapper+FWUIKit

@interface FWViewControllerWrapper (FWUIKit)

/// 判断当前控制器是否是根控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
@property (nonatomic, assign, readonly) BOOL isRoot;

/// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
@property (nonatomic, assign, readonly) BOOL isChild;

/// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
@property (nonatomic, assign, readonly) BOOL isPresented;

/// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
@property (nonatomic, assign, readonly) BOOL isPageSheet;

/// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
@property (nonatomic, assign, readonly) BOOL isViewVisible;

/// 是否已经加载完，默认NO，加载完成后可标记为YES，可用于第一次加载时显示loading等判断
@property (nonatomic, assign) BOOL isLoaded;

@end

NS_ASSUME_NONNULL_END
