//
//  UITextView+FWPlaceholder.h
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (FWPlaceholder)

// 占位文本
@property (nonatomic, strong) NSString *fwPlaceholder;

// 占位颜色
@property (nonatomic, strong) UIColor *fwPlaceholderColor;

// 带属性占位文本
@property (nonatomic, strong) NSAttributedString *fwAttributedPlaceholder;

@end
