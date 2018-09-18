/*!
 @header     UIView+FWFramework.m
 @indexgroup FWFramework
 @brief      UIView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UIView+FWFramework.h"

@implementation UIView (FWFramework)

#pragma mark - ViewController

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

- (UIViewController *)fwTopMostController
{
    NSMutableArray *topControllers = [NSMutableArray array];
    
    UIViewController *topController = self.window.rootViewController;
    if (topController) {
        [topControllers addObject:topController];
    }
    
    while ([topController presentedViewController]) {
        topController = [topController presentedViewController];
        [topControllers addObject:topController];
    }
    
    UIResponder *matchController = [self fwViewController];
    while (matchController != nil && [topControllers containsObject:matchController] == NO) {
        do {
            matchController = [matchController nextResponder];
        } while (matchController != nil && [matchController isKindOfClass:[UIViewController class]] == NO);
    }
    
    return (UIViewController *)matchController;
}

@end
