/*!
 @header     FWFloatLayoutView.m
 @indexgroup FWFramework
 @brief      FWFloatLayoutView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import "FWFloatLayoutView.h"

#define FWValueSwitchAlignLeftOrRight(valueLeft, valueRight) ([self shouldAlignRight] ? valueRight : valueLeft)

const CGSize FWFloatLayoutViewAutomaticalMaximumItemSize = {-1, -1};

@implementation FWFloatLayoutView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self didInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    self.contentMode = UIViewContentModeLeft;
    self.minimumItemSize = CGSizeZero;
    self.maximumItemSize = FWFloatLayoutViewAutomaticalMaximumItemSize;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self layoutSubviewsWithSize:size shouldLayout:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutSubviewsWithSize:self.bounds.size shouldLayout:YES];
}

- (CGSize)layoutSubviewsWithSize:(CGSize)size shouldLayout:(BOOL)shouldLayout {
    NSArray<UIView *> *visibleItemViews = [self visibleSubviews];
    
    if (visibleItemViews.count == 0) {
        return CGSizeMake(self.padding.left + self.padding.right, self.padding.top + self.padding.bottom);
    }
    
    // 如果是左对齐，则代表 item 左上角的坐标，如果是右对齐，则代表 item 右上角的坐标
    CGPoint itemViewOrigin = CGPointMake(FWValueSwitchAlignLeftOrRight(self.padding.left, size.width - self.padding.right), self.padding.top);
    CGFloat currentRowMaxY = itemViewOrigin.y;
    CGSize maximumItemSize = CGSizeEqualToSize(self.maximumItemSize, FWFloatLayoutViewAutomaticalMaximumItemSize) ? CGSizeMake(size.width - (self.padding.left + self.padding.right), size.height - (self.padding.top + self.padding.bottom)) : self.maximumItemSize;
    NSInteger line = -1;
    for (NSInteger i = 0, l = visibleItemViews.count; i < l; i++) {
        UIView *itemView = visibleItemViews[i];
        
        CGRect itemViewFrame;
        CGSize itemViewSize = [itemView sizeThatFits:maximumItemSize];
        itemViewSize.width = MIN(maximumItemSize.width, MAX(self.minimumItemSize.width, itemViewSize.width));
        itemViewSize.height = MIN(maximumItemSize.height, MAX(self.minimumItemSize.height, itemViewSize.height));
        
        BOOL shouldBreakline = i == 0 ? YES : FWValueSwitchAlignLeftOrRight(itemViewOrigin.x + self.itemMargins.left + itemViewSize.width + self.padding.right > size.width,
                                                           itemViewOrigin.x - self.itemMargins.right - itemViewSize.width - self.padding.left < 0);
        if (shouldBreakline) {
            line++;
            currentRowMaxY += line > 0 ? self.itemMargins.top : 0;
            // 换行，每一行第一个 item 是不考虑 itemMargins 的
            itemViewFrame = CGRectMake(FWValueSwitchAlignLeftOrRight(self.padding.left, size.width - self.padding.right - itemViewSize.width), currentRowMaxY, itemViewSize.width, itemViewSize.height);
            itemViewOrigin.y = CGRectGetMinY(itemViewFrame);
        } else {
            // 当前行放得下
            itemViewFrame = CGRectMake(FWValueSwitchAlignLeftOrRight(itemViewOrigin.x + self.itemMargins.left, itemViewOrigin.x - self.itemMargins.right - itemViewSize.width), itemViewOrigin.y, itemViewSize.width, itemViewSize.height);
        }
        itemViewOrigin.x = FWValueSwitchAlignLeftOrRight(CGRectGetMaxX(itemViewFrame) + self.itemMargins.right, CGRectGetMinX(itemViewFrame) - self.itemMargins.left);
        currentRowMaxY = MAX(currentRowMaxY, CGRectGetMaxY(itemViewFrame) + self.itemMargins.bottom);
        
        if (shouldLayout) {
            itemView.frame = itemViewFrame;
        }
    }
    
    // 最后一行不需要考虑 itemMarins.bottom，所以这里减掉
    currentRowMaxY -= self.itemMargins.bottom;
    
    CGSize resultSize = CGSizeMake(size.width, currentRowMaxY + self.padding.bottom);
    return resultSize;
}

- (NSArray<UIView *> *)visibleSubviews {
    NSMutableArray<UIView *> *visibleItemViews = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0, l = self.subviews.count; i < l; i++) {
        UIView *itemView = self.subviews[i];
        if (!itemView.hidden) {
            [visibleItemViews addObject:itemView];
        }
    }
    
    return visibleItemViews;
}

- (BOOL)shouldAlignRight {
    return self.contentMode == UIViewContentModeRight;
}

@end
