/*!
 @header     UITableView+FWDynamicLayout.h
 @indexgroup FWFramework
 @brief      UITableView+FWDynamicLayout
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UITableViewCell+FWDynamicLayout

typedef void(^FWCellConfigurationBlock)(__kindof UITableViewCell *cell);

/*!
 @brief UITableViewCell+FWDynamicLayout
 */
@interface UITableViewCell (FWDynamicLayout)

/// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
@property (nonatomic, assign) BOOL fwMaxYViewFixed;

/// 最大Y视图的底部内边距，可避免新创建View来撑开Cell，默认0
@property (nonatomic, assign) CGFloat fwMaxYViewPadding;

/// 通用绑定视图模型方法，未指定configuration时默认调用
@property (nullable, nonatomic, strong) id fwViewModel;

/// 免注册创建UITableViewCell，内部自动处理缓冲池，默认Default类型
+ (instancetype)fwCellWithTableView:(UITableView *)tableView;

/// 免注册alloc创建UITableViewCell，内部自动处理缓冲池，指定style类型
+ (instancetype)fwCellWithTableView:(UITableView *)tableView
                              style:(UITableViewCellStyle)style;

/// 根据视图模型自动计算cell高度，不使用缓存，子类可重写
+ (CGFloat)fwHeightWithViewModel:(nullable id)viewModel
                       tableView:(UITableView *)tableView;

@end

#pragma mark - UITableViewHeaderFooterView+FWDynamicLayout

typedef NS_ENUM(NSInteger, FWHeaderFooterViewType) {
    FWHeaderFooterViewTypeHeader = 0,
    FWHeaderFooterViewTypeFooter = 1,
};

typedef void(^FWHeaderFooterViewConfigurationBlock)(__kindof UITableViewHeaderFooterView *headerFooterView);

/*!
 @brief UITableViewHeaderFooterView+FWDynamicLayout
 */
@interface UITableViewHeaderFooterView (FWDynamicLayout)

/// 如果用来确定HeaderFooterView所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
@property (nonatomic, assign) BOOL fwMaxYViewFixed;

/// 最大Y视图的底部内边距，可避免新创建View来撑开HeaderFooterView，默认0
@property (nonatomic, assign) CGFloat fwMaxYViewPadding;

/// 通用绑定视图模型方法，未指定configuration时默认调用
@property (nullable, nonatomic, strong) id fwViewModel;

/// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池
+ (instancetype)fwHeaderFooterViewWithTableView:(UITableView *)tableView;

/// 根据视图模型自动计算cell高度，不使用缓存，子类可重写
+ (CGFloat)fwHeightWithViewModel:(nullable id)viewModel
                            type:(FWHeaderFooterViewType)type
                       tableView:(UITableView *)tableView;

@end

#pragma mark - UITableView+FWDynamicLayout

/*!
 @brief 表格自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现

 @see https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight
*/
@interface UITableView (FWDynamicLayout)

/// 手工清空高度缓存，用于高度发生变化的情况
- (void)fwClearHeightCache;

#pragma mark - Cell

/// 获取 Cell 需要的高度，内部无缓存操作
/// @param clazz cell类
/// @param configuration 布局cell句柄，内部不会拥有Block，不需要__weak
/// @return cell高度
- (CGFloat)fwHeightWithCellClass:(Class)clazz
                   configuration:(FWCellConfigurationBlock)configuration;

/// 获取 Cell 需要的高度，内部自动处理缓存，缓存标识 indexPath
/// @param clazz cell class
/// @param indexPath 使用 indexPath 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGFloat)fwHeightWithCellClass:(Class)clazz
                cacheByIndexPath:(NSIndexPath *)indexPath
                   configuration:(FWCellConfigurationBlock)configuration;

/// 获取 Cell 需要的高度，内部自动处理缓存，缓存标识 key
/// @param clazz cell class
/// @param key 使用 key 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGFloat)fwHeightWithCellClass:(Class)clazz
                      cacheByKey:(nullable id<NSCopying>)key
                   configuration:(FWCellConfigurationBlock)configuration;

#pragma mark - HeaderFooterView

/// 获取 HeaderFooter 需要的高度，内部无缓存操作
/// @param clazz HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                        type:(FWHeaderFooterViewType)type
                               configuration:(FWHeaderFooterViewConfigurationBlock)configuration;

/// 获取 HeaderFooter 需要的高度，内部自动处理缓存，缓存标识 section
/// @param clazz HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param section 使用 section 做缓存标识
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                        type:(FWHeaderFooterViewType)type
                              cacheBySection:(NSInteger)section
                               configuration:(FWHeaderFooterViewConfigurationBlock)configuration;

/// 获取 HeaderFooter 需要的高度，内部自动处理缓存，缓存标识 key
/// @param clazz HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param key 使用 key 做缓存标识
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)fwHeightWithHeaderFooterViewClass:(Class)clazz
                                        type:(FWHeaderFooterViewType)type
                                  cacheByKey:(nullable id<NSCopying>)key
                               configuration:(FWHeaderFooterViewConfigurationBlock)configuration;

@end

NS_ASSUME_NONNULL_END
