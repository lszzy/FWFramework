//
//  FWUIKit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIDevice+FWUIKit

@interface UIDevice (FWUIKit)

/// 设置设备token原始Data，格式化并保存
+ (void)fw_setDeviceTokenData:(nullable NSData *)tokenData NS_REFINED_FOR_SWIFT;

/// 获取或设置设备Token格式化后的字符串
@property (class, nonatomic, copy, nullable) NSString *fw_deviceToken NS_REFINED_FOR_SWIFT;

/// 获取设备模型，格式："iPhone6,1"
@property (class, nonatomic, copy, readonly, nullable) NSString *fw_deviceModel NS_REFINED_FOR_SWIFT;

/// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
@property (class, nonatomic, copy, readonly, nullable) NSString *fw_deviceIDFV NS_REFINED_FOR_SWIFT;

/// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
@property (class, nonatomic, copy, readonly, nullable) NSString *fw_deviceIDFA NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIView+FWUIKit

@interface UIView (FWUIKit)

/// 视图是否可见，视图hidden为NO、alpha>0.01、window存在且size不为0才认为可见
@property (nonatomic, assign, readonly) BOOL fw_isViewVisible NS_REFINED_FOR_SWIFT;

/// 获取响应的视图控制器
@property (nonatomic, strong, readonly, nullable) __kindof UIViewController *fw_viewController NS_REFINED_FOR_SWIFT;

/// 设置额外热区(点击区域)
@property (nonatomic, assign) UIEdgeInsets fw_touchInsets NS_REFINED_FOR_SWIFT;

/// 设置自动计算适合高度的frame，需实现sizeThatFits:方法
@property (nonatomic, assign) CGRect fw_fitFrame NS_REFINED_FOR_SWIFT;

/// 计算当前视图适合大小，需实现sizeThatFits:方法
@property (nonatomic, assign, readonly) CGSize fw_fitSize NS_REFINED_FOR_SWIFT;

/// 计算指定边界，当前视图适合大小，需实现sizeThatFits:方法
- (CGSize)fw_fitSizeWithDrawSize:(CGSize)drawSize NS_REFINED_FOR_SWIFT;

/// 根据tag查找subview，仅从subviews中查找
- (nullable __kindof UIView *)fw_subviewWithTag:(NSInteger)tag NS_REFINED_FOR_SWIFT;

/// 设置阴影颜色、偏移和半径
- (void)fw_setShadowColor:(nullable UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius NS_REFINED_FOR_SWIFT;

/// 绘制四边边框
- (void)fw_setBorderColor:(nullable UIColor *)color width:(CGFloat)width NS_REFINED_FOR_SWIFT;

/// 绘制四边边框和四角圆角
- (void)fw_setBorderColor:(nullable UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius NS_REFINED_FOR_SWIFT;

/// 绘制四角圆角
- (void)fw_setCornerRadius:(CGFloat)radius NS_REFINED_FOR_SWIFT;

/// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)fw_setBorderLayer:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width NS_REFINED_FOR_SWIFT;

/// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)fw_setBorderLayer:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset NS_REFINED_FOR_SWIFT;

/// 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)fw_setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius NS_REFINED_FOR_SWIFT;

/// 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)fw_setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius borderColor:(nullable UIColor *)color width:(CGFloat)width NS_REFINED_FOR_SWIFT;

/// 绘制单边或多边边框视图。使用AutoLayout
- (void)fw_setBorderView:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width NS_REFINED_FOR_SWIFT;

/// 绘制单边或多边边框。使用AutoLayout
- (void)fw_setBorderView:(UIRectEdge)edge color:(nullable UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset NS_REFINED_FOR_SWIFT;

/// 开始倒计时，从window移除时自动取消，回调参数为剩余时间
- (dispatch_source_t)fw_startCountDown:(NSInteger)seconds block:(void (^)(NSInteger countDown))block NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UILabel+FWUIKit

@interface UILabel (FWUIKit)

/// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *fw_textAttributes NS_REFINED_FOR_SWIFT;

/// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于0时恢复默认行高
@property (nonatomic, assign) CGFloat fw_lineHeight NS_REFINED_FOR_SWIFT;

/// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
@property (nonatomic, assign) UIEdgeInsets fw_contentInset NS_REFINED_FOR_SWIFT;

/// 纵向分布方式，默认居中
@property (nonatomic, assign) UIControlContentVerticalAlignment fw_verticalAlignment NS_REFINED_FOR_SWIFT;

/// 添加点击手势并自动识别NSLinkAttributeName|URL属性，点击高亮时回调链接，点击其它区域回调nil
- (void)fw_addLinkGestureWithBlock:(void (^)(id _Nullable link))block NS_REFINED_FOR_SWIFT;

/// 获取手势触发位置的文本属性，可实现行内点击效果等，allowsSpacing默认为NO空白处不可点击。为了识别更准确，attributedText需指定font
- (NSDictionary<NSAttributedStringKey, id> *)fw_attributesWithGesture:(UIGestureRecognizer *)gesture allowsSpacing:(BOOL)allowsSpacing NS_REFINED_FOR_SWIFT;

/// 快速设置标签
- (void)fw_setFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor NS_REFINED_FOR_SWIFT;

/// 快速设置标签并指定文本
- (void)fw_setFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor text:(nullable NSString *)text NS_REFINED_FOR_SWIFT;

/// 快速创建标签
+ (instancetype)fw_labelWithFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor NS_REFINED_FOR_SWIFT;

/// 快速创建标签并指定文本
+ (instancetype)fw_labelWithFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor text:(nullable NSString *)text NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIButton+FWUIKit

@interface UIButton (FWUIKit)

/// 自定义按钮禁用时的alpha，如0.5，默认0不生效
@property (nonatomic, assign) CGFloat fw_disabledAlpha NS_REFINED_FOR_SWIFT;

/// 自定义按钮高亮时的alpha，如0.5，默认0不生效
@property (nonatomic, assign) CGFloat fw_highlightedAlpha NS_REFINED_FOR_SWIFT;

/// 快速设置文本按钮
- (void)fw_setTitle:(nullable NSString *)title font:(nullable UIFont *)font titleColor:(nullable UIColor *)titleColor NS_REFINED_FOR_SWIFT;

/// 快速设置文本
- (void)fw_setTitle:(nullable NSString *)title NS_REFINED_FOR_SWIFT;

/// 快速设置图片
- (void)fw_setImage:(nullable UIImage *)image NS_REFINED_FOR_SWIFT;

/// 设置图片的居中边位置，需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距
///
/// imageEdgeInsets: 仅有image时相对于button，都有时上左下相对于button，右相对于title
/// titleEdgeInsets: 仅有title时相对于button，都有时上右下相对于button，左相对于image
- (void)fw_setImageEdge:(UIRectEdge)edge spacing:(CGFloat)spacing NS_REFINED_FOR_SWIFT;

/// 设置状态背景色
- (void)fw_setBackgroundColor:(nullable UIColor *)backgroundColor forState:(UIControlState)state NS_REFINED_FOR_SWIFT;

/// 快速创建文本按钮
+ (instancetype)fw_buttonWithTitle:(nullable NSString *)title font:(nullable UIFont *)font titleColor:(nullable UIColor *)titleColor NS_REFINED_FOR_SWIFT;

/// 快速创建图片按钮
+ (instancetype)fw_buttonWithImage:(nullable UIImage *)image NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIScrollView+FWUIKit

@interface UIScrollView (FWUIKit)

/// 判断当前scrollView内容是否足够滚动
@property (nonatomic, assign, readonly) BOOL fw_canScroll NS_REFINED_FOR_SWIFT;

/// 判断当前的scrollView内容是否足够水平滚动
@property (nonatomic, assign, readonly) BOOL fw_canScrollHorizontal NS_REFINED_FOR_SWIFT;

/// 判断当前的scrollView内容是否足够纵向滚动
@property (nonatomic, assign, readonly) BOOL fw_canScrollVertical NS_REFINED_FOR_SWIFT;

/// 当前scrollView滚动到指定边
- (void)fw_scrollToEdge:(UIRectEdge)edge animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 是否已滚动到指定边
- (BOOL)fw_isScrollToEdge:(UIRectEdge)edge NS_REFINED_FOR_SWIFT;

/// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
- (CGPoint)fw_contentOffsetOfEdge:(UIRectEdge)edge NS_REFINED_FOR_SWIFT;

/// 总页数，自动识别翻页方向
@property (nonatomic, assign, readonly) NSInteger fw_totalPage NS_REFINED_FOR_SWIFT;

/// 当前页数，不支持动画，自动识别翻页方向
@property (nonatomic, assign) NSInteger fw_currentPage NS_REFINED_FOR_SWIFT;

/// 设置当前页数，支持动画，自动识别翻页方向
- (void)fw_setCurrentPage:(NSInteger)page animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 是否是最后一页，自动识别翻页方向
@property (nonatomic, assign, readonly) BOOL fw_isLastPage NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIPageControl+FWUIKit

@interface UIPageControl (FWUIKit)

/// 自定义圆点大小，默认{10, 10}
@property (nonatomic, assign) CGSize fw_preferredSize NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UISlider+FWUIKit

@interface UISlider (FWUIKit)

/// 中间圆球的大小，默认zero
@property (nonatomic, assign) CGSize fw_thumbSize NS_REFINED_FOR_SWIFT;

/// 中间圆球的颜色，默认nil
@property (nonatomic, strong, nullable) UIColor *fw_thumbColor NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UISwitch+FWUIKit

@interface UISwitch (FWUIKit)

/// 自定义尺寸大小，默认{51,31}
@property (nonatomic, assign) CGSize fw_preferredSize NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UITextField+FWUIKit

@interface UITextField (FWUIKit)

/// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger fw_maxLength NS_REFINED_FOR_SWIFT;

/// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger fw_maxUnicodeLength NS_REFINED_FOR_SWIFT;

/// 自定义文字改变处理句柄，默认nil
@property (nonatomic, copy, nullable) void (^fw_textChangedBlock)(NSString *text) NS_REFINED_FOR_SWIFT;

/// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
- (void)fw_textLengthChanged NS_REFINED_FOR_SWIFT;

/// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
- (NSString *)fw_filterText:(NSString *)text NS_REFINED_FOR_SWIFT;

/// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
@property (nonatomic, assign) NSTimeInterval fw_autoCompleteInterval NS_REFINED_FOR_SWIFT;

/// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
@property (nullable, nonatomic, copy) void (^fw_autoCompleteBlock)(NSString *text) NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UITextView+FWUIKit

@interface UITextView (FWUIKit)

/// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger fw_maxLength NS_REFINED_FOR_SWIFT;

/// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger fw_maxUnicodeLength NS_REFINED_FOR_SWIFT;

/// 自定义文字改变处理句柄，自动trimString，默认nil
@property (nonatomic, copy, nullable) void (^fw_textChangedBlock)(NSString *text) NS_REFINED_FOR_SWIFT;

/// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
- (void)fw_textLengthChanged NS_REFINED_FOR_SWIFT;

/// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
- (NSString *)fw_filterText:(NSString *)text NS_REFINED_FOR_SWIFT;

/// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
@property (nonatomic, assign) NSTimeInterval fw_autoCompleteInterval NS_REFINED_FOR_SWIFT;

/// 设置自动完成处理句柄，自动trimString，默认nil，注意输入框内容为空时会立即触发
@property (nullable, nonatomic, copy) void (^fw_autoCompleteBlock)(NSString *text) NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UITableViewCell+FWUIKit

@interface UITableViewCell (FWUIKit)

/// 设置分割线内边距，iOS8+默认15.f，设为UIEdgeInsetsZero可去掉
@property (nonatomic, assign) UIEdgeInsets fw_separatorInset NS_REFINED_FOR_SWIFT;

/// 获取当前所属tableView
@property (nonatomic, weak, readonly, nullable) UITableView *fw_tableView NS_REFINED_FOR_SWIFT;

/// 获取当前显示indexPath
@property (nonatomic, readonly, nullable) NSIndexPath *fw_indexPath NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UICollectionViewCell+FWUIKit

@interface UICollectionViewCell (FWUIKit)

/// 获取当前所属collectionView
@property (nonatomic, weak, readonly, nullable) UICollectionView *fw_collectionView NS_REFINED_FOR_SWIFT;

/// 获取当前显示indexPath
@property (nonatomic, readonly, nullable) NSIndexPath *fw_indexPath NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWUIKit

@interface UIViewController (FWUIKit)

/// 判断当前控制器是否是根控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
@property (nonatomic, assign, readonly) BOOL fw_isRoot NS_REFINED_FOR_SWIFT;

/// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
@property (nonatomic, assign, readonly) BOOL fw_isChild NS_REFINED_FOR_SWIFT;

/// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
@property (nonatomic, assign, readonly) BOOL fw_isPresented NS_REFINED_FOR_SWIFT;

/// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
@property (nonatomic, assign, readonly) BOOL fw_isPageSheet NS_REFINED_FOR_SWIFT;

/// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
@property (nonatomic, assign, readonly) BOOL fw_isViewVisible NS_REFINED_FOR_SWIFT;

/// 是否已经加载完，默认NO，加载完成后可标记为YES，可用于第一次加载时显示loading等判断
@property (nonatomic, assign) BOOL fw_isLoaded NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END