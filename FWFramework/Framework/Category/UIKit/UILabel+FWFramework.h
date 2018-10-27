/*!
 @header     UILabel+FWFramework.h
 @indexgroup FWFramework
 @brief      UILabel+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/10/22
 */

#import <UIKit/UIKit.h>

/*!
 @brief UILabel+FWFramework
 */
@interface UILabel (FWFramework)

// 自定义内容边距。未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fwContentInset;

// 纵向分布方式，默认居中
@property (nonatomic, assign) UIControlContentVerticalAlignment fwVerticalAlignment;

// 快速设置标签，不设置传nil即可
- (void)fwSetFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text;

// 快速创建标签，不初始化传nil即可
+ (instancetype)fwLabelWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text;

@end
