/*!
 @header     UICollectionView+FWDynamicLayout.m
 @indexgroup FWFramework
 @brief      UICollectionView+FWDynamicLayout
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/14
 */

#import "UICollectionView+FWDynamicLayout.h"
#import <objc/runtime.h>

#pragma mark - FWDynamicLayoutSizeCache

@interface FWDynamicLayoutSizeCache : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSValue *> *sizeDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSValue *> *verticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSValue *> *horizontalDictionary;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSValue *> *headerSizeDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSValue *> *headerVerticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSValue *> *headerHorizontalDictionary;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSValue *> *footerSizeDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSValue *> *footerVerticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSValue *> *footerHorizontalDictionary;

- (void)removeAllObjects;

@end

@implementation FWDynamicLayoutSizeCache

- (void)removeAllObjects {
    if (_verticalDictionary) [_verticalDictionary removeAllObjects];
    if (_horizontalDictionary) [_horizontalDictionary removeAllObjects];
    
    if (_headerVerticalDictionary) [_headerVerticalDictionary removeAllObjects];
    if (_headerHorizontalDictionary) [_headerHorizontalDictionary removeAllObjects];
    
    if (_footerVerticalDictionary) [_footerVerticalDictionary removeAllObjects];
    if (_footerHorizontalDictionary) [_footerHorizontalDictionary removeAllObjects];
}

#pragma mark - Cell

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)sizeDictionary {
    return UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width ? self.verticalDictionary : self.horizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)verticalDictionary {
    if (!_verticalDictionary) {
        _verticalDictionary = @{}.mutableCopy;
    }
    return _verticalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)horizontalDictionary {
    if (!_horizontalDictionary) {
        _horizontalDictionary = @{}.mutableCopy;
    }
    return _horizontalDictionary;
}

#pragma mark - ReusableView

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)headerSizeDictionary {
    return UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width ? self.headerVerticalDictionary : self.headerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)headerVerticalDictionary {
    if (!_headerVerticalDictionary) {
        _headerVerticalDictionary = @{}.mutableCopy;
    }
    return _headerVerticalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)headerHorizontalDictionary {
    if (!_headerHorizontalDictionary) {
        _headerHorizontalDictionary = @{}.mutableCopy;
    }
    return _headerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)footerSizeDictionary {
    return UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width ? self.footerVerticalDictionary : self.footerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)footerVerticalDictionary {
    if (!_footerVerticalDictionary) {
        _footerVerticalDictionary = @{}.mutableCopy;
    }
    return _footerVerticalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSValue *> *)footerHorizontalDictionary {
    if (!_footerHorizontalDictionary) {
        _footerHorizontalDictionary = @{}.mutableCopy;
    }
    return _footerHorizontalDictionary;
}

@end

#pragma mark - UICollectionViewCell+FWDynamicLayout

@implementation UICollectionViewCell (FWDynamicLayout)

- (BOOL)fwMaxViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxViewFixed:(BOOL)fwMaxViewFixed {
    objc_setAssociatedObject(self, @selector(fwMaxViewFixed), @(fwMaxViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGSize)fwMaxViewPadding {
    return [objc_getAssociatedObject(self, _cmd) CGSizeValue];
}

- (void)setFwMaxViewPadding:(CGSize)fwMaxViewPadding {
    objc_setAssociatedObject(self, @selector(fwMaxViewPadding), [NSValue valueWithCGSize:fwMaxViewPadding], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fwMaxView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFwMaxView:(UIView *)fwMaxView {
    objc_setAssociatedObject(self, @selector(fwMaxView), fwMaxView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)fwViewModel {
    return objc_getAssociatedObject(self, @selector(fwViewModel));
}

- (void)setFwViewModel:(id)fwViewModel {
    if (fwViewModel != self.fwViewModel) {
        [self willChangeValueForKey:@"fwViewModel"];
        objc_setAssociatedObject(self, @selector(fwViewModel), fwViewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwViewModel"];
    }
}

+ (instancetype)fwCellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    if ([objc_getAssociatedObject(collectionView, (__bridge const void * _Nonnull)(self)) boolValue]) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [collectionView registerClass:self forCellWithReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(collectionView, (__bridge const void * _Nonnull)(self), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel
               collectionView:(UICollectionView *)collectionView {
    return [collectionView fwSizeWithCellClass:self configuration:^(__kindof UICollectionViewCell * _Nonnull cell) {
        cell.fwViewModel = viewModel;
    }];
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel
                        width:(CGFloat)width
               collectionView:(UICollectionView *)collectionView {
    return [collectionView fwSizeWithCellClass:self width:width configuration:^(__kindof UICollectionViewCell * _Nonnull cell) {
        cell.fwViewModel = viewModel;
    }];
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel
                       height:(CGFloat)height
               collectionView:(UICollectionView *)collectionView {
    return [collectionView fwSizeWithCellClass:self height:height configuration:^(__kindof UICollectionViewCell * _Nonnull cell) {
        cell.fwViewModel = viewModel;
    }];
}

@end

#pragma mark - UICollectionReusableView+FWDynamicLayout

@implementation UICollectionReusableView (FWDynamicLayout)

- (BOOL)fwMaxViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxViewFixed:(BOOL)fwMaxViewFixed {
    objc_setAssociatedObject(self, @selector(fwMaxViewFixed), @(fwMaxViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGSize)fwMaxViewPadding {
    return [objc_getAssociatedObject(self, _cmd) CGSizeValue];
}

- (void)setFwMaxViewPadding:(CGSize)fwMaxViewPadding {
    objc_setAssociatedObject(self, @selector(fwMaxViewPadding), [NSValue valueWithCGSize:fwMaxViewPadding], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fwMaxView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFwMaxView:(UIView *)fwMaxView {
    objc_setAssociatedObject(self, @selector(fwMaxView), fwMaxView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)fwViewModel {
    return objc_getAssociatedObject(self, @selector(fwViewModel));
}

- (void)setFwViewModel:(id)fwViewModel {
    if (fwViewModel != self.fwViewModel) {
        [self willChangeValueForKey:@"fwViewModel"];
        objc_setAssociatedObject(self, @selector(fwViewModel), fwViewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwViewModel"];
    }
}

+ (instancetype)fwReusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    SEL reuseSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@", reuseIdentifier, kind]);
    if ([objc_getAssociatedObject(collectionView, reuseSelector) boolValue]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [collectionView registerClass:self forSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(collectionView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel kind:(NSString *)kind collectionView:(UICollectionView *)collectionView {
    return [collectionView fwSizeWithReusableViewClass:self kind:kind configuration:^(__kindof UICollectionReusableView * _Nonnull reusableView) {
        reusableView.fwViewModel = viewModel;
    }];
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel width:(CGFloat)width kind:(NSString *)kind collectionView:(UICollectionView *)collectionView {
    return [collectionView fwSizeWithReusableViewClass:self width:width kind:kind configuration:^(__kindof UICollectionReusableView * _Nonnull reusableView) {
        reusableView.fwViewModel = viewModel;
    }];
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel height:(CGFloat)height kind:(NSString *)kind collectionView:(UICollectionView *)collectionView {
    return [collectionView fwSizeWithReusableViewClass:self height:height kind:kind configuration:^(__kindof UICollectionReusableView * _Nonnull reusableView) {
        reusableView.fwViewModel = viewModel;
    }];
}

@end

#pragma mark - UICollectionView+FWDynamicLayout

@implementation UICollectionView (FWDynamicLayout)

- (void)fwClearSizeCache
{
    [self.fwDynamicLayoutSizeCache removeAllObjects];
}

- (FWDynamicLayoutSizeCache *)fwDynamicLayoutSizeCache {
    FWDynamicLayoutSizeCache *cache = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((cache == nil), 0)) {
        cache = [[FWDynamicLayoutSizeCache alloc] init];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

#pragma mark - Cell

- (UIView *)fwDynamicViewWithCellClass:(Class)clazz {
    NSString *className = NSStringFromClass(clazz);
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[className];
    if (view) return view;
    
    UICollectionViewCell *cell = [[clazz alloc] init];
    view = [UIView new];
    [view addSubview:cell];
    dict[className] = view;
    return view;
}

- (CGSize)fwDynamicSizeWithCellClass:(Class)clazz
                       configuration:(FWCollectionCellConfigurationBlock)configuration {
    UIView *view = [self fwDynamicViewWithCellClass:clazz];
    CGFloat width = CGRectGetWidth(self.frame);
    if (width <= 0) {
        // 获取 CollectionView 宽度
        UIView *layoutView = self.superview ? self.superview : self;
        [layoutView setNeedsLayout];
        [layoutView layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UICollectionViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0, 0.0, width, 0.0);
    
    // 让外面布局 Cell
    !configuration ? : configuration(cell);

    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY = 0.0;
    if (cell.fwMaxViewFixed) {
        if (cell.fwMaxView) {
            maxY = CGRectGetMaxY(cell.fwMaxView.frame);
        } else {
            __block UIView *maxView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxView = obj;
                }
            }];
            cell.fwMaxView = maxView;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += cell.fwMaxViewPadding.height;
    return CGSizeMake(width, maxY);
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwDynamicSizeWithCellClass:clazz configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwDynamicSizeWithCellClass:clazz configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz height:(CGFloat)height configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwDynamicSizeWithCellClass:clazz configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz cacheByIndexPath:(NSIndexPath *)indexPath configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz width:(CGFloat)width cacheByIndexPath:(NSIndexPath *)indexPath configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz height:(CGFloat)height cacheByIndexPath:(NSIndexPath *)indexPath configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz cacheByKey:(id<NSCopying>)key configuration:(FWCollectionCellConfigurationBlock)configuration {
    if (key && self.fwDynamicLayoutSizeCache.sizeDictionary[key]) {
        return self.fwDynamicLayoutSizeCache.sizeDictionary[key].CGSizeValue;
    }
    CGSize cellSize = [self fwDynamicSizeWithCellClass:clazz configuration:configuration];
    if (key) {
        self.fwDynamicLayoutSizeCache.sizeDictionary[key] = [NSValue valueWithCGSize:cellSize];
    }
    return cellSize;
}

- (CGSize)fwSizeWithCellClass:(Class)clazz width:(CGFloat)width cacheByKey:(id<NSCopying>)key configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz cacheByKey:key configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz height:(CGFloat)height cacheByKey:(id<NSCopying>)key configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz cacheByKey:key configuration:configuration];
}

#pragma mark - ReusableView

- (UIView *)fwDynamicViewWithReusableViewClass:(Class)clazz
                                      selector:(SEL)selector {
    NSString *className = NSStringFromClass(clazz);
    NSMutableDictionary *dict = objc_getAssociatedObject(self, selector);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, selector, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[className];
    if (view) return view;

    UIView *headerView = [[clazz alloc] init];
    view = [UIView new];
    [view addSubview:headerView];
    dict[className] = view;
    return view;
}

- (CGSize)fwDynamicSizeWithReusableViewClass:(Class)clazz
                                        kind:(NSString *)kind
                               configuration:(FWReusableViewConfigurationBlock)configuration {
    SEL selector = NSSelectorFromString(kind);
    UIView *view = [self fwDynamicViewWithReusableViewClass:clazz selector:selector];
    CGFloat width = CGRectGetWidth(self.frame);
    if (width <= 0) {
        // 获取 CollectionView 宽度
        UIView *layoutView = self.superview ? self.superview : self;
        [layoutView setNeedsLayout];
        [layoutView layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UICollectionReusableView *reusableView = view.subviews.firstObject;
    reusableView.frame = CGRectMake(0.0, 0.0, width, 0.0);

    // 让外面布局 UICollectionReusableView
    !configuration ? : configuration(reusableView);
    
    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    UIView *contentView = reusableView;
    if (reusableView.fwMaxViewFixed) {
        if (reusableView.fwMaxView) {
            maxY = CGRectGetMaxY(reusableView.fwMaxView.frame);
        } else {
            __block UIView *maxView = nil;
            [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxView = obj;
                }
            }];
            reusableView.fwMaxView = maxView;
        }
    } else {
        [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += reusableView.fwMaxViewPadding.height;
    return CGSizeMake(width, maxY);
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwDynamicSizeWithReusableViewClass:clazz kind:kind configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwDynamicSizeWithReusableViewClass:clazz kind:kind configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwDynamicSizeWithReusableViewClass:clazz kind:kind configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwSizeWithReusableViewClass:clazz kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwSizeWithReusableViewClass:clazz kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwSizeWithReusableViewClass:clazz kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        if (key && self.fwDynamicLayoutSizeCache.headerSizeDictionary[key]) {
            return self.fwDynamicLayoutSizeCache.headerSizeDictionary[key].CGSizeValue;
        }
        CGSize viewSize = [self fwDynamicSizeWithReusableViewClass:clazz kind:kind configuration:configuration];
        if (key) {
            self.fwDynamicLayoutSizeCache.headerSizeDictionary[key] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    } else {
        if (key && self.fwDynamicLayoutSizeCache.footerSizeDictionary[key]) {
            return self.fwDynamicLayoutSizeCache.footerSizeDictionary[key].CGSizeValue;
        }
        CGSize viewSize = [self fwDynamicSizeWithReusableViewClass:clazz kind:kind configuration:configuration];
        if (key) {
            self.fwDynamicLayoutSizeCache.footerSizeDictionary[key] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    }
}

@end
