//
//  FWUIKit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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

/// 选中并获取指定索引TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
- (nullable __kindof UIViewController *)fw_selectTabBarIndex:(NSUInteger)index NS_REFINED_FOR_SWIFT;

/// 选中并获取指定类TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
- (nullable __kindof UIViewController *)fw_selectTabBarController:(Class)viewController NS_REFINED_FOR_SWIFT;

/// 选中并获取指定条件TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
- (nullable __kindof UIViewController *)fw_selectTabBarBlock:(BOOL (NS_NOESCAPE ^)(__kindof UIViewController *viewController))block NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIControl+FWUIKit

/// 防重复点击可以手工控制enabled或userInteractionEnabled，如request开始时禁用，结束时启用等
@interface UIControl (FWUIKit)

/// 设置Touch事件触发间隔，防止短时间多次触发事件，默认0
@property (nonatomic, assign) NSTimeInterval fw_touchEventInterval UI_APPEARANCE_SELECTOR NS_REFINED_FOR_SWIFT;

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

/// 自定义光标大小，不为0才会生效，默认zero不生效
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

/// 自定义光标大小，不为0才会生效，默认zero不生效
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

NS_ASSUME_NONNULL_END
