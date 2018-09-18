/*!
 @header     UIButton+FWFramework.m
 @indexgroup FWFramework
 @brief      UIButton+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UIButton+FWFramework.h"
#import <objc/runtime.h>

@implementation UIButton (FWFramework)

#pragma mark - Touch

- (UIEdgeInsets)fwTouchInsets
{
    return [objc_getAssociatedObject(self, @selector(fwTouchInsets)) UIEdgeInsetsValue];
}

- (void)setFwTouchInsets:(UIEdgeInsets)fwTouchInsets
{
    objc_setAssociatedObject(self, @selector(fwTouchInsets), [NSValue valueWithUIEdgeInsets:fwTouchInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    NSValue *insetsValue = objc_getAssociatedObject(self, @selector(fwTouchInsets));
    if (insetsValue) {
        UIEdgeInsets touchInsets = [insetsValue UIEdgeInsetsValue];
        CGRect bounds = self.bounds;
        bounds = CGRectMake(bounds.origin.x - touchInsets.left,
                            bounds.origin.y - touchInsets.top,
                            bounds.size.width + touchInsets.left + touchInsets.right,
                            bounds.size.height + touchInsets.top + touchInsets.bottom);
        return CGRectContainsPoint(bounds, point);
    }
    
    return [super pointInside:point withEvent:event];
}

- (void)fwSetImageEdge:(UIRectEdge)edge spacing:(CGFloat)spacing
{
    CGFloat imageWith = self.imageView.image.size.width;
    CGFloat imageHeight = self.imageView.image.size.height;
    CGSize labelSize = [self.titleLabel.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.titleLabel.font, NSFontAttributeName, nil]];
    CGFloat labelWidth = labelSize.width;
    CGFloat labelHeight = labelSize.height;
    
    // image中心移动的x距离
    CGFloat imageOffsetX = (imageWith + labelWidth) / 2 - imageWith / 2;
    // image中心移动的y距离
    CGFloat imageOffsetY = imageHeight / 2 + spacing / 2;
    // label中心移动的x距离
    CGFloat labelOffsetX = (imageWith + labelWidth / 2) - (imageWith + labelWidth) / 2;
    // label中心移动的y距离
    CGFloat labelOffsetY = labelHeight / 2 + spacing / 2;
    
    switch (edge) {
        case UIRectEdgeLeft:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, -spacing / 2, 0, spacing / 2);
            self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing / 2, 0, -spacing / 2);
            break;
        case UIRectEdgeRight:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, labelWidth + spacing / 2, 0, -(labelWidth + spacing / 2));
            self.titleEdgeInsets = UIEdgeInsetsMake(0, -(imageHeight + spacing / 2), 0, imageHeight + spacing / 2);
            break;
        case UIRectEdgeTop:
            self.imageEdgeInsets = UIEdgeInsetsMake(-imageOffsetY, imageOffsetX, imageOffsetY, -imageOffsetX);
            self.titleEdgeInsets = UIEdgeInsetsMake(labelOffsetY, -labelOffsetX, -labelOffsetY, labelOffsetX);
            break;
        case UIRectEdgeBottom:
            self.imageEdgeInsets = UIEdgeInsetsMake(imageOffsetY, imageOffsetX, -imageOffsetY, -imageOffsetX);
            self.titleEdgeInsets = UIEdgeInsetsMake(-labelOffsetY, -labelOffsetX, labelOffsetY, labelOffsetX);
            break;
        default:
            break;
    }
    
}

- (void)fwSetBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundImage:image forState:state];
}

- (void)fwCountDown:(NSInteger)timeout title:(NSString *)title waitTitle:(NSString *)waitTitle
{
    // 倒计时时间，每秒执行
    __block NSInteger countdown = timeout;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        // 倒计时时间
        if (countdown <= 0) {
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                // 先设置titleLabel，再设置title，防止闪烁，下同
                self.titleLabel.text = title;
                [self setTitle:title forState:UIControlStateNormal];
                self.enabled = YES;
            });
        } else {
            countdown--;
            dispatch_async(dispatch_get_main_queue(), ^{
                // 时间+1，防止倒计时显示0秒
                NSString *waitText = [NSString stringWithFormat:waitTitle, (countdown + 1)];
                self.titleLabel.text = waitText;
                [self setTitle:waitText forState:UIControlStateNormal];
                self.enabled = NO;
            });
        }
    });
    dispatch_resume(_timer);
}

@end
