//
//  NSMutableAttributedString+M80.h
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "M80AttributedLabelDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableAttributedString (M80)

- (void)fwSetTextColor:(UIColor*)color;
- (void)fwSetTextColor:(UIColor*)color range:(NSRange)range;

- (void)fwSetFont:(UIFont*)font;
- (void)fwSetFont:(UIFont*)font range:(NSRange)range;

- (void)fwSetUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier;
- (void)fwSetUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier
                    range:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
