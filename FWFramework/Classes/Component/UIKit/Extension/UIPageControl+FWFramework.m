/*!
 @header     UIPageControl+FWFramework.m
 @indexgroup FWFramework
 @brief      UIPageControl+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/3
 */

#import "UIPageControl+FWFramework.h"

@implementation UIPageControl (FWFramework)

- (void)fwSetIndicatorSize:(CGSize)indicatorSize
{
    CGSize initialSize = self.bounds.size;
    if (CGSizeEqualToSize(initialSize, CGSizeZero)) {
        initialSize = CGSizeMake(10, 10);
    }
    
    CGFloat scale = indicatorSize.height / initialSize.height;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

@implementation UIActivityIndicatorView (FWFramework)

+ (instancetype)fwIndicatorViewWithColor:(UIColor *)color
{
    UIActivityIndicatorViewStyle indicatorStyle;
    if (@available(iOS 13.0, *)) {
        indicatorStyle = UIActivityIndicatorViewStyleMedium;
    } else {
        indicatorStyle = UIActivityIndicatorViewStyleWhite;
    }
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    indicatorView.color = color ?: UIColor.whiteColor;
    indicatorView.hidesWhenStopped = YES;
    return indicatorView;
}

- (void)fwSetIndicatorSize:(CGSize)indicatorSize
{
    CGSize initialSize = self.bounds.size;
    CGFloat scale = indicatorSize.width / initialSize.width;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

@end
