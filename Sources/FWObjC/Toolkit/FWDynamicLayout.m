//
//  FWDynamicLayout.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWDynamicLayout.h"
#import "FWAutoLayout.h"
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

- (BOOL)fw_maxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self, @selector(fw_maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_maxYViewPadding {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFw_maxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self, @selector(fw_maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_maxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fw_maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fw_maxYView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFw_maxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self, @selector(fw_maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)fw_cellWithTableView:(UITableView *)tableView {
    return [self fw_cellWithTableView:tableView style:UITableViewCellStyleDefault];
}

+ (instancetype)fw_cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style {
    return [self fw_cellWithTableView:tableView style:style reuseIdentifier:nil];
}

+ (instancetype)fw_cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style
                                reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) return cell;
    return [[self alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
}

+ (CGFloat)fw_heightWithTableView:(UITableView *)tableView
                 configuration:(FWCellConfigurationBlock)configuration {
    return [tableView fw_heightWithCellClass:self configuration:configuration];
}

@end

#pragma mark - UITableViewHeaderFooterView+FWDynamicLayout

@implementation UITableViewHeaderFooterView (FWDynamicLayout)

- (BOOL)fw_maxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self, @selector(fw_maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_maxYViewPadding {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFw_maxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self, @selector(fw_maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_maxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fw_maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fw_maxYView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFw_maxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self, @selector(fw_maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)fw_headerFooterViewWithTableView:(UITableView *)tableView {
    return [self fw_headerFooterViewWithTableView:tableView reuseIdentifier:nil];
}

+ (instancetype)fw_headerFooterViewWithTableView:(UITableView *)tableView reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    SEL reuseSelector = NSSelectorFromString(reuseIdentifier);
    if ([objc_getAssociatedObject(tableView, reuseSelector) boolValue]) {
        return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    }
    [tableView registerClass:self forHeaderFooterViewReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
}

+ (CGFloat)fw_heightWithTableView:(UITableView *)tableView
                          type:(FWHeaderFooterViewType)type
                 configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [tableView fw_heightWithHeaderFooterViewClass:self type:type configuration:configuration];
}

@end

#pragma mark - UITableView+FWDynamicLayout

@implementation UITableView (FWDynamicLayout)

#pragma mark - Cache

- (void)fw_clearHeightCache
{
    [self.fw_dynamicLayoutHeightCache removeAllObjects];
}

- (void)fw_setCellHeightCache:(CGFloat)height forIndexPath:(NSIndexPath *)indexPath
{
    [self fw_setCellHeightCache:height forKey:indexPath];
}

- (void)fw_setCellHeightCache:(CGFloat)height forKey:(id<NSCopying>)key
{
    self.fw_dynamicLayoutHeightCache.heightDictionary[key] = height > 0 ? @(height) : nil;
}

- (CGFloat)fw_cellHeightCacheForIndexPath:(NSIndexPath *)indexPath
{
    return [self fw_cellHeightCacheForKey:indexPath];
}

- (CGFloat)fw_cellHeightCacheForKey:(id<NSCopying>)key
{
    NSNumber *height = self.fw_dynamicLayoutHeightCache.heightDictionary[key];
    return height ? height.doubleValue : UITableViewAutomaticDimension;
}

- (void)fw_setHeaderFooterHeightCache:(CGFloat)height type:(FWHeaderFooterViewType)type forSection:(NSInteger)section
{
    [self fw_setHeaderFooterHeightCache:height type:type forKey:@(section)];
}

- (void)fw_setHeaderFooterHeightCache:(CGFloat)height type:(FWHeaderFooterViewType)type forKey:(id<NSCopying>)key
{
    if (type == FWHeaderFooterViewTypeHeader) {
        self.fw_dynamicLayoutHeightCache.headerHeightDictionary[key] = height > 0 ? @(height) : nil;
    } else {
        self.fw_dynamicLayoutHeightCache.footerHeightDictionary[key] = height > 0 ? @(height) : nil;
    }
}

- (CGFloat)fw_headerFooterHeightCache:(FWHeaderFooterViewType)type forSection:(NSInteger)section
{
    return [self fw_headerFooterHeightCache:type forKey:@(section)];
}

- (CGFloat)fw_headerFooterHeightCache:(FWHeaderFooterViewType)type forKey:(id<NSCopying>)key
{
    if (type == FWHeaderFooterViewTypeHeader) {
        NSNumber *height = self.fw_dynamicLayoutHeightCache.headerHeightDictionary[key];
        return height ? height.doubleValue : UITableViewAutomaticDimension;
    } else {
        NSNumber *height = self.fw_dynamicLayoutHeightCache.footerHeightDictionary[key];
        return height ? height.doubleValue : UITableViewAutomaticDimension;
    }
}

- (FWDynamicLayoutHeightCache *)fw_dynamicLayoutHeightCache {
    FWDynamicLayoutHeightCache *cache = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((cache == nil), 0)) {
        cache = [[FWDynamicLayoutHeightCache alloc] init];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

#pragma mark - Cell

- (UIView *)fw_dynamicViewWithCellClass:(Class)clazz {
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

- (CGFloat)fw_dynamicHeightWithCellClass:(Class)clazz
                        configuration:(FWCellConfigurationBlock)configuration
                          shouldCache:(BOOL *)shouldCache {
    UIView *view = [self fw_dynamicViewWithCellClass:clazz];
    CGFloat width = CGRectGetWidth(self.frame);
    if (width <= 0 && self.superview) {
        // 获取 TableView 宽度
        [self.superview setNeedsLayout];
        [self.superview layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }
    if (shouldCache) *shouldCache = width > 0;

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0, 0.0, width, 0.0);
    
    // 让外面布局 Cell
    [cell prepareForReuse];
    !configuration ? : configuration(cell);
    
    // 自动撑开方式
    if (cell.fw_maxYViewExpanded) {
        return [cell fw_layoutHeightWithWidth:width];
    }

    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY = 0.0;
    if (cell.fw_maxYViewFixed) {
        if (cell.fw_maxYView) {
            maxY = CGRectGetMaxY(cell.fw_maxYView.frame);
        } else {
            __block UIView *maxYView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            cell.fw_maxYView = maxYView;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += cell.fw_maxYViewPadding;
    return maxY;
}

- (CGFloat)fw_heightWithCellClass:(Class)clazz
                 configuration:(FWCellConfigurationBlock)configuration {
    return [self fw_dynamicHeightWithCellClass:clazz configuration:configuration shouldCache:NULL];
}

- (CGFloat)fw_heightWithCellClass:(Class)clazz
              cacheByIndexPath:(NSIndexPath *)indexPath
                 configuration:(FWCellConfigurationBlock)configuration {
    return [self fw_heightWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGFloat)fw_heightWithCellClass:(Class)clazz
                    cacheByKey:(id<NSCopying>)key
                 configuration:(FWCellConfigurationBlock)configuration {
    if (key && self.fw_dynamicLayoutHeightCache.heightDictionary[key]) {
        return self.fw_dynamicLayoutHeightCache.heightDictionary[key].doubleValue;
    }
    BOOL shouldCache = YES;
    CGFloat cellHeight = [self fw_dynamicHeightWithCellClass:clazz configuration:configuration shouldCache:&shouldCache];
    if (key && shouldCache) {
        self.fw_dynamicLayoutHeightCache.heightDictionary[key] = @(cellHeight);
    }
    return cellHeight;
}

#pragma mark - HeaderFooterView

- (UIView *)fw_dynamicViewWithHeaderFooterViewClass:(Class)clazz
                                      identifier:(NSString *)identifier {
    NSString *classIdentifier = [NSStringFromClass(clazz) stringByAppendingString:identifier];
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[classIdentifier];
    if (view) return view;

    UIView *headerView = [[clazz alloc] initWithReuseIdentifier:nil];
    view = [UIView new];
    [view addSubview:headerView];
    dict[classIdentifier] = view;
    return view;
}

- (CGFloat)fw_dynamicHeightWithHeaderFooterViewClass:(Class)clazz
                                             type:(FWHeaderFooterViewType)type
                                    configuration:(FWHeaderFooterViewConfigurationBlock)configuration
                                      shouldCache:(BOOL *)shouldCache {
    NSString *identifier = [NSString stringWithFormat:@"%@", @(type)];
    UIView *view = [self fw_dynamicViewWithHeaderFooterViewClass:clazz identifier:identifier];
    CGFloat width = CGRectGetWidth(self.frame);
    if (width <= 0 && self.superview) {
        // 获取 TableView 宽度
        [self.superview setNeedsLayout];
        [self.superview layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }
    if (shouldCache) *shouldCache = width > 0;

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewHeaderFooterView *headerFooterView = view.subviews.firstObject;
    headerFooterView.frame = CGRectMake(0.0, 0.0, width, 0.0);

    // 让外面布局 UITableViewHeaderFooterView
    [headerFooterView prepareForReuse];
    !configuration ? : configuration(headerFooterView);
    
    // 自动撑开方式
    if (headerFooterView.fw_maxYViewExpanded) {
        return [headerFooterView fw_layoutHeightWithWidth:width];
    }
    
    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    UIView *contentView = headerFooterView.contentView.subviews.count ? headerFooterView.contentView : headerFooterView;
    if (headerFooterView.fw_maxYViewFixed) {
        if (headerFooterView.fw_maxYView) {
            maxY = CGRectGetMaxY(headerFooterView.fw_maxYView.frame);
        } else {
            __block UIView *maxYView = nil;
            [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            headerFooterView.fw_maxYView = maxYView;
        }
    } else {
        [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += headerFooterView.fw_maxYViewPadding;
    return maxY;
}

- (CGFloat)fw_heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                             configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fw_dynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration shouldCache:NULL];
}

- (CGFloat)fw_heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                            cacheBySection:(NSInteger)section
                             configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fw_heightWithHeaderFooterViewClass:clazz type:type cacheByKey:@(section) configuration:configuration];
}

- (CGFloat)fw_heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                                cacheByKey:(id<NSCopying>)key
                             configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    if (type == FWHeaderFooterViewTypeHeader) {
        if (key && self.fw_dynamicLayoutHeightCache.headerHeightDictionary[key]) {
            return self.fw_dynamicLayoutHeightCache.headerHeightDictionary[key].doubleValue;
        }
        BOOL shouldCache = YES;
        CGFloat viewHeight = [self fw_dynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration shouldCache:&shouldCache];
        if (key && shouldCache) {
            self.fw_dynamicLayoutHeightCache.headerHeightDictionary[key] = @(viewHeight);
        }
        return viewHeight;
    } else {
        if (key && self.fw_dynamicLayoutHeightCache.footerHeightDictionary[key]) {
            return self.fw_dynamicLayoutHeightCache.footerHeightDictionary[key].doubleValue;
        }
        BOOL shouldCache = YES;
        CGFloat viewHeight = [self fw_dynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration shouldCache:&shouldCache];
        if (key && shouldCache) {
            self.fw_dynamicLayoutHeightCache.footerHeightDictionary[key] = @(viewHeight);
        }
        return viewHeight;
    }
}

@end

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

- (BOOL)fw_maxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self, @selector(fw_maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_maxYViewPadding {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFw_maxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self, @selector(fw_maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_maxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fw_maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fw_maxYView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFw_maxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self, @selector(fw_maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)fw_cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath {
    return [self fw_cellWithCollectionView:collectionView indexPath:indexPath reuseIdentifier:nil];
}

+ (instancetype)fw_cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath
                         reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    SEL reuseSelector = NSSelectorFromString(reuseIdentifier);
    if ([objc_getAssociatedObject(collectionView, reuseSelector) boolValue]) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [collectionView registerClass:self forCellWithReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(collectionView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
}

+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                   configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [collectionView fw_sizeWithCellClass:self configuration:configuration];
}

+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                           width:(CGFloat)width
                   configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [collectionView fw_sizeWithCellClass:self width:width configuration:configuration];
}

+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                          height:(CGFloat)height
                   configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [collectionView fw_sizeWithCellClass:self height:height configuration:configuration];
}

@end

#pragma mark - UICollectionReusableView+FWDynamicLayout

@implementation UICollectionReusableView (FWDynamicLayout)

- (BOOL)fw_maxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self, @selector(fw_maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_maxYViewPadding {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFw_maxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self, @selector(fw_maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_maxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_maxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fw_maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fw_maxYView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFw_maxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self, @selector(fw_maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)fw_reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath {
    return [self fw_reusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath reuseIdentifier:nil];
}

+ (instancetype)fw_reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    SEL reuseSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@", reuseIdentifier, kind]);
    if ([objc_getAssociatedObject(collectionView, reuseSelector) boolValue]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [collectionView registerClass:self forSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(collectionView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
}

+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                            kind:(NSString *)kind
                   configuration:(FWReusableViewConfigurationBlock)configuration {
    return [collectionView fw_sizeWithReusableViewClass:self kind:kind configuration:configuration];
}

+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                           width:(CGFloat)width
                            kind:(NSString *)kind
                   configuration:(FWReusableViewConfigurationBlock)configuration {
    return [collectionView fw_sizeWithReusableViewClass:self width:width kind:kind configuration:configuration];
}

+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                          height:(CGFloat)height
                            kind:(NSString *)kind
                   configuration:(FWReusableViewConfigurationBlock)configuration {
    return [collectionView fw_sizeWithReusableViewClass:self height:height kind:kind configuration:configuration];
}

@end

#pragma mark - UICollectionView+FWDynamicLayout

@implementation UICollectionView (FWDynamicLayout)

#pragma mark - Cache

- (void)fw_clearSizeCache
{
    [self.fw_dynamicLayoutSizeCache removeAllObjects];
}

- (void)fw_setCellSizeCache:(CGSize)size forIndexPath:(NSIndexPath *)indexPath
{
    [self fw_setCellSizeCache:size forKey:indexPath];
}

- (void)fw_setCellSizeCache:(CGSize)size forKey:(id<NSCopying>)key
{
    self.fw_dynamicLayoutSizeCache.sizeDictionary[key] = (size.width > 0 && size.height > 0) ? [NSValue valueWithCGSize:size] : nil;
}

- (CGSize)fw_cellSizeCacheForIndexPath:(NSIndexPath *)indexPath
{
    return [self fw_cellSizeCacheForKey:indexPath];
}

- (CGSize)fw_cellSizeCacheForKey:(id<NSCopying>)key
{
    NSValue *value = self.fw_dynamicLayoutSizeCache.sizeDictionary[key];
    return value ? value.CGSizeValue : UICollectionViewFlowLayoutAutomaticSize;
}

- (void)fw_setReusableViewSizeCache:(CGSize)size kind:(NSString *)kind forSection:(NSInteger)section
{
    [self fw_setReusableViewSizeCache:size kind:kind forKey:@(section)];
}

- (void)fw_setReusableViewSizeCache:(CGSize)size kind:(NSString *)kind forKey:(id<NSCopying>)key
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        self.fw_dynamicLayoutSizeCache.headerSizeDictionary[key] = (size.width > 0 && size.height > 0) ? [NSValue valueWithCGSize:size] : nil;
    } else {
        self.fw_dynamicLayoutSizeCache.footerSizeDictionary[key] = (size.width > 0 && size.height > 0) ? [NSValue valueWithCGSize:size] : nil;
    }
}

- (CGSize)fw_reusableViewSizeCache:(NSString *)kind forSection:(NSInteger)section
{
    return [self fw_reusableViewSizeCache:kind forKey:@(section)];
}

- (CGSize)fw_reusableViewSizeCache:(NSString *)kind forKey:(id<NSCopying>)key
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        NSValue *value = self.fw_dynamicLayoutSizeCache.headerSizeDictionary[key];
        return value ? value.CGSizeValue : UICollectionViewFlowLayoutAutomaticSize;
    } else {
        NSValue *value = self.fw_dynamicLayoutSizeCache.footerSizeDictionary[key];
        return value ? value.CGSizeValue : UICollectionViewFlowLayoutAutomaticSize;
    }
}

- (FWDynamicLayoutSizeCache *)fw_dynamicLayoutSizeCache {
    FWDynamicLayoutSizeCache *cache = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((cache == nil), 0)) {
        cache = [[FWDynamicLayoutSizeCache alloc] init];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

#pragma mark - Cell

- (UIView *)fw_dynamicViewWithCellClass:(Class)clazz
                          identifier:(NSString *)identifier {
    NSString *classIdentifier = [NSStringFromClass(clazz) stringByAppendingString:identifier];
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[classIdentifier];
    if (view) return view;
    
    UICollectionViewCell *cell = [[clazz alloc] init];
    view = [UIView new];
    [view addSubview:cell];
    dict[classIdentifier] = view;
    return view;
}

- (CGSize)fw_dynamicSizeWithCellClass:(Class)clazz
                               width:(CGFloat)fixedWidth
                              height:(CGFloat)fixedHeight
                       configuration:(FWCollectionCellConfigurationBlock)configuration
                         shouldCache:(BOOL *)shouldCache {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@", @(fixedWidth), @(fixedHeight)];
    UIView *view = [self fw_dynamicViewWithCellClass:clazz identifier:identifier];
    CGFloat width = fixedWidth;
    CGFloat height = fixedHeight;
    if (width <= 0 && height <= 0) {
        width = CGRectGetWidth(self.frame);
        if (width <= 0 && self.superview) {
            // 获取 CollectionView 宽度
            [self.superview setNeedsLayout];
            [self.superview layoutIfNeeded];
            width = CGRectGetWidth(self.frame);
        }
    }
    if (shouldCache) *shouldCache = fixedHeight > 0 || width > 0;

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, height);
    UICollectionViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0, 0.0, width, height);
    
    // 让外面布局 Cell
    [cell prepareForReuse];
    !configuration ? : configuration(cell);
    
    // 自动撑开方式
    if (cell.fw_maxYViewExpanded) {
        if (fixedHeight > 0) {
            width = [cell fw_layoutWidthWithHeight:height];
        } else {
            height = [cell fw_layoutHeightWithWidth:width];
        }
        return CGSizeMake(width, height);
    }

    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY = 0.0;
    CGFloat (^maxYBlock)(UIView *view) = ^CGFloat(UIView *view) {
        return fixedHeight > 0 ? CGRectGetMaxX(view.frame) : CGRectGetMaxY(view.frame);
    };
    if (cell.fw_maxYViewFixed) {
        if (cell.fw_maxYView) {
            maxY = maxYBlock(cell.fw_maxYView);
        } else {
            __block UIView *maxYView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = maxYBlock(obj);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            cell.fw_maxYView = maxYView;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = maxYBlock(obj);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += cell.fw_maxYViewPadding;
    return fixedHeight > 0 ? CGSizeMake(maxY, height) : CGSizeMake(width, maxY);
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
              configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_dynamicSizeWithCellClass:clazz width:0 height:0 configuration:configuration shouldCache:NULL];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_dynamicSizeWithCellClass:clazz width:width height:0 configuration:configuration shouldCache:NULL];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
                       height:(CGFloat)height
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_dynamicSizeWithCellClass:clazz width:0 height:height configuration:configuration shouldCache:NULL];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_sizeWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_sizeWithCellClass:clazz width:width cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
                       height:(CGFloat)height
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_sizeWithCellClass:clazz height:height cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_sizeWithCellClass:clazz width:0 height:0 cacheByKey:key configuration:configuration];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_sizeWithCellClass:clazz width:width height:0 cacheByKey:key configuration:configuration];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz height:(CGFloat)height cacheByKey:(id<NSCopying>)key configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fw_sizeWithCellClass:clazz width:0 height:height cacheByKey:key configuration:configuration];
}

- (CGSize)fw_sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                       height:(CGFloat)height
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    id<NSCopying> cacheKey = key;
    if (cacheKey && (width > 0 || height > 0)) {
        cacheKey = [NSString stringWithFormat:@"%@-%@-%@", cacheKey, @(width), @(height)];
    }
    
    if (cacheKey && self.fw_dynamicLayoutSizeCache.sizeDictionary[cacheKey]) {
        return self.fw_dynamicLayoutSizeCache.sizeDictionary[cacheKey].CGSizeValue;
    }
    BOOL shouldCache = YES;
    CGSize cellSize = [self fw_dynamicSizeWithCellClass:clazz width:width height:height configuration:configuration shouldCache:&shouldCache];
    if (cacheKey && shouldCache) {
        self.fw_dynamicLayoutSizeCache.sizeDictionary[cacheKey] = [NSValue valueWithCGSize:cellSize];
    }
    return cellSize;
}

#pragma mark - ReusableView

- (UIView *)fw_dynamicViewWithReusableViewClass:(Class)clazz
                                  identifier:(NSString *)identifier {
    NSString *classIdentifier = [NSStringFromClass(clazz) stringByAppendingString:identifier];
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[classIdentifier];
    if (view) return view;

    UIView *reusableView = [[clazz alloc] init];
    view = [UIView new];
    [view addSubview:reusableView];
    dict[classIdentifier] = view;
    return view;
}

- (CGSize)fw_dynamicSizeWithReusableViewClass:(Class)clazz
                                       width:(CGFloat)fixedWidth
                                      height:(CGFloat)fixedHeight
                                        kind:(NSString *)kind
                               configuration:(FWReusableViewConfigurationBlock)configuration
                                 shouldCache:(BOOL *)shouldCache {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@-%@", kind, @(fixedWidth), @(fixedHeight)];
    UIView *view = [self fw_dynamicViewWithReusableViewClass:clazz identifier:identifier];
    CGFloat width = fixedWidth;
    CGFloat height = fixedHeight;
    if (width <= 0 && height <= 0) {
        width = CGRectGetWidth(self.frame);
        if (width <= 0 && self.superview) {
            // 获取 CollectionView 宽度
            [self.superview setNeedsLayout];
            [self.superview layoutIfNeeded];
            width = CGRectGetWidth(self.frame);
        }
    }
    if (shouldCache) *shouldCache = fixedHeight > 0 || width > 0;

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, height);
    UICollectionReusableView *reusableView = view.subviews.firstObject;
    reusableView.frame = CGRectMake(0.0, 0.0, width, height);

    // 让外面布局 UICollectionReusableView
    [reusableView prepareForReuse];
    !configuration ? : configuration(reusableView);
    
    // 自动撑开方式
    if (reusableView.fw_maxYViewExpanded) {
        if (fixedHeight > 0) {
            width = [reusableView fw_layoutWidthWithHeight:height];
        } else {
            height = [reusableView fw_layoutHeightWithWidth:width];
        }
        return CGSizeMake(width, height);
    }
    
    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    CGFloat (^maxYBlock)(UIView *view) = ^CGFloat(UIView *view) {
        return fixedHeight > 0 ? CGRectGetMaxX(view.frame) : CGRectGetMaxY(view.frame);
    };
    if (reusableView.fw_maxYViewFixed) {
        if (reusableView.fw_maxYView) {
            maxY = maxYBlock(reusableView.fw_maxYView);
        } else {
            __block UIView *maxYView = nil;
            [reusableView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = maxYBlock(obj);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            reusableView.fw_maxYView = maxYView;
        }
    } else {
        [reusableView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = maxYBlock(obj);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += reusableView.fw_maxYViewPadding;
    return fixedHeight > 0 ? CGSizeMake(maxY, height) : CGSizeMake(width, maxY);
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_dynamicSizeWithReusableViewClass:clazz width:0 height:0 kind:kind configuration:configuration shouldCache:NULL];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_dynamicSizeWithReusableViewClass:clazz width:width height:0 kind:kind configuration:configuration shouldCache:NULL];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_dynamicSizeWithReusableViewClass:clazz width:0 height:height kind:kind configuration:configuration shouldCache:NULL];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_sizeWithReusableViewClass:clazz kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_sizeWithReusableViewClass:clazz width:width kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_sizeWithReusableViewClass:clazz height:height kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_sizeWithReusableViewClass:clazz width:0 height:0 kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_sizeWithReusableViewClass:clazz width:width height:0 kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fw_sizeWithReusableViewClass:clazz width:0 height:height kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    id<NSCopying> cacheKey = key;
    if (cacheKey && (width > 0 || height > 0)) {
        cacheKey = [NSString stringWithFormat:@"%@-%@-%@", cacheKey, @(width), @(height)];
    }
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        if (cacheKey && self.fw_dynamicLayoutSizeCache.headerSizeDictionary[cacheKey]) {
            return self.fw_dynamicLayoutSizeCache.headerSizeDictionary[cacheKey].CGSizeValue;
        }
        BOOL shouldCache = YES;
        CGSize viewSize = [self fw_dynamicSizeWithReusableViewClass:clazz width:width height:height kind:kind configuration:configuration shouldCache:&shouldCache];
        if (cacheKey && shouldCache) {
            self.fw_dynamicLayoutSizeCache.headerSizeDictionary[cacheKey] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    } else {
        if (cacheKey && self.fw_dynamicLayoutSizeCache.footerSizeDictionary[cacheKey]) {
            return self.fw_dynamicLayoutSizeCache.footerSizeDictionary[cacheKey].CGSizeValue;
        }
        BOOL shouldCache = YES;
        CGSize viewSize = [self fw_dynamicSizeWithReusableViewClass:clazz width:width height:height kind:kind configuration:configuration shouldCache:&shouldCache];
        if (cacheKey && shouldCache) {
            self.fw_dynamicLayoutSizeCache.footerSizeDictionary[cacheKey] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    }
}

@end
