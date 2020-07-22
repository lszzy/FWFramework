/*!
 @header     UINavigationController+FWFramework.m
 @indexgroup FWFramework
 @brief      UINavigationController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UINavigationController+FWFramework.h"
#import "UIViewController+FWBack.h"
#import <objc/runtime.h>

@interface FWFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Ignore when no view controller is pushed into the navigation stack.
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    // Ignore when the active view controller doesn't allow interactive pop.
    UIViewController *topViewController = self.navigationController.viewControllers.lastObject;
    if (topViewController.fwFullscreenPopGestureDisabled) {
        return NO;
    }
    
    // Compatible with UIViewController+FWBack protocol
    if ([topViewController respondsToSelector:@selector(fwPopBackBarItem)] &&
        ![topViewController fwPopBackBarItem]) {
        return NO;
    }
    
    // Ignore when the beginning location is beyond max allowed initial distance to left edge.
    CGPoint beginningLocation = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGFloat maxAllowedInitialDistance = topViewController.fwFullscreenPopGestureDistance;
    if (maxAllowedInitialDistance > 0 && beginningLocation.x > maxAllowedInitialDistance) {
        return NO;
    }
    
    // Ignore pan gesture when the navigation controller is currently in transition.
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    // Prevent calling the handler when the gesture begins in an opposite direction.
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    BOOL isLeftToRight = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight;
    CGFloat multiplier = isLeftToRight ? 1 : - 1;
    if ((translation.x * multiplier) <= 0) {
        return NO;
    }
    
    return YES;
}

@end

@implementation UINavigationController (FWFramework)

+ (BOOL)fwIsFullscreenPopGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.delegate isKindOfClass:[FWFullscreenPopGestureRecognizerDelegate class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)fwFullscreenPopGestureEnabled
{
    return self.fwFullscreenPopGestureRecognizer.enabled;
}

- (void)setFwFullscreenPopGestureEnabled:(BOOL)enabled
{
    if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.fwFullscreenPopGestureRecognizer]) {
        // Add our own gesture recognizer to where the onboard screen edge pan gesture recognizer is attached to.
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.fwFullscreenPopGestureRecognizer];
        
        // Forward the gesture events to the private handler of the onboard gesture recognizer.
        NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        self.fwFullscreenPopGestureRecognizer.delegate = self.fwPopGestureRecognizerDelegate;
        [self.fwFullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];
    }
    
    // Enable/Disable our own gesture recognizer.
    self.fwFullscreenPopGestureRecognizer.enabled = enabled;
    // Disable/Enable the onboard gesture recognizer.
    self.interactivePopGestureRecognizer.enabled = !enabled;
}

- (FWFullscreenPopGestureRecognizerDelegate *)fwPopGestureRecognizerDelegate
{
    FWFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    if (!delegate) {
        delegate = [[FWFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

- (UIPanGestureRecognizer *)fwFullscreenPopGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);
    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

@end

@implementation UIViewController (FWFullscreenPopGesture)

- (BOOL)fwFullscreenPopGestureDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwFullscreenPopGestureDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(fwFullscreenPopGestureDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fwFullscreenPopGestureDistance
{
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
}

- (void)setFwFullscreenPopGestureDistance:(CGFloat)distance
{
    objc_setAssociatedObject(self, @selector(fwFullscreenPopGestureDistance), @(MAX(0, distance)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
