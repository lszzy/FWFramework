/*!
 @header     FWKeyboard.h
 @indexgroup FWFramework
 @brief      FWKeyboard
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UITextField+FWKeyboard

/// 文本输入框键盘管理分类
@interface UITextField (FWKeyboard)

#pragma mark - Keyboard

/// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager UI_APPEARANCE_SELECTOR;

/// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing UI_APPEARANCE_SELECTOR;

/// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL fwKeyboardResign UI_APPEARANCE_SELECTOR;

/// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL fwTouchResign UI_APPEARANCE_SELECTOR;

/// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
@property (nullable, nonatomic, weak) UIScrollView *fwKeyboardScrollView;

#pragma mark - Return

/// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
@property (nonatomic, assign) BOOL fwReturnResign;

/// 设置点击键盘完成按钮自动切换的下一个输入框，二选一
@property (nullable, nonatomic, weak) UIResponder *fwReturnResponder;

/// 设置点击键盘完成按钮的事件句柄
@property (nullable, nonatomic, copy) void (^fwReturnBlock)(UITextField *textField);

#pragma mark - Toolbar

/// 添加Toolbar，指定右边按钮标题和句柄(默认收起键盘)
- (UIToolbar *)fwAddToolbar:(UIBarStyle)barStyle title:(NSString *)title block:(nullable void (^)(id sender))block;

/// 添加Toolbar，可选指定左边和右边按钮
- (UIToolbar *)fwAddToolbar:(UIBarStyle)barStyle leftItem:(nullable UIBarButtonItem *)leftItem rightItem:(nullable UIBarButtonItem *)rightItem;

@end

#pragma mark - UITextView+FWKeyboard

/// 多行输入框键盘管理分类
@interface UITextView (FWKeyboard)

#pragma mark - Keyboard

/// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager UI_APPEARANCE_SELECTOR;

/// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing UI_APPEARANCE_SELECTOR;

/// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL fwKeyboardResign UI_APPEARANCE_SELECTOR;

/// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL fwTouchResign UI_APPEARANCE_SELECTOR;

/// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
@property (nullable, nonatomic, weak) UIScrollView *fwKeyboardScrollView;

#pragma mark - Return

/// 点击键盘完成按钮是否关闭键盘，默认NO，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nonatomic, assign) BOOL fwReturnResign;

/// 设置点击键盘完成按钮自动切换的下一个输入框，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nullable, nonatomic, weak) UIResponder *fwReturnResponder;

/// 设置点击键盘完成按钮的事件句柄。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nullable, nonatomic, copy) void (^fwReturnBlock)(UITextView *textView);

/// 调用上面三个方法后会修改delegate，此方法始终访问外部delegate
@property (nullable, nonatomic, weak) id<UITextViewDelegate> fwDelegate;

#pragma mark - Toolbar

/// 添加Toolbar，指定右边按钮标题和句柄(默认收起键盘)
- (UIToolbar *)fwAddToolbar:(UIBarStyle)barStyle title:(NSString *)title block:(nullable void (^)(id sender))block;

/// 添加Toolbar，可选指定左边和右边按钮
- (UIToolbar *)fwAddToolbar:(UIBarStyle)barStyle leftItem:(nullable UIBarButtonItem *)leftItem rightItem:(nullable UIBarButtonItem *)rightItem;

@end

#pragma mark - UITextView+FWPlaceholder

/// 多行输入框占位文本分类
@interface UITextView (FWPlaceholder)

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

NS_ASSUME_NONNULL_END
