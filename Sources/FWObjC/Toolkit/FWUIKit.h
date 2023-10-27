//
//  FWUIKit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIBezierPath+FWUIKit

@interface UIBezierPath (FWUIKit)

/// 绘制形状图片，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
- (nullable UIImage *)fw_shapeImage:(CGSize)size
                     strokeWidth:(CGFloat)strokeWidth
                     strokeColor:(UIColor *)strokeColor
                       fillColor:(nullable UIColor *)fillColor NS_REFINED_FOR_SWIFT;

/// 绘制形状Layer，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
- (CAShapeLayer *)fw_shapeLayer:(CGRect)rect
                 strokeWidth:(CGFloat)strokeWidth
                 strokeColor:(UIColor *)strokeColor
                   fillColor:(nullable UIColor *)fillColor NS_REFINED_FOR_SWIFT;

/// 根据点计算折线路径(NSValue点)
+ (UIBezierPath *)fw_linesWithPoints:(NSArray *)points NS_REFINED_FOR_SWIFT;

/// 根据点计算贝塞尔曲线路径
+ (UIBezierPath *)fw_quadCurvedPathWithPoints:(NSArray *)points NS_REFINED_FOR_SWIFT;

/// 计算两点的中心点
+ (CGPoint)fw_middlePoint:(CGPoint)p1 withPoint:(CGPoint)p2 NS_REFINED_FOR_SWIFT;

/// 计算两点的贝塞尔曲线控制点
+ (CGPoint)fw_controlPoint:(CGPoint)p1 withPoint:(CGPoint)p2 NS_REFINED_FOR_SWIFT;

/// 将角度(0~360)转换为弧度，周长为2*M_PI*r
+ (CGFloat)fw_radianWithDegree:(CGFloat)degree NS_REFINED_FOR_SWIFT;

/// 将弧度转换为角度(0~360)
+ (CGFloat)fw_degreeWithRadian:(CGFloat)radian NS_REFINED_FOR_SWIFT;

/// 根据滑动方向计算rect的线段起点、终点中心点坐标数组(示范：田)。默认从上到下滑动
+ (NSArray<NSValue *> *)fw_linePointsWithRect:(CGRect)rect direction:(UISwipeGestureRecognizerDirection)direction NS_REFINED_FOR_SWIFT;

@end

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

/// 是否越狱
@property (class, nonatomic, assign, readonly) BOOL fw_isJailbroken NS_REFINED_FOR_SWIFT;

/// 本地IP地址
@property (class, nonatomic, copy, readonly, nullable) NSString *fw_ipAddress NS_REFINED_FOR_SWIFT;

/// 本地主机名称
@property (class, nonatomic, copy, readonly, nullable) NSString *fw_hostName NS_REFINED_FOR_SWIFT;

/// 手机运营商名称
@property (class, nonatomic, copy, readonly, nullable) NSString *fw_carrierName NS_REFINED_FOR_SWIFT;

/// 手机蜂窝网络类型，仅区分2G|3G|4G|5G
@property (class, nonatomic, copy, readonly, nullable) NSString *fw_networkType NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIView+FWUIKit

/// 事件穿透实现方法：重写-hitTest:withEvent:方法，当为指定视图(如self)时返回nil排除即可
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

/// 绘制四边虚线边框和四角圆角。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
- (void)fw_setDashBorderLayer:(nullable UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius lineLength:(CGFloat)lineLength lineSpacing:(CGFloat)lineSpacing NS_REFINED_FOR_SWIFT;

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

/// 设置毛玻璃效果，使用UIVisualEffectView。内容需要添加到UIVisualEffectView.contentView
- (nullable UIVisualEffectView *)fw_setBlurEffect:(UIBlurEffectStyle)style NS_REFINED_FOR_SWIFT;

/// 移除所有子视图
- (void)fw_removeAllSubviews NS_REFINED_FOR_SWIFT;

/// 递归查找指定子类的第一个子视图(含自身)
- (nullable __kindof UIView *)fw_subviewOfClass:(Class)clazz NS_REFINED_FOR_SWIFT;

/// 递归查找指定条件的第一个子视图(含自身)
- (nullable __kindof UIView *)fw_subviewOfBlock:(BOOL (^)(UIView *view))block NS_REFINED_FOR_SWIFT;

/// 递归查找指定条件的第一个父视图(含自身)
- (nullable __kindof UIView *)fw_superviewOfBlock:(BOOL (^)(UIView *view))block NS_REFINED_FOR_SWIFT;

/// 图片截图
@property (nonatomic, readonly, nullable) UIImage *fw_snapshotImage NS_REFINED_FOR_SWIFT;

/// Pdf截图
@property (nonatomic, readonly, nullable) NSData *fw_snapshotPdf NS_REFINED_FOR_SWIFT;

/// 自定义视图排序索引，需结合sortSubviews使用，默认0不处理
@property (nonatomic, assign) NSInteger fw_sortIndex NS_REFINED_FOR_SWIFT;

/// 根据sortIndex排序subviews，需结合sortIndex使用
- (void)fw_sortSubviews NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIImageView+FWUIKit

@interface UIImageView (FWUIKit)

/// 设置图片模式为ScaleAspectFill，自动拉伸不变形，超过区域隐藏。可通过appearance统一设置
- (void)fw_setContentModeAspectFill UI_APPEARANCE_SELECTOR NS_REFINED_FOR_SWIFT;

/// 优化图片人脸显示，参考：https://github.com/croath/UIImageView-BetterFace
- (void)fw_faceAware NS_REFINED_FOR_SWIFT;

/// 倒影效果
- (void)fw_reflect NS_REFINED_FOR_SWIFT;

/// 图片水印
- (void)fw_setImage:(UIImage *)image watermarkImage:(UIImage *)watermarkImage inRect:(CGRect)rect NS_REFINED_FOR_SWIFT;

/// 文字水印，指定区域
- (void)fw_setImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString inRect:(CGRect)rect NS_REFINED_FOR_SWIFT;

/// 文字水印，指定坐标
- (void)fw_setImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString atPoint:(CGPoint)point NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIWindow+FWUIKit

@interface UIWindow (FWUIKit)

/// 获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
- (nullable __kindof UIViewController *)fw_getTabBarControllerWithIndex:(NSInteger)index NS_REFINED_FOR_SWIFT;

/// 获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
- (nullable __kindof UIViewController *)fw_getTabBarControllerOfClass:(Class)clazz NS_REFINED_FOR_SWIFT;

/// 获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
- (nullable __kindof UIViewController *)fw_getTabBarControllerWithBlock:(BOOL (NS_NOESCAPE ^)(__kindof UIViewController *viewController))block NS_REFINED_FOR_SWIFT;

/// 选中并获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
- (nullable __kindof UIViewController *)fw_selectTabBarControllerWithIndex:(NSInteger)index NS_REFINED_FOR_SWIFT;

/// 选中并获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
- (nullable __kindof UIViewController *)fw_selectTabBarControllerOfClass:(Class)clazz NS_REFINED_FOR_SWIFT;

/// 选中并获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
- (nullable __kindof UIViewController *)fw_selectTabBarControllerWithBlock:(BOOL (NS_NOESCAPE ^)(__kindof UIViewController *viewController))block NS_REFINED_FOR_SWIFT;

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

/// 计算当前文本所占尺寸，需frame或者宽度布局完整
@property (nonatomic, assign, readonly) CGSize fw_textSize NS_REFINED_FOR_SWIFT;

/// 计算当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
@property (nonatomic, assign, readonly) CGSize fw_attributedTextSize NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIControl+FWUIKit

/// 防重复点击可以手工控制enabled或userInteractionEnabled，如request开始时禁用，结束时启用等
@interface UIControl (FWUIKit)

/// 设置Touch事件触发间隔，防止短时间多次触发事件，默认0
@property (nonatomic, assign) NSTimeInterval fw_touchEventInterval UI_APPEARANCE_SELECTOR NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIButton+FWUIKit

@interface UIButton (FWUIKit)

/// 全局自定义按钮高亮时的alpha配置，默认0.5
@property (class, nonatomic, assign) CGFloat fw_highlightedAlpha NS_REFINED_FOR_SWIFT;
    
/// 全局自定义按钮禁用时的alpha配置，默认0.3
@property (class, nonatomic, assign) CGFloat fw_disabledAlpha NS_REFINED_FOR_SWIFT;

/// 自定义按钮禁用时的alpha，如0.3，默认0不生效
@property (nonatomic, assign) CGFloat fw_disabledAlpha NS_REFINED_FOR_SWIFT;

/// 自定义按钮高亮时的alpha，如0.5，默认0不生效
@property (nonatomic, assign) CGFloat fw_highlightedAlpha NS_REFINED_FOR_SWIFT;

/// 自定义按钮禁用状态改变时的句柄，默认nil
@property (nonatomic, copy, nullable) void (^fw_disabledChanged)(UIButton *button, BOOL disabled) NS_REFINED_FOR_SWIFT;

/// 自定义按钮高亮状态改变时的句柄，默认nil
@property (nonatomic, copy, nullable) void (^fw_highlightedChanged)(UIButton *button, BOOL highlighted) NS_REFINED_FOR_SWIFT;

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

/// 开始按钮倒计时，从window移除时自动取消。等待时按钮disabled，非等待时enabled。时间支持格式化，示例：重新获取(%lds)
- (dispatch_source_t)fw_startCountDown:(NSInteger)seconds title:(NSString *)title waitTitle:(NSString *)waitTitle NS_REFINED_FOR_SWIFT;

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

/// 快捷设置contentOffset.x
@property (nonatomic, assign) CGFloat fw_contentOffsetX NS_REFINED_FOR_SWIFT;

/// 快捷设置contentOffset.y
@property (nonatomic, assign) CGFloat fw_contentOffsetY NS_REFINED_FOR_SWIFT;

/// 内容视图，子视图需添加到本视图，布局约束完整时可自动滚动
@property (nonatomic, strong, readonly) UIView *fw_contentView NS_REFINED_FOR_SWIFT;

/**
 设置自动布局视图悬停到指定父视图固定位置，在scrollViewDidScroll:中调用即可
 
 @param view 需要悬停的视图，须占满fromSuperview
 @param fromSuperview 起始的父视图，须是scrollView的子视图
 @param toSuperview 悬停的目标视图，须是scrollView的父级视图，一般控制器self.view
 @param toPosition 需要悬停的目标位置，相对于toSuperview的originY位置
 @return 相对于悬浮位置的距离，可用来设置导航栏透明度等
 */
- (CGFloat)fw_hoverView:(UIView *)view
         fromSuperview:(UIView *)fromSuperview
           toSuperview:(UIView *)toSuperview
            toPosition:(CGFloat)toPosition NS_REFINED_FOR_SWIFT;

/// 是否开始识别pan手势
@property (nullable, nonatomic, copy) BOOL (^fw_shouldBegin)(UIGestureRecognizer *gestureRecognizer) NS_REFINED_FOR_SWIFT;

/// 是否允许同时识别多个手势
@property (nullable, nonatomic, copy) BOOL (^fw_shouldRecognizeSimultaneously)(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer) NS_REFINED_FOR_SWIFT;

/// 是否另一个手势识别失败后，才能识别pan手势
@property (nullable, nonatomic, copy) BOOL (^fw_shouldRequireFailure)(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer) NS_REFINED_FOR_SWIFT;

/// 是否pan手势识别失败后，才能识别另一个手势
@property (nullable, nonatomic, copy) BOOL (^fw_shouldBeRequiredToFail)(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer) NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIGestureRecognizer+FWUIKit

/**
 gestureRecognizerShouldBegin：是否继续进行手势识别，默认YES
 shouldRecognizeSimultaneouslyWithGestureRecognizer: 是否支持多手势触发。默认NO
 shouldRequireFailureOfGestureRecognizer：是否otherGestureRecognizer触发失败时，才开始触发gestureRecognizer。返回YES，第一个手势失败
 shouldBeRequiredToFailByGestureRecognizer：在otherGestureRecognizer识别其手势之前，是否gestureRecognizer必须触发失败。返回YES，第二个手势失败
 */
@interface UIGestureRecognizer (FWUIKit)

/// 获取手势直接作用的view，不同于view，此处是view的subview
@property (nullable, nonatomic, weak, readonly) UIView *fw_targetView NS_REFINED_FOR_SWIFT;

/// 是否正在拖动中：Began || Changed
@property (nonatomic, assign, readonly) BOOL fw_isTracking NS_REFINED_FOR_SWIFT;

/// 是否是激活状态: isEnabled && (Began || Changed)
@property (nonatomic, assign, readonly) BOOL fw_isActive NS_REFINED_FOR_SWIFT;

/// 判断手势是否正作用于指定视图
- (BOOL)fw_hitTestWithView:(nullable UIView *)view NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIPanGestureRecognizer+FWUIKit

@interface UIPanGestureRecognizer (FWUIKit)

/// 当前滑动方向，如果多个方向滑动，取绝对值较大的一方，失败返回0
@property (nonatomic, assign, readonly) UISwipeGestureRecognizerDirection fw_swipeDirection NS_REFINED_FOR_SWIFT;

/// 当前滑动进度，滑动绝对值相对于手势视图的宽或高
@property (nonatomic, assign, readonly) CGFloat fw_swipePercent NS_REFINED_FOR_SWIFT;

/// 计算指定方向的滑动进度
- (CGFloat)fw_swipePercentOfDirection:(UISwipeGestureRecognizerDirection)direction NS_REFINED_FOR_SWIFT;

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

/// 自定义关闭时除圆点的背景色
@property (nonatomic, strong, nullable) UIColor *fw_offTintColor UI_APPEARANCE_SELECTOR NS_REFINED_FOR_SWIFT;

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

/// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
@property (nonatomic, assign) BOOL fw_menuDisabled NS_REFINED_FOR_SWIFT;

/// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
@property (nonatomic, assign) CGRect fw_cursorRect NS_REFINED_FOR_SWIFT;

/// 获取及设置当前选中文字范围
@property (nonatomic, assign) NSRange fw_selectedRange NS_REFINED_FOR_SWIFT;

/// 移动光标到最后
- (void)fw_selectAllRange NS_REFINED_FOR_SWIFT;

/// 移动光标到指定位置，兼容动态text赋值
- (void)fw_moveCursor:(NSInteger)offset NS_REFINED_FOR_SWIFT;

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

/// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
@property (nonatomic, assign) BOOL fw_menuDisabled NS_REFINED_FOR_SWIFT;

/// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
@property (nonatomic, assign) CGRect fw_cursorRect NS_REFINED_FOR_SWIFT;

/// 获取及设置当前选中文字范围
@property (nonatomic, assign) NSRange fw_selectedRange NS_REFINED_FOR_SWIFT;

/// 移动光标到最后
- (void)fw_selectAllRange NS_REFINED_FOR_SWIFT;

/// 移动光标到指定位置，兼容动态text赋值
- (void)fw_moveCursor:(NSInteger)offset NS_REFINED_FOR_SWIFT;

/// 计算当前文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整
@property (nonatomic, assign, readonly) CGSize fw_textSize NS_REFINED_FOR_SWIFT;

/// 计算当前属性文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整，attributedText需指定字体
@property (nonatomic, assign, readonly) CGSize fw_attributedTextSize NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UITableView+FWUIKit

@interface UITableView (FWUIKit)

/// 全局清空TableView默认多余边距
+ (void)fw_resetTableStyle NS_REFINED_FOR_SWIFT;

/// 是否启动高度估算布局，启用后需要子视图布局完整，无需实现heightForRow方法(iOS11默认启用，会先cellForRow再heightForRow)
@property (nonatomic, assign) BOOL fw_estimatedLayout UI_APPEARANCE_SELECTOR NS_REFINED_FOR_SWIFT;

/// 清除Grouped等样式默认多余边距，注意CGFLOAT_MIN才会生效，0不会生效
- (void)fw_resetTableStyle NS_REFINED_FOR_SWIFT;

/// reloadData完成回调
- (void)fw_reloadDataWithCompletion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// reloadData禁用动画
- (void)fw_reloadDataWithoutAnimation NS_REFINED_FOR_SWIFT;

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

#pragma mark - UICollectionView+FWUIKit

@interface UICollectionView (FWUIKit)

/// reloadData完成回调
- (void)fw_reloadDataWithCompletion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// reloadData禁用动画
- (void)fw_reloadDataWithoutAnimation NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UICollectionViewCell+FWUIKit

@interface UICollectionViewCell (FWUIKit)

/// 获取当前所属collectionView
@property (nonatomic, weak, readonly, nullable) UICollectionView *fw_collectionView NS_REFINED_FOR_SWIFT;

/// 获取当前显示indexPath
@property (nonatomic, readonly, nullable) NSIndexPath *fw_indexPath NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UISearchBar+FWUIKit

@interface UISearchBar (FWUIKit)

/// 自定义内容边距，可调整左右距离和TextField高度，未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fw_contentInset NS_REFINED_FOR_SWIFT;

/// 自定义取消按钮边距，未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fw_cancelButtonInset NS_REFINED_FOR_SWIFT;

/// 输入框内部视图
@property (nullable, nonatomic, weak, readonly) UITextField *fw_textField NS_REFINED_FOR_SWIFT;

/// 取消按钮内部视图，showsCancelButton开启后才存在
@property (nullable, nonatomic, weak, readonly) UIButton *fw_cancelButton NS_REFINED_FOR_SWIFT;

/// 设置整体背景色
@property (nonatomic, strong, nullable) UIColor *fw_backgroundColor NS_REFINED_FOR_SWIFT;

/// 设置输入框背景色
@property (nonatomic, strong, nullable) UIColor *fw_textFieldBackgroundColor NS_REFINED_FOR_SWIFT;

/// 设置搜索图标离左侧的偏移位置，非居中时生效
@property (nonatomic, assign) CGFloat fw_searchIconOffset NS_REFINED_FOR_SWIFT;

/// 设置搜索文本离左侧图标的偏移位置
@property (nonatomic, assign) CGFloat fw_searchTextOffset NS_REFINED_FOR_SWIFT;

/// 设置TextField搜索图标(placeholder)是否居中，否则居左
@property (nonatomic, assign) BOOL fw_searchIconCenter NS_REFINED_FOR_SWIFT;

/// 强制取消按钮一直可点击，需在showsCancelButton设置之后生效。默认SearchBar失去焦点之后取消按钮不可点击
@property (nonatomic, assign) BOOL fw_forceCancelButtonEnabled NS_REFINED_FOR_SWIFT;

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

/// 获取祖先视图，标签栏存在时为标签栏根视图，导航栏存在时为导航栏根视图，否则为控制器根视图
@property (nonatomic, strong, readonly) UIView *fw_ancestorView NS_REFINED_FOR_SWIFT;

/// 是否已经加载完数据，默认NO，加载数据完成后可标记为YES，可用于第一次加载时显示loading等判断
@property (nonatomic, assign) BOOL fw_isDataLoaded NS_REFINED_FOR_SWIFT;

/// 添加子控制器到当前视图，解决不能触发viewWillAppear等的bug
- (void)fw_addChildViewController:(UIViewController *)viewController NS_REFINED_FOR_SWIFT;

/// 添加子控制器到指定视图，可自定义布局，解决不能触发viewWillAppear等的bug
- (void)fw_addChildViewController:(UIViewController *)viewController inView:(nullable UIView *)view layout:(nullable void (NS_NOESCAPE ^)(UIView *view))layout NS_REFINED_FOR_SWIFT;

/// 移除子控制器，解决不能触发viewWillAppear等的bug
- (void)fw_removeChildViewController:(UIViewController *)viewController NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
