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
    objc_setAssociatedObject(self, @selector(fwStatisticalClick), fwStatisticalClick, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self fwStatisticalClickWithBlock:^(FWStatisticalObject *object) {
        object.name = fwStatisticalClick.name;
        object.userInfo = fwStatisticalClick.userInfo;
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }];
}

- (void)fwStatisticalClickWithBlock:(FWStatisticalBlock)block
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [gesture fwAddBlock:^(UIGestureRecognizer *sender) {
                FWStatisticalObject *object = [FWStatisticalObject new];
                object.view = sender.view;
                block(object);
            }];
        }
    }
}

@end

@implementation UIControl (FWStatistical)

- (void)fwStatisticalClickWithBlock:(FWStatisticalBlock)block
{
    [self fwAddBlock:^(UIButton *sender) {
        FWStatisticalObject *object = [FWStatisticalObject new];
        object.view = sender;
        block(object);
    } forControlEvents:UIControlEventTouchUpInside];
}

- (FWStatisticalObject *)fwStatisticalChanged
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalChanged));
}

- (void)setFwStatisticalChanged:(FWStatisticalObject *)fwStatisticalChanged
{
    objc_setAssociatedObject(self, @selector(fwStatisticalChanged), fwStatisticalChanged, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self fwStatisticalChangedWithBlock:^(FWStatisticalObject *object) {
        object.name = fwStatisticalChanged.name;
        object.userInfo = fwStatisticalChanged.userInfo;
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }];
}

- (void)fwStatisticalChangedWithBlock:(FWStatisticalBlock)block
{
    [self fwAddBlock:^(UIButton *sender) {
        FWStatisticalObject *object = [FWStatisticalObject new];
        object.view = sender;
        block(object);
    } forControlEvents:UIControlEventValueChanged];
}

@end

@implementation UITableView (FWStatistical)

- (void)fwStatisticalClickWithBlock:(FWStatisticalBlock)block
{
    [(NSObject *)self.delegate fwHookSelector:@selector(tableView:didSelectRowAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UITableView *tableView, NSIndexPath *indexPath){
        FWStatisticalObject *object = [FWStatisticalObject new];
        object.view = tableView;
        object.indexPath = indexPath;
        block(object);
    } options:FWAspectPositionAfter error:NULL];
}

@end

@implementation UICollectionView (FWStatistical)

- (void)fwStatisticalClickWithBlock:(FWStatisticalBlock)block
{
    [(NSObject *)self.delegate fwHookSelector:@selector(collectionView:didSelectItemAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UICollectionView *collectionView, NSIndexPath *indexPath){
        FWStatisticalObject *object = [FWStatisticalObject new];
        object.view = collectionView;
        object.indexPath = indexPath;
        block(object);
    } options:FWAspectPositionAfter error:NULL];
}

@end
