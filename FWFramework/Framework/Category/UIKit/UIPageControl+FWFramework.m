/*!
 @header     UIPageControl+FWFramework.m
 @indexgroup FWFramework
 @brief      UIPageControl+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/3
 */

#import "UIPageControl+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

@implementation UIPageControl (FWFramework)

+ (void)load
{
    [self fwSwizzleInstanceMethod:@selector(setCurrentPage:) with:@selector(fwInnerSetCurrentPage:)];
}

- (CGSize)fwIndicatorSize
{
    return [objc_getAssociatedObject(self, @selector(fwIndicatorSize)) CGSizeValue];
}

- (void)setFwIndicatorSize:(CGSize)fwIndicatorSize
{
    objc_setAssociatedObject(self, @selector(fwIndicatorSize), [NSValue valueWithCGSize:fwIndicatorSize], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwInnerSetCurrentPage:(NSInteger)currentPage
{
    [self fwInnerSetCurrentPage:currentPage];
    
    // 自定义尺寸时才生效
    NSValue *sizeValue = objc_getAssociatedObject(self, @selector(fwIndicatorSize));
    if (sizeValue) {
        CGSize size = [sizeValue CGSizeValue];
        for (UIView *subview in self.subviews) {
            [subview setFrame:CGRectMake(subview.frame.origin.x, subview.frame.origin.y, size.width, size.height)];
        }
    }
}

@end
