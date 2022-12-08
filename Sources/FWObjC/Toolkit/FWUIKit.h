//
//  FWUIKit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
