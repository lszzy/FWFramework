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

// 兼容 Swift
#define kSwiftClassNibName(clasName) ([clasName rangeOfString:@"."].location != NSNotFound ? [clasName componentsSeparatedByString:@"."].lastObject : clasName)

/// 内部使用到的分类。
@interface UITableView (BMPrivate)

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *heightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSMutableArray <NSNumber *> *> *heightArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerHeightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *headerHeightArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerHeightDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *footerHeightArray;

/// 是否已经初始化过。
@property (nonatomic, assign, readonly) BOOL isDynamicLayoutInitializationed;

- (void)bm_dynamicLayoutInitialization;

@end

#define kIS_VERTICAL (UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width)
#define kDefaultHeight @(-1.0)

@interface UITableView (__BMPrivate__)

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerVerticalDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *headerHorizontalDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *headerVerticalArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *headerHorizontalArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *verticalDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *horizontalDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSMutableArray <NSNumber *> *> *verticalArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSMutableArray <NSNumber *> *> *horizontalArray;

@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerVerticalDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary <id<NSCopying>, NSNumber *> *footerHorizontalDictionary;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *footerVerticalArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *footerHorizontalArray;

@end

@implementation UITableView (BMPrivate)

#pragma mark - header property

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)headerHeightDictionary {
    return kIS_VERTICAL ? self.headerVerticalDictionary : self.headerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)headerVerticalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)headerHorizontalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableArray<NSNumber *> *)headerHeightArray {
    return kIS_VERTICAL ? self.headerVerticalArray : self.headerHorizontalArray;
}

- (NSMutableArray<NSNumber *> *)headerVerticalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (NSMutableArray<NSNumber *> *)headerHorizontalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

#pragma mark - cell property

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)heightDictionary {
    return kIS_VERTICAL ? self.verticalDictionary : self.horizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)verticalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)horizontalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)heightArray {
    return kIS_VERTICAL ? self.verticalArray : self.horizontalArray;
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)verticalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (NSMutableArray<NSMutableArray <NSNumber *> *> *)horizontalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

#pragma mark - footer property

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)footerHeightDictionary {
    return kIS_VERTICAL ? self.footerVerticalDictionary : self.footerHorizontalDictionary;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)footerVerticalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableDictionary<id<NSCopying>, NSNumber *> *)footerHorizontalDictionary {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((dict == nil), 0)) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (NSMutableArray<NSNumber *> *)footerHeightArray {
    return kIS_VERTICAL ? self.footerVerticalArray : self.footerHorizontalArray;
}

- (NSMutableArray<NSNumber *> *)footerVerticalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (NSMutableArray<NSNumber *> *)footerHorizontalArray {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (__builtin_expect((arr == nil), 0)) {
        arr = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (BOOL)isDynamicLayoutInitializationed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)bm_dynamicLayoutInitialization {
    [self _initCacheArrayWithDataSource:self.dataSource];
    objc_setAssociatedObject(self, @selector(isDynamicLayoutInitializationed), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - load

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {

            @selector(reloadData),

            @selector(insertSections:withRowAnimation:),
            @selector(deleteSections:withRowAnimation:),
            @selector(reloadSections:withRowAnimation:),
            @selector(moveSection:toSection:),

            @selector(insertRowsAtIndexPaths:withRowAnimation:),
            @selector(deleteRowsAtIndexPaths:withRowAnimation:),
            @selector(reloadRowsAtIndexPaths:withRowAnimation:),
            @selector(moveRowAtIndexPath:toIndexPath:)
        };

        for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
            SEL originalSelector = selectors[index];
            SEL swizzledSelector = NSSelectorFromString([@"tableView_dynamicLayout_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
            Method originalMethod = class_getInstanceMethod(self, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)tableView_dynamicLayout_reloadData {
    // reloadData 时，清空缓存数据。
    if (self.isDynamicLayoutInitializationed) {
        [self _initCacheArrayWithDataSource:self.dataSource];
    }
    [self tableView_dynamicLayout_reloadData];
}

- (void)tableView_dynamicLayout_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.isDynamicLayoutInitializationed) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self _initCacheArrayWithDataSource:self.dataSource];
    }
    [self tableView_dynamicLayout_insertSections:sections withRowAnimation:animation];
}

- (void)tableView_dynamicLayout_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.isDynamicLayoutInitializationed) {
        [sections enumerateIndexesWithOptions:(NSEnumerationReverse) usingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
            // cell
            [self.verticalArray         removeObjectAtIndex:section];
            [self.horizontalArray       removeObjectAtIndex:section];
            // header footer
            [self.headerVerticalArray   removeObjectAtIndex:section];
            [self.headerHorizontalArray removeObjectAtIndex:section];
            [self.footerVerticalArray   removeObjectAtIndex:section];
            [self.footerHorizontalArray removeObjectAtIndex:section];
        }];
    }
    [self tableView_dynamicLayout_deleteSections:sections withRowAnimation:animation];
}

- (void)tableView_dynamicLayout_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.isDynamicLayoutInitializationed) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
            // 组的数据可能改变 需要重新获取组的行数
            NSInteger sectionCount = [self.dataSource tableView:self numberOfRowsInSection:section];
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:sectionCount];
            while (sectionCount-- > 0) {
                [arr addObject:kDefaultHeight];
            }
            self.verticalArray[section]   = arr.mutableCopy;
            self.horizontalArray[section] = arr.mutableCopy;

            // header footer
            self.headerVerticalArray[section]   = kDefaultHeight;
            self.headerHorizontalArray[section] = kDefaultHeight;
            self.footerVerticalArray[section]   = kDefaultHeight;
            self.footerHorizontalArray[section] = kDefaultHeight;
        }];
    }
    [self tableView_dynamicLayout_reloadSections:sections withRowAnimation:animation];
}

- (void)tableView_dynamicLayout_moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    if (self.isDynamicLayoutInitializationed) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self _initCacheArrayWithDataSource:self.dataSource];
    }
    [self tableView_dynamicLayout_moveSection:section toSection:newSection];
}

- (void)tableView_dynamicLayout_insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.isDynamicLayoutInitializationed) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self _initCacheArrayWithDataSource:self.dataSource];
    }
    [self tableView_dynamicLayout_insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)tableView_dynamicLayout_deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.isDynamicLayoutInitializationed) {
        NSMutableArray *tempIndexPaths = indexPaths.mutableCopy;
        [tempIndexPaths sortUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
            if (obj1.section == obj2.section) {
                return obj1.row < obj2.row;
            }
            return obj1.section < obj2.section;
        }];
        [tempIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.verticalArray[obj.section]   removeObjectAtIndex:obj.row];
            [self.horizontalArray[obj.section] removeObjectAtIndex:obj.row];
        }];
    }
    [self tableView_dynamicLayout_deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)tableView_dynamicLayout_reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.isDynamicLayoutInitializationed) {
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            self.verticalArray[obj.section][obj.row]   = kDefaultHeight;
            self.horizontalArray[obj.section][obj.row] = kDefaultHeight;
        }];
    }
    [self tableView_dynamicLayout_reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)tableView_dynamicLayout_moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    if (self.isDynamicLayoutInitializationed) {
        // 清空缓存数据，这里可以优化，由于需要考虑太多的情况，暂时没有提供全面的测试方法，暂时直接全部刷新。
        [self _initCacheArrayWithDataSource:self.dataSource];
    }
    [self tableView_dynamicLayout_moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
}

#pragma mark - Private Method

- (void)_initCacheArrayWithDataSource:(id<UITableViewDataSource>)dataSource {
    if (!dataSource) {
        return;
    }
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
            [arr addObject:kDefaultHeight];
        }
        [verticalArray addObject:arr];
        [horizontalArray addObject:arr.mutableCopy];
        tempSections++;
    }
    [self.verticalArray removeAllObjects];
    [self.verticalArray addObjectsFromArray:verticalArray.copy];

    [self.horizontalArray removeAllObjects];
    [self.horizontalArray addObjectsFromArray:horizontalArray.copy];
    [self _initHeaderFooterCacheArrayWithSections:sections];
}

- (void)_initHeaderFooterCacheArrayWithSections:(NSInteger)sections {
    // 2-1、竖屏状态下的 HeaderView 高度缓存
    // 2-2、横屏状态下的 HeaderView 高度缓存
    // 2-3、竖屏状态下的 FooterView 高度缓存
    // 2-4、横屏状态下的 FooterView 高度缓存
    [self.headerVerticalArray   removeAllObjects];
    [self.headerHorizontalArray removeAllObjects];
    [self.footerVerticalArray   removeAllObjects];
    [self.footerHorizontalArray removeAllObjects];
    NSInteger temp = 0;
    while (temp++ < sections) {
        [self.headerVerticalArray   addObject:kDefaultHeight];
        [self.headerHorizontalArray addObject:kDefaultHeight];
        [self.footerVerticalArray   addObject:kDefaultHeight];
        [self.footerHorizontalArray addObject:kDefaultHeight];
    }
}

@end

@implementation UITableViewCell (BMDynamicLayout)

- (BOOL)bm_maxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBm_maxYViewFixed:(BOOL)bm_maxYViewFixed {
    objc_setAssociatedObject(self, @selector(bm_maxYViewFixed), @(bm_maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)bm_tableViewCellFromNibWithTableView:(UITableView *)tableView {
    NSString *selfClassName = NSStringFromClass(self.class);
    NSString *reuseIdentifier = [selfClassName stringByAppendingString:@"BMNibDynamicLayoutReuseIdentifier"];

    if ([objc_getAssociatedObject(tableView, (__bridge const void * _Nonnull)(self)) boolValue]) {
        // 已注册
        return [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    }
    // 未注册，开始注册
    UINib *nib = [UINib nibWithNibName:kSwiftClassNibName(selfClassName) bundle:[NSBundle bundleForClass:self.class]];
    [tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, (__bridge const void * _Nonnull)(self), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
}

+ (instancetype)bm_tableViewCellFromAllocWithTableView:(UITableView *)tableView {
    return [self bm_tableViewCellFromAllocWithTableView:tableView style:(UITableViewCellStyleDefault)];
}

+ (instancetype)bm_tableViewCellFromAllocWithTableView:(UITableView *)tableView style:(UITableViewCellStyle)style {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"BMAllocDynamicLayoutReuseIdentifier"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) {
        return cell;
    }
    return [[self alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
}

@end

@implementation UITableViewHeaderFooterView (BMDynamicLayout)

- (BOOL)bm_maxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBm_maxYViewFixed:(BOOL)bm_maxYViewFixed {
    objc_setAssociatedObject(self, @selector(bm_maxYViewFixed), @(bm_maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)bm_tableViewHeaderFooterViewFromNibWithTableView:(UITableView *)tableView {
    NSString *selfClassName = NSStringFromClass(self.class);
    NSString *reuseIdentifier = [selfClassName stringByAppendingString:@"BMNibDynamicLayoutReuseIdentifier"];
    if ([objc_getAssociatedObject(tableView, (__bridge const void * _Nonnull)(object_getClass(self))) boolValue]) {
        // 已注册
        return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    }
    // 未注册，开始注册
    UINib *nib = [UINib nibWithNibName:kSwiftClassNibName(selfClassName) bundle:[NSBundle bundleForClass:self.class]];
    [tableView registerNib:nib forHeaderFooterViewReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, (__bridge const void * _Nonnull)(object_getClass(self)), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
}

+ (instancetype)bm_tableViewHeaderFooterViewFromAllocWithTableView:(UITableView *)tableView {
    NSString *selfClassName = NSStringFromClass(self.class);
    NSString *reuseIdentifier = [selfClassName stringByAppendingString:@"BMAllocDynamicLayoutReuseIdentifier"];
    if ([objc_getAssociatedObject(tableView, (__bridge const void * _Nonnull)(self)) boolValue]) {
        // 已注册
        return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    }
    // 未注册，开始注册
    [tableView registerClass:self forHeaderFooterViewReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, (__bridge const void * _Nonnull)(self), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
}

@end

void tableViewDynamicLayoutLayoutIfNeeded(UIView *view);
inline void tableViewDynamicLayoutLayoutIfNeeded(UIView *view) {
    // https://juejin.im/post/5a30f24bf265da432e5c0070/
    // https://objccn.io/issue-3-5/
    // http://tech.gc.com/demystifying-ios-layout/
    [view setNeedsLayout];
    [view layoutIfNeeded];
}

#pragma mark - UITableViewCell BMDynamicLayoutPrivate

@interface UITableViewCell (BMDynamicLayoutPrivate)

@property (nonatomic, strong) UIView *dynamicLayout_maxYView;

@end

@implementation UITableViewCell (BMDynamicLayoutPrivate)

- (UIView *)dynamicLayout_maxYView {
    return objc_getAssociatedObject(self, @selector(setDynamicLayout_maxYView:));
}

- (void)setDynamicLayout_maxYView:(UIView *)dynamicLayout_maxYView {
    objc_setAssociatedObject(self, _cmd, dynamicLayout_maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UITableViewHeaderFooterView BMDynamicLayoutPrivate

@interface UITableViewHeaderFooterView (BMDynamicLayoutPrivate)

@property (nonatomic, strong) UIView *dynamicLayout_maxYView;

@end

@implementation UITableViewHeaderFooterView (BMDynamicLayoutPrivate)

- (UIView *)dynamicLayout_maxYView {
    return objc_getAssociatedObject(self, @selector(setDynamicLayout_maxYView:));
}

- (void)setDynamicLayout_maxYView:(UIView *)dynamicLayout_maxYView {
    objc_setAssociatedObject(self, _cmd, dynamicLayout_maxYView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UITableView BMDynamicLayout

@implementation UITableView (BMDynamicLayout)

#pragma mark - private cell

- (UIView *)_cellViewWithCellClass:(Class)clas {
    NSString *cellClassName = NSStringFromClass(clas);

    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[cellClassName];
    if (view) {
        // 直接返回
        return view;
    }
    
    NSBundle *bundle = [NSBundle bundleForClass:clas];
    NSString *path = [bundle pathForResource:kSwiftClassNibName(cellClassName) ofType:@"nib"];
    UITableViewCell *cell = nil;
    if (path.length > 0) {
        NSArray <UITableViewCell *> *arr = [[UINib nibWithNibName:kSwiftClassNibName(cellClassName) bundle:bundle] instantiateWithOwner:nil options:nil];
        for (UITableViewCell *obj in arr) {
            if ([obj isMemberOfClass:clas]) {
                cell = obj;
                // 清空 reuseIdentifier
                [cell setValue:nil forKey:@"reuseIdentifier"];
                break;
            }
        }
    }
    if (!cell) {
        // 这里使用默认的 UITableViewCellStyleDefault 类型。
        // 如果需要自定义高度，通常都是使用的此类型, 暂时不考虑其他。
        cell = [[clas alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    view = [UIView new];
    [view addSubview:cell];
    dict[cellClassName] = view;
    return view;
}

- (CGFloat)_heightWithCellClass:(Class)clas
                  configuration:(BMConfigurationCellBlock)configuration {
    UIView *view = [self _cellViewWithCellClass:clas];
    // 获取 TableView 宽度
    UIView *temp = self.superview ? self.superview : self;
    tableViewDynamicLayoutLayoutIfNeeded(temp);
    CGFloat width = CGRectGetWidth(self.frame);

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0, 0.0, width, 0.0);

    // 让外面布局 Cell
    !configuration ? : configuration(cell);

    // 刷新布局
    tableViewDynamicLayoutLayoutIfNeeded(view);

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    if (cell.bm_maxYViewFixed) {
        if (cell.dynamicLayout_maxYView) {
            return CGRectGetMaxY(cell.dynamicLayout_maxYView.frame);
        }
        __block UIView *maxXView = nil;
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
                maxXView = obj;
            }
        }];
        cell.dynamicLayout_maxYView = maxXView;
        return maxY;
    }
    [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat tempY = CGRectGetMaxY(obj.frame);
        if (tempY > maxY) {
            maxY = tempY;
        }
    }];
    return maxY;
}

#pragma mark - private HeaderFooterView

- (UIView *)_headerFooterViewWithHeaderFooterViewClass:(Class)clas
                                                   sel:(SEL)sel {
    NSString *headerFooterViewClassName = NSStringFromClass(clas);

    NSMutableDictionary *dict = objc_getAssociatedObject(self, sel);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, sel, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *view = dict[headerFooterViewClassName];
    if (view) {
        // 直接返回
        return view;
    }

    NSBundle *bundle = [NSBundle bundleForClass:clas];
    NSString *path = [bundle pathForResource:kSwiftClassNibName(headerFooterViewClassName) ofType:@"nib"];
    UIView *headerView = nil;
    if (path.length > 0) {
        NSArray <UITableViewHeaderFooterView *> *arr = [[UINib nibWithNibName:kSwiftClassNibName(headerFooterViewClassName) bundle:bundle] instantiateWithOwner:nil options:nil];
        for (UITableViewHeaderFooterView *obj in arr) {
            if ([obj isMemberOfClass:clas]) {
                headerView = obj;
                // 清空 reuseIdentifier
                [headerView setValue:nil forKey:@"reuseIdentifier"];
                break;
            }
        }
    }
    if (!headerView) {
        headerView = [[clas alloc] initWithReuseIdentifier:nil];
    }
    view = [UIView new];
    [view addSubview:headerView];
    dict[headerFooterViewClassName] = view;
    return view;
}

- (CGFloat)_heightWithHeaderFooterViewClass:(Class)clas
                                        sel:(SEL)sel
                              configuration:(BMConfigurationHeaderFooterViewBlock)configuration {
    UIView *view = [self _headerFooterViewWithHeaderFooterViewClass:clas sel:sel];
    // 获取 TableView 宽度
    UIView *temp = self.superview ? self.superview : self;
    tableViewDynamicLayoutLayoutIfNeeded(temp);
    CGFloat width = CGRectGetWidth(self.frame);

    // 设置 Frame
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    UITableViewHeaderFooterView *headerFooterView = view.subviews.firstObject;
    headerFooterView.frame = CGRectMake(0.0, 0.0, width, 0.0);

    // 让外面布局 UITableViewHeaderFooterView
    !configuration ? : configuration(headerFooterView);
    // 刷新布局
    tableViewDynamicLayoutLayoutIfNeeded(view);

    UIView *contentView = headerFooterView.contentView.subviews.count ? headerFooterView.contentView : headerFooterView;

    // 获取需要的高度
    __block CGFloat maxY  = 0.0;
    if (headerFooterView.bm_maxYViewFixed) {
        if (headerFooterView.dynamicLayout_maxYView) {
            return CGRectGetMaxY(headerFooterView.dynamicLayout_maxYView.frame);
        }
        __block UIView *maxXView = nil;
        [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
                maxXView = obj;
            }
        }];
        headerFooterView.dynamicLayout_maxYView = maxXView;
        return maxY;
    }
    [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat tempY = CGRectGetMaxY(obj.frame);
        if (tempY > maxY) {
            maxY = tempY;
        }
    }];
    return maxY;
}

- (CGFloat)_heightWithHeaderViewClass:(Class)clas
                        configuration:(BMConfigurationHeaderFooterViewBlock)configuration {
    return [self _heightWithHeaderFooterViewClass:clas sel:_cmd configuration:configuration];
}

- (CGFloat)_heightWithFooterViewClass:(Class)clas
                        configuration:(BMConfigurationHeaderFooterViewBlock)configuration {
    return [self _heightWithHeaderFooterViewClass:clas sel:_cmd configuration:configuration];
}

#pragma mark - Public cell

- (CGFloat)bm_heightWithCellClass:(Class)clas
                    configuration:(BMConfigurationCellBlock)configuration {
    if (__builtin_expect((!self.isDynamicLayoutInitializationed), 0)) {
        [self bm_dynamicLayoutInitialization];
    }
    return [self _heightWithCellClass:clas configuration:configuration];
}

- (CGFloat)bm_heightWithCellClass:(Class)clas
                 cacheByIndexPath:(NSIndexPath *)indexPath
                    configuration:(BMConfigurationCellBlock)configuration {
    if (__builtin_expect((!self.isDynamicLayoutInitializationed), 0)) {
        [self bm_dynamicLayoutInitialization];
    }
    NSNumber *number = self.heightArray[indexPath.section][indexPath.row];
    if (number.doubleValue < 0.0) {
        // 没有缓存
        // 计算高度
        CGFloat cellHeight = [self _heightWithCellClass:clas configuration:configuration];
        // 缓存高度
        self.heightArray[indexPath.section][indexPath.row] = @(cellHeight);
        return cellHeight;
    }
    return number.doubleValue;
}

- (CGFloat)bm_heightWithCellClass:(Class)clas
                       cacheByKey:(id<NSCopying>)key
                    configuration:(BMConfigurationCellBlock)configuration {
    if (__builtin_expect((!self.isDynamicLayoutInitializationed), 0)) {
        [self bm_dynamicLayoutInitialization];
    }
    if (key && self.heightDictionary[key]) {
        return self.heightDictionary[key].doubleValue;
    }
    CGFloat cellHeight = [self _heightWithCellClass:clas configuration:configuration];
    if (key) {
        self.heightDictionary[key] = @(cellHeight);
    }
    return cellHeight;
}

#pragma mark - Public HeaderFooter

- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                                configuration:(BMConfigurationHeaderFooterViewBlock)configuration {
    if (__builtin_expect((!self.isDynamicLayoutInitializationed), 0)) {
        [self bm_dynamicLayoutInitialization];
    }
    if (type == BMHeaderFooterViewDynamicLayoutTypeHeader) {
        return [self _heightWithHeaderViewClass:clas configuration:configuration];
    }
    return [self _heightWithFooterViewClass:clas configuration:configuration];
}

- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                               cacheBySection:(NSInteger)section
                                configuration:(BMConfigurationHeaderFooterViewBlock)configuration {
    if (__builtin_expect((!self.isDynamicLayoutInitializationed), 0)) {
        [self bm_dynamicLayoutInitialization];
    }
    if (type == BMHeaderFooterViewDynamicLayoutTypeHeader) {
        NSNumber *number = self.headerHeightArray[section];
        if (number.doubleValue >= 0.0) {
            return number.doubleValue;
        }
        // not cache
        // get cache height
        CGFloat height = [self _heightWithHeaderViewClass:clas configuration:configuration];
        // save cache height
        self.headerHeightArray[section] = @(height);
        return height;
    }
    NSNumber *number = self.footerHeightArray[section];
    if (number.doubleValue >= 0.0) {
        return number.doubleValue;
    }
    // not cache
    // get cache height
    CGFloat height = [self _heightWithFooterViewClass:clas configuration:configuration];
    // save cache height
    self.footerHeightArray[section] = @(height);
    return height;
}

- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                                   cacheByKey:(id<NSCopying>)key
                                configuration:(BMConfigurationHeaderFooterViewBlock)configuration {
    if (__builtin_expect((!self.isDynamicLayoutInitializationed), 0)) {
        [self bm_dynamicLayoutInitialization];
    }
    if (type == BMHeaderFooterViewDynamicLayoutTypeHeader) {
        if (key && self.headerHeightDictionary[key]) {
            return self.headerHeightDictionary[key].doubleValue;
        }
        CGFloat cellHeight = [self _heightWithHeaderViewClass:clas configuration:configuration];
        if (key) {
            self.heightDictionary[key] = @(cellHeight);
        }
        return cellHeight;

    }
    if (key && self.footerHeightDictionary[key]) {
        return self.footerHeightDictionary[key].doubleValue;
    }
    CGFloat cellHeight = [self _heightWithFooterViewClass:clas configuration:configuration];
    if (key) {
        self.footerHeightDictionary[key] = @(cellHeight);
    }
    return cellHeight;
}

@end
