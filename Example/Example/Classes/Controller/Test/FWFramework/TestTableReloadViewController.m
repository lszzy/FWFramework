//
//  TestTableReloadViewController.m
//  Example
//
//  Created by wuyong on 2019/11/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestTableReloadViewController.h"

@interface TestTableReloadViewController ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation TestTableReloadViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    FWWeakifySelf();
    self.timer = [NSTimer fwCommonTimerWithTimeInterval:10 block:^(NSTimer * _Nonnull timer) {
        FWStrongifySelf();
        [self onRefreshing];
    } repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.timer invalidate];
    self.timer = nil;
}

- (void)renderView
{
    [self.tableView fwAddPullRefreshWithTarget:self action:@selector(onRefreshing)];
    [self.tableView fwAddInfiniteScrollWithTarget:self action:@selector(onLoading)];
}

- (void)renderData
{
    [self.tableView fwTriggerPullRefresh];
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
    return cell;
}

- (NSString *)newObject
{
    NSString *object = [NSString stringWithFormat:@"我是数据 %@", @(self.tableData.count + 1)];
    return object;
}

- (void)onRefreshing
{
    NSLog(@"开始刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        [self.tableData removeAllObjects];
        for (int i = 0; i < 10; i++) {
            [self.tableData addObject:[self newObject]];
        }
        [self.tableView.fwPullRefreshView stopAnimating];
        [self.tableView reloadData];
    });
}

- (void)onLoading
{
    NSLog(@"开始加载");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"加载完成");
        
        for (int i = 0; i < 10; i++) {
            [self.tableData addObject:[self newObject]];
        }
        [self.tableView.fwInfiniteScrollView stopAnimating];
        [self.tableView reloadData];
    });
}

@end
