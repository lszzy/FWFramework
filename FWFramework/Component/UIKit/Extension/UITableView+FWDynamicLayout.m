/*!
 @header     UITableView+FWDynamicLayout.m
 @indexgroup FWFramework
 @brief      UITableView+FWDynamicLayout
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/14
 */

#import "UITableView+FWDynamicLayout.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWDynamicLayoutHeightCache

#define FWDynamicLayoutIsVertical (UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width)
#define FWDynamicLayoutDefaultHeight @(-1.0)

@interface FWDynamicLayoutHeightCache : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *heightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSMutableArray <NSNumber *> *> *heightArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerHeightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *headerHeightArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerHeightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *footerHeightArray;

@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerVerticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerHorizontalDictionary;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *headerVerticalArray;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *headerHorizontalArray;

@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *verticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *horizontalDictionary;
@property (nonatomic, strong) NSMutableArray <NSMutableArray <NSNumber *> *> *verticalArray;
@property (nonatomic, strong) NSMutableArray <NSMutableArray <NSNumber *> *> *horizontalArray;

@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerVerticalDictionary;
@property (nonatomic, strong) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerHorizontalDictionary;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *footerVerticalArray;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *footerHorizontalArray;

@end

@implementation FWDynamicLayoutHeightCache

#pragma mark - Header

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)headerHeightDictionary {
    return FWDynamicLayoutIsVertical ? self.headerVerticalDictionary : self.headerHorizontalDictionary;
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

- (NSMutableArray<NSNumber *> *)headerHeightArray {
    return FWDynamicLayoutIsVertical ? self.headerVerticalArray : self.headerHorizontalArray;
}

- (NSMutableArray<NSNumber *> *)headerVerticalArray {
    if (!_headerVerticalArray) {
        _headerVerticalArray = @[].mutableCopy;
    }
    return _headerVerticalArray;
}

- (NSMutableArray<NSNumber *> *)headerHorizontalArray {
    if (!_headerHorizontalArray) {
        _headerHorizontalArray = @[].mutableCopy;
    }
    return _headerHorizontalArray;
}

#pragma mark - Cell

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)heightDictionary {
    return FWDynamicLayoutIsVertical ? self.verticalDictionary : self.horizontalDictionary;
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

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)heightArray {
    return FWDynamicLayoutIsVertical ? self.verticalArray : self.horizontalArray;
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)verticalArray {
    if (!_verticalArray) {
        _verticalArray = @[].mutableCopy;
    }
    return _verticalArray;
}

- (NSMutableArray<NSMutableArray <NSNumber *> *> *)horizontalArray {
    if (!_horizontalArray) {
        _horizontalArray = @[].mutableCopy;
    }
    return _horizontalArray;
}

#pragma mark - Footer

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)footerHeightDictionary {
    return FWDynamicLayoutIsVertical ? self.footerVerticalDictionary : self.footerHorizontalDictionary;
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

- (NSMutableArray<NSNumber *> *)footerHeightArray {
    return FWDynamicLayoutIsVertical ? self.footerVerticalArray : self.footerHorizontalArray;
}

- (NSMutableArray<NSNumber *> *)footerVerticalArray {
    if (!_footerVerticalArray) {
        _footerVerticalArray = @[].mutableCopy;
    }
    return _footerVerticalArray;
}

- (NSMutableArray<NSNumber *> *)footerHorizontalArray {
    if (!_footerHorizontalArray) {
        _footerHorizontalArray = @[].mutableCopy;
    }
    return _footerHorizontalArray;
}

@end

#pragma mark - UITableView+FWInnerDynamicLayout

@interface UITableView (FWInnerDynamicLayout)

@property (nonatomic, readonly) FWDynamicLayoutHeightCache *fwDynamicLayoutHeightCache;

@property (nonatomic, assign, readonly) BOOL fwIsDynamicLayoutInitialized;

- (void)fwDynamicLayoutInitialize;

@end

@implementation UITableView (FWInnerDynamicLayout)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UITableView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            // reloadData 时，清空缓存数据
            if (selfObject.fwIsDynamicLayoutInitialized) {
                [selfObject fwSetupCacheArrayWithDataSource:selfObject.dataSource];
            }
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UITableView, @selector(insertSections:withRowAnimation:), FWSwizzleReturn(void), FWSwizzleArgs(NSIndexSet *sections, UITableViewRowAnimation animation), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
                [selfObject fwSetupCacheArrayWithDataSource:selfObject.dataSource];
            }
            FWSwizzleOriginal(sections, animation);
        }));
        FWSwizzleClass(UITableView, @selector(deleteSections:withRowAnimation:), FWSwizzleReturn(void), FWSwizzleArgs(NSIndexSet *sections, UITableViewRowAnimation animation), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                [sections enumerateIndexesWithOptions:(NSEnumerationReverse) usingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
                    // cell
                    [selfObject.fwDynamicLayoutHeightCache.verticalArray         removeObjectAtIndex:section];
                    [selfObject.fwDynamicLayoutHeightCache.horizontalArray       removeObjectAtIndex:section];
                    // header footer
                    [selfObject.fwDynamicLayoutHeightCache.headerVerticalArray   removeObjectAtIndex:section];
                    [selfObject.fwDynamicLayoutHeightCache.headerHorizontalArray removeObjectAtIndex:section];
                    [selfObject.fwDynamicLayoutHeightCache.footerVerticalArray   removeObjectAtIndex:section];
                    [selfObject.fwDynamicLayoutHeightCache.footerHorizontalArray removeObjectAtIndex:section];
                }];
            }
            FWSwizzleOriginal(sections, animation);
        }));
        FWSwizzleClass(UITableView, @selector(reloadSections:withRowAnimation:), FWSwizzleReturn(void), FWSwizzleArgs(NSIndexSet *sections, UITableViewRowAnimation animation), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
                    // 组的数据可能改变 需要重新获取组的行数
                    NSInteger sectionCount = [selfObject.dataSource tableView:selfObject numberOfRowsInSection:section];
                    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:sectionCount];
                    while (sectionCount-- > 0) {
                        [arr addObject:FWDynamicLayoutDefaultHeight];
                    }
                    selfObject.fwDynamicLayoutHeightCache.verticalArray[section]   = arr.mutableCopy;
                    selfObject.fwDynamicLayoutHeightCache.horizontalArray[section] = arr.mutableCopy;

                    // header footer
                    selfObject.fwDynamicLayoutHeightCache.headerVerticalArray[section]   = FWDynamicLayoutDefaultHeight;
                    selfObject.fwDynamicLayoutHeightCache.headerHorizontalArray[section] = FWDynamicLayoutDefaultHeight;
                    selfObject.fwDynamicLayoutHeightCache.footerVerticalArray[section]   = FWDynamicLayoutDefaultHeight;
                    selfObject.fwDynamicLayoutHeightCache.footerHorizontalArray[section] = FWDynamicLayoutDefaultHeight;
                }];
            }
            FWSwizzleOriginal(sections, animation);
        }));
        FWSwizzleClass(UITableView, @selector(moveSection:toSection:), FWSwizzleReturn(void), FWSwizzleArgs(NSInteger section, NSInteger newSection), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
                [selfObject fwSetupCacheArrayWithDataSource:selfObject.dataSource];
            }
            FWSwizzleOriginal(section, newSection);
        }));
        
        FWSwizzleClass(UITableView, @selector(insertRowsAtIndexPaths:withRowAnimation:), FWSwizzleReturn(void), FWSwizzleArgs(NSArray<NSIndexPath *> *indexPaths, UITableViewRowAnimation animation), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
                [selfObject fwSetupCacheArrayWithDataSource:selfObject.dataSource];
            }
            FWSwizzleOriginal(indexPaths, animation);
        }));
        FWSwizzleClass(UITableView, @selector(deleteRowsAtIndexPaths:withRowAnimation:), FWSwizzleReturn(void), FWSwizzleArgs(NSArray<NSIndexPath *> *indexPaths, UITableViewRowAnimation animation), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                NSMutableArray *tempIndexPaths = indexPaths.mutableCopy;
                [tempIndexPaths sortUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
                    if (obj1.section == obj2.section) {
                        return obj1.row < obj2.row;
                    }
                    return obj1.section < obj2.section;
                }];
                [tempIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [selfObject.fwDynamicLayoutHeightCache.verticalArray[obj.section]   removeObjectAtIndex:obj.row];
                    [selfObject.fwDynamicLayoutHeightCache.horizontalArray[obj.section] removeObjectAtIndex:obj.row];
                }];
            }
            FWSwizzleOriginal(indexPaths, animation);
        }));
        FWSwizzleClass(UITableView, @selector(reloadRowsAtIndexPaths:withRowAnimation:), FWSwizzleReturn(void), FWSwizzleArgs(NSArray<NSIndexPath *> *indexPaths, UITableViewRowAnimation animation), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    selfObject.fwDynamicLayoutHeightCache.verticalArray[obj.section][obj.row]   = FWDynamicLayoutDefaultHeight;
                    selfObject.fwDynamicLayoutHeightCache.horizontalArray[obj.section][obj.row] = FWDynamicLayoutDefaultHeight;
                }];
            }
            FWSwizzleOriginal(indexPaths, animation);
        }));
        FWSwizzleClass(UITableView, @selector(moveRowAtIndexPath:toIndexPath:), FWSwizzleReturn(void), FWSwizzleArgs(NSIndexPath *indexPath, NSIndexPath *newIndexPath), FWSwizzleCode({
            if (selfObject.fwIsDynamicLayoutInitialized) {
                // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
                [selfObject fwSetupCacheArrayWithDataSource:selfObject.dataSource];
            }
            FWSwizzleOriginal(indexPath, newIndexPath);
        }));
    });
}

- (FWDynamicLayoutHeightCache *)fwDynamicLayoutHeightCache {
    FWDynamicLayoutHeightCache *cache = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((cache == nil), 0)) {
        cache = [[FWDynamicLayoutHeightCache alloc] init];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

- (BOOL)fwIsDynamicLayoutInitialized {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)fwDynamicLayoutInitialize {
    [self fwSetupCacheArrayWithDataSource:self.dataSource];
    objc_setAssociatedObject(self, @selector(fwIsDynamicLayoutInitialized), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void)fwSetupCacheArrayWithDataSource:(id<UITableViewDataSource>)dataSource {
    if (!dataSource) return;
    
    // 1、清空 cell 的以 IndexPath 为标识的高度缓存
    NSInteger sections = 1;
    if ([dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        sections = [dataSource numberOfSectionsInTableView:self];
    }

    // 1-1、竖屏状态下的 cell 高度缓存
    // 1-2、横屏状态下的 cell 高度缓存
    NSInteger tempSections = 0;
    NSMutableArray *verticalArray   = [NSMutableArray arrayWithCapacity:sections];
    NSMutableArray *horizontalArray = [NSMutableArray arrayWithCapacity:sections];
    while (tempSections < sections) {
        NSInteger rowCount = [dataSource tableView:self numberOfRowsInSection:tempSections];
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:rowCount];
        while (rowCount-- > 0) {
            [arr addObject:FWDynamicLayoutDefaultHeight];
        }
        [verticalArray addObject:arr];
        [horizontalArray addObject:arr.mutableCopy];
        tempSections++;
    }
    [self.fwDynamicLayoutHeightCache.verticalArray removeAllObjects];
    [self.fwDynamicLayoutHeightCache.verticalArray addObjectsFromArray:verticalArray.copy];

    [self.fwDynamicLayoutHeightCache.horizontalArray removeAllObjects];
    [self.fwDynamicLayoutHeightCache.horizontalArray addObjectsFromArray:horizontalArray.copy];
    
    // 2-1、竖屏状态下的 HeaderView 高度缓存
    // 2-2、横屏状态下的 HeaderView 高度缓存
    // 2-3、竖屏状态下的 FooterView 高度缓存
    // 2-4、横屏状态下的 FooterView 高度缓存
    [self.fwDynamicLayoutHeightCache.headerVerticalArray   removeAllObjects];
    [self.fwDynamicLayoutHeightCache.headerHorizontalArray removeAllObjects];
    [self.fwDynamicLayoutHeightCache.footerVerticalArray   removeAllObjects];
    [self.fwDynamicLayoutHeightCache.footerHorizontalArray removeAllObjects];
    NSInteger temp = 0;
    while (temp++ < sections) {
        [self.fwDynamicLayoutHeightCache.headerVerticalArray   addObject:FWDynamicLayoutDefaultHeight];
        [self.fwDynamicLayoutHeightCache.headerHorizontalArray addObject:FWDynamicLayoutDefaultHeight];
        [self.fwDynamicLayoutHeightCache.footerVerticalArray   addObject:FWDynamicLayoutDefaultHeight];
        [self.fwDynamicLayoutHeightCache.footerHorizontalArray addObject:FWDynamicLayoutDefaultHeight];
    }
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
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
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

+ (instancetype)fwCellWithTableView:(UITableView *)tableView {
    return [self fwCellWithTableView:tableView style:UITableViewCellStyleDefault];
}

+ (instancetype)fwCellWithTableView:(UITableView *)tableView style:(UITableViewCellStyle)style {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"FWDynamicLayoutReuseIdentifier"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) {
        return cell;
    }
    return [[self alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
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
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
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

@end

#pragma mark - UITableView+FWDynamicLayout

@implementation UITableView (FWDynamicLayout)

- (void)fwClearHeightCache
{
    if (self.fwIsDynamicLayoutInitialized) {
        [self fwSetupCacheArrayWithDataSource:self.dataSource];
    }
}

#pragma mark - Cell

- (UIView *)fwCellViewWithCellClass:(Class)clazz {
    NSString *cellClassName = NSStringFromClass(clazz);

    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[cellClassName];
    if (view) {
        return view;
    }
    
    // 这里使用默认的 UITableViewCellStyleDefault 类型。如果需要自定义高度，通常都是使用的此类型, 暂时不考虑其他。
    UITableViewCell *cell = [[clazz alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    view = [UIView new];
    [view addSubview:cell];
    dict[cellClassName] = view;
    return view;
}

- (CGFloat)fwDynamicHeightWithCellClass:(Class)clazz
                        configuration:(FWCellConfigurationBlock)configuration {
    UIView *view = [self fwCellViewWithCellClass:clazz];
    // 获取 TableView 宽度
    UIView *temp = self.superview ? self.superview : self;
    [temp setNeedsLayout];
    [temp layoutIfNeeded];
    CGFloat width = CGRectGetWidth(self.frame);

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
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
    return [self fwDynamicHeightWithCellClass:clazz configuration:configuration];
}

- (CGFloat)fwHeightWithCellClass:(Class)clazz
                 cacheByIndexPath:(NSIndexPath *)indexPath
                    configuration:(FWCellConfigurationBlock)configuration {
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
    NSNumber *number = self.fwDynamicLayoutHeightCache.heightArray[indexPath.section][indexPath.row];
    if (number.doubleValue < 0.0) {
        CGFloat cellHeight = [self fwDynamicHeightWithCellClass:clazz configuration:configuration];
        self.fwDynamicLayoutHeightCache.heightArray[indexPath.section][indexPath.row] = @(cellHeight);
        return cellHeight;
    }
    return number.doubleValue;
}

- (CGFloat)fwHeightWithCellClass:(Class)clazz
                       cacheByKey:(id<NSCopying>)key
                    configuration:(FWCellConfigurationBlock)configuration {
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
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

- (UIView *)fwHeaderFooterViewWithHeaderFooterViewClass:(Class)clazz
                                                   sel:(SEL)sel {
    NSString *headerFooterViewClassName = NSStringFromClass(clazz);

    NSMutableDictionary *dict = objc_getAssociatedObject(self, sel);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, sel, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[headerFooterViewClassName];
    if (view) {
        return view;
    }

    UIView *headerView = [[clazz alloc] initWithReuseIdentifier:nil];
    view = [UIView new];
    [view addSubview:headerView];
    dict[headerFooterViewClassName] = view;
    return view;
}

- (CGFloat)fwDynamicHeightWithHeaderFooterViewClass:(Class)clazz
                                        sel:(SEL)sel
                              configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    UIView *view = [self fwHeaderFooterViewWithHeaderFooterViewClass:clazz sel:sel];
    // 获取 TableView 宽度
    UIView *temp = self.superview ? self.superview : self;
    [temp setNeedsLayout];
    [temp layoutIfNeeded];
    CGFloat width = CGRectGetWidth(self.frame);

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
    return [self fwDynamicHeightWithHeaderFooterViewClass:clazz sel:_cmd configuration:configuration];
}

- (CGFloat)fwDynamicHeightWithFooterViewClass:(Class)clazz
                        configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fwDynamicHeightWithHeaderFooterViewClass:clazz sel:_cmd configuration:configuration];
}

- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                         type:(FWHeaderFooterViewType)type
                                configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
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
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
    if (type == FWHeaderFooterViewTypeHeader) {
        NSNumber *number = self.fwDynamicLayoutHeightCache.headerHeightArray[section];
        if (number.doubleValue >= 0.0) {
            return number.doubleValue;
        }
        CGFloat height = [self fwDynamicHeightWithHeaderViewClass:clazz configuration:configuration];
        self.fwDynamicLayoutHeightCache.headerHeightArray[section] = @(height);
        return height;
    } else {
        NSNumber *number = self.fwDynamicLayoutHeightCache.footerHeightArray[section];
        if (number.doubleValue >= 0.0) {
            return number.doubleValue;
        }
        CGFloat height = [self fwDynamicHeightWithFooterViewClass:clazz configuration:configuration];
        self.fwDynamicLayoutHeightCache.footerHeightArray[section] = @(height);
        return height;
    }
}

- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                         type:(FWHeaderFooterViewType)type
                                   cacheByKey:(id<NSCopying>)key
                                configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
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
