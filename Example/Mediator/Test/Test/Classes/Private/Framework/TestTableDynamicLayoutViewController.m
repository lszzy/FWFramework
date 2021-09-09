//
//  TestTableDynamicLayoutViewController.m
//  Example
//
//  Created by wuyong on 2020/9/17.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestTableDynamicLayoutViewController.h"

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
        self.fwSeparatorInset = UIEdgeInsetsZero;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [Theme cellColor];
        
        UILabel *titleLabel = [UILabel fwAutoLayoutView];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont fwFontOfSize:15];
        titleLabel.textColor = [Theme textColor];
        self.myTitleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        [titleLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
            make.leftWithInset(15).rightWithInset(15).topWithInset(15);
        }];
        
        UILabel *textLabel = [UILabel fwAutoLayoutView];
        textLabel.numberOfLines = 0;
        textLabel.font = [UIFont fwFontOfSize:13];
        textLabel.textColor = [Theme textColor];
        self.myTextLabel = textLabel;
        [self.contentView addSubview:textLabel];
        [textLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
            make.leftToView(titleLabel).rightToView(titleLabel);
            NSLayoutConstraint *constraint = [textLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:titleLabel withOffset:10];
            [textLabel fwAddCollapseConstraint:constraint];
            textLabel.fwAutoCollapse = YES;
        }];
        
        // maxY视图不需要和bottom布局，默认平齐，可设置底部间距
        self.fwMaxYViewPadding = 15;
        UIImageView *imageView = [UIImageView fwAutoLayoutView];
        self.myImageView = imageView;
        imageView.userInteractionEnabled = YES;
        [imageView fwSetContentModeAspectFill];
        [imageView fwAddTapGestureWithTarget:self action:@selector(onImageClick:)];
        [self.contentView addSubview:imageView];
        [imageView fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:15];
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:15];
            NSLayoutConstraint *widthCons = [imageView fwSetDimension:NSLayoutAttributeWidth toSize:100];
            NSLayoutConstraint *heightCons = [imageView fwSetDimension:NSLayoutAttributeHeight toSize:100];
            NSLayoutConstraint *constraint = [imageView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:10];
            [imageView fwAddCollapseConstraint:widthCons];
            [imageView fwAddCollapseConstraint:heightCons];
            [imageView fwAddCollapseConstraint:constraint];
            imageView.fwAutoCollapse = YES;
        }];
    }
    return self;
}

- (void)setObject:(TestTableDynamicLayoutObject *)object
{
    _object = object;
    // 自动收缩
    self.myTitleLabel.text = object.title;
    if ([object.imageUrl fwIsFormatUrl]) {
        [self.myImageView fwSetImageWithURL:[NSURL URLWithString:object.imageUrl] placeholderImage:[TestBundle imageNamed:@"public_icon"]];
    } else if (object.imageUrl.length > 0) {
        self.myImageView.image = [TestBundle imageNamed:object.imageUrl];
    } else {
        self.myImageView.image = nil;
    }
    // 手工收缩
    self.myTextLabel.text = object.text;
    
    [self.myImageView fwConstraintToSuperview:NSLayoutAttributeBottom].active = isExpanded;
    self.fwMaxYViewExpanded = isExpanded;
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
        self.contentView.backgroundColor = [Theme cellColor];
        self.fwMaxYViewPadding = 15;
        
        UILabel *titleLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:nil];
        titleLabel.numberOfLines = 0;
        _titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        titleLabel.fwLayoutChain.leftWithInset(15).topWithInset(15).rightWithInset(15).bottomWithInset(15);
    }
    return self;
}

- (void)setFwViewModel:(id)fwViewModel
{
    [super setFwViewModel:fwViewModel];
    
    self.titleLabel.text = FWSafeString(fwViewModel);
    
    [self.titleLabel fwConstraintToSuperview:NSLayoutAttributeBottom].active = isExpanded;
    self.fwMaxYViewExpanded = isExpanded;
}

@end

@interface TestTableDynamicLayoutViewController () <FWTableViewController, FWPhotoBrowserDelegate>

@property (nonatomic, strong) FWPhotoBrowser *photoBrowser;

@end

@implementation TestTableDynamicLayoutViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderView
{
    // [self.tableView fwSetTemplateLayout:NO];
    
    FWWeakifySelf();
    [self.tableView fwResetGroupedStyle];
    self.tableView.backgroundColor = [Theme tableColor];
    [self.tableView fwSetRefreshingBlock:^{
        FWStrongifySelf();
        
        [self onRefreshing];
    }];
    self.tableView.fwPullRefreshView.stateBlock = ^(FWPullRefreshView * _Nonnull view, FWPullRefreshState state) {
        FWStrongifySelf();
        
        self.fwNavigationItem.title = [NSString stringWithFormat:@"refresh state-%@", @(state)];
    };
    self.tableView.fwPullRefreshView.progressBlock = ^(FWPullRefreshView * _Nonnull view, CGFloat progress) {
        FWStrongifySelf();
        
        self.fwNavigationItem.title = [NSString stringWithFormat:@"refresh progress-%.2f", progress];
    };
    
    FWInfiniteScrollView.height = 64;
    [self.tableView fwSetLoadingBlock:^{
        FWStrongifySelf();
        
        [self onLoading];
    }];
    self.tableView.fwInfiniteScrollView.preloadHeight = 200;
    self.tableView.fwInfiniteScrollView.stateBlock = ^(FWInfiniteScrollView * _Nonnull view, FWInfiniteScrollState state) {
        FWStrongifySelf();
        
        self.fwNavigationItem.title = [NSString stringWithFormat:@"load state-%@", @(state)];
    };
    self.tableView.fwInfiniteScrollView.progressBlock = ^(FWInfiniteScrollView * _Nonnull view, CGFloat progress) {
        FWStrongifySelf();
        
        self.fwNavigationItem.title = [NSString stringWithFormat:@"load progress-%.2f", progress];
    };
}

- (void)renderModel
{
    FWWeakifySelf();
    [self fwSetRightBarItem:FWIcon.refreshImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"刷新", @"布局撑开", @"布局不撑开"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            if (index == 1) {
                isExpanded = YES;
            } else if (index == 2) {
                isExpanded = NO;
            }
            [self renderData];
        }];
    }];
}

- (void)renderData
{
    [self.tableView fwBeginRefreshing];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 渲染可重用Cell
    TestTableDynamicLayoutCell *cell = [TestTableDynamicLayoutCell fwCellWithTableView:tableView];
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
    return [tableView fwHeightWithCellClass:[TestTableDynamicLayoutCell class]
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
        [self.tableData fwRemoveObjectAtIndex:indexPath.row];
        [self.tableView fwReloadDataWithoutCache];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TestTableDynamicLayoutHeaderView *headerView = [TestTableDynamicLayoutHeaderView fwHeaderFooterViewWithTableView:tableView];
    headerView.fwViewModel = @"我是表格Header\n我是表格Header";
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = [tableView fwHeightWithHeaderFooterViewClass:[TestTableDynamicLayoutHeaderView class] type:FWHeaderFooterViewTypeHeader configuration:^(TestTableDynamicLayoutHeaderView *headerView) {
        headerView.fwViewModel = @"我是表格Header\n我是表格Header";
    }];
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    TestTableDynamicLayoutHeaderView *footerView = [TestTableDynamicLayoutHeaderView fwHeaderFooterViewWithTableView:tableView];
    footerView.fwViewModel = @"我是表格Footer\n我是表格Footer\n我是表格Footer";
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = [tableView fwHeightWithHeaderFooterViewClass:[TestTableDynamicLayoutHeaderView class] type:FWHeaderFooterViewTypeFooter configuration:^(TestTableDynamicLayoutHeaderView *footerView) {
        footerView.fwViewModel = @"我是表格Footer\n我是表格Footer\n我是表格Footer";
    }];
    return height;
}

- (TestTableDynamicLayoutObject *)randomObject
{
    static NSMutableArray *randomArray;
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
                                 @"public_icon",
                                 @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                                 @"http://littlesvr.ca/apng/images/SteamEngine.webp",
                                 @"public_picture",
                                 @"http://ww2.sinaimg.cn/bmiddle/9ecab84ejw1emgd5nd6eaj20c80c8q4a.jpg",
                                 @"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif",
                                 @"test.gif",
                                 @"http://ww4.sinaimg.cn/bmiddle/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
                                 @"https://pic3.zhimg.com/b471eb23a_im.jpg",
                                 @"http://ww4.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
                                 @"http://ww3.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                                 @"http://ww2.sinaimg.cn/bmiddle/677febf5gw1erma104rhyj20k03dz16y.jpg",
                                 @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg"
                                 ]];
    });
    
    TestTableDynamicLayoutObject *object = [TestTableDynamicLayoutObject new];
    object.title = [[randomArray objectAtIndex:0] fwRandomObject];
    object.text = [[randomArray objectAtIndex:1] fwRandomObject];
    object.imageUrl =[[randomArray objectAtIndex:2] fwRandomObject];
    return object;
}

- (void)onRefreshing
{
    NSLog(@"开始刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        [self.tableData removeAllObjects];
        for (int i = 0; i < 4; i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView fwReloadDataWithoutCache];
        
        self.tableView.fwShowRefreshing = self.tableData.count < 20 ? YES : NO;
        [self.tableView fwEndRefreshing];
        if (!self.tableView.fwShowRefreshing) {
            self.fwNavigationItem.rightBarButtonItem = nil;
        }
    });
}

- (void)onLoading
{
    NSLog(@"开始加载");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"加载完成");
        
        for (int i = 0; i < 4; i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
        self.tableView.fwShowLoading = self.tableData.count < 20 ? YES : NO;
        [self.tableView fwEndLoading];
    });
}

#pragma mark - FWPhotoBrowserDelegate

- (void)onPhotoBrowser:(TestTableDynamicLayoutCell *)cell indexPath:(NSIndexPath *)indexPath
{
    // 移除所有缓存
    [[FWImageDownloader defaultInstance].imageCache removeAllImages];
    [[FWImageDownloader defaultURLCache] removeAllCachedResponses];
    
    // 初始化浏览器
    if (!self.photoBrowser) {
        FWPhotoBrowser *photoBrowser = [FWPhotoBrowser new];
        self.photoBrowser = photoBrowser;
        photoBrowser.delegate = self;
        photoBrowser.longPressBlock = ^(NSInteger index) {
            NSLog(@"%zd", index);
        };
    }
    
    NSMutableArray *pictureUrls = [NSMutableArray array];
    NSInteger count = 0;
    for (TestTableDynamicLayoutObject *object in self.tableData) {
        NSString *imageUrl = object.imageUrl;
        imageUrl.fwTempObject = @(count++);
        if ([imageUrl fwIsFormatUrl] || imageUrl.length < 1) {
            [pictureUrls addObject:imageUrl];
        } else {
            [pictureUrls addObject:[TestBundle imageNamed:object.imageUrl]];
        }
    }
    self.photoBrowser.pictureUrls = pictureUrls;
    self.photoBrowser.currentIndex = indexPath.row;
    [self.photoBrowser showFromView:cell.myImageView];
}

#pragma mark - FWPhotoBrowserDelegate

- (UIView *)photoBrowser:(FWPhotoBrowser *)photoBrowser viewForIndex:(NSInteger)index {
    TestTableDynamicLayoutCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return cell.myImageView;
}

/*
 - (CGSize)photoBrowser:(FWPhotoBrowser *)photoBrowser imageSizeForIndex:(NSInteger)index {
 
 ESPictureModel *model = self.pictureModels[index];
 CGSize size = CGSizeMake(model.width, model.height);
 return size;
 }*/

/*
 - (UIImage *)photoBrowser:(FWPhotoBrowser *)photoBrowser placeholderImageForIndex:(NSInteger)index {
 return [TestBundle imageNamed:@"public_icon"];
 }*/

/*
- (id)photoBrowser:(FWPhotoBrowser *)photoBrowser photoUrlForIndex:(NSInteger)index {
    return self.browserImages[index];
}*/

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser startLoadPhotoView:(FWPhotoView *)photoView {
    // 创建可重用子视图
    UIButton *button = [photoView viewWithTag:101];
    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = 101;
        [button setTitle:@"保存" forState:UIControlStateNormal];
        [button setTitleColor:[Theme textColor] forState:UIControlStateNormal];
        [button fwAddTouchTarget:self action:@selector(onSaveImage:)];
        // 添加到phtoView，默认会滚动。也可固定位置添加到photoBrowser
        [photoView addSubview:button];
        // 布局必须相对于父视图，如photoBrowser，才能固定。默认会滚动
        [button fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:photoBrowser withOffset:FWStatusBarHeight];
        [button fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:photoBrowser withOffset:-15];
        [button fwSetDimensionsToSize:CGSizeMake(80, FWNavigationBarHeight)];
    }
    
    // 默认隐藏按钮
    button.hidden = YES;
}

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser finishLoadPhotoView:(FWPhotoView *)photoView {
    UIButton *button = [photoView viewWithTag:101];
    button.hidden = !photoView.imageLoaded;
}

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser scrollToIndex:(NSInteger)index {
    NSLog(@"%ld", index);
}

#pragma mark - Action

- (void)onSaveImage:(UIButton *)button {
    FWPhotoView *photoView = (FWPhotoView *)button.superview;
    UIImage *image = photoView.imageView.image;
    FWWeakifySelf();
    [image fwSaveImageWithBlock:^(NSError * _Nonnull error) {
        FWStrongifySelf();
        [self fwShowAlertWithTitle:(error ? @"保存失败" : @"保存成功") message:nil cancel:nil cancelBlock:nil];
    }];
}

@end
