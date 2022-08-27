//
//  TestTableController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestTableController.h"
#import "AppSwift.h"
@import FWFramework;

static BOOL isExpanded = NO;

@interface TestTableDynamicLayoutObject : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSString *imageUrl;

@end

@implementation TestTableDynamicLayoutObject

@end

@interface TestTableDynamicLayoutCell : UITableViewCell

@property (nonatomic, strong) TestTableDynamicLayoutObject *object;

@property (nonatomic, strong) UILabel *myTitleLabel;

@property (nonatomic, strong) UILabel *myTextLabel;

@property (nonatomic, strong) UIImageView *myImageView;

@property (nonatomic, copy) void (^imageClicked)(TestTableDynamicLayoutObject *object);

@end

@implementation TestTableDynamicLayoutCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.fw_separatorInset = UIEdgeInsetsZero;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [AppTheme cellColor];
        
        UILabel *titleLabel = [UILabel new];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont fw_fontOfSize:15];
        titleLabel.textColor = [AppTheme textColor];
        self.myTitleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        [titleLabel fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
            make.leftWithInset(15).rightWithInset(15).topWithInset(15);
        }];
        
        UILabel *textLabel = [UILabel new];
        textLabel.numberOfLines = 0;
        textLabel.font = [UIFont fw_fontOfSize:13];
        textLabel.textColor = [AppTheme textColor];
        self.myTextLabel = textLabel;
        [self.contentView addSubview:textLabel];
        [textLabel fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
            make.leftToView(titleLabel).rightToView(titleLabel);
            NSLayoutConstraint *constraint = [textLabel fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:titleLabel withOffset:10];
            [textLabel fw_addCollapseConstraint:constraint];
            textLabel.fw_autoCollapse = YES;
        }];
        
        // maxY视图不需要和bottom布局，默认平齐，可设置底部间距
        self.fw_maxYViewPadding = 15;
        UIImageView *imageView = [UIImageView new];
        self.myImageView = imageView;
        imageView.userInteractionEnabled = YES;
        [imageView fw_setContentModeAspectFill];
        [imageView fw_addTapGestureWithTarget:self action:@selector(onImageClick:)];
        [self.contentView addSubview:imageView];
        [imageView fw_layoutMaker:^(FWLayoutChain * _Nonnull make) {
            [imageView fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:15];
            [imageView fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:15];
            NSLayoutConstraint *widthCons = [imageView fw_setDimension:NSLayoutAttributeWidth toSize:100];
            NSLayoutConstraint *heightCons = [imageView fw_setDimension:NSLayoutAttributeHeight toSize:100];
            NSLayoutConstraint *constraint = [imageView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:10];
            [imageView fw_addCollapseConstraint:widthCons];
            [imageView fw_addCollapseConstraint:heightCons];
            [imageView fw_addCollapseConstraint:constraint];
            imageView.fw_autoCollapse = YES;
        }];
    }
    return self;
}

- (void)setObject:(TestTableDynamicLayoutObject *)object
{
    _object = object;
    // 自动收缩
    self.myTitleLabel.text = object.title;
    if ([object.imageUrl fw_isFormatUrl]) {
        [self.myImageView fw_setImageWithURL:[NSURL URLWithString:object.imageUrl] placeholderImage:[UIImage fw_appIconImage]];
    } else if (object.imageUrl.length > 0) {
        self.myImageView.image = [FWModuleBundle imageNamed:object.imageUrl];
    } else {
        self.myImageView.image = nil;
    }
    // 手工收缩
    self.myTextLabel.text = object.text;
    
    [self.myImageView fw_constraintToSuperview:NSLayoutAttributeBottom].active = isExpanded;
    self.fw_maxYViewExpanded = isExpanded;
}

- (void)onImageClick:(UIGestureRecognizer *)gesture
{
    if (self.imageClicked) {
        self.imageClicked(self.object);
    }
}

@end

@interface TestTableDynamicLayoutHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation TestTableDynamicLayoutHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [AppTheme cellColor];
        self.fw_maxYViewPadding = 15;
        
        UILabel *titleLabel = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor]];
        titleLabel.numberOfLines = 0;
        _titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        titleLabel.fw_layoutChain.leftWithInset(15).topWithInset(15).rightWithInset(15).bottomWithInset(15);
        
        [self renderData:nil];
    }
    return self;
}

- (void)renderData:(NSString *)text
{
    self.titleLabel.text = FWSafeString(text);
    [self.titleLabel fw_constraintToSuperview:NSLayoutAttributeBottom].active = isExpanded;
    self.fw_maxYViewExpanded = isExpanded;
}

@end

@interface TestTableController () <FWTableViewController>

@end

@implementation TestTableController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupTableView
{
    FWWeakifySelf();
    [self.tableView fw_resetGroupedStyle];
    self.tableView.alwaysBounceVertical = YES;
    self.tableView.backgroundColor = [AppTheme tableColor];
    [self.tableView fw_setRefreshingBlock:^{
        FWStrongifySelf();
        
        [self onRefreshing];
    }];
    self.tableView.fw_pullRefreshView.stateBlock = ^(FWPullRefreshView * _Nonnull view, FWPullRefreshState state) {
        FWStrongifySelf();
        
        self.navigationItem.title = [NSString stringWithFormat:@"refresh state-%@", @(state)];
    };
    self.tableView.fw_pullRefreshView.progressBlock = ^(FWPullRefreshView * _Nonnull view, CGFloat progress) {
        FWStrongifySelf();
        
        self.navigationItem.title = [NSString stringWithFormat:@"refresh progress-%.2f", progress];
    };
    
    FWInfiniteScrollView.height = 64;
    [self.tableView fw_setLoadingBlock:^{
        FWStrongifySelf();
        
        [self onLoading];
    }];
    // self.tableView.fw_infiniteScrollView.preloadHeight = 200;
    self.tableView.fw_infiniteScrollView.stateBlock = ^(FWInfiniteScrollView * _Nonnull view, FWInfiniteScrollState state) {
        FWStrongifySelf();
        
        self.navigationItem.title = [NSString stringWithFormat:@"load state-%@", @(state)];
    };
    self.tableView.fw_infiniteScrollView.progressBlock = ^(FWInfiniteScrollView * _Nonnull view, CGFloat progress) {
        FWStrongifySelf();
        
        self.navigationItem.title = [NSString stringWithFormat:@"load progress-%.2f", progress];
    };
}

- (void)setupTableLayout
{
    [self.tableView fw_pinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
    [self.tableView fw_pinEdgeToSafeArea:NSLayoutAttributeTop];
}

- (void)setupNavbar
{
    FWWeakifySelf();
    [self fw_setRightBarItem:@(UIBarButtonSystemItemRefresh) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self fw_showSheetWithTitle:nil message:@"滚动视图顶部未延伸" cancel:@"取消" actions:@[self.tableView.contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentNever ? @"contentInset自适应" : @"contentInset不适应", isExpanded ? @"布局不撑开" : @"布局撑开"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            if (index == 0) {
                self.tableView.contentInsetAdjustmentBehavior = (self.tableView.contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentNever) ? UIScrollViewContentInsetAdjustmentAutomatic : UIScrollViewContentInsetAdjustmentNever;
            } else if (index == 1) {
                isExpanded = !isExpanded;
            }
            [self setupSubviews];
        }];
    }];
}

- (void)setupSubviews
{
    [self.tableView fw_beginRefreshing];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 渲染可重用Cell
    TestTableDynamicLayoutCell *cell = [TestTableDynamicLayoutCell fw_cellWithTableView:tableView];
    FWWeakifySelf();
    FWWeakify(cell);
    cell.imageClicked = ^(TestTableDynamicLayoutObject *object) {
        FWStrongifySelf();
        FWStrongify(cell);
        [self onPhotoBrowser:cell indexPath:indexPath];
    };
    cell.object = [self.tableData objectAtIndex:indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 最后一次上拉会产生跳跃，处理此方法即可
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView fw_heightWithCellClass:[TestTableDynamicLayoutCell class]
                           cacheByIndexPath:indexPath
                              configuration:^(TestTableDynamicLayoutCell * _Nonnull cell) {
        cell.object = [self.tableData objectAtIndex:indexPath.row];
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tableData removeObjectAtIndex:indexPath.row];
        [self.tableView fw_clearHeightCache];
        [self.tableView reloadData];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.tableData.count < 1) {
        return nil;
    }
    TestTableDynamicLayoutHeaderView *headerView = [TestTableDynamicLayoutHeaderView fw_headerFooterViewWithTableView:tableView];
    [headerView renderData:@"我是表格Header\n我是表格Header"];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.tableData.count < 1) {
        return 0;
    }
    CGFloat height = [tableView fw_heightWithHeaderFooterViewClass:[TestTableDynamicLayoutHeaderView class] type:FWHeaderFooterViewTypeHeader configuration:^(TestTableDynamicLayoutHeaderView *headerView) {
        [headerView renderData:@"我是表格Header\n我是表格Header"];
    }];
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.tableData.count < 1) {
        return nil;
    }
    TestTableDynamicLayoutHeaderView *footerView = [TestTableDynamicLayoutHeaderView fw_headerFooterViewWithTableView:tableView];
    [footerView renderData:@"我是表格Footer\n我是表格Footer\n我是表格Footer"];
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.tableData.count < 1) {
        return 0;
    }
    CGFloat height = [tableView fw_heightWithHeaderFooterViewClass:[TestTableDynamicLayoutHeaderView class] type:FWHeaderFooterViewTypeFooter configuration:^(TestTableDynamicLayoutHeaderView *footerView) {
        [footerView renderData:@"我是表格Footer\n我是表格Footer\n我是表格Footer"];
    }];
    return height;
}

- (TestTableDynamicLayoutObject *)randomObject
{
    static NSMutableArray<NSArray *> *randomArray;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        randomArray = [NSMutableArray array];
        
        [randomArray addObject:@[
            @"",
            @"这是标题",
            @"这是复杂的标题这是复杂的标题这是复杂的标题",
            @"这是复杂的标题这是复杂的标题\n这是复杂的标题这是复杂的标题",
            @"这是复杂的标题\n这是复杂的标题\n这是复杂的标题\n这是复杂的标题",
        ]];
        
        [randomArray addObject:@[
            @"",
            @"这是内容",
            @"这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容这是复杂的内容",
            @"这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容",
            @"这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容\n这是复杂的内容这是复杂的内容",
        ]];
        
        [randomArray addObject:@[
            @"",
            @"Animation.png",
            @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
            @"http://littlesvr.ca/apng/images/SteamEngine.webp",
            @"http://ww2.sinaimg.cn/bmiddle/9ecab84ejw1emgd5nd6eaj20c80c8q4a.jpg",
            @"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif",
            @"Loading.gif",
            @"http://ww4.sinaimg.cn/bmiddle/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
            @"https://pic3.zhimg.com/b471eb23a_im.jpg",
            @"http://ww4.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
            @"http://ww3.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
            @"http://ww2.sinaimg.cn/bmiddle/677febf5gw1erma104rhyj20k03dz16y.jpg",
            @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg"
        ]];
    });
    
    TestTableDynamicLayoutObject *object = [TestTableDynamicLayoutObject new];
    object.title = [[randomArray objectAtIndex:0] fw_randomObject];
    object.text = [[randomArray objectAtIndex:1] fw_randomObject];
    object.imageUrl =[[randomArray objectAtIndex:2] fw_randomObject];
    return object;
}

- (void)onRefreshing
{
    NSLog(@"开始刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        [self.tableData removeAllObjects];
        for (int i = 0; i < 1; i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView fw_clearHeightCache];
        [self.tableView reloadData];
        
        self.tableView.fw_shouldRefreshing = self.tableData.count < 20 ? YES : NO;
        [self.tableView fw_endRefreshing];
        if (!self.tableView.fw_shouldRefreshing) {
            self.navigationItem.rightBarButtonItem = nil;
        }
    });
}

- (void)onLoading
{
    NSLog(@"开始加载");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"加载完成");
        
        for (int i = 0; i < 1; i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
        self.tableView.fw_loadingFinished = self.tableData.count >= 20 ? YES : NO;
        [self.tableView fw_endLoading];
    });
}

#pragma mark - FWPhotoBrowserDelegate

- (void)onPhotoBrowser:(TestTableDynamicLayoutCell *)cell indexPath:(NSIndexPath *)indexPath
{
    // 移除所有缓存
    [[FWImageDownloader defaultInstance].imageCache removeAllImages];
    [[FWImageDownloader defaultURLCache] removeAllCachedResponses];
    
    NSMutableArray *pictureUrls = [NSMutableArray array];
    NSInteger count = 0;
    for (TestTableDynamicLayoutObject *object in self.tableData) {
        NSString *imageUrl = object.imageUrl;
        imageUrl.fw_tempObject = @(count++);
        if ([imageUrl fw_isFormatUrl] || imageUrl.length < 1) {
            [pictureUrls addObject:imageUrl];
        } else {
            [pictureUrls addObject:[FWModuleBundle imageNamed:object.imageUrl]];
        }
    }
    
    FWWeakifySelf();
    [self fw_showImagePreviewWithImageURLs:pictureUrls imageInfos:nil currentIndex:indexPath.row sourceView:^id _Nullable(NSInteger index) {
        FWStrongifySelf();
        TestTableDynamicLayoutCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        return cell.myImageView;
    }];
}

@end
