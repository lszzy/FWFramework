//
//  FWDynamicLayout.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UITableViewCell+FWDynamicLayout

typedef void(^FWCellConfigurationBlock)(__kindof UITableViewCell *cell) NS_SWIFT_NAME(CellConfigurationBlock);
typedef void(^FWCellIndexPathBlock)(__kindof UITableViewCell *cell, NSIndexPath *indexPath) NS_SWIFT_NAME(CellIndexPathBlock);

@interface UITableViewCell (FWDynamicLayout)

/// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
@property (nonatomic, assign) BOOL fw_maxYViewFixed NS_REFINED_FOR_SWIFT;

/// 最大Y视图的底部内边距，可避免新创建View来撑开Cell，默认0
@property (nonatomic, assign) CGFloat fw_maxYViewPadding NS_REFINED_FOR_SWIFT;

/// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
@property (nonatomic, assign) BOOL fw_maxYViewExpanded NS_REFINED_FOR_SWIFT;

/// 免注册创建UITableViewCell，内部自动处理缓冲池，默认Default类型
+ (instancetype)fw_cellWithTableView:(UITableView *)tableView NS_REFINED_FOR_SWIFT;

/// 免注册alloc创建UITableViewCell，内部自动处理缓冲池，指定style类型
+ (instancetype)fw_cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style NS_REFINED_FOR_SWIFT;

/// 免注册alloc创建UITableViewCell，内部自动处理缓冲池，指定style类型，指定reuseIdentifier
+ (instancetype)fw_cellWithTableView:(UITableView *)tableView
                                          style:(UITableViewCellStyle)style
                                reuseIdentifier:(nullable NSString *)reuseIdentifier NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算cell高度，不使用缓存，子类可重写
+ (CGFloat)fw_heightWithTableView:(UITableView *)tableView
                 configuration:(NS_NOESCAPE FWCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UITableViewHeaderFooterView+FWDynamicLayout

typedef NS_ENUM(NSInteger, FWHeaderFooterViewType) {
    FWHeaderFooterViewTypeHeader = 0,
    FWHeaderFooterViewTypeFooter = 1,
} NS_SWIFT_NAME(HeaderFooterViewType);

typedef void(^FWHeaderFooterViewConfigurationBlock)(__kindof UITableViewHeaderFooterView *headerFooterView) NS_SWIFT_NAME(HeaderFooterViewConfigurationBlock);
typedef void(^FWHeaderFooterViewSectionBlock)(__kindof UITableViewHeaderFooterView *headerFooterView, NSInteger section) NS_SWIFT_NAME(HeaderFooterViewSectionBlock);

@interface UITableViewHeaderFooterView (FWDynamicLayout)

/// 如果用来确定HeaderFooterView所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
@property (nonatomic, assign) BOOL fw_maxYViewFixed NS_REFINED_FOR_SWIFT;

/// 最大Y视图的底部内边距，可避免新创建View来撑开HeaderFooterView，默认0
@property (nonatomic, assign) CGFloat fw_maxYViewPadding NS_REFINED_FOR_SWIFT;

/// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
@property (nonatomic, assign) BOOL fw_maxYViewExpanded NS_REFINED_FOR_SWIFT;

/// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池
+ (instancetype)fw_headerFooterViewWithTableView:(UITableView *)tableView NS_REFINED_FOR_SWIFT;

/// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池，指定reuseIdentifier
+ (instancetype)fw_headerFooterViewWithTableView:(UITableView *)tableView reuseIdentifier:(nullable NSString *)reuseIdentifier NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算cell高度，不使用缓存，子类可重写
+ (CGFloat)fw_heightWithTableView:(UITableView *)tableView
                          type:(FWHeaderFooterViewType)type
                 configuration:(NS_NOESCAPE FWHeaderFooterViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UITableView+FWDynamicLayout

/**
 表格自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现

 如果使用系统自动高度，建议设置estimatedRowHeight提高性能
 @see https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight
*/
@interface UITableView (FWDynamicLayout)

#pragma mark - Cache

/// 手工清空所有高度缓存，用于高度发生变化的情况
- (void)fw_clearHeightCache NS_REFINED_FOR_SWIFT;

/// 指定indexPath设置cell高度缓存，如willDisplayCell调用，height为cell.frame.size.height，设置为0时清除缓存
- (void)fw_setCellHeightCache:(CGFloat)height forIndexPath:(NSIndexPath *)indexPath NS_REFINED_FOR_SWIFT;

/// 指定key设置cell高度缓存，如willDisplayCell调用，height为cell.frame.size.height，设置为0时清除缓存
- (void)fw_setCellHeightCache:(CGFloat)height forKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

/// 指定indexPath获取cell缓存高度，如estimatedHeightForRow调用，默认值automaticDimension
- (CGFloat)fw_cellHeightCacheForIndexPath:(NSIndexPath *)indexPath NS_REFINED_FOR_SWIFT;

/// 指定key获取cell缓存高度，如estimatedHeightForRow调用，默认值automaticDimension
- (CGFloat)fw_cellHeightCacheForKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

/// 指定section设置HeaderFooter高度缓存，如willDisplayHeaderFooter调用，height为view.frame.size.height，设置为0时清除缓存
- (void)fw_setHeaderFooterHeightCache:(CGFloat)height type:(FWHeaderFooterViewType)type forSection:(NSInteger)section NS_REFINED_FOR_SWIFT;

/// 指定key设置HeaderFooter高度缓存，如willDisplayHeaderFooter调用，height为view.frame.size.height，设置为0时清除缓存
- (void)fw_setHeaderFooterHeightCache:(CGFloat)height type:(FWHeaderFooterViewType)type forKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

/// 指定section获取HeaderFooter缓存高度，如estimatedHeightForHeaderFooter调用，默认值automaticDimension
- (CGFloat)fw_headerFooterHeightCache:(FWHeaderFooterViewType)type forSection:(NSInteger)section NS_REFINED_FOR_SWIFT;

/// 指定key获取HeaderFooter缓存高度，如estimatedHeightForHeaderFooter调用，默认值automaticDimension
- (CGFloat)fw_headerFooterHeightCache:(FWHeaderFooterViewType)type forKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

#pragma mark - Cell

/// 获取 Cell 需要的高度，内部无缓存操作
/// @param clazz cell类
/// @param configuration 布局cell句柄，内部不会拥有Block，不需要__weak
/// @return cell高度
- (CGFloat)fw_heightWithCellClass:(Class)clazz
                 configuration:(NS_NOESCAPE FWCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的高度，内部自动处理缓存，缓存标识 indexPath
/// @param clazz cell class
/// @param indexPath 使用 indexPath 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGFloat)fw_heightWithCellClass:(Class)clazz
              cacheByIndexPath:(NSIndexPath *)indexPath
                 configuration:(NS_NOESCAPE FWCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的高度，内部自动处理缓存，缓存标识 key
/// @param clazz cell class
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGFloat)fw_heightWithCellClass:(Class)clazz
                    cacheByKey:(nullable id<NSCopying>)key
                 configuration:(NS_NOESCAPE FWCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

#pragma mark - HeaderFooterView

/// 获取 HeaderFooter 需要的高度，内部无缓存操作
/// @param clazz HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)fw_heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                             configuration:(NS_NOESCAPE FWHeaderFooterViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 HeaderFooter 需要的高度，内部自动处理缓存，缓存标识 section
/// @param clazz HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param section 使用 section 做缓存标识
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)fw_heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                            cacheBySection:(NSInteger)section
                             configuration:(NS_NOESCAPE FWHeaderFooterViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 HeaderFooter 需要的高度，内部自动处理缓存，缓存标识 key
/// @param clazz HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)fw_heightWithHeaderFooterViewClass:(Class)clazz
                                      type:(FWHeaderFooterViewType)type
                                cacheByKey:(nullable id<NSCopying>)key
                             configuration:(NS_NOESCAPE FWHeaderFooterViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UICollectionViewCell+FWDynamicLayout

typedef void(^FWCollectionCellConfigurationBlock)(__kindof UICollectionViewCell *cell) NS_SWIFT_NAME(CollectionCellConfigurationBlock);
typedef void(^FWCollectionCellIndexPathBlock)(__kindof UICollectionViewCell *cell, NSIndexPath *indexPath) NS_SWIFT_NAME(CollectionCellIndexPathBlock);

@interface UICollectionViewCell (FWDynamicLayout)

/// 如果用来确定Cell所需尺寸的View是唯一的，请把此值设置为YES，可提升一定的性能
@property (nonatomic, assign) BOOL fw_maxYViewFixed NS_REFINED_FOR_SWIFT;

/// 最大Y视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开Cell，默认0
@property (nonatomic, assign) CGFloat fw_maxYViewPadding NS_REFINED_FOR_SWIFT;

/// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
@property (nonatomic, assign) BOOL fw_maxYViewExpanded NS_REFINED_FOR_SWIFT;

/// 免注册创建UICollectionViewCell，内部自动处理缓冲池
+ (instancetype)fw_cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath NS_REFINED_FOR_SWIFT;

/// 免注册创建UICollectionViewCell，内部自动处理缓冲池，指定reuseIdentifier
+ (instancetype)fw_cellWithCollectionView:(UICollectionView *)collectionView
                               indexPath:(NSIndexPath *)indexPath
                         reuseIdentifier:(nullable NSString *)reuseIdentifier NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算view大小，子类可重写
+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                   configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算view大小，固定宽度，子类可重写
+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                           width:(CGFloat)width
                   configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算view大小，固定高度，子类可重写
+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                          height:(CGFloat)height
                   configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UICollectionReusableView+FWDynamicLayout

typedef void(^FWReusableViewConfigurationBlock)(__kindof UICollectionReusableView *reusableView) NS_SWIFT_NAME(ReusableViewConfigurationBlock);
typedef void(^FWReusableViewIndexPathBlock)(__kindof UICollectionReusableView *reusableView, NSIndexPath *indexPath) NS_SWIFT_NAME(ReusableViewIndexPathBlock);

@interface UICollectionReusableView (FWDynamicLayout)

/// 如果用来确定ReusableView所需尺寸的View是唯一的，请把此值设置为YES，可提升一定的性能
@property (nonatomic, assign) BOOL fw_maxYViewFixed NS_REFINED_FOR_SWIFT;

/// 最大Y尺寸视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开ReusableView，默认0
@property (nonatomic, assign) CGFloat fw_maxYViewPadding NS_REFINED_FOR_SWIFT;

/// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
@property (nonatomic, assign) BOOL fw_maxYViewExpanded NS_REFINED_FOR_SWIFT;

/// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池
+ (instancetype)fw_reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath NS_REFINED_FOR_SWIFT;

/// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池，指定reuseIdentifier
+ (instancetype)fw_reusableViewWithCollectionView:(UICollectionView *)collectionView
                                            kind:(NSString *)kind
                                       indexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(nullable NSString *)reuseIdentifier NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算view大小，子类可重写
+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                            kind:(NSString *)kind
                   configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算view大小，固定宽度，子类可重写
+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                           width:(CGFloat)width
                            kind:(NSString *)kind
                   configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 根据配置自动计算view大小，固定高度，子类可重写
+ (CGSize)fw_sizeWithCollectionView:(UICollectionView *)collectionView
                          height:(CGFloat)height
                            kind:(NSString *)kind
                   configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UICollectionView+FWDynamicLayout

/**
 集合自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
 
 如果使用系统自动尺寸，建议设置estimatedItemSize提高性能
*/
@interface UICollectionView (FWDynamicLayout)

#pragma mark - Cache

/// 手工清空尺寸缓存，用于尺寸发生变化的情况
- (void)fw_clearSizeCache NS_REFINED_FOR_SWIFT;

/// 指定indexPath设置cell尺寸缓存，设置为zero时清除缓存
- (void)fw_setCellSizeCache:(CGSize)size forIndexPath:(NSIndexPath *)indexPath NS_REFINED_FOR_SWIFT;

/// 指定key设置cell尺寸缓存，设置为zero时清除缓存
- (void)fw_setCellSizeCache:(CGSize)size forKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

/// 指定indexPath获取cell缓存尺寸，默认值automaticSize
- (CGSize)fw_cellSizeCacheForIndexPath:(NSIndexPath *)indexPath NS_REFINED_FOR_SWIFT;

/// 指定key获取cell缓存尺寸，默认值automaticSize
- (CGSize)fw_cellSizeCacheForKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

/// 指定section设置ReusableView尺寸缓存，设置为zero时清除缓存
- (void)fw_setReusableViewSizeCache:(CGSize)size kind:(NSString *)kind forSection:(NSInteger)section NS_REFINED_FOR_SWIFT;

/// 指定key设置ReusableView尺寸缓存，设置为zero时清除缓存
- (void)fw_setReusableViewSizeCache:(CGSize)size kind:(NSString *)kind forKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

/// 指定section获取ReusableView缓存尺寸，默认值automaticSize
- (CGSize)fw_reusableViewSizeCache:(NSString *)kind forSection:(NSInteger)section NS_REFINED_FOR_SWIFT;

/// 指定key获取ReusableView缓存尺寸，默认值automaticSize
- (CGSize)fw_reusableViewSizeCache:(NSString *)kind forKey:(id<NSCopying>)key NS_REFINED_FOR_SWIFT;

#pragma mark - Cell

/// 获取 Cell 需要的尺寸，内部无缓存操作
/// @param clazz cell类
/// @param configuration 布局cell句柄，内部不会拥有Block，不需要__weak
/// @return cell尺寸
- (CGSize)fw_sizeWithCellClass:(Class)clazz
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，固定宽度，内部无缓存操作
/// @param clazz cell类
/// @param width 固定宽度
/// @param configuration 布局cell句柄，内部不会拥有Block，不需要__weak
/// @return cell尺寸
- (CGSize)fw_sizeWithCellClass:(Class)clazz
                      width:(CGFloat)width
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，固定高度，内部无缓存操作
/// @param clazz cell类
/// @param height 固定高度
/// @param configuration 布局cell句柄，内部不会拥有Block，不需要__weak
/// @return cell尺寸
- (CGSize)fw_sizeWithCellClass:(Class)clazz
                     height:(CGFloat)height
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，内部自动处理缓存，缓存标识 indexPath
/// @param clazz cell class
/// @param indexPath 使用 indexPath 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithCellClass:(Class)clazz
           cacheByIndexPath:(NSIndexPath *)indexPath
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 indexPath
/// @param clazz cell class
/// @param width 固定宽度
/// @param indexPath 使用 indexPath 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithCellClass:(Class)clazz
                      width:(CGFloat)width
           cacheByIndexPath:(NSIndexPath *)indexPath
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 indexPath
/// @param clazz cell class
/// @param height 固定高度
/// @param indexPath 使用 indexPath 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithCellClass:(Class)clazz
                     height:(CGFloat)height
           cacheByIndexPath:(NSIndexPath *)indexPath
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，内部自动处理缓存，缓存标识 key
/// @param clazz cell class
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithCellClass:(Class)clazz
                 cacheByKey:(nullable id<NSCopying>)key
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 key
/// @param clazz cell class
/// @param width 固定宽度
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithCellClass:(Class)clazz
                      width:(CGFloat)width
                 cacheByKey:(nullable id<NSCopying>)key
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 Cell 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 key
/// @param clazz cell class
/// @param height 固定高度
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithCellClass:(Class)clazz
                     height:(CGFloat)height
                 cacheByKey:(nullable id<NSCopying>)key
              configuration:(NS_NOESCAPE FWCollectionCellConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

#pragma mark - ReusableView

/// 获取 ReusableView 需要的尺寸，内部无缓存操作
/// @param clazz ReusableView class
/// @param kind ReusableView类型，Header 或者 Footer
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                               kind:(NSString *)kind
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，固定宽度，内部无缓存操作
/// @param clazz ReusableView class
/// @param width 固定宽度
/// @param kind ReusableView类型，Header 或者 Footer
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                              width:(CGFloat)width
                               kind:(NSString *)kind
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，固定高度，内部无缓存操作
/// @param clazz ReusableView class
/// @param height 固定高度
/// @param kind ReusableView类型，Header 或者 Footer
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                             height:(CGFloat)height
                               kind:(NSString *)kind
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，内部自动处理缓存，缓存标识 section
/// @param clazz ReusableView class
/// @param kind ReusableView类型，Header 或者 Footer
/// @param section 使用 section 做缓存标识
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                               kind:(NSString *)kind
                     cacheBySection:(NSInteger)section
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 section
/// @param clazz ReusableView class
/// @param width 固定宽度
/// @param kind ReusableView类型，Header 或者 Footer
/// @param section 使用 section 做缓存标识
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                              width:(CGFloat)width
                               kind:(NSString *)kind
                     cacheBySection:(NSInteger)section
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 section
/// @param clazz ReusableView class
/// @param height 固定高度
/// @param kind ReusableView类型，Header 或者 Footer
/// @param section 使用 section 做缓存标识
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                             height:(CGFloat)height
                               kind:(NSString *)kind
                     cacheBySection:(NSInteger)section
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，内部自动处理缓存，缓存标识 key
/// @param clazz ReusableView class
/// @param kind ReusableView类型，Header 或者 Footer
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                               kind:(NSString *)kind
                         cacheByKey:(nullable id<NSCopying>)key
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 key
/// @param clazz ReusableView class
/// @param width 固定宽度
/// @param kind ReusableView类型，Header 或者 Footer
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                              width:(CGFloat)width
                               kind:(NSString *)kind
                         cacheByKey:(nullable id<NSCopying>)key
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

/// 获取 ReusableView 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 key
/// @param clazz ReusableView class
/// @param height 固定高度
/// @param kind ReusableView类型，Header 或者 Footer
/// @param key 使用 key 做缓存标识，如数据唯一id，对象hash等
/// @param configuration 布局 ReusableView，内部不会拥有 Block，不需要 __weak
- (CGSize)fw_sizeWithReusableViewClass:(Class)clazz
                             height:(CGFloat)height
                               kind:(NSString *)kind
                         cacheByKey:(nullable id<NSCopying>)key
                      configuration:(NS_NOESCAPE FWReusableViewConfigurationBlock)configuration NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
