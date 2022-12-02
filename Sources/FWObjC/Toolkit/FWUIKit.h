//
//  FWUIKit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIImageView+FWUIKit

@interface UIImageView (FWUIKit)

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

@end

NS_ASSUME_NONNULL_END
