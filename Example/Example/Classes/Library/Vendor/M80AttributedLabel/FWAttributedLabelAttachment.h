//
//  M80AttributedLabelAttachment.h
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "M80AttributedLabelDefines.h"

NS_ASSUME_NONNULL_BEGIN

void fwAttributedDeallocCallback(void* ref);
CGFloat fwAttributedAscentCallback(void *ref);
CGFloat fwAttributedDescentCallback(void *ref);
CGFloat fwAttributedWidthCallback(void* ref);

@interface FWAttributedLabelAttachment : NSObject
@property (nonatomic,strong)    id                  content;
@property (nonatomic,assign)    UIEdgeInsets        margin;
@property (nonatomic,assign)    FWAttributedAlignment   alignment;
@property (nonatomic,assign)    CGFloat             fontAscent;
@property (nonatomic,assign)    CGFloat             fontDescent;
@property (nonatomic,assign)    CGSize              maxSize;


+ (FWAttributedLabelAttachment *)attachmentWith:(id)content
                                          margin:(UIEdgeInsets)margin
                                       alignment:(FWAttributedAlignment)alignment
                                         maxSize:(CGSize)maxSize;

- (CGSize)boxSize;

@end


NS_ASSUME_NONNULL_END
