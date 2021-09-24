/*!
 @header     FWUIKit.m
 @indexgroup FWFramework
 @brief      FWUIKit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWUIKit.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>
#if FWCOMPONENT_TRACKING_ENABLED
#import <AdSupport/ASIdentifierManager.h>
#endif

#pragma mark - UIDevice+FWUIKit

@implementation UIDevice (FWUIKit)

+ (void)fwSetDeviceTokenData:(NSData *)tokenData
{
    if (tokenData) {
        NSMutableString *deviceToken = [NSMutableString string];
        const char *bytes = tokenData.bytes;
        NSInteger count = tokenData.length;
        for (int i = 0; i < count; i++) {
            [deviceToken appendFormat:@"%02x", bytes[i] & 0x000000FF];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[deviceToken copy] forKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)fwDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
}

+ (NSString *)fwDeviceModel
{
    static NSString *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
}

+ (NSString *)fwDeviceIDFV
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSString *)fwDeviceIDFA
{
#if FWCOMPONENT_TRACKING_ENABLED
    return [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
#else
    return nil;
#endif
}

@end

#pragma mark - UIView+FWUIKit

@implementation UIView (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(pointInside:withEvent:), FWSwizzleReturn(BOOL), FWSwizzleArgs(CGPoint point, UIEvent *event), FWSwizzleCode({
            NSValue *insetsValue = objc_getAssociatedObject(selfObject, @selector(fwTouchInsets));
            if (insetsValue) {
                UIEdgeInsets touchInsets = [insetsValue UIEdgeInsetsValue];
                CGRect bounds = selfObject.bounds;
                bounds = CGRectMake(bounds.origin.x - touchInsets.left,
                                    bounds.origin.y - touchInsets.top,
                                    bounds.size.width + touchInsets.left + touchInsets.right,
                                    bounds.size.height + touchInsets.top + touchInsets.bottom);
                return CGRectContainsPoint(bounds, point);
            }
            
            return FWSwizzleOriginal(point, event);
        }));
        
        FWSwizzleClass(UIButton, @selector(setEnabled:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL enabled), FWSwizzleCode({
            FWSwizzleOriginal(enabled);
            
            if (selfObject.fwDisabledAlpha > 0) {
                selfObject.alpha = enabled ? 1 : selfObject.fwDisabledAlpha;
            }
        }));
        
        FWSwizzleClass(UIButton, @selector(setHighlighted:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL highlighted), FWSwizzleCode({
            FWSwizzleOriginal(highlighted);
            
            if (selfObject.enabled && selfObject.fwHighlightedAlpha > 0) {
                selfObject.alpha = highlighted ? selfObject.fwHighlightedAlpha : 1;
            }
        }));
    });
}

- (UIViewController *)fwViewController
{
    UIResponder *responder = [self nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (UIEdgeInsets)fwTouchInsets
{
    return [objc_getAssociatedObject(self, @selector(fwTouchInsets)) UIEdgeInsetsValue];
}

- (void)setFwTouchInsets:(UIEdgeInsets)fwTouchInsets
{
    objc_setAssociatedObject(self, @selector(fwTouchInsets), [NSValue valueWithUIEdgeInsets:fwTouchInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)fwFrameApplyTransform
{
    return self.frame;
}

- (void)setFwFrameApplyTransform:(CGRect)fwFrameApplyTransform
{
    self.frame = [UIView fwRectApplyTransform:fwFrameApplyTransform transform:self.transform anchorPoint:self.layer.anchorPoint];
}

/// 计算目标点 targetPoint 围绕坐标点 coordinatePoint 通过 transform 之后此点的坐标。@see https://github.com/Tencent/QMUI_iOS
+ (CGPoint)fwPointApplyTransform:(CGPoint)coordinatePoint targetPoint:(CGPoint)targetPoint transform:(CGAffineTransform)transform
{
    CGPoint p;
    p.x = (targetPoint.x - coordinatePoint.x) * transform.a + (targetPoint.y - coordinatePoint.y) * transform.c + coordinatePoint.x;
    p.y = (targetPoint.x - coordinatePoint.x) * transform.b + (targetPoint.y - coordinatePoint.y) * transform.d + coordinatePoint.y;
    p.x += transform.tx;
    p.y += transform.ty;
    return p;
}

/// 系统的 CGRectApplyAffineTransform 只会按照 anchorPoint 为 (0, 0) 的方式去计算，但通常情况下我们面对的是 UIView/CALayer，它们默认的 anchorPoint 为 (.5, .5)，所以增加这个函数，在计算 transform 时可以考虑上 anchorPoint 的影响。@see https://github.com/Tencent/QMUI_iOS
+ (CGRect)fwRectApplyTransform:(CGRect)rect transform:(CGAffineTransform)transform anchorPoint:(CGPoint)anchorPoint
{
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    CGPoint oPoint = CGPointMake(rect.origin.x + width * anchorPoint.x, rect.origin.y + height * anchorPoint.y);
    CGPoint top_left = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x, rect.origin.y) transform:transform];
    CGPoint bottom_left = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x, rect.origin.y + height) transform:transform];
    CGPoint top_right = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x + width, rect.origin.y) transform:transform];
    CGPoint bottom_right = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x + width, rect.origin.y + height) transform:transform];
    CGFloat minX = MIN(MIN(MIN(top_left.x, bottom_left.x), top_right.x), bottom_right.x);
    CGFloat maxX = MAX(MAX(MAX(top_left.x, bottom_left.x), top_right.x), bottom_right.x);
    CGFloat minY = MIN(MIN(MIN(top_left.y, bottom_left.y), top_right.y), bottom_right.y);
    CGFloat maxY = MAX(MAX(MAX(top_left.y, bottom_left.y), top_right.y), bottom_right.y);
    CGFloat newWidth = maxX - minX;
    CGFloat newHeight = maxY - minY;
    CGRect result = CGRectMake(minX, minY, newWidth, newHeight);
    return result;
}

@end

#pragma mark - UIButton+FWUIKit

@implementation UIButton (FWUIKit)

- (CGFloat)fwDisabledAlpha
{
    return [objc_getAssociatedObject(self, @selector(fwDisabledAlpha)) doubleValue];
}

- (void)setFwDisabledAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fwDisabledAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (alpha > 0) {
        self.alpha = self.isEnabled ? 1 : alpha;
    }
}

- (CGFloat)fwHighlightedAlpha
{
    return [objc_getAssociatedObject(self, @selector(fwHighlightedAlpha)) doubleValue];
}

- (void)setFwHighlightedAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fwHighlightedAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.enabled && alpha > 0) {
        self.alpha = self.isHighlighted ? alpha : 1;
    }
}

@end

#pragma mark - UIScrollView+FWUIKit

@implementation UIScrollView (FWUIKit)

- (BOOL)fwCanScroll
{
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) {
        return NO;
    }
    
    if (self.contentSize.width + self.adjustedContentInset.left + self.adjustedContentInset.right > CGRectGetWidth(self.bounds)) {
        return YES;
    }
    
    return self.contentSize.height + self.adjustedContentInset.top + self.adjustedContentInset.bottom > CGRectGetHeight(self.bounds);
}

- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated
{
    CGPoint contentOffset = self.contentOffset;
    switch (edge) {
        case UIRectEdgeTop:
            contentOffset.y = -self.adjustedContentInset.top;
            break;
        case UIRectEdgeLeft:
            contentOffset.x = -self.adjustedContentInset.left;
            break;
        case UIRectEdgeBottom:
            contentOffset.y = self.contentSize.height - self.bounds.size.height + self.adjustedContentInset.bottom;
            break;
        case UIRectEdgeRight:
            contentOffset.x = self.contentSize.width - self.bounds.size.width + self.adjustedContentInset.right;
            break;
        default:
            break;
    }
    [self setContentOffset:contentOffset animated:animated];
}

@end

#pragma mark - UISlider+FWUIKit

@implementation UISlider (FWUIKit)

- (CGSize)fwThumbSize
{
    NSValue *value = objc_getAssociatedObject(self, @selector(fwThumbSize));
    return value ? [value CGSizeValue] : CGSizeZero;
}

- (void)setFwThumbSize:(CGSize)fwThumbSize
{
    objc_setAssociatedObject(self, @selector(fwThumbSize), [NSValue valueWithCGSize:fwThumbSize], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwUpdateThumbImage];
}

- (UIColor *)fwThumbColor
{
    return objc_getAssociatedObject(self, @selector(fwThumbColor));
}

- (void)setFwThumbColor:(UIColor *)fwThumbColor
{
    objc_setAssociatedObject(self, @selector(fwThumbColor), fwThumbColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwUpdateThumbImage];
}

- (void)fwUpdateThumbImage
{
    CGSize thumbSize = self.fwThumbSize;
    if (thumbSize.width <= 0 || thumbSize.height <= 0) return;
    UIColor *thumbColor = self.fwThumbColor ?: (self.tintColor ?: [UIColor whiteColor]);
    UIImage *thumbImage = [UIImage fwImageWithSize:thumbSize block:^(CGContextRef  _Nonnull context) {
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
        CGContextSetFillColorWithColor(context, thumbColor.CGColor);
        [path fill];
    }];
    
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
}

@end

#pragma mark - UISwitch+FWUIKit

@implementation UISwitch (FWUIKit)

- (void)fwSetSize:(CGSize)size
{
    CGFloat height = self.bounds.size.height;
    if (height <= 0) {
        height = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
        if (height <= 0) height = 31;
    }
    CGFloat scale = size.height / height;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

#pragma mark - UIViewController+FWUIKit

@implementation UIViewController (FWUIKit)

- (BOOL)fwIsRoot
{
    return !self.navigationController || self.navigationController.viewControllers.firstObject == self;
}

- (BOOL)fwIsChild
{
    UIViewController *parentController = self.parentViewController;
    if (parentController && ![parentController isKindOfClass:[UINavigationController class]] &&
        ![parentController isKindOfClass:[UITabBarController class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)fwIsPresented
{
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.viewControllers.firstObject != self) return NO;
        viewController = self.navigationController;
    }
    return viewController.presentingViewController.presentedViewController == viewController;
}

- (BOOL)fwIsPageSheet
{
    if (@available(iOS 13.0, *)) {
        UIViewController *controller = self.navigationController ?: self;
        if (!controller.presentingViewController) return NO;
        UIModalPresentationStyle style = controller.modalPresentationStyle;
        if (style == UIModalPresentationAutomatic || style == UIModalPresentationPageSheet) return YES;
    }
    return NO;
}

- (BOOL)fwIsViewVisible
{
    return self.isViewLoaded && self.view.window;
}

- (BOOL)fwIsLoaded
{
    return [objc_getAssociatedObject(self, @selector(fwIsLoaded)) boolValue];
}

- (void)setFwIsLoaded:(BOOL)fwIsLoaded
{
    objc_setAssociatedObject(self, @selector(fwIsLoaded), @(fwIsLoaded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
