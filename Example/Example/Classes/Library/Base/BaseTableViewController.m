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

- (UITableView *)tableView
{
    UITableView *tableView = objc_getAssociatedObject(self, _cmd);
    if (!tableView) {
        tableView = [[FWViewControllerManager sharedInstance] performIntercepter:_cmd withObject:self];
        tableView.backgroundColor = [AppTheme tableColor];
        // 渲染可重用单元格类
        NSDictionary *cellDict = [self renderCellClass];
        for (NSString *cellIdentifier in cellDict) {
            [tableView registerClass:[cellDict objectForKey:cellIdentifier] forCellReuseIdentifier:cellIdentifier];
        }
        // 默认启用估算高度
        [tableView fwSetTemplateLayout:YES];
        objc_setAssociatedObject(self, _cmd, tableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableView;
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
    return self.tableData.count;
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
