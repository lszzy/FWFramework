/*!
 @header     UIView+FWStatistical.m
 @indexgroup FWFramework
 @brief      UIView+FWStatistical
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/1/16
 */

#import "UIView+FWStatistical.h"
#import "UIView+FWBlock.h"
#import "FWAspect.h"
#import <objc/runtime.h>

#pragma mark - FWStatistical

NSString *const FWStatisticalEventTriggeredNotification = @"FWStatisticalEventTriggeredNotification";

@interface FWStatisticalObject ()

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSDictionary *userInfo;

@property (nonatomic, weak, nullable) __kindof UIView *view;
@property (nonatomic, strong, nullable) NSIndexPath *indexPath;

@end

@implementation FWStatisticalObject

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name userInfo:nil];
}

- (instancetype)initWithName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _userInfo = [userInfo copy];
    }
    return self;
}

@end

#pragma mark - UIView+FWStatistical

@implementation UIView (FWStatistical)

- (FWStatisticalObject *)fwStatisticalClick
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalClick));
}

- (void)setFwStatisticalClick:(FWStatisticalObject *)fwStatisticalClick
{
    if (!self.fwStatisticalClick && !self.fwStatisticalClickBlock) {
        [self fwStatisticalClickRegister];
    }
    
    objc_setAssociatedObject(self, @selector(fwStatisticalClick), fwStatisticalClick, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWStatisticalBlock)fwStatisticalClickBlock
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalClickBlock));
}

- (void)setFwStatisticalClickBlock:(FWStatisticalBlock)fwStatisticalClickBlock
{
    if (!self.fwStatisticalClick && !self.fwStatisticalClickBlock) {
        [self fwStatisticalClickRegister];
    }
    
    objc_setAssociatedObject(self, @selector(fwStatisticalClickBlock), fwStatisticalClickBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - Protect

- (void)fwStatisticalClickRegister
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [gesture fwAddBlock:^(UIGestureRecognizer *sender) {
                [sender.view fwStatisticalClickHandler:nil];
            }];
        }
    }
}

- (void)fwStatisticalClickHandler:(NSIndexPath *)indexPath
{
    FWStatisticalObject *object = self.fwStatisticalClick ?: [FWStatisticalObject new];
    object.view = self;
    object.indexPath = indexPath;
    if (self.fwStatisticalClickBlock) {
        self.fwStatisticalClickBlock(object);
    }
    if (self.fwStatisticalClick) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

@end

@implementation UIControl (FWStatistical)

- (FWStatisticalObject *)fwStatisticalChanged
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalChanged));
}

- (void)setFwStatisticalChanged:(FWStatisticalObject *)fwStatisticalChanged
{
    if (!self.fwStatisticalChanged && !self.fwStatisticalChangedBlock) {
        [self fwStatisticalChangedRegister];
    }
    
    objc_setAssociatedObject(self, @selector(fwStatisticalChanged), fwStatisticalChanged, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWStatisticalBlock)fwStatisticalChangedBlock
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalChangedBlock));
}

- (void)setFwStatisticalChangedBlock:(FWStatisticalBlock)fwStatisticalChangedBlock
{
    if (!self.fwStatisticalChanged && !self.fwStatisticalChangedBlock) {
        [self fwStatisticalChangedRegister];
    }
    
    objc_setAssociatedObject(self, @selector(fwStatisticalChangedBlock), fwStatisticalChangedBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - Protect

- (void)fwStatisticalClickRegister
{
    [self fwAddBlock:^(UIButton *sender) {
        [sender fwStatisticalClickHandler:nil];
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)fwStatisticalChangedRegister
{
    [self fwAddBlock:^(UIButton *sender) {
        [sender fwStatisticalChangedHandler:nil];
    } forControlEvents:UIControlEventValueChanged];
}

- (void)fwStatisticalChangedHandler:(NSIndexPath *)indexPath
{
    FWStatisticalObject *object = self.fwStatisticalChanged ?: [FWStatisticalObject new];
    object.view = self;
    object.indexPath = indexPath;
    if (self.fwStatisticalChangedBlock) {
        self.fwStatisticalChangedBlock(object);
    }
    if (self.fwStatisticalChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

@end

@implementation UITableView (FWStatistical)

- (void)fwStatisticalClickRegister
{
    [(NSObject *)self.delegate fwHookSelector:@selector(tableView:didSelectRowAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UITableView *tableView, NSIndexPath *indexPath){
        [tableView fwStatisticalClickHandler:indexPath];
    } options:FWAspectPositionAfter error:NULL];
}

@end

@implementation UICollectionView (FWStatistical)

- (void)fwStatisticalClickRegister
{
    [(NSObject *)self.delegate fwHookSelector:@selector(collectionView:didSelectItemAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UICollectionView *collectionView, NSIndexPath *indexPath){
        [collectionView fwStatisticalClickHandler:indexPath];
    } options:FWAspectPositionAfter error:NULL];
}

@end
