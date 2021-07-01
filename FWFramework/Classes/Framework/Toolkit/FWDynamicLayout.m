/*!
 @header     FWDynamicLayout.m
 @indexgroup FWFramework
 @brief      FWDynamicLayout
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

- (BOOL)fwMaxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxYViewExpanded:(BOOL)fwMaxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fwMaxYViewExpanded), @(fwMaxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

+ (instancetype)fwCellWithTableView:(UITableView *)tableView
                              style:(UITableViewCellStyle)style {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    return [self fwCellWithTableView:tableView style:style reuseIdentifier:reuseIdentifier];
}

+ (instancetype)fwCellWithTableView:(UITableView *)tableView
                              style:(UITableViewCellStyle)style
                    reuseIdentifier:(NSString *)reuseIdentifier {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) return cell;
    return [[self alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
}

+ (CGFloat)fwHeightWithViewModel:(id)viewModel
                       tableView:(UITableView *)tableView {
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

- (BOOL)fwMaxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxYViewExpanded:(BOOL)fwMaxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fwMaxYViewExpanded), @(fwMaxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    return [self fwHeaderFooterViewWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

+ (instancetype)fwHeaderFooterViewWithTableView:(UITableView *)tableView
                                reuseIdentifier:(NSString *)reuseIdentifier {
    SEL reuseSelector = NSSelectorFromString(reuseIdentifier);
    if ([objc_getAssociatedObject(tableView, reuseSelector) boolValue]) {
        return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    }
    [tableView registerClass:self forHeaderFooterViewReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
}

+ (CGFloat)fwHeightWithViewModel:(id)viewModel
                            type:(FWHeaderFooterViewType)type
                       tableView:(UITableView *)tableView {
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
    if (width <= 0 && self.superview) {
        // 获取 TableView 宽度
        [self.superview setNeedsLayout];
        [self.superview layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0, 0.0, width, 0.0);
    
    // 让外面布局 Cell
    [cell prepareForReuse];
    !configuration ? : configuration(cell);
    
    // 自动撑开方式
    if (cell.fwMaxYViewExpanded) {
        return [cell fwLayoutHeightWithWidth:width];
    }

    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY = 0.0;
    if (cell.fwMaxYViewFixed) {
        if (cell.fwMaxYView) {
            maxY = CGRectGetMaxY(cell.fwMaxYView.frame);
        } else {
            __block UIView *maxYView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            cell.fwMaxYView = maxYView;
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

- (CGFloat)fwDynamicHeightWithHeaderFooterViewClass:(Class)clazz
                                               type:(FWHeaderFooterViewType)type
                                      configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    NSString *identifier = [NSString stringWithFormat:@"%@", @(type)];
    UIView *view = [self fwDynamicViewWithHeaderFooterViewClass:clazz identifier:identifier];
    CGFloat width = CGRectGetWidth(self.frame);
    if (width <= 0 && self.superview) {
        // 获取 TableView 宽度
        [self.superview setNeedsLayout];
        [self.superview layoutIfNeeded];
        width = CGRectGetWidth(self.frame);
    }

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewHeaderFooterView *headerFooterView = view.subviews.firstObject;
    headerFooterView.frame = CGRectMake(0.0, 0.0, width, 0.0);

    // 让外面布局 UITableViewHeaderFooterView
    [headerFooterView prepareForReuse];
    !configuration ? : configuration(headerFooterView);
    
    // 自动撑开方式
    if (headerFooterView.fwMaxYViewExpanded) {
        return [headerFooterView fwLayoutHeightWithWidth:width];
    }
    
    // 刷新布局
    [view setNeedsLayout];
    [view layoutIfNeeded];

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    UIView *contentView = headerFooterView.contentView.subviews.count ? headerFooterView.contentView : headerFooterView;
    if (headerFooterView.fwMaxYViewFixed) {
        if (headerFooterView.fwMaxYView) {
            maxY = CGRectGetMaxY(headerFooterView.fwMaxYView.frame);
        } else {
            __block UIView *maxYView = nil;
            [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            headerFooterView.fwMaxYView = maxYView;
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

- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                        type:(FWHeaderFooterViewType)type
                               configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fwDynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration];
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
        CGFloat viewHeight = [self fwDynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration];
        if (key) {
            self.fwDynamicLayoutHeightCache.headerHeightDictionary[key] = @(viewHeight);
        }
        return viewHeight;
    } else {
        if (key && self.fwDynamicLayoutHeightCache.footerHeightDictionary[key]) {
            return self.fwDynamicLayoutHeightCache.footerHeightDictionary[key].doubleValue;
        }
        CGFloat viewHeight = [self fwDynamicHeightWithHeaderFooterViewClass:clazz type:type configuration:configuration];
        if (key) {
            self.fwDynamicLayoutHeightCache.footerHeightDictionary[key] = @(viewHeight);
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

- (BOOL)fwMaxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxYViewExpanded:(BOOL)fwMaxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fwMaxYViewExpanded), @(fwMaxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

+ (instancetype)fwCellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    return [self fwCellWithCollectionView:collectionView indexPath:indexPath reuseIdentifier:reuseIdentifier];
}

+ (instancetype)fwCellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath
                         reuseIdentifier:(NSString *)reuseIdentifier {
    SEL reuseSelector = NSSelectorFromString(reuseIdentifier);
    if ([objc_getAssociatedObject(collectionView, reuseSelector) boolValue]) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [collectionView registerClass:self forCellWithReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(collectionView, reuseSelector, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

- (BOOL)fwMaxYViewExpanded {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwMaxYViewExpanded:(BOOL)fwMaxYViewExpanded {
    objc_setAssociatedObject(self, @selector(fwMaxYViewExpanded), @(fwMaxYViewExpanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

+ (instancetype)fwReusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    return [self fwReusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath reuseIdentifier:reuseIdentifier];
}

+ (instancetype)fwReusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(NSString *)reuseIdentifier {
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

- (UIView *)fwDynamicViewWithCellClass:(Class)clazz
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

- (CGSize)fwDynamicSizeWithCellClass:(Class)clazz
                               width:(CGFloat)fixedWidth
                              height:(CGFloat)fixedHeight
                       configuration:(FWCollectionCellConfigurationBlock)configuration {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@", @(fixedWidth), @(fixedHeight)];
    UIView *view = [self fwDynamicViewWithCellClass:clazz identifier:identifier];
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

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, height);
    UICollectionViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0, 0.0, width, height);
    
    // 让外面布局 Cell
    [cell prepareForReuse];
    !configuration ? : configuration(cell);
    
    // 自动撑开方式
    if (cell.fwMaxYViewExpanded) {
        if (fixedHeight > 0) {
            width = [cell fwLayoutWidthWithHeight:height];
        } else {
            height = [cell fwLayoutHeightWithWidth:width];
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
    if (cell.fwMaxYViewFixed) {
        if (cell.fwMaxYView) {
            maxY = maxYBlock(cell.fwMaxYView);
        } else {
            __block UIView *maxYView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = maxYBlock(obj);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            cell.fwMaxYView = maxYView;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = maxYBlock(obj);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += cell.fwMaxYViewPadding;
    return fixedHeight > 0 ? CGSizeMake(maxY, height) : CGSizeMake(width, maxY);
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwDynamicSizeWithCellClass:clazz width:0 height:0 configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwDynamicSizeWithCellClass:clazz width:width height:0 configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                       height:(CGFloat)height
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwDynamicSizeWithCellClass:clazz width:0 height:height configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz width:width cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                       height:(CGFloat)height
             cacheByIndexPath:(NSIndexPath *)indexPath
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz height:height cacheByKey:indexPath configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz width:0 height:0 cacheByKey:key configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz width:width height:0 cacheByKey:key configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz height:(CGFloat)height cacheByKey:(id<NSCopying>)key configuration:(FWCollectionCellConfigurationBlock)configuration {
    return [self fwSizeWithCellClass:clazz width:0 height:height cacheByKey:key configuration:configuration];
}

- (CGSize)fwSizeWithCellClass:(Class)clazz
                        width:(CGFloat)width
                       height:(CGFloat)height
                   cacheByKey:(id<NSCopying>)key
                configuration:(FWCollectionCellConfigurationBlock)configuration {
    id<NSCopying> cacheKey = key;
    if (cacheKey && (width > 0 || height > 0)) {
        cacheKey = [NSString stringWithFormat:@"%@-%@-%@", cacheKey, @(width), @(height)];
    }
    
    if (cacheKey && self.fwDynamicLayoutSizeCache.sizeDictionary[cacheKey]) {
        return self.fwDynamicLayoutSizeCache.sizeDictionary[cacheKey].CGSizeValue;
    }
    CGSize cellSize = [self fwDynamicSizeWithCellClass:clazz width:width height:height configuration:configuration];
    if (cacheKey) {
        self.fwDynamicLayoutSizeCache.sizeDictionary[cacheKey] = [NSValue valueWithCGSize:cellSize];
    }
    return cellSize;
}

#pragma mark - ReusableView

- (UIView *)fwDynamicViewWithReusableViewClass:(Class)clazz
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

- (CGSize)fwDynamicSizeWithReusableViewClass:(Class)clazz
                                       width:(CGFloat)fixedWidth
                                      height:(CGFloat)fixedHeight
                                        kind:(NSString *)kind
                               configuration:(FWReusableViewConfigurationBlock)configuration {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@-%@", kind, @(fixedWidth), @(fixedHeight)];
    UIView *view = [self fwDynamicViewWithReusableViewClass:clazz identifier:identifier];
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

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, height);
    UICollectionReusableView *reusableView = view.subviews.firstObject;
    reusableView.frame = CGRectMake(0.0, 0.0, width, height);

    // 让外面布局 UICollectionReusableView
    [reusableView prepareForReuse];
    !configuration ? : configuration(reusableView);
    
    // 自动撑开方式
    if (reusableView.fwMaxYViewExpanded) {
        if (fixedHeight > 0) {
            width = [reusableView fwLayoutWidthWithHeight:height];
        } else {
            height = [reusableView fwLayoutHeightWithWidth:width];
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
    if (reusableView.fwMaxYViewFixed) {
        if (reusableView.fwMaxYView) {
            maxY = maxYBlock(reusableView.fwMaxYView);
        } else {
            __block UIView *maxYView = nil;
            [reusableView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = maxYBlock(obj);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxYView = obj;
                }
            }];
            reusableView.fwMaxYView = maxYView;
        }
    } else {
        [reusableView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = maxYBlock(obj);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
    }
    maxY += reusableView.fwMaxYViewPadding;
    return fixedHeight > 0 ? CGSizeMake(maxY, height) : CGSizeMake(width, maxY);
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwDynamicSizeWithReusableViewClass:clazz width:0 height:0 kind:kind configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwDynamicSizeWithReusableViewClass:clazz width:width height:0 kind:kind configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwDynamicSizeWithReusableViewClass:clazz width:0 height:height kind:kind configuration:configuration];
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
    return [self fwSizeWithReusableViewClass:clazz width:width kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                       cacheBySection:(NSInteger)section
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwSizeWithReusableViewClass:clazz height:height kind:kind cacheByKey:@(section) configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwSizeWithReusableViewClass:clazz width:0 height:0 kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                                width:(CGFloat)width
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwSizeWithReusableViewClass:clazz width:width height:0 kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
                               height:(CGFloat)height
                                 kind:(NSString *)kind
                           cacheByKey:(id<NSCopying>)key
                        configuration:(FWReusableViewConfigurationBlock)configuration {
    return [self fwSizeWithReusableViewClass:clazz width:0 height:height kind:kind cacheByKey:key configuration:configuration];
}

- (CGSize)fwSizeWithReusableViewClass:(Class)clazz
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
        if (cacheKey && self.fwDynamicLayoutSizeCache.headerSizeDictionary[cacheKey]) {
            return self.fwDynamicLayoutSizeCache.headerSizeDictionary[cacheKey].CGSizeValue;
        }
        CGSize viewSize = [self fwDynamicSizeWithReusableViewClass:clazz width:width height:height kind:kind configuration:configuration];
        if (cacheKey) {
            self.fwDynamicLayoutSizeCache.headerSizeDictionary[cacheKey] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    } else {
        if (cacheKey && self.fwDynamicLayoutSizeCache.footerSizeDictionary[cacheKey]) {
            return self.fwDynamicLayoutSizeCache.footerSizeDictionary[cacheKey].CGSizeValue;
        }
        CGSize viewSize = [self fwDynamicSizeWithReusableViewClass:clazz width:width height:height kind:kind configuration:configuration];
        if (cacheKey) {
            self.fwDynamicLayoutSizeCache.footerSizeDictionary[cacheKey] = [NSValue valueWithCGSize:viewSize];
        }
        return viewSize;
    }
}

@end
