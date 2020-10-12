//
//  TestTableDynamicLayoutViewController.m
//  Example
//
//  Created by wuyong on 2020/9/17.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestTableDynamicLayoutViewController.h"

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
        self.contentView.backgroundColor = [UIColor fwRandomColor];
        
        UILabel *titleLabel = [UILabel fwAutoLayoutView];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont appFontNormal];
        titleLabel.textColor = [UIColor appColorBlackOpacityHuge];
        self.myTitleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        [titleLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
            make.leftWithInset(15).rightWithInset(15).topWithInset(15);
        }];
        
        UILabel *textLabel = [UILabel fwAutoLayoutView];
        textLabel.numberOfLines = 0;
        textLabel.font = [UIFont appFontSmall];
        textLabel.textColor = [UIColor appColorBlackOpacityLarge];
        self.myTextLabel = textLabel;
        [self.contentView addSubview:textLabel];
        [textLabel fwLayoutMaker:^(FWLayoutChain * _Nonnull make) {
            make.leftToView(titleLabel).rightToView(titleLabel);
            NSLayoutConstraint *constraint = [textLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:titleLabel withOffset:kAppPaddingNormal];
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
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:kAppPaddingLarge];
            NSLayoutConstraint *widthCons = [imageView fwSetDimension:NSLayoutAttributeWidth toSize:100];
            NSLayoutConstraint *heightCons = [imageView fwSetDimension:NSLayoutAttributeHeight toSize:100];
            NSLayoutConstraint *constraint = [imageView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:kAppPaddingNormal];
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
        [self.myImageView fwSetImageWithURL:[NSURL URLWithString:object.imageUrl] placeholderImage:[UIImage imageNamed:@"public_icon"]];
    } else if (object.imageUrl.length > 0) {
        self.myImageView.image = [UIImage imageNamed:object.imageUrl];
    } else {
        self.myImageView.image = nil;
    }
    // 手工收缩
    self.myTextLabel.text = object.text;
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
        self.contentView.backgroundColor = [UIColor fwRandomColor];
        self.fwMaxYViewPadding = 15;
        
        UILabel *titleLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:nil];
        titleLabel.numberOfLines = 0;
        _titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        titleLabel.fwLayoutChain.leftWithInset(15).topWithInset(15).rightWithInset(15);
    }
    return self;
}

- (void)setFwViewModel:(id)fwViewModel
{
    [super setFwViewModel:fwViewModel];
    
    self.titleLabel.text = FWSafeString(fwViewModel);
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
    self.tableView.backgroundColor = [UIColor appColorBg];
    [self.tableView fwAddPullRefreshWithBlock:^{
        FWStrongifySelf();
        
        [self onRefreshing];
    }];
    self.tableView.fwPullRefreshView.stateBlock = ^(FWPullRefreshView * _Nonnull view, FWPullRefreshState state) {
        FWStrongifySelf();
        
        self.title = [NSString stringWithFormat:@"refresh state-%@", @(state)];
    };
    self.tableView.fwPullRefreshView.progressBlock = ^(FWPullRefreshView * _Nonnull view, CGFloat progress) {
        FWStrongifySelf();
        
        self.title = [NSString stringWithFormat:@"refresh progress-%.2f", progress];
    };
    
    FWInfiniteScrollView.height = 64;
    [self.tableView fwAddInfiniteScrollWithBlock:^{
        FWStrongifySelf();
        
        [self onLoading];
    }];
    self.tableView.fwInfiniteScrollView.preloadHeight = 200;
    self.tableView.fwInfiniteScrollView.stateBlock = ^(FWInfiniteScrollView * _Nonnull view, FWInfiniteScrollState state) {
        FWStrongifySelf();
        
        self.title = [NSString stringWithFormat:@"load state-%@", @(state)];
    };
    self.tableView.fwInfiniteScrollView.progressBlock = ^(FWInfiniteScrollView * _Nonnull view, CGFloat progress) {
        FWStrongifySelf();
        
        self.title = [NSString stringWithFormat:@"load progress-%.2f", progress];
    };
}

- (void)renderModel
{
    [self fwSetRightBarItem:@(UIBarButtonSystemItemRefresh) target:self action:@selector(renderData)];
}

- (void)renderData
{
    [self.tableView fwTriggerPullRefresh];
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
        [self onPhotoBrowser:cell];
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
        [self.tableView fwClearHeightCache];
        [self.tableView reloadData];
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
                                 @"",
                                 @"public_icon",
                                 @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                                 @"http://littlesvr.ca/apng/images/SteamEngine.webp",
                                 @"public_picture",
                                 @"http://ww2.sinaimg.cn/thumbnail/9ecab84ejw1emgd5nd6eaj20c80c8q4a.jpg",
                                 @"http://ww2.sinaimg.cn/thumbnail/642beb18gw1ep3629gfm0g206o050b2a.gif",
                                 @"http://ww4.sinaimg.cn/thumbnail/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
                                 @"https://pic3.zhimg.com/b471eb23a_im.jpg",
                                 @"http://ww4.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
                                 @"http://ww3.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                                 @"http://ww2.sinaimg.cn/thumbnail/677febf5gw1erma104rhyj20k03dz16y.jpg",
                                 @"http://ww4.sinaimg.cn/thumbnail/677febf5gw1erma1g5xd0j20k0esa7wj.jpg"
                                 ]];
    });
    
    TestTableDynamicLayoutObject *object = [TestTableDynamicLayoutObject new];
    object.title = [[randomArray objectAtIndex:0] fwRandomObject];
    object.text = [[randomArray objectAtIndex:1] fwRandomObject];
    NSString *imageName =[[randomArray objectAtIndex:2] fwRandomObject];
    if (imageName.length > 0) {
        object.imageUrl = imageName;
    }
    return object;
}

- (void)onRefreshing
{
    NSLog(@"开始刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        for (int i = 0; i < 4; i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
        self.tableView.fwShowPullRefresh = self.tableData.count < 20 ? YES : NO;
        [self.tableView.fwPullRefreshView stopAnimating];
        if (!self.tableView.fwShowPullRefresh) {
            self.navigationItem.rightBarButtonItem = nil;
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
        
        self.tableView.fwShowInfiniteScroll = self.tableData.count < 20 ? YES : NO;
        [self.tableView.fwInfiniteScrollView stopAnimating];
    });
}

#pragma mark - FWPhotoBrowserDelegate

- (void)onPhotoBrowser:(TestTableDynamicLayoutCell *)cell
{
    // 移除所有缓存
    [[FWImageDownloader defaultInstance].imageCache removeAllImages];
    [[FWImageDownloader defaultURLCache] removeAllCachedResponses];
    
    // 初始化浏览器
    if (!self.photoBrowser) {
        FWPhotoBrowser *photoBrowser = [FWPhotoBrowser new];
        self.photoBrowser = photoBrowser;
        photoBrowser.delegate = self;
        photoBrowser.pictureUrls = @[
                                     @"http://ww2.sinaimg.cn/bmiddle/9ecab84ejw1emgd5nd6eaj20c80c8q4a.jpg",
                                     @"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif",
                                     @"http://ww4.sinaimg.cn/bmiddle/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
                                     @"public_picture",
                                     @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                                     @"http://littlesvr.ca/apng/images/SteamEngine.webp",
                                     @"https://pic3.zhimg.com/b471eb23a_im.jpg",
                                     @"http://ww4.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
                                     @"public_icon",
                                     @"http://ww3.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                                     @"http://ww2.sinaimg.cn/bmiddle/677febf5gw1erma104rhyj20k03dz16y.jpg",
                                     @"loading.gif",
                                     @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg"
                                     ];
        photoBrowser.longPressBlock = ^(NSInteger index) {
            NSLog(@"%zd", index);
        };
    }
    
    // 设置打开Index
    NSString *fromImageUrl = [cell.object.imageUrl stringByReplacingOccurrencesOfString:@"thumbnail" withString:@"bmiddle"];
    NSInteger currentIndex = [self.photoBrowser.pictureUrls indexOfObject:fromImageUrl];
    self.photoBrowser.currentIndex = currentIndex != NSNotFound ? currentIndex : 0;
    [self.photoBrowser showFromView:cell.myImageView];
}

#pragma mark - FWPhotoBrowserDelegate

/*
- (UIView *)photoBrowser:(FWPhotoBrowser *)photoBrowser viewForIndex:(NSInteger)index {
    return self.fromView;
}*/

/*
 - (CGSize)photoBrowser:(FWPhotoBrowser *)photoBrowser imageSizeForIndex:(NSInteger)index {
 
 ESPictureModel *model = self.pictureModels[index];
 CGSize size = CGSizeMake(model.width, model.height);
 return size;
 }*/

/*
 - (UIImage *)photoBrowser:(FWPhotoBrowser *)photoBrowser placeholderImageForIndex:(NSInteger)index {
 return [UIImage imageNamed:@"public_icon"];
 }*/

/*
- (NSString *)photoBrowser:(FWPhotoBrowser *)photoBrowser photoUrlForIndex:(NSInteger)index {
    return self.browserImages[index];
}*/

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser startLoadPhotoView:(FWPhotoView *)photoView {
    // 创建可重用子视图
    UIButton *button = [photoView viewWithTag:101];
    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = 101;
        [button setTitle:@"保存" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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
        [self fwShowAlertWithTitle:(error ? @"保存失败" : @"保存成功") message:nil cancel:@"确定" cancelBlock:nil];
    }];
}

@end
