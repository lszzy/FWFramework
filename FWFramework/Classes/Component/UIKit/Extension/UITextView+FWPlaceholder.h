//
//  UITextView+FWPlaceholder.h
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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

#pragma mark - AutoHeight

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
