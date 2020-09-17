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

#pragma mark - UITableView+FWInnerDynamicLayout

#define FWDynamicLayoutIsVertical (UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width)
#define FWDynamicLayoutDefaultHeight @(-1.0)

@interface UITableView (FWInnerDynamicLayout)

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwHeightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSMutableArray <NSNumber *> *> *fwHeightArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwHeaderHeightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *fwHeaderHeightArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwFooterHeightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *fwFooterHeightArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwHeaderVerticalDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwHeaderHorizontalDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *fwHeaderVerticalArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *fwHeaderHorizontalArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwVerticalDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwHorizontalDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSMutableArray <NSNumber *> *> *fwVerticalArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSMutableArray <NSNumber *> *> *fwHorizontalArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwFooterVerticalDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *fwFooterHorizontalDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *fwFooterVerticalArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *fwFooterHorizontalArray;

@property (nonatomic, assign, readonly) BOOL fwIsDynamicLayoutInitialized;

- (void)fwDynamicLayoutInitialize;

@end

@implementation UITableView (FWInnerDynamicLayout)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(reloadData) with:@selector(fwDynamicLayoutReloadData)];
        
        [self fwSwizzleInstanceMethod:@selector(insertSections:withRowAnimation:) with:@selector(fwDynamicLayoutInsertSections:withRowAnimation:)];
        [self fwSwizzleInstanceMethod:@selector(deleteSections:withRowAnimation:) with:@selector(fwDynamicLayoutDeleteSections:withRowAnimation:)];
        [self fwSwizzleInstanceMethod:@selector(reloadSections:withRowAnimation:) with:@selector(fwDynamicLayoutReloadSections:withRowAnimation:)];
        [self fwSwizzleInstanceMethod:@selector(moveSection:toSection:) with:@selector(fwDynamicLayoutMoveSection:toSection:)];
        
        [self fwSwizzleInstanceMethod:@selector(insertRowsAtIndexPaths:withRowAnimation:) with:@selector(fwDynamicLayoutInsertRowsAtIndexPaths:withRowAnimation:)];
        [self fwSwizzleInstanceMethod:@selector(deleteRowsAtIndexPaths:withRowAnimation:) with:@selector(fwDynamicLayoutDeleteRowsAtIndexPaths:withRowAnimation:)];
        [self fwSwizzleInstanceMethod:@selector(reloadRowsAtIndexPaths:withRowAnimation:) with:@selector(fwDynamicLayoutReloadRowsAtIndexPaths:withRowAnimation:)];
        [self fwSwizzleInstanceMethod:@selector(moveRowAtIndexPath:toIndexPath:) with:@selector(fwDynamicLayoutMoveRowAtIndexPath:toIndexPath:)];
    });
}

- (void)fwDynamicLayoutReloadData {
    // reloadData 时，清空缓存数据。
    if (self.fwIsDynamicLayoutInitialized) {
        [self fwSetupCacheArrayWithDataSource:self.dataSource];
    }
    [self fwDynamicLayoutReloadData];
}

- (void)fwDynamicLayoutInsertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.fwIsDynamicLayoutInitialized) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self fwSetupCacheArrayWithDataSource:self.dataSource];
    }
    [self fwDynamicLayoutInsertSections:sections withRowAnimation:animation];
}

- (void)fwDynamicLayoutDeleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.fwIsDynamicLayoutInitialized) {
        [sections enumerateIndexesWithOptions:(NSEnumerationReverse) usingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
            // cell
            [self.fwVerticalArray         removeObjectAtIndex:section];
            [self.fwHorizontalArray       removeObjectAtIndex:section];
            // header footer
            [self.fwHeaderVerticalArray   removeObjectAtIndex:section];
            [self.fwHeaderHorizontalArray removeObjectAtIndex:section];
            [self.fwFooterVerticalArray   removeObjectAtIndex:section];
            [self.fwFooterHorizontalArray removeObjectAtIndex:section];
        }];
    }
    [self fwDynamicLayoutDeleteSections:sections withRowAnimation:animation];
}

- (void)fwDynamicLayoutReloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.fwIsDynamicLayoutInitialized) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
            // 组的数据可能改变 需要重新获取组的行数
            NSInteger sectionCount = [self.dataSource tableView:self numberOfRowsInSection:section];
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:sectionCount];
            while (sectionCount-- > 0) {
                [arr addObject:FWDynamicLayoutDefaultHeight];
            }
            self.fwVerticalArray[section]   = arr.mutableCopy;
            self.fwHorizontalArray[section] = arr.mutableCopy;

            // header footer
            self.fwHeaderVerticalArray[section]   = FWDynamicLayoutDefaultHeight;
            self.fwHeaderHorizontalArray[section] = FWDynamicLayoutDefaultHeight;
            self.fwFooterVerticalArray[section]   = FWDynamicLayoutDefaultHeight;
            self.fwFooterHorizontalArray[section] = FWDynamicLayoutDefaultHeight;
        }];
    }
    [self fwDynamicLayoutReloadSections:sections withRowAnimation:animation];
}

- (void)fwDynamicLayoutMoveSection:(NSInteger)section toSection:(NSInteger)newSection {
    if (self.fwIsDynamicLayoutInitialized) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self fwSetupCacheArrayWithDataSource:self.dataSource];
    }
    [self fwDynamicLayoutMoveSection:section toSection:newSection];
}

- (void)fwDynamicLayoutInsertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.fwIsDynamicLayoutInitialized) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self fwSetupCacheArrayWithDataSource:self.dataSource];
    }
    [self fwDynamicLayoutInsertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)fwDynamicLayoutDeleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.fwIsDynamicLayoutInitialized) {
        NSMutableArray *tempIndexPaths = indexPaths.mutableCopy;
        [tempIndexPaths sortUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
            if (obj1.section == obj2.section) {
                return obj1.row < obj2.row;
            }
            return obj1.section < obj2.section;
        }];
        [tempIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.fwVerticalArray[obj.section]   removeObjectAtIndex:obj.row];
            [self.fwHorizontalArray[obj.section] removeObjectAtIndex:obj.row];
        }];
    }
    [self fwDynamicLayoutDeleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)fwDynamicLayoutReloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.fwIsDynamicLayoutInitialized) {
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            self.fwVerticalArray[obj.section][obj.row]   = FWDynamicLayoutDefaultHeight;
            self.fwHorizontalArray[obj.section][obj.row] = FWDynamicLayoutDefaultHeight;
        }];
    }
    [self fwDynamicLayoutReloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)fwDynamicLayoutMoveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    if (self.fwIsDynamicLayoutInitialized) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self fwSetupCacheArrayWithDataSource:self.dataSource];
    }
    [self fwDynamicLayoutMoveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
}

#pragma mark - Header

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwHeaderHeightDictionary {
    return FWDynamicLayoutIsVertical ? self.fwHeaderVerticalDictionary : self.fwHeaderHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwHeaderVerticalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwHeaderHorizontalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableArray<NSNumber *> *)fwHeaderHeightArray {
    return FWDynamicLayoutIsVertical ? self.fwHeaderVerticalArray : self.fwHeaderHorizontalArray;
}

- (NSMutableArray<NSNumber *> *)fwHeaderVerticalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (NSMutableArray<NSNumber *> *)fwHeaderHorizontalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

#pragma mark - Cell

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwHeightDictionary {
    return FWDynamicLayoutIsVertical ? self.fwVerticalDictionary : self.fwHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwVerticalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwHorizontalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)fwHeightArray {
    return FWDynamicLayoutIsVertical ? self.fwVerticalArray : self.fwHorizontalArray;
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)fwVerticalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (NSMutableArray<NSMutableArray <NSNumber *> *> *)fwHorizontalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

#pragma mark - Footer

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwFooterHeightDictionary {
    return FWDynamicLayoutIsVertical ? self.fwFooterVerticalDictionary : self.fwFooterHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwFooterVerticalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)fwFooterHorizontalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableArray<NSNumber *> *)fwFooterHeightArray {
    return FWDynamicLayoutIsVertical ? self.fwFooterVerticalArray : self.fwFooterHorizontalArray;
}

- (NSMutableArray<NSNumber *> *)fwFooterVerticalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (NSMutableArray<NSNumber *> *)fwFooterHorizontalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
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
    [self.fwVerticalArray removeAllObjects];
    [self.fwVerticalArray addObjectsFromArray:verticalArray.copy];

    [self.fwHorizontalArray removeAllObjects];
    [self.fwHorizontalArray addObjectsFromArray:horizontalArray.copy];
    [self fwSetupHeaderFooterCacheArrayWithSections:sections];
}

- (void)fwSetupHeaderFooterCacheArrayWithSections:(NSInteger)sections {
    // 2-1、竖屏状态下的 HeaderView 高度缓存
    // 2-2、横屏状态下的 HeaderView 高度缓存
    // 2-3、竖屏状态下的 FooterView 高度缓存
    // 2-4、横屏状态下的 FooterView 高度缓存
    [self.fwHeaderVerticalArray   removeAllObjects];
    [self.fwHeaderHorizontalArray removeAllObjects];
    [self.fwFooterVerticalArray   removeAllObjects];
    [self.fwFooterHorizontalArray removeAllObjects];
    NSInteger temp = 0;
    while (temp++ < sections) {
        [self.fwHeaderVerticalArray   addObject:FWDynamicLayoutDefaultHeight];
        [self.fwHeaderHorizontalArray addObject:FWDynamicLayoutDefaultHeight];
        [self.fwFooterVerticalArray   addObject:FWDynamicLayoutDefaultHeight];
        [self.fwFooterHorizontalArray addObject:FWDynamicLayoutDefaultHeight];
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

- (CGFloat)fwInnerHeightWithCellClass:(Class)clazz
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
    return [self fwInnerHeightWithCellClass:clazz configuration:configuration];
}

- (CGFloat)fwHeightWithCellClass:(Class)clazz
                 cacheByIndexPath:(NSIndexPath *)indexPath
                    configuration:(FWCellConfigurationBlock)configuration {
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
    NSNumber *number = self.fwHeightArray[indexPath.section][indexPath.row];
    if (number.doubleValue < 0.0) {
        CGFloat cellHeight = [self fwInnerHeightWithCellClass:clazz configuration:configuration];
        self.fwHeightArray[indexPath.section][indexPath.row] = @(cellHeight);
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
    if (key && self.fwHeightDictionary[key]) {
        return self.fwHeightDictionary[key].doubleValue;
    }
    CGFloat cellHeight = [self fwInnerHeightWithCellClass:clazz configuration:configuration];
    if (key) {
        self.fwHeightDictionary[key] = @(cellHeight);
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

- (CGFloat)fwInnerHeightWithHeaderFooterViewClass:(Class)clazz
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

- (CGFloat)fwInnerHeightWithHeaderViewClass:(Class)clazz
                        configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fwInnerHeightWithHeaderFooterViewClass:clazz sel:_cmd configuration:configuration];
}

- (CGFloat)fwInnerHeightWithFooterViewClass:(Class)clazz
                        configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    return [self fwInnerHeightWithHeaderFooterViewClass:clazz sel:_cmd configuration:configuration];
}

- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                         type:(FWHeaderFooterViewType)type
                                configuration:(FWHeaderFooterViewConfigurationBlock)configuration {
    if (__builtin_expect((!self.fwIsDynamicLayoutInitialized), 0)) {
        [self fwDynamicLayoutInitialize];
    }
    if (type == FWHeaderFooterViewTypeHeader) {
        return [self fwInnerHeightWithHeaderViewClass:clazz configuration:configuration];
    } else {
        return [self fwInnerHeightWithFooterViewClass:clazz configuration:configuration];
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
        NSNumber *number = self.fwHeaderHeightArray[section];
        if (number.doubleValue >= 0.0) {
            return number.doubleValue;
        }
        CGFloat height = [self fwInnerHeightWithHeaderViewClass:clazz configuration:configuration];
        self.fwHeaderHeightArray[section] = @(height);
        return height;
    } else {
        NSNumber *number = self.fwFooterHeightArray[section];
        if (number.doubleValue >= 0.0) {
            return number.doubleValue;
        }
        CGFloat height = [self fwInnerHeightWithFooterViewClass:clazz configuration:configuration];
        self.fwFooterHeightArray[section] = @(height);
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
        if (key && self.fwHeaderHeightDictionary[key]) {
            return self.fwHeaderHeightDictionary[key].doubleValue;
        }
        CGFloat cellHeight = [self fwInnerHeightWithHeaderViewClass:clazz configuration:configuration];
        if (key) {
            self.fwHeaderHeightDictionary[key] = @(cellHeight);
        }
        return cellHeight;
    } else {
        if (key && self.fwFooterHeightDictionary[key]) {
            return self.fwFooterHeightDictionary[key].doubleValue;
        }
        CGFloat cellHeight = [self fwInnerHeightWithFooterViewClass:clazz configuration:configuration];
        if (key) {
            self.fwFooterHeightDictionary[key] = @(cellHeight);
        }
        return cellHeight;
    }
}

@end
