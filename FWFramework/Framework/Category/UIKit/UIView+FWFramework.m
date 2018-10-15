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

#pragma mark - Subview

- (UIView *)fwSubviewOfClass:(Class)clazz
{
    return [self fwSubviewOfBlock:^BOOL(UIView *view) {
        return [view isKindOfClass:clazz];
    }];
}

- (UIView *)fwSubviewOfBlock:(BOOL (^)(UIView *view))block
{
    if (block(self)) {
        return self;
    }
    
    /* 如果需要顺序查找所有子视图，失败后再递归查找，参考此代码即可
    for (UIView *subview in self.subviews) {
        if (block(subview)) {
            return subview;
        }
    } */
    
    for (UIView *subview in self.subviews) {
        UIView *resultView = [subview fwSubviewOfBlock:block];
        if (resultView) {
            return resultView;
        }
    }
    
    return nil;
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
