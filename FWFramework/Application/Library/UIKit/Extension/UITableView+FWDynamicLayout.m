/*!
 @header     UITableView+FWDynamicLayout.m
 @indexgroup FWFramework
 @brief      UITableView+FWDynamicLayout
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/14
 */

#import "UITableView+FWDynamicLayout.h"
#import <objc/runtime.h>

#pragma mark - FWDynamicLayoutHeightCache

@interface FWDynamicLayoutHeightCache : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *heightDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *verticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *horizontalDictionary;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerHeightDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerVerticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerHorizontalDictionary;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerHeightDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerVerticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerHorizontalDictionary;

- (void)removeAllObjects;

@end

@implementation FWDynamicLayoutHeightCache

- (void)removeAllObjects {
    if (_verticalDictionary) [_verticalDictionary removeAllObjects];
    if (_horizontalDictionary) [_horizontalDictionary removeAllObjects];
    
    if (_headerVerticalDictionary) [_headerVerticalDictionary removeAllObjects];
    if (_headerHorizontalDictionary) [_headerHorizontalDictionary removeAllObjects];
    
    if (_footerVerticalDictionary) [_footerVerticalDictionary removeAllObjects];
    if (_footerHorizontalDictionary) [_footerHorizontalDictionary removeAllObjects];
}

#pragma mark - Cell

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)heightDictionary {
    return UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width ? self.verticalDictionary : self.horizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)verticalDictionary {
    if (!_verticalDictionary) {
        _verticalDictionary = @{}.mutableCopy;
    }
    return _verticalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)horizontalDictionary {
    if (!_horizontalDictionary) {
        _horizontalDictionary = @{}.mutableCopy;
    }
    return _horizontalDictionary;
}

#pragma mark - HeaderFooter

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)headerHeightDictionary {
    return UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width ? self.headerVerticalDictionary : self.headerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)headerVerticalDictionary {
    if (!_headerVerticalDictionary) {
        _headerVerticalDictionary = @{}.mutableCopy;
    }
    return _headerVerticalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)headerHorizontalDictionary {
    if (!_headerHorizontalDictionary) {
        _headerHorizontalDictionary = @{}.mutableCopy;
    }
    return _headerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)footerHeightDictionary {
    return UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width ? self.footerVerticalDictionary : self.footerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)footerVerticalDictionary {
    if (!_footerVerticalDictionary) {
        _footerVerticalDictionary = @{}.mutableCopy;
    }
    return _footerVerticalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)footerHorizontalDictionary {
    if (!_footerHorizontalDictionary) {
        _footerHorizontalDictionary = @{}.mutableCopy;
    }
    return _footerHorizontalDictionary;
}

@end

#pragma mark - UITableViewCell+FWDynamicLayout

@implementation UITableViewCell (FWDynamicLayout)

- (BOOL)fwMaxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxYViewFixed:(BOOL)fwMaxYViewFixed {
    objc_setAssociatedObject(self, @selector(fwMaxYViewFixed), @(fwMaxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fwMaxYViewPadding {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFwMaxYViewPadding:(CGFloat)fwMaxYViewPadding {
    objc_setAssociatedObject(self, @selector(fwMaxYViewPadding), @(fwMaxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fwMaxYView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFwMaxYView:(UIView *)fwMaxYView {
    objc_setAssociatedObject(self, @selector(fwMaxYView), fwMaxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

+ (instancetype)fwCellWithTableView:(UITableView *)tableView {
    return [self fwCellWithTableView:tableView style:UITableViewCellStyleDefault];
}

+ (instancetype)fwCellWithTableView:(UITableView *)tableView style:(UITableViewCellStyle)style {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) return cell;
    return [[self alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
}

+ (CGFloat)fwHeightWithViewModel:(id)viewModel tableView:(UITableView *)tableView {
    return [tableView fwHeightWithCellClass:self configuration:^(__kindof UITableViewCell * _Nonnull cell) {
        cell.fwViewModel = viewModel;
    }];
}

@end

#pragma mark - UITableViewHeaderFooterView+FWDynamicLayout

@implementation UITableViewHeaderFooterView (FWDynamicLayout)

- (BOOL)fwMaxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxYViewFixed:(BOOL)fwMaxYViewFixed {
    objc_setAssociatedObject(self, @selector(fwMaxYViewFixed), @(fwMaxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fwMaxYViewPadding {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFwMaxYViewPadding:(CGFloat)fwMaxYViewPadding {
    objc_setAssociatedObject(self, @selector(fwMaxYViewPadding), @(fwMaxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fwMaxYView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFwMaxYView:(UIView *)fwMaxYView {
    objc_setAssociatedObject(self, @selector(fwMaxYView), fwMaxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

+ (instancetype)fwHeaderFooterViewWithTableView:(UITableView *)tableView {
    NSString *selfClassName = NSStringFromClass(self.class);
    NSString *reuseIdentifier = [selfClassName stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    if ([objc_getAssociatedObject(tableView, (__bridge const void * _Nonnull)(self)) boolValue]) {
        return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    }
    [tableView registerClass:self forHeaderFooterViewReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, (__bridge const void * _Nonnull)(self), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
}

+ (CGFloat)fwHeightWithViewModel:(id)viewModel type:(FWHeaderFooterViewType)type tableView:(UITableView *)tableView {
    return [tableView fwHeightWithHeaderFooterViewClass:self type:type configuration:^(__kindof UITableViewHeaderFooterView * _Nonnull headerFooterView) {
        headerFooterView.fwViewModel = viewModel;
    }];
}

@end

#pragma mark - UITableView+FWDynamicLayout

@implementation UITableView (FWDynamicLayout)

- (void)fwClearHeightCache
{
    [self.fwDynamicLayoutHeightCache removeAllObjects];
}

- (FWDynamicLayoutHeightCache *)fwDynamicLayoutHeightCache {
    FWDynamicLayoutHeightCache *cache = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((cache == nil), 0)) {
        cache = [[FWDynamicLayoutHeightCache alloc] init];
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
    
    // 这里使用默认的 UITableViewCellStyleDefault 类型。如果需要自定义高度，通常都是使用的此类型, 暂时不考虑其他
    UITableViewCell *cell = [[clazz alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    view = [UIView new];
    [view addSubview:cell];
    dict[className] = view;
    return view;
}

- (CGFloat)fwDynamicHeightWithCellClass:(Class)clazz
                          configuration:(FWCellConfigurationBlock)configuration {
    UIView *view = [self fwDynamicViewWithCellClass:clazz];
    CGFloat width = CGRectGetWidth(self.frame);
    if (width <= 0) {
        // 获取 TableView 宽度
        UIView *layoutView = self.superview ? self.superview : self;
        [layoutView setNeedsLayout];
        [layoutView layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0, 0.0, width, 0.0);
    
    // 让外面布局 Cell
    !configuration ? : configuration(cell);

    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY = 0.0;
    if (cell.fwMaxYViewFixed) {
        if (cell.fwMaxYView) {
            maxY = CGRectGetMaxY(cell.fwMaxYView.frame);
        } else {
            __block UIView *maxXView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxXView = obj;
                }
            }];
            cell.fwMaxYView = maxXView;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += cell.fwMaxYViewPadding;
    return maxY;
}

- (CGFloat)fwHeightWithCellClass:(Class)clazz
                   configuration:(FWCellConfigurationBlock)configuration {
    return [self fwDynamicHeightWithCellClass:clazz configuration:configuration];
}

- (CGFloat)fwHeightWithCellClass:(Class)clazz
                cacheByIndexPath:(NSIndexPath *)indexPath
                   configuration:(FWCellConfigurationBlock)configuration {
    return [self fwHeightWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGFloat)fwHeightWithCellClass:(Class)clazz
                      cacheByKey:(id<NSCopying>)key
                   configuration:(FWCellConfigurationBlock)configuration {
    if (key && self.fwDynamicLayoutHeightCache.heightDictionary[key]) {
        return self.fwDynamicLayoutHeightCache.heightDictionary[key].doubleValue;
    }
    CGFloat cellHeight = [self fwDynamicHeightWithCellClass:clazz configuration:configuration];
    if (key) {
        self.fwDynamicLayoutHeightCache.heightDictionary[key] = @(cellHeight);
    }
    return cellHeight;
}

#pragma mark - HeaderFooterView

- (UIView *)fwDynamicViewWithHeaderFooterViewClass:(Class)clazz
                                          selector:(SEL)selector {
    NSString *className = NSStringFromClass(clazz);
    NSMutableDictionary *dict = objc_getAssociatedObject(self, selector);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, selector, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[className];
    if (view) return view;

    UIView *headerView = [[clazz alloc] initWithReuseIdentifier:nil];
    view = [UIView new];
    [view addSubview:headerView];
    dict[className] = view;
    return view;
}

- (CGFloat)fwDynamicHeightWithHeaderFooterViewClass:(Class)clazz
                                           selector:(SEL)selector
                                      configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    UIView *view = [self fwDynamicViewWithHeaderFooterViewClass:clazz selector:selector];
    CGFloat width = CGRectGetWidth(self.frame);
    if (width <= 0) {
        // 获取 TableView 宽度
        UIView *layoutView = self.superview ? self.superview : self;
        [layoutView setNeedsLayout];
        [layoutView layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewHeaderFooterView *headerFooterView = view.subviews.firstObject;
    headerFooterView.frame = CGRectMake(0.0, 0.0, width, 0.0);

    // 让外面布局 UITableViewHeaderFooterView
    !configuration ? : configuration(headerFooterView);
    
    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    UIView *contentView = headerFooterView.contentView.subviews.count ? headerFooterView.contentView : headerFooterView;

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    if (headerFooterView.fwMaxYViewFixed) {
        if (headerFooterView.fwMaxYView) {
            maxY = CGRectGetMaxY(headerFooterView.fwMaxYView.frame);
        } else {
            __block UIView *maxXView = nil;
            [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxXView = obj;
                }
            }];
            headerFooterView.fwMaxYView = maxXView;
        }
    } else {
        [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += headerFooterView.fwMaxYViewPadding;
    return maxY;
}

- (CGFloat)fwDynamicHeightWithHeaderViewClass:(Class)clazz
                                configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fwDynamicHeightWithHeaderFooterViewClass:clazz selector:_cmd configuration:configuration];
}

- (CGFloat)fwDynamicHeightWithFooterViewClass:(Class)clazz
                                configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fwDynamicHeightWithHeaderFooterViewClass:clazz selector:_cmd configuration:configuration];
}

- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                        type:(FWHeaderFooterViewType)type
                               configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    if (type == FWHeaderFooterViewTypeHeader) {
        return [self fwDynamicHeightWithHeaderViewClass:clazz configuration:configuration];
    } else {
        return [self fwDynamicHeightWithFooterViewClass:clazz configuration:configuration];
    }
}

- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                        type:(FWHeaderFooterViewType)type
                              cacheBySection:(NSInteger)section
                               configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fwHeightWithHeaderFooterViewClass:clazz type:type cacheByKey:@(section) configuration:configuration];
}

- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                        type:(FWHeaderFooterViewType)type
                                  cacheByKey:(id<NSCopying>)key
                               configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    if (type == FWHeaderFooterViewTypeHeader) {
        if (key && self.fwDynamicLayoutHeightCache.headerHeightDictionary[key]) {
            return self.fwDynamicLayoutHeightCache.headerHeightDictionary[key].doubleValue;
        }
        CGFloat cellHeight = [self fwDynamicHeightWithHeaderViewClass:clazz configuration:configuration];
        if (key) {
            self.fwDynamicLayoutHeightCache.headerHeightDictionary[key] = @(cellHeight);
        }
        return cellHeight;
    } else {
        if (key && self.fwDynamicLayoutHeightCache.footerHeightDictionary[key]) {
            return self.fwDynamicLayoutHeightCache.footerHeightDictionary[key].doubleValue;
        }
        CGFloat cellHeight = [self fwDynamicHeightWithFooterViewClass:clazz configuration:configuration];
        if (key) {
            self.fwDynamicLayoutHeightCache.footerHeightDictionary[key] = @(cellHeight);
        }
        return cellHeight;
    }
}

@end
