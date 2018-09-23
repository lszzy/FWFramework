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

#pragma mark - Snapshot

- (UIImage *)fwSnapshotImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    // iOS7+：是否更新屏幕后再截图，效率高
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    // iOS6+：截取当前状态，效率低
    // [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}

- (NSData *)fwSnapshotPdf
{
    CGRect bounds = self.bounds;
    NSMutableData *data = [NSMutableData data];
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)data);
    CGContextRef context = CGPDFContextCreate(consumer, &bounds, NULL);
    CGDataConsumerRelease(consumer);
    if (!context) return nil;
    CGPDFContextBeginPage(context, NULL);
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    [self.layer renderInContext:context];
    CGPDFContextEndPage(context);
    CGPDFContextClose(context);
    CGContextRelease(context);
    return data;
}

@end
