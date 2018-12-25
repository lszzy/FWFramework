//
//  M80AttributedLabelDefines.h
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#ifndef M80AttributedLabel_M80AttributedLabelDefines_h
#define M80AttributedLabel_M80AttributedLabelDefines_h

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, FWAttributedAlignment) {
    FWAttributedAlignmentTop,
    FWAttributedAlignmentCenter,
    FWAttributedAlignmentBottom
};

@class FWAttributedLabel;

@protocol FWAttributedLabelDelegate <NSObject>
- (void)attributedLabel:(FWAttributedLabel *)label
             clickedOnLink:(id)linkData;

@end

typedef NSArray * _Nullable (^FWCustomDetectLinkBlock)(NSString * _Nullable text);

NS_ASSUME_NONNULL_END

#endif
