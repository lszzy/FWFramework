//
//  TestTableReloadViewController.m
//  Example
//
//  Created by wuyong on 2019/11/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestTableReloadViewController.h"

@interface TestTableReloadCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation TestTableReloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UILabel *titleLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:nil];
        _titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        titleLabel.fwLayoutChain.centerY().leftWithInset(15).rightWithInset(15);
    }
    return self;
}

@end

@interface TestTableReloadViewController () <FWTableViewController>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL isTimer;

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
    [self fwSetRightBarItem:self.timer ? FWIcon.stopImage : FWIcon.playImage block:^(id  _Nonnull sender) {
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
        self.isTimer = YES;
        [self onRefreshing];
        self.isTimer = NO;
    } repeats:YES];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderView
{
    self.tableView.fwPullRefreshHeight = FWPullRefreshView.height + UIScreen.fwSafeAreaInsets.top;
    [self.tableView fwSetRefreshingTarget:self action:@selector(onRefreshing)];
    self.tableView.fwInfiniteScrollHeight = FWInfiniteScrollView.height + UIScreen.fwSafeAreaInsets.bottom;
    [self.tableView fwSetLoadingTarget:self action:@selector(onLoading)];
}

- (void)renderData
{
    [self.tableView fwBeginRefreshing];
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TestTableReloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[TestTableReloadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.titleLabel.text = [self.tableData objectAtIndex:indexPath.row];
    return cell;
}

- (void)onRefreshing
{
    BOOL isTimer = self.isTimer;
    if (isTimer && (self.tableView.isDragging || self.tableView.isDecelerating)) {
        NSLog(@"拖动中，暂停自动刷新");
        return;
    }
    
    if (isTimer) {
        NSLog(@"开始自动刷新");
    } else {
        NSLog(@"开始刷新");
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (isTimer) {
            NSLog(@"自动刷新完成");
        } else {
            NSLog(@"刷新完成");
        }
        
        [self.tableData removeAllObjects];
        for (int i = 0; i < 10; i++) {
            [self.tableData addObject:[NSString stringWithFormat:@"我是数据 %@", @(self.tableData.count + self.count + 1)]];
        }
        [self.tableView fwEndRefreshing];
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
        [self.tableView fwEndLoading];
        [self.tableView reloadData];
    });
}

@end
