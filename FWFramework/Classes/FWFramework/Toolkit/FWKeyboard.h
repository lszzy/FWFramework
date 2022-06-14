/**
 @header     FWKeyboard.h
 @indexgroup FWFramework
      FWKeyboard
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWTextFieldWrapper+FWKeyboard

/// 文本输入框键盘管理分类
@interface FWTextFieldWrapper (FWKeyboard)

#pragma mark - Keyboard

/// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL keyboardManager UI_APPEARANCE_SELECTOR;

/// 设置输入框和键盘的空白间距，默认10.0
@property (nonatomic, assign) CGFloat keyboardDistance UI_APPEARANCE_SELECTOR;

/// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
@property (nonatomic, assign) CGFloat reboundDistance UI_APPEARANCE_SELECTOR;

/// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL keyboardResign UI_APPEARANCE_SELECTOR;

/// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL touchResign UI_APPEARANCE_SELECTOR;

/// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
@property (nullable, nonatomic, weak) UIScrollView *keyboardScrollView;

#pragma mark - Return

/// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
@property (nonatomic, assign) BOOL returnResign UI_APPEARANCE_SELECTOR;

/// 设置点击键盘完成按钮自动切换的下一个输入框，二选一
@property (nullable, nonatomic, weak) UIResponder *returnResponder;

/// 设置点击键盘完成按钮的事件句柄
@property (nullable, nonatomic, copy) void (^returnBlock)(UITextField *textField);

#pragma mark - Toolbar

/// 获取关联的键盘Toolbar对象，可自定义样式
@property (nonatomic, strong) UIToolbar *keyboardToolbar;

/// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
@property (nonatomic, strong, nullable) id toolbarPreviousButton;

/// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
@property (nonatomic, strong, nullable) id toolbarNextButton;

/// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
@property (nonatomic, strong, nullable) id toolbarDoneButton;

/// 设置Toolbar点击前一个按钮时聚焦的输入框，默认nil
@property (nullable, nonatomic, weak) UIResponder *previousResponder;

/// 设置Toolbar点击下一个按钮时聚焦的输入框，默认nil
@property (nullable, nonatomic, weak) UIResponder *nextResponder;

/// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
- (CGFloat)keyboardHeight:(NSNotification *)notification;

/// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
- (void)keyboardAnimate:(NSNotification *)notification
             animations:(void (^)(void))animations
             completion:(void (^ __nullable)(BOOL finished))completion;

/// 添加Toolbar，指定标题和完成句柄，使用默认按钮
/// @param title 标题，不能点击
/// @param doneBlock 右侧完成按钮句柄，默认收起键盘
- (void)addToolbarWithTitle:(nullable id)title
                  doneBlock:(nullable void (^)(id sender))doneBlock;

/// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
/// @param titleItem 居中标题按钮
/// @param previousItem 左侧前一个按钮
/// @param nextItem 左侧下一个按钮
/// @param doneItem 右侧完成按钮
- (void)addToolbarWithTitleItem:(nullable UIBarButtonItem *)titleItem
                   previousItem:(nullable UIBarButtonItem *)previousItem
                       nextItem:(nullable UIBarButtonItem *)nextItem
                       doneItem:(nullable UIBarButtonItem *)doneItem;

@end

#pragma mark - FWTextViewWrapper+FWKeyboard

/// 多行输入框键盘管理分类
@interface FWTextViewWrapper (FWKeyboard)

#pragma mark - Keyboard

/// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL keyboardManager UI_APPEARANCE_SELECTOR;

/// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat keyboardDistance UI_APPEARANCE_SELECTOR;

/// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
@property (nonatomic, assign) CGFloat reboundDistance UI_APPEARANCE_SELECTOR;

/// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL keyboardResign UI_APPEARANCE_SELECTOR;

/// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL touchResign UI_APPEARANCE_SELECTOR;

/// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
@property (nullable, nonatomic, weak) UIScrollView *keyboardScrollView;

#pragma mark - Return

/// 点击键盘完成按钮是否关闭键盘，默认NO，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nonatomic, assign) BOOL returnResign UI_APPEARANCE_SELECTOR;

/// 设置点击键盘完成按钮自动切换的下一个输入框，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nullable, nonatomic, weak) UIResponder *returnResponder;

/// 设置点击键盘完成按钮的事件句柄。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nullable, nonatomic, copy) void (^returnBlock)(UITextView *textView);

/// 调用上面三个方法后会修改delegate，此方法始终访问外部delegate
@property (nullable, nonatomic, weak) id<UITextViewDelegate> delegate;

#pragma mark - Toolbar

/// 获取关联的键盘Toolbar对象，可自定义
@property (nonatomic, strong) UIToolbar *keyboardToolbar;

/// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
@property (nonatomic, strong, nullable) id toolbarPreviousButton;

/// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
@property (nonatomic, strong, nullable) id toolbarNextButton;

/// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
@property (nonatomic, strong, nullable) id toolbarDoneButton;

/// 设置Toolbar点击前一个按钮时聚焦的输入框，默认nil
@property (nullable, nonatomic, weak) UIResponder *previousResponder;

/// 设置Toolbar点击下一个按钮时聚焦的输入框，默认nil
@property (nullable, nonatomic, weak) UIResponder *nextResponder;

/// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
- (CGFloat)keyboardHeight:(NSNotification *)notification;

/// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
- (void)keyboardAnimate:(NSNotification *)notification
             animations:(void (^)(void))animations
             completion:(void (^ __nullable)(BOOL finished))completion;

/// 添加Toolbar，指定标题和完成句柄，使用默认按钮
/// @param title 标题，不能点击
/// @param doneBlock 右侧完成按钮句柄，默认收起键盘
- (void)addToolbarWithTitle:(nullable id)title
                  doneBlock:(nullable void (^)(id sender))doneBlock;

/// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
/// @param titleItem 居中标题按钮
/// @param previousItem 左侧前一个按钮
/// @param nextItem 左侧下一个按钮
/// @param doneItem 右侧完成按钮
- (void)addToolbarWithTitleItem:(nullable UIBarButtonItem *)titleItem
                   previousItem:(nullable UIBarButtonItem *)previousItem
                       nextItem:(nullable UIBarButtonItem *)nextItem
                       doneItem:(nullable UIBarButtonItem *)doneItem;

@end

#pragma mark - FWTextViewWrapper+FWPlaceholder

/// 多行输入框占位文本分类
@interface FWTextViewWrapper (FWPlaceholder)

/// 占位文本，默认nil
@property (nullable, nonatomic, strong) NSString *placeholder;

/// 占位颜色，默认系统颜色
@property (nullable, nonatomic, strong) UIColor *placeholderColor;

/// 带属性占位文本，默认nil
@property (nullable, nonatomic, strong) NSAttributedString *attributedPlaceholder;

/// 自定义占位文本内间距，默认zero与内容一致
@property (nonatomic, assign) UIEdgeInsets placeholderInset;

/// 自定义垂直分布方式，会自动修改contentInset，默认Top与系统一致
@property (nonatomic, assign) UIControlContentVerticalAlignment verticalAlignment;

/// 是否启用自动高度功能，随文字改变高度
@property (nonatomic, assign) BOOL autoHeightEnabled;

/// 最大高度，默认CGFLOAT_MAX，启用自动高度后生效
@property (nonatomic, assign) CGFloat maxHeight;

/// 最小高度，默认0，启用自动高度后生效
@property (nonatomic, assign) CGFloat minHeight;

/// 高度改变回调句柄，默认nil，启用自动高度后生效
@property (nullable, nonatomic, copy) void (^heightDidChange)(CGFloat height);

/// 快捷启用自动高度，并设置最大高度和回调句柄
- (void)autoHeightWithMaxHeight:(CGFloat)maxHeight didChange:(nullable void (^)(CGFloat height))didChange;

@end

NS_ASSUME_NONNULL_END
