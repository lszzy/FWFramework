/*!
 @header     BaseTableViewController.m
 @indexgroup Example
 @brief      BaseTableViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "BaseTableViewController.h"

@implementation BaseTableViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // 初始化表格数据
        _dataList = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

#pragma mark - Render

- (void)setupView
{
    // 创建自动布局表格
    _tableView = [self renderTableView];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_tableView];
    
    // 渲染可重用单元格类
    NSDictionary *cellDict = [self renderCellClass];
    for (NSString *cellIdentifier in cellDict) {
        [_tableView registerClass:[cellDict objectForKey:cellIdentifier] forCellReuseIdentifier:cellIdentifier];
    }
    
    // 渲染表格布局
    [self renderTableLayout];
    
    // 初始化表格frame
    [_tableView setNeedsLayout];
    [_tableView layoutIfNeeded];
}

- (UITableView *)renderTableView
{
    // 默认Plain样式
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    // 默认表格底部为空
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    // 兼容TableView
    [tableView fwContentInsetNever];
    // 默认启用估算高度
    [tableView fwSetTemplateLayout:YES];
    return tableView;
}

- (void)renderTableLayout
{
    [self.tableView fwPinEdgesToSuperview];
}

- (NSDictionary<NSString *, Class> *)renderCellClass
{
    // 使用自定义cell，class方式，子类重写
    // return @{ @"cell" : [UITableViewCell class] };
    
    // 使用默认cell，view方式，子类重写
    return nil;
}

- (UITableViewCell *)renderCellView:(NSString *)reuseIdentifier
{
    // 默认Default样式
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    return cell;
}

- (NSString *)renderCellIdentifier:(NSIndexPath *)indexPath
{
    return @"cell";
}

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    /*
     // 设置最后一条分隔线撑满模板
     if (indexPath.row == self.dataList.count - 1) {
        cell.fwSeparatorInset = UIEdgeInsetsZero;
     }
     */
    
    // 子类重写
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self renderCellIdentifier:indexPath];
    Class cellClass = [[self renderCellClass] objectForKey:cellIdentifier];
    // cell类方式，渲染cell和数据
    if (cellClass) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        [self renderCellData:cell indexPath:indexPath];
        return cell;
        // cell视图方式，渲染cell和数据
    } else {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [self renderCellView:cellIdentifier];
        }
        [self renderCellData:cell indexPath:indexPath];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView fwTemplateHeightAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView fwSetTemplateHeight:cell.fwHeight atIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 默认取消选中状态
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self onCellSelect:indexPath];
}

#pragma mark - Action

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    // 子类重写
}

@end
