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
@property (nonatomic, assign) NSInteger count;

@end

@implementation TestTableReloadViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startTimer];
    [self setupItem];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopTimer];
}

- (void)setupItem
{
    FWWeakifySelf();
    [self fwSetRightBarItem:@(self.timer ? UIBarButtonSystemItemStop : UIBarButtonSystemItemPlay) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        
        if (self.timer) {
            [self stopTimer];
        } else {
            [self startTimer];
        }
        [self setupItem];
    }];
}

- (void)startTimer
{
    FWWeakifySelf();
    self.timer = [NSTimer fwCommonTimerWithTimeInterval:10 block:^(NSTimer * _Nonnull timer) {
        FWStrongifySelf();
        [self onRefreshing];
    } repeats:YES];
}

- (void)stopTimer
{
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

- (void)onRefreshing
{
    NSLog(@"开始刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        [self.tableData removeAllObjects];
        for (int i = 0; i < 10; i++) {
            [self.tableData addObject:[NSString stringWithFormat:@"我是数据 %@", @(self.tableData.count + self.count + 1)]];
        }
        [self.tableView.fwPullRefreshView stopAnimating];
        [self.tableView reloadData];
        self.count++;
    });
}

- (void)onLoading
{
    NSLog(@"开始加载");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"加载完成");
        
        for (int i = 0; i < 10; i++) {
            [self.tableData addObject:[NSString stringWithFormat:@"我是数据 %@", @(self.tableData.count + 1)]];
        }
        [self.tableView.fwInfiniteScrollView stopAnimating];
        [self.tableView reloadData];
    });
}

@end
