//
//  FWDebugger.h
//  FWFramework
//
//  Created by wuyong on 2022/4/24.
//

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

/// https://github.com/Tencent/QMUI_iOS
@interface FWObjectWrapper (FWDebugger)

/// 获取当前对象的所有 @property、方法，父类的方法也会分别列出
@property (nonatomic, copy, readonly) NSString *methodList;

/// 获取当前对象的所有 @property、方法，不包含父类的
@property (nonatomic, copy, readonly) NSString *shortMethodList;

/// 当前对象的所有 Ivar 变量
@property (nonatomic, copy, readonly) NSString *ivarList;

@end

@interface FWViewWrapper (FWDebugger)

/// 获取当前 UIView 层级树信息
@property (nonatomic, copy, readonly) NSString *viewInfo;

/// 是否需要添加debug背景色，默认NO
@property(nonatomic, assign) BOOL showDebugColor;

/// 是否每个view的背景色随机，如果不随机则统一使用半透明红色，默认NO
@property(nonatomic, assign) BOOL randomDebugColor;

@end

@interface FWLabelWrapper (FWDebugger)

/**
 调试功能，打开后会在 label 第一行文字里把 descender、xHeight、capHeight、lineHeight 所在的位置以线条的形式标记出来。
 对这些属性的解释可以看这篇文章 https://www.rightpoint.com/rplabs/ios-tracking-typography
 */
@property (nonatomic, assign) BOOL showPrincipalLines;

/**
 当打开 showPrincipalLines 时，通过这个属性控制线条的颜色，默认为 半透明红色
 */
@property (nonatomic, strong) UIColor *principalLineColor;

@end

NS_ASSUME_NONNULL_END
