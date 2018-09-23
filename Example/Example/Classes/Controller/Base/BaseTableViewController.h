/*!
 @header     BaseTableViewController.h
 @indexgroup Example
 @brief      BaseTableViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "BaseViewController.h"

/*!
 @brief BaseTableViewController
 */
@interface BaseTableViewController : BaseViewController <UITableViewDataSource, UITableViewDelegate>

// 数据源
@property (nonatomic, readonly) NSMutableArray *dataList;

// 表格视图
@property (nonatomic, readonly) UITableView *tableView;

// 渲染表格视图，默认Plain样式，Header为nil，Footer为空视图，loadView自动调用。Plain有悬停，Group无悬停
- (UITableView *)renderTableView;

// 渲染表格布局，默认铺满，loadView自动调用
- (void)renderTableLayout;

// 渲染可重用单元格类，格式identifier=>class，自动调用registerClass:forCellReuseIdentifier:进行注册。和renderCellView二选一
- (NSDictionary<NSString *, Class> *)renderCellClass;

// 渲染可重用单元格视图，需手工调用initWithStyle:reuseIdentifier:初始化。和renderCellClass二选一
- (UITableViewCell *)renderCellView:(NSString *)reuseIdentifier;

// 渲染单元格标记，默认唯一标记"cell"。重写可支持多个标记
- (NSString *)renderCellIdentifier:(NSIndexPath *)indexPath;

// 渲染单元格数据，cellForRowAtIndexPath自动调用
- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath;

#pragma mark - Action

// 单元格选中事件，didSelectRowAtIndexPath自动调用
- (void)onCellSelect:(NSIndexPath *)indexPath;

@end
