/*!
 @header     UITableView+FWDynamicLayout.h
 @indexgroup FWFramework
 @brief      UITableView+FWDynamicLayout
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/14
 */

#import <UIKit/UIKit.h>

@interface UITableViewCell (BMDynamicLayout)

/// 如果你的 Cell 中用来确定 Cell 所需高度的 View 是唯一的,
/// 请把此值设置为 YES，可提升一定的性能。
@property (nonatomic, assign) IBInspectable BOOL bm_maxYViewFixed;

/// 免注册 IB 创建 UITableViewCell，内部自动处理缓冲池。
/// @param tableView tableView
+ (instancetype)bm_tableViewCellFromNibWithTableView:(UITableView *)tableView;

/// 免注册 alloc 创建 UITableViewCell，内部自动处理缓冲池, 默认 UITableViewCellStyleDefault 类型
/// @param tableView tableView
+ (instancetype)bm_tableViewCellFromAllocWithTableView:(UITableView *)tableView;

/// 免注册 alloc 创建 UITableViewCell，内部自动处理缓冲池。
/// @param tableView tableView
/// @param style cell style
+ (instancetype)bm_tableViewCellFromAllocWithTableView:(UITableView *)tableView style:(UITableViewCellStyle)style;

@end

@interface UITableViewHeaderFooterView (BMDynamicLayout)

/// 如果你的 HeaderFooterView 中用来确定 HeaderFooterView 所需高度的 View 是唯一的,
/// 请把此值设置为 YES，可提升一定的性能。
@property (nonatomic, assign) IBInspectable BOOL bm_maxYViewFixed;

/// 免注册 IB 创建 UITableViewHeaderFooterView，内部自动处理缓冲池。
/// @param tableView tableView
+ (instancetype)bm_tableViewHeaderFooterViewFromNibWithTableView:(UITableView *)tableView;

/// 免注册 alloc 创建 UITableViewHeaderFooterView，内部自动处理缓冲池。
/// @param tableView tableView
+ (instancetype)bm_tableViewHeaderFooterViewFromAllocWithTableView:(UITableView *)tableView;

@end

typedef NS_ENUM(NSInteger, BMHeaderFooterViewDynamicLayoutType) {
    BMHeaderFooterViewDynamicLayoutTypeHeader = 0,
    BMHeaderFooterViewDynamicLayoutTypeFooter = 1,
};

typedef void(^BMConfigurationCellBlock)(__kindof UITableViewCell *cell);
typedef void(^BMConfigurationHeaderFooterViewBlock)(__kindof UITableViewHeaderFooterView *headerFooterView);

/*!
 @brief 表格自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现

 @see https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight
*/
@interface UITableView (BMDynamicLayout)

#pragma mark - cell

/*
 获取 Cell 需要的高度 ，内部无缓存操作
 @param clas cell class
 @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
 
 ...
 
 #import <UITableViewDynamicLayoutCacheHeight/UITableViewDynamicLayoutCacheHeight.h>

 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
     return [tableView bm_heightWithCellClass:UITableViewCell.class
                                configuration:^(__kindof UITableViewCell * _Nonnull cell) {
         cell.textLabel.text = @"My Text";
     }];
 }
 
 */
- (CGFloat)bm_heightWithCellClass:(Class)clas
                    configuration:(BMConfigurationCellBlock)configuration;

/// 获取 Cell 需要的高度 ，内部自动处理缓存，缓存标识 indexPath
/// @param clas cell class
/// @param indexPath 使用 indexPath 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGFloat)bm_heightWithCellClass:(Class)clas
                 cacheByIndexPath:(NSIndexPath *)indexPath
                    configuration:(BMConfigurationCellBlock)configuration;

/// 获取 Cell 需要的高度 ，内部自动处理缓存，缓存标识 key
/// @param clas cell class
/// @param key 使用 key 做缓存标识
/// @param configuration 布局 cell，内部不会拥有 Block，不需要 __weak
- (CGFloat)bm_heightWithCellClass:(Class)clas
                       cacheByKey:(id<NSCopying>)key
                    configuration:(BMConfigurationCellBlock)configuration;

#pragma mark - HeaderFooter

/// 获取 HeaderFooter 需要的高度 ，内部无缓存操作
/// @param clas HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                                configuration:(BMConfigurationHeaderFooterViewBlock)configuration;

/// 获取 HeaderFooter 需要的高度 ， 内部自动处理缓存，缓存标识 section
/// @param clas HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param section 使用 section 做缓存标识
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                               cacheBySection:(NSInteger)section
                                configuration:(BMConfigurationHeaderFooterViewBlock)configuration;

/// 获取 HeaderFooter 需要的高度 ， 内部自动处理缓存，缓存标识 key
/// @param clas HeaderFooter class
/// @param type HeaderFooter类型，Header 或者 Footer
/// @param key 使用 key 做缓存标识
/// @param configuration 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                                   cacheByKey:(id<NSCopying>)key
                                configuration:(BMConfigurationHeaderFooterViewBlock)configuration;

@end
