/**
 @header     FWDynamicLayout.m
 @indexgroup FWFramework
      FWDynamicLayout
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/14
 */

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

#pragma mark - FWTableViewCellWrapper+FWDynamicLayout

@implementation FWTableViewCellWrapper (FWDynamicLayout)

- (BOOL)maxYViewFixed {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self.base, @selector(maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)maxYViewPadding {
    return [objc_getAssociatedObject(self.base, _cmd) doubleValue];
}

- (void)setMaxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self.base, @selector(maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)maxYViewExpanded {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self.base, @selector(maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)maxYView {
    return objc_getAssociatedObject(self.base, _cmd);
}

- (void)setMaxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self.base, @selector(maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UITableViewCell (FWDynamicLayout)

+ (instancetype)cellWithTableView:(UITableView *)tableView {
    return [[self fw] cellWithTableView:tableView];
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style {
    return [[self fw] cellWithTableView:tableView style:style];
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style
                                reuseIdentifier:(NSString *)reuseIdentifier {
    return [[self fw] cellWithTableView:tableView style:style reuseIdentifier:reuseIdentifier];
}

@end

@implementation FWTableViewCellClassWrapper (FWDynamicLayout)

- (__kindof UITableViewCell *)cellWithTableView:(UITableView *)tableView {
    return [self cellWithTableView:tableView style:UITableViewCellStyleDefault];
}

- (__kindof UITableViewCell *)cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style {
    return [self cellWithTableView:tableView style:style reuseIdentifier:nil];
}

- (__kindof UITableViewCell *)cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style
                                reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self.base) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) return cell;
    return [[self.base alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
}

- (CGFloat)heightWithTableView:(UITableView *)tableView
                 configuration:(FWCellConfigurationBlock)configuration {
    return [tableView.fw heightWithCellClass:self.base configuration:configuration];
}

@end

#pragma mark - FWTableViewHeaderFooterViewWrapper+FWDynamicLayout

@implementation FWTableViewHeaderFooterViewWrapper (FWDynamicLayout)

- (BOOL)maxYViewFixed {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self.base, @selector(maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)maxYViewPadding {
    return [objc_getAssociatedObject(self.base, _cmd) doubleValue];
}

- (void)setMaxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self.base, @selector(maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)maxYViewExpanded {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self.base, @selector(maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)maxYView {
    return objc_getAssociatedObject(self.base, _cmd);
}

- (void)setMaxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self.base, @selector(maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UITableViewHeaderFooterView (FWDynamicLayout)

+ (instancetype)headerFooterViewWithTableView:(UITableView *)tableView {
    return [[self fw] headerFooterViewWithTableView:tableView];
}

+ (instancetype)headerFooterViewWithTableView:(UITableView *)tableView reuseIdentifier:(NSString *)reuseIdentifier {
    return [[self fw] headerFooterViewWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

@end

@implementation FWTableViewHeaderFooterViewClassWrapper (FWDynamicLayout)

- (__kindof UITableViewHeaderFooterView *)headerFooterViewWithTableView:(UITableView *)tableView {
    return [self headerFooterViewWithTableView:tableView reuseIdentifier:nil];
}

- (__kindof UITableViewHeaderFooterView *)headerFooterViewWithTableView:(UITableView *)tableView reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self.base) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    SEL reuseSelector = NSSelectorFromString(reuseIdentifier);
    if ([objc_getAssociatedObject(tableView, reuseSelector) boolValue]) {
        return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    }
    [tableView registerClass:self.base forHeaderFooterViewReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
}

- (CGFloat)heightWithTableView:(UITableView *)tableView
                          type:(FWHeaderFooterViewType)type
                 configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [tableView.fw heightWithHeaderFooterViewClass:self.base type:type configuration:configuration];
}

@end

#pragma mark - FWTableViewWrapper+FWDynamicLayout

@implementation FWTableViewWrapper (FWDynamicLayout)

- (void)clearHeightCache
{
    [self.dynamicLayoutHeightCache removeAllObjects];
}

- (FWDynamicLayoutHeightCache *)dynamicLayoutHeightCache {
    FWDynamicLayoutHeightCache *cache = objc_getAssociatedObject(self.base, _cmd);
    if (__builtin_expect((cache == nil), 0)) {
        cache = [[FWDynamicLayoutHeightCache alloc] init];
        objc_setAssociatedObject(self.base, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

#pragma mark - Cell

- (UIView *)dynamicViewWithCellClass:(Class)clazz {
    NSString *className = NSStringFromClass(clazz);
    NSMutableDictionary *dict = objc_getAssociatedObject(self.base, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self.base, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

- (CGFloat)dynamicHeightWithCellClass:(Class)clazz
                        configuration:(FWCellConfigurationBlock)configuration
                          shouldCache:(BOOL *)shouldCache {
    UIView *view = [self dynamicViewWithCellClass:clazz];
    CGFloat width = CGRectGetWidth(self.base.frame);
    if (width <= 0 && self.base.superview) {
        // 获取 TableView 宽度
        [self.base.superview setNeedsLayout];
        [self.base.superview layoutIfNeeded];
        width = CGRectGetWidth(self.base.frame);
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
    if (cell.fw.maxYViewExpanded) {
        return [cell.fw layoutHeightWithWidth:width];
    }

    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY = 0.0;
    if (cell.fw.maxYViewFixed) {
        if (cell.fw.maxYView) {
            maxY = CGRectGetMaxY(cell.fw.maxYView.frame);
        } else {
            __block UIView *maxYView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            cell.fw.maxYView = maxYView;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += cell.fw.maxYViewPadding;
    return maxY;
}

- (CGFloat)heightWithCellClass:(Class)clazz
                 configuration:(FWCellConfigurationBlock)configuration {
    return [self dynamicHeightWithCellClass:clazz configuration:configuration shouldCache:NULL];
}

- (CGFloat)heightWithCellClass:(Class)clazz
              cacheByIndexPath:(NSIndexPath *)indexPath
                 configuration:(FWCellConfigurationBlock)configuration {
    return [self heightWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGFloat)heightWithCellClass:(Class)clazz
                    cacheByKey:(id<NSCopying>)key
                 configuration:(FWCellConfigurationBlock)configuration {
    if (key && self.dynamicLayoutHeightCache.heightDictionary[key]) {
        return self.dynamicLayoutHeightCache.heightDictionary[key].doubleValue;
    }
    BOOL shouldCache = YES;
    CGFloat cellHeight = [self dynamicHeightWithCellClass:clazz configuration:configuration shouldCache:&shouldCache];
    if (key && shouldCache) {
        self.dynamicLayoutHeightCache.heightDictionary[key] = @(cellHeight);
    }
    return cellHeight;
}

#pragma mark - HeaderFooterView

- (UIView *)dynamicViewWithHeaderFooterViewClass:(Class)clazz
                                      identifier:(NSString *)identifier {
    NSString *classIdentifier = [NSStringFromClass(clazz) stringByAppendingString:identifier];
    NSMutableDictionary *dict = objc_getAssociatedObject(self.base, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self.base, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[classIdentifier];
    if (view) return view;

    UIView *headerView = [[clazz alloc] initWithReuseIdentifier:nil];
    view = [UIView new];
    [view addSubview:headerView];
    dict[classIdentifier] = view;
    return view;
}

- (CGFloat)dynamicHeightWithHeaderFooterViewClass:(Class)clazz
                                             type:(FWHeaderFooterViewType)type
                                    configuration:(FWHeaderFooterViewConfigurationBlock)configuration
                                      shouldCache:(BOOL *)shouldCache {
    NSString *identifier = [NSString stringWithFormat:@"%@", @(type)];
    UIView *view = [self dynamicViewWithHeaderFooterViewClass:clazz identifier:identifier];
    CGFloat width = CGRectGetWidth(self.base.frame);
    if (width <= 0 && self.base.superview) {
        // 获取 TableView 宽度
        [self.base.superview setNeedsLayout];
        [self.base.superview layoutIfNeeded];
        width = CGRectGetWidth(self.base.frame);
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
    if (headerFooterView.fw.maxYViewExpanded) {
        return [headerFooterView.fw layoutHeightWithWidth:width];
    }
    
    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    UIView *contentView = headerFooterView.contentView.subviews.count ? headerFooterView.contentView : headerFooterView;
    if (headerFooterView.fw.maxYViewFixed) {
        if (headerFooterView.fw.maxYView) {
            maxY = CGRectGetMaxY(headerFooterView.fw.maxYView.frame);
        } else {
            __block UIView *maxYView = nil;
            [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            headerFooterView.fw.maxYView = maxYView;
        }
    } else {
        [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += headerFooterView.fw.maxYViewPadding;
    return maxY;
}

- (CGFloat)heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                             configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self dynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration shouldCache:NULL];
}

- (CGFloat)heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                            cacheBySection:(NSInteger)section
                             configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self heightWithHeaderFooterViewClass:clazz type:type cacheByKey:@(section) configuration:configuration];
}

- (CGFloat)heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                                cacheByKey:(id<NSCopying>)key
                             configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    if (type == FWHeaderFooterViewTypeHeader) {
        if (key && self.dynamicLayoutHeightCache.headerHeightDictionary[key]) {
            return self.dynamicLayoutHeightCache.headerHeightDictionary[key].doubleValue;
        }
        BOOL shouldCache = YES;
        CGFloat viewHeight = [self dynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration shouldCache:&shouldCache];
        if (key && shouldCache) {
            self.dynamicLayoutHeightCache.headerHeightDictionary[key] = @(viewHeight);
        }
        return viewHeight;
    } else {
        if (key && self.dynamicLayoutHeightCache.footerHeightDictionary[key]) {
            return self.dynamicLayoutHeightCache.footerHeightDictionary[key].doubleValue;
        }
        BOOL shouldCache = YES;
        CGFloat viewHeight = [self dynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration shouldCache:&shouldCache];
        if (key && shouldCache) {
            self.dynamicLayoutHeightCache.footerHeightDictionary[key] = @(viewHeight);
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

#pragma mark - FWCollectionViewCellWrapper+FWDynamicLayout

@implementation FWCollectionViewCellWrapper (FWDynamicLayout)

- (BOOL)maxYViewFixed {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self.base, @selector(maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)maxYViewPadding {
    return [objc_getAssociatedObject(self.base, _cmd) doubleValue];
}

- (void)setMaxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self.base, @selector(maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)maxYViewExpanded {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self.base, @selector(maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)maxYView {
    return objc_getAssociatedObject(self.base, _cmd);
}

- (void)setMaxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self.base, @selector(maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UICollectionViewCell (FWDynamicLayout)

+ (instancetype)cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath {
    return [[self fw] cellWithCollectionView:collectionView indexPath:indexPath];
}

+ (instancetype)cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath
                         reuseIdentifier:(NSString *)reuseIdentifier {
    return [[self fw] cellWithCollectionView:collectionView indexPath:indexPath reuseIdentifier:reuseIdentifier];
}

@end

@implementation FWCollectionViewCellClassWrapper (FWDynamicLayout)

- (__kindof UICollectionViewCell *)cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath {
    return [self cellWithCollectionView:collectionView indexPath:indexPath reuseIdentifier:nil];
}

- (__kindof UICollectionViewCell *)cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath
                         reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self.base) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    SEL reuseSelector = NSSelectorFromString(reuseIdentifier);
    if ([objc_getAssociatedObject(collectionView, reuseSelector) boolValue]) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [collectionView registerClass:self.base forCellWithReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(collectionView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
}

- (CGSize)sizeWithCollectionView:(UICollectionView *)collectionView
                   configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [collectionView.fw sizeWithCellClass:self.base configuration:configuration];
}

- (CGSize)sizeWithCollectionView:(UICollectionView *)collectionView
                           width:(CGFloat)width
                   configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [collectionView.fw sizeWithCellClass:self.base width:width configuration:configuration];
}

- (CGSize)sizeWithCollectionView:(UICollectionView *)collectionView
                          height:(CGFloat)height
                   configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [collectionView.fw sizeWithCellClass:self.base height:height configuration:configuration];
}

@end

#pragma mark - FWCollectionReusableViewWrapper+FWDynamicLayout

@implementation FWCollectionReusableViewWrapper (FWDynamicLayout)

- (BOOL)maxYViewFixed {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewFixed:(BOOL)maxYViewFixed {
    objc_setAssociatedObject(self.base, @selector(maxYViewFixed), @(maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)maxYViewPadding {
    return [objc_getAssociatedObject(self.base, _cmd) doubleValue];
}

- (void)setMaxYViewPadding:(CGFloat)maxYViewPadding {
    objc_setAssociatedObject(self.base, @selector(maxYViewPadding), @(maxYViewPadding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)maxYViewExpanded {
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setMaxYViewExpanded:(BOOL)maxYViewExpanded {
    objc_setAssociatedObject(self.base, @selector(maxYViewExpanded), @(maxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)maxYView {
    return objc_getAssociatedObject(self.base, _cmd);
}

- (void)setMaxYView:(UIView *)maxYView {
    objc_setAssociatedObject(self.base, @selector(maxYView), maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UICollectionReusableView (FWDynamicLayout)

+ (instancetype)reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath {
    return [[self fw] reusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath];
}

+ (instancetype)reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(NSString *)reuseIdentifier {
    return [[self fw] reusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath reuseIdentifier:reuseIdentifier];
}

@end

@implementation FWCollectionReusableViewClassWrapper (FWDynamicLayout)

- (__kindof UICollectionReusableView *)reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath {
    return [self reusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath reuseIdentifier:nil];
}

- (__kindof UICollectionReusableView *)reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier) reuseIdentifier = [NSStringFromClass(self.base) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    SEL reuseSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@", reuseIdentifier, kind]);
    if ([objc_getAssociatedObject(collectionView, reuseSelector) boolValue]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [collectionView registerClass:self.base forSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(collectionView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
}

- (CGSize)sizeWithCollectionView:(UICollectionView *)collectionView
                            kind:(NSString *)kind
                   configuration:(FWReusableViewConfigurationBlock)configuration {
    return [collectionView.fw sizeWithReusableViewClass:self.base kind:kind configuration:configuration];
}

- (CGSize)sizeWithCollectionView:(UICollectionView *)collectionView
                           width:(CGFloat)width
                            kind:(NSString *)kind
                   configuration:(FWReusableViewConfigurationBlock)configuration {
    return [collectionView.fw sizeWithReusableViewClass:self.base width:width kind:kind configuration:configuration];
}

- (CGSize)sizeWithCollectionView:(UICollectionView *)collectionView
                          height:(CGFloat)height
                            kind:(NSString *)kind
                   configuration:(FWReusableViewConfigurationBlock)configuration {
    return [collectionView.fw sizeWithReusableViewClass:self.base height:height kind:kind configuration:configuration];
}

@end

#pragma mark - FWCollectionViewWrapper+FWDynamicLayout

@implementation FWCollectionViewWrapper (FWDynamicLayout)

- (void)clearSizeCache
{
    [self.dynamicLayoutSizeCache removeAllObjects];
}

- (FWDynamicLayoutSizeCache *)dynamicLayoutSizeCache {
    FWDynamicLayoutSizeCache *cache = objc_getAssociatedObject(self.base, _cmd);
    if (__builtin_expect((cache == nil), 0)) {
        cache = [[FWDynamicLayoutSizeCache alloc] init];
        objc_setAssociatedObject(self.base, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

#pragma mark - Cell

- (UIView *)dynamicViewWithCellClass:(Class)clazz
                          identifier:(NSString *)identifier {
    NSString *classIdentifier = [NSStringFromClass(clazz) stringByAppendingString:identifier];
    NSMutableDictionary *dict = objc_getAssociatedObject(self.base, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self.base, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[classIdentifier];
    if (view) return view;
    
    UICollectionViewCell *cell = [[clazz alloc] init];
    view = [UIView new];
    [view addSubview:cell];
    dict[classIdentifier] = view;
    return view;
}

- (CGSize)dynamicSizeWithCellClass:(Class)clazz
                               width:(CGFloat)fixedWidth
                              height:(CGFloat)fixedHeight
                       configuration:(FWCollectionCellConfigurationBlock)configuration
                         shouldCache:(BOOL *)shouldCache {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@", @(fixedWidth), @(fixedHeight)];
    UIView *view = [self dynamicViewWithCellClass:clazz identifier:identifier];
    CGFloat width = fixedWidth;
    CGFloat height = fixedHeight;
    if (width <= 0 && height <= 0) {
        width = CGRectGetWidth(self.base.frame);
        if (width <= 0 && self.base.superview) {
            // 获取 CollectionView 宽度
            [self.base.superview setNeedsLayout];
            [self.base.superview layoutIfNeeded];
            width = CGRectGetWidth(self.base.frame);
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
    if (cell.fw.maxYViewExpanded) {
        if (fixedHeight > 0) {
            width = [cell.fw layoutWidthWithHeight:height];
        } else {
            height = [cell.fw layoutHeightWithWidth:width];
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
    if (cell.fw.maxYViewFixed) {
        if (cell.fw.maxYView) {
            maxY = maxYBlock(cell.fw.maxYView);
        } else {
            __block UIView *maxYView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = maxYBlock(obj);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            cell.fw.maxYView = maxYView;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = maxYBlock(obj);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += cell.fw.maxYViewPadding;
    return fixedHeight > 0 ? CGSizeMake(maxY, height) : CGSizeMake(width, maxY);
}

- (CGSize)sizeWithCellClass:(Class)clazz
              configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self dynamicSizeWithCellClass:clazz width:0 height:0 configuration:configuration shouldCache:NULL];
}

- (CGSize)sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self dynamicSizeWithCellClass:clazz width:width height:0 configuration:configuration shouldCache:NULL];
}

- (CGSize)sizeWithCellClass:(Class)clazz
                       height:(CGFloat)height
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self dynamicSizeWithCellClass:clazz width:0 height:height configuration:configuration shouldCache:NULL];
}

- (CGSize)sizeWithCellClass:(Class)clazz
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self sizeWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGSize)sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self sizeWithCellClass:clazz width:width cacheByKey:indexPath configuration:configuration];
}

- (CGSize)sizeWithCellClass:(Class)clazz
                       height:(CGFloat)height
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self sizeWithCellClass:clazz height:height cacheByKey:indexPath configuration:configuration];
}

- (CGSize)sizeWithCellClass:(Class)clazz
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self sizeWithCellClass:clazz width:0 height:0 cacheByKey:key configuration:configuration];
}

- (CGSize)sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self sizeWithCellClass:clazz width:width height:0 cacheByKey:key configuration:configuration];
}

- (CGSize)sizeWithCellClass:(Class)clazz height:(CGFloat)height cacheByKey:(id<NSCopying>)key configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self sizeWithCellClass:clazz width:0 height:height cacheByKey:key configuration:configuration];
}

- (CGSize)sizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                       height:(CGFloat)height
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    id<NSCopying> cacheKey = key;
    if (cacheKey && (width > 0 || height > 0)) {
        cacheKey = [NSString stringWithFormat:@"%@-%@-%@", cacheKey, @(width), @(height)];
    }
    
    if (cacheKey && self.dynamicLayoutSizeCache.sizeDictionary[cacheKey]) {
        return self.dynamicLayoutSizeCache.sizeDictionary[cacheKey].CGSizeValue;
    }
    BOOL shouldCache = YES;
    CGSize cellSize = [self dynamicSizeWithCellClass:clazz width:width height:height configuration:configuration shouldCache:&shouldCache];
    if (cacheKey && shouldCache) {
        self.dynamicLayoutSizeCache.sizeDictionary[cacheKey] = [NSValue valueWithCGSize:cellSize];
    }
    return cellSize;
}

#pragma mark - ReusableView

- (UIView *)dynamicViewWithReusableViewClass:(Class)clazz
                                  identifier:(NSString *)identifier {
    NSString *classIdentifier = [NSStringFromClass(clazz) stringByAppendingString:identifier];
    NSMutableDictionary *dict = objc_getAssociatedObject(self.base, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self.base, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[classIdentifier];
    if (view) return view;

    UIView *reusableView = [[clazz alloc] init];
    view = [UIView new];
    [view addSubview:reusableView];
    dict[classIdentifier] = view;
    return view;
}

- (CGSize)dynamicSizeWithReusableViewClass:(Class)clazz
                                       width:(CGFloat)fixedWidth
                                      height:(CGFloat)fixedHeight
                                        kind:(NSString *)kind
                               configuration:(FWReusableViewConfigurationBlock)configuration
                                 shouldCache:(BOOL *)shouldCache {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@-%@", kind, @(fixedWidth), @(fixedHeight)];
    UIView *view = [self dynamicViewWithReusableViewClass:clazz identifier:identifier];
    CGFloat width = fixedWidth;
    CGFloat height = fixedHeight;
    if (width <= 0 && height <= 0) {
        width = CGRectGetWidth(self.base.frame);
        if (width <= 0 && self.base.superview) {
            // 获取 CollectionView 宽度
            [self.base.superview setNeedsLayout];
            [self.base.superview layoutIfNeeded];
            width = CGRectGetWidth(self.base.frame);
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
    if (reusableView.fw.maxYViewExpanded) {
        if (fixedHeight > 0) {
            width = [reusableView.fw layoutWidthWithHeight:height];
        } else {
            height = [reusableView.fw layoutHeightWithWidth:width];
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
    if (reusableView.fw.maxYViewFixed) {
        if (reusableView.fw.maxYView) {
            maxY = maxYBlock(reusableView.fw.maxYView);
        } else {
            __block UIView *maxYView = nil;
            [reusableView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = maxYBlock(obj);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            reusableView.fw.maxYView = maxYView;
        }
    } else {
        [reusableView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = maxYBlock(obj);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += reusableView.fw.maxYViewPadding;
    return fixedHeight > 0 ? CGSizeMake(maxY, height) : CGSizeMake(width, maxY);
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self dynamicSizeWithReusableViewClass:clazz width:0 height:0 kind:kind configuration:configuration shouldCache:NULL];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self dynamicSizeWithReusableViewClass:clazz width:width height:0 kind:kind configuration:configuration shouldCache:NULL];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self dynamicSizeWithReusableViewClass:clazz width:0 height:height kind:kind configuration:configuration shouldCache:NULL];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self sizeWithReusableViewClass:clazz kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self sizeWithReusableViewClass:clazz width:width kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self sizeWithReusableViewClass:clazz height:height kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self sizeWithReusableViewClass:clazz width:0 height:0 kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self sizeWithReusableViewClass:clazz width:width height:0 kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self sizeWithReusableViewClass:clazz width:0 height:height kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)sizeWithReusableViewClass:(Class)clazz
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
        if (cacheKey && self.dynamicLayoutSizeCache.headerSizeDictionary[cacheKey]) {
            return self.dynamicLayoutSizeCache.headerSizeDictionary[cacheKey].CGSizeValue;
        }
        BOOL shouldCache = YES;
        CGSize viewSize = [self dynamicSizeWithReusableViewClass:clazz width:width height:height kind:kind configuration:configuration shouldCache:&shouldCache];
        if (cacheKey && shouldCache) {
            self.dynamicLayoutSizeCache.headerSizeDictionary[cacheKey] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    } else {
        if (cacheKey && self.dynamicLayoutSizeCache.footerSizeDictionary[cacheKey]) {
            return self.dynamicLayoutSizeCache.footerSizeDictionary[cacheKey].CGSizeValue;
        }
        BOOL shouldCache = YES;
        CGSize viewSize = [self dynamicSizeWithReusableViewClass:clazz width:width height:height kind:kind configuration:configuration shouldCache:&shouldCache];
        if (cacheKey && shouldCache) {
            self.dynamicLayoutSizeCache.footerSizeDictionary[cacheKey] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    }
}

@end
