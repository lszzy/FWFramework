/*!
 @header     UIScrollView+FWEmptyView.m
 @indexgroup FWFramework
 @brief      UIScrollView+FWEmptyView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "UIScrollView+FWEmptyView.h"
#import "FWAutoLayout.h"
#import <objc/runtime.h>

#pragma mark - FWEmptyViewWeakTarget

@interface FWEmptyViewWeakTarget : NSObject

@property (nonatomic, readonly, weak) id weakObject;

- (instancetype)initWithWeakObject:(id)object;

@end

@implementation FWEmptyViewWeakTarget

- (instancetype)initWithWeakObject:(id)object
{
    self = [super init];
    if (self) {
        _weakObject = object;
    }
    return self;
}

@end

#pragma mark - FWEmptyContentView

@interface FWEmptyContentView : UIView

@property (nonatomic, strong) UIView *contentView;

@end

@implementation FWEmptyContentView

- (instancetype)init
{
    self =  [super init];
    if (self) {
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview
{
    CGRect superviewBounds = self.superview.bounds;
    self.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(superviewBounds), CGRectGetHeight(superviewBounds));
    self.contentView.alpha = 1.0;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.userInteractionEnabled = YES;
        _contentView.alpha = 0;
    }
    return _contentView;
}

@end


#pragma mark - UIScrollView+FWEmptyView

static char const * const kEmptyViewDataSource = "emptyViewDataSource";
static char const * const kEmptyViewDelegate   = "emptyViewDelegate";
static char const * const kEmptyContentView    = "emptyContentView";

static NSString * const kEmptyViewImageAnimationKey = @"emptyViewImageAnimation";

@interface UIScrollView () <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) FWEmptyContentView *fwEmptyContentView;

@end

@implementation UIScrollView (FWEmptyView)

- (id<FWEmptyViewDataSource>)fwEmptyViewDataSource
{
    FWEmptyViewWeakTarget *target = objc_getAssociatedObject(self, kEmptyViewDataSource);
    return target.weakObject;
}

- (id<FWEmptyViewDelegate>)fwEmptyViewDelegate
{
    FWEmptyViewWeakTarget *target = objc_getAssociatedObject(self, kEmptyViewDelegate);
    return target.weakObject;
}

- (BOOL)fwEmptyViewVisible
{
    UIView *view = objc_getAssociatedObject(self, kEmptyContentView);
    return view ? !view.hidden : NO;
}

- (FWEmptyContentView *)fwEmptyContentView
{
    FWEmptyContentView *view = objc_getAssociatedObject(self, kEmptyContentView);
    if (!view) {
        view = [FWEmptyContentView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.userInteractionEnabled = YES;
        view.hidden = YES;
        
        [self setFwEmptyContentView:view];
    }
    return view;
}

- (BOOL)fwEmptyCanDisplay
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource conformsToProtocol:@protocol(FWEmptyViewDataSource)]) {
        if ([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]] || [self isKindOfClass:[UIScrollView class]]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)fwEmptyItemsCount
{
    NSInteger items = 0;
    
    // UIScollView doesn't respond to 'dataSource' so let's exit
    if (![self respondsToSelector:@selector(dataSource)]) {
        return items;
    }
    
    // UITableView support
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;
        id <UITableViewDataSource> dataSource = tableView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource tableView:tableView numberOfRowsInSection:section];
            }
        }
    // UICollectionView support
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        id <UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource collectionView:collectionView numberOfItemsInSection:section];
            }
        }
    }
    
    return items;
}


#pragma mark - Data Source Getters

- (BOOL)fwEmptyShouldDisplay
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldDisplay:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldDisplay:self];
    }
    return YES;
}

- (BOOL)fwEmptyShouldBeForcedToDisplay
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldBeForcedToDisplay:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldBeForcedToDisplay:self];
    }
    return NO;
}

- (BOOL)fwEmptyIsScrollAllowed
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldAllowScroll:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldAllowScroll:self];
    }
    return NO;
}

- (void)setFwEmptyViewDataSource:(id<FWEmptyViewDataSource>)dataSource
{
    if (!dataSource || ![self fwEmptyCanDisplay]) {
        [self fwEmptyInvalidate];
    }
    
    objc_setAssociatedObject(self, kEmptyViewDataSource, [[FWEmptyViewWeakTarget alloc] initWithWeakObject:dataSource], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // We add method sizzling for injecting -fw_reloadData implementation to the native -reloadData implementation
    [self fwEmptySwizzleIfPossible:@selector(reloadData)];
    
    // Exclusively for UITableView, we also inject -fw_reloadData to -endUpdates
    if ([self isKindOfClass:[UITableView class]]) {
        [self fwEmptySwizzleIfPossible:@selector(endUpdates)];
    }
}

- (void)setFwEmptyViewDelegate:(id<FWEmptyViewDelegate>)delegate
{
    if (!delegate) {
        [self fwEmptyInvalidate];
    }
    
    objc_setAssociatedObject(self, kEmptyViewDelegate, [[FWEmptyViewWeakTarget alloc] initWithWeakObject:delegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFwEmptyContentView:(FWEmptyContentView *)view
{
    objc_setAssociatedObject(self, kEmptyContentView, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwReloadEmptyView
{
    [self fwEmptyReloadEmptyView];
}

- (void)fwEmptyReloadEmptyView
{
    if (![self fwEmptyCanDisplay]) {
        return;
    }
    
    if (([self fwEmptyShouldDisplay] && [self fwEmptyItemsCount] == 0) || [self fwEmptyShouldBeForcedToDisplay]) {
        FWEmptyContentView *view = self.fwEmptyContentView;
        
        if (!view.superview) {
            // Send the view all the way to the back, in case a header and/or footer is present, as well as for sectionHeaders or any other content
            if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && self.subviews.count > 1) {
                [self insertSubview:view atIndex:0];
            }
            else {
                [self addSubview:view];
            }
        }
        
        view.backgroundColor = [UIColor clearColor];
        
        if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwShowEmptyView:scrollView:)]) {
            [self.fwEmptyViewDataSource fwShowEmptyView:view scrollView:self];
        }
        
        view.hidden = NO;
        view.clipsToBounds = YES;
        
        [UIView performWithoutAnimation:^{
            [view layoutIfNeeded];
        }];
        
        // Configure scroll permission
        self.scrollEnabled = [self fwEmptyIsScrollAllowed];
    } else if (self.fwEmptyViewVisible) {
        [self fwEmptyInvalidate];
    }
}

- (void)fwEmptyInvalidate
{
    if (self.fwEmptyContentView) {
        [self.fwEmptyContentView removeFromSuperview];
        
        [self setFwEmptyContentView:nil];
    }
    
    self.scrollEnabled = YES;
}

static NSMutableDictionary *fwEmpty_impLookupTable;
static NSString *const FWEmptySwizzleInfoPointerKey = @"pointer";
static NSString *const FWEmptySwizzleInfoOwnerKey = @"owner";
static NSString *const FWEmptySwizzleInfoSelectorKey = @"selector";

// Based on Bryce Buchanan's swizzling technique http://blog.newrelic.com/2014/04/16/right-way-to-swizzle/
// And Juzzin's ideas https://github.com/juzzin/JUSEmptyViewController

void fwEmpty_original_implementation(id self, SEL _cmd)
{
    // Fetch original implementation from lookup table
    Class baseClass = fwEmpty_baseClassToSwizzleForTarget(self);
    NSString *key = fwEmpty_implementationKey(baseClass, _cmd);
    
    NSDictionary *swizzleInfo = [fwEmpty_impLookupTable objectForKey:key];
    NSValue *impValue = [swizzleInfo valueForKey:FWEmptySwizzleInfoPointerKey];
    
    IMP impPointer = [impValue pointerValue];
    
    // We then inject the additional implementation for reloading the empty dataset
    // Doing it before calling the original implementation does update the 'isEmptyDataSetVisible' flag on time.
    [self fwEmptyReloadEmptyView];
    
    // If found, call original implementation
    if (impPointer) {
        ((void(*)(id,SEL))impPointer)(self,_cmd);
    }
}

NSString *fwEmpty_implementationKey(Class class, SEL selector)
{
    if (!class || !selector) {
        return nil;
    }
    
    NSString *className = NSStringFromClass([class class]);
    
    NSString *selectorName = NSStringFromSelector(selector);
    return [NSString stringWithFormat:@"%@_%@",className,selectorName];
}

Class fwEmpty_baseClassToSwizzleForTarget(id target)
{
    if ([target isKindOfClass:[UITableView class]]) {
        return [UITableView class];
    }
    else if ([target isKindOfClass:[UICollectionView class]]) {
        return [UICollectionView class];
    }
    else if ([target isKindOfClass:[UIScrollView class]]) {
        return [UIScrollView class];
    }
    
    return nil;
}

- (void)fwEmptySwizzleIfPossible:(SEL)selector
{
    // Check if the target responds to selector
    if (![self respondsToSelector:selector]) {
        return;
    }
    
    // Create the lookup table
    if (!fwEmpty_impLookupTable) {
        fwEmpty_impLookupTable = [[NSMutableDictionary alloc] initWithCapacity:3]; // 3 represent the supported base classes
    }
    
    // We make sure that setImplementation is called once per class kind, UITableView or UICollectionView.
    for (NSDictionary *info in [fwEmpty_impLookupTable allValues]) {
        Class class = [info objectForKey:FWEmptySwizzleInfoOwnerKey];
        NSString *selectorName = [info objectForKey:FWEmptySwizzleInfoSelectorKey];
        
        if ([selectorName isEqualToString:NSStringFromSelector(selector)]) {
            if ([self isKindOfClass:class]) {
                return;
            }
        }
    }
    
    Class baseClass = fwEmpty_baseClassToSwizzleForTarget(self);
    NSString *key = fwEmpty_implementationKey(baseClass, selector);
    NSValue *impValue = [[fwEmpty_impLookupTable objectForKey:key] valueForKey:FWEmptySwizzleInfoPointerKey];
    
    // If the implementation for this class already exist, skip!!
    if (impValue || !key || !baseClass) {
        return;
    }
    
    // Swizzle by injecting additional implementation
    Method method = class_getInstanceMethod(baseClass, selector);
    IMP fwEmpty_newImplementation = method_setImplementation(method, (IMP)fwEmpty_original_implementation);
    
    // Store the new implementation in the lookup table
    NSDictionary *swizzledInfo = @{FWEmptySwizzleInfoOwnerKey: baseClass,
                                   FWEmptySwizzleInfoSelectorKey: NSStringFromSelector(selector),
                                   FWEmptySwizzleInfoPointerKey: [NSValue valueWithPointer:fwEmpty_newImplementation]};
    
    [fwEmpty_impLookupTable setObject:swizzledInfo forKey:key];
}

@end
