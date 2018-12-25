//
//  M80AttributedLabelURL.h
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "M80AttributedLabelDefines.h"


NS_ASSUME_NONNULL_BEGIN

@interface FWAttributedLabelURL : NSObject
@property (nonatomic,strong)                id      linkData;
@property (nonatomic,assign)                NSRange range;
@property (nonatomic,strong,nullable)       UIColor *color;

+ (FWAttributedLabelURL *)urlWithLinkData:(id)linkData
                                     range:(NSRange)range
                                     color:(nullable UIColor *)color;


+ (nullable NSArray *)detectLinks:(nullable NSString *)plainText;

+ (void)setCustomDetectMethod:(nullable FWCustomDetectLinkBlock)block;
@end


NS_ASSUME_NONNULL_END
