/*!
 @header     TestTableLayoutViewController.m
 @indexgroup Example
 @brief      TestTableLayoutViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "TestTableLayoutViewController.h"

@interface TestTableLayoutObject : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSString *imageUrl;

@end

@implementation TestTableLayoutObject

@end

@interface TestTableLayoutCell ()

@property (nonatomic, strong) TestTableLayoutObject *object;

@property (nonatomic, strong) UILabel *myTitleLabel;

@property (nonatomic, strong) UILabel *myTextLabel;

@property (nonatomic, strong) UIImageView *myImageView;

@property (nonatomic, copy) void (^imageClicked)(TestTableLayoutObject *object);

@end

@implementation TestTableLayoutCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.fwSeparatorInset = UIEdgeInsetsZero;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [Theme backgroundColor];
        
        UIView *bgView = [UIView fwAutoLayoutView];
        bgView.backgroundColor = [Theme cellColor];
        bgView.layer.masksToBounds = NO;
        bgView.layer.cornerRadius = 10;
        [bgView fwSetShadowColor:[UIColor grayColor] offset:CGSizeMake(0, 0) radius:5];
        [self.contentView addSubview:bgView];
        bgView.fwLayoutChain.edgesWithInsets(UIEdgeInsetsMake(10, 10, 10, 10));
        
        UIView *expectView = [UIView fwAutoLayoutView];
        expectView.backgroundColor = [UIColor redColor];
        expectView.hidden = YES;
        [bgView addSubview:expectView];
        expectView.fwLayoutChain.edgesWithInsets(UIEdgeInsetsMake(10, 10, 10, 10));
        
        UILabel *titleLabel = [UILabel fwAutoLayoutView];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont fwFontOfSize:15];
        titleLabel.textColor = [Theme textColor];
        self.myTitleLabel = titleLabel;
        [bgView addSubview:titleLabel]; {
            [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:15];
            [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:15];
            NSLayoutConstraint *constraint = [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:15];
            [titleLabel fwAddCollapseConstraint:constraint];
            titleLabel.fwAutoCollapse = YES;
        }
        
        UILabel *textLabel = [UILabel fwAutoLayoutView];
        textLabel.numberOfLines = 0;
        textLabel.font = [UIFont fwFontOfSize:13];
        textLabel.textColor = [Theme textColor];
        self.myTextLabel = textLabel;
        [bgView addSubview:textLabel]; {
            [textLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:15];
            [textLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:15];
            NSLayoutConstraint *constraint = [textLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:titleLabel withOffset:10];
            [textLabel fwAddCollapseConstraint:constraint];
        }
        
        UIImageView *imageView = [UIImageView fwAutoLayoutView];
        self.myImageView = imageView;
        imageView.userInteractionEnabled = YES;
        [imageView fwAddTapGestureWithTarget:self action:@selector(onImageClick:)];
        [bgView addSubview:imageView]; {
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:15];
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:15 relation:NSLayoutRelationGreaterThanOrEqual];
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:15];
            NSLayoutConstraint *constraint = [imageView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:10];
            [imageView fwAddCollapseConstraint:constraint];
            imageView.fwAutoCollapse = YES;
        }
    }
    return self;
}

- (void)setObject:(TestTableLayoutObject *)object
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
    if (object.text.length > 0) {
        self.myTextLabel.fwCollapsed = NO;
    } else {
        self.myTextLabel.fwCollapsed = YES;
    }
}

- (void)onImageClick:(UIGestureRecognizer *)gesture
{
    if (self.imageClicked) {
        self.imageClicked(self.object);
    }
}

@end

@interface TestTableLayoutViewController () <FWTableViewController, FWPhotoBrowserDelegate>

@property (nonatomic, strong) FWPhotoBrowser *photoBrowser;
@property (nonatomic, assign) BOOL isShort;

@end

@implementation TestTableLayoutViewController

- (void)renderView
{
    self.isShort = [@[@0, @1].fwRandomObject fwAsInteger] == 0;
    FWWeakifySelf();
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
    self.tableView.fwInfiniteScrollView.preloadHeight = self.isShort ? 0 : 200;
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
    [self fwSetRightBarItem:FWIcon.refreshImage target:self action:@selector(renderData)];
}

- (void)renderData
{
    [self.tableView fwBeginRefreshing];
}

#pragma mark - TableView

- (void)renderTableView
{
    self.tableView.backgroundColor = [Theme tableColor];
    [self.tableView registerClass:[TestTableLayoutCell class] forCellReuseIdentifier:@"Cell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 渲染可重用Cell
    TestTableLayoutCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    FWWeakifySelf();
    FWWeakify(cell);
    cell.imageClicked = ^(TestTableLayoutObject *object) {
        FWStrongifySelf();
        FWStrongify(cell);
        [self onPhotoBrowser:cell];
    };
    TestTableLayoutObject *object = [self.tableData objectAtIndex:indexPath.row];
    cell.object = object;
    return cell;
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
        [self.tableView reloadData];
    }
}

- (TestTableLayoutObject *)randomObject
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
    
    TestTableLayoutObject *object = [TestTableLayoutObject new];
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
        
        [self.tableData removeAllObjects];
        for (int i = 0; i < (self.isShort ? 1 : 4); i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
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
        
        for (int i = 0; i < (self.isShort ? 1 : 4); i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
        self.tableView.fwShowLoading = self.tableData.count < 20 ? YES : NO;
        [self.tableView fwEndLoading];
    });
}

#pragma mark - FWPhotoBrowserDelegate

- (void)onPhotoBrowser:(TestTableLayoutCell *)cell
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
                                     [TestBundle imageNamed:@"public_picture"],
                                     @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                                     @"http://littlesvr.ca/apng/images/SteamEngine.webp",
                                     @"https://pic3.zhimg.com/b471eb23a_im.jpg",
                                     @"http://ww4.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
                                     [TestBundle imageNamed:@"public_icon"],
                                     @"http://ww3.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                                     @"http://ww2.sinaimg.cn/bmiddle/677febf5gw1erma104rhyj20k03dz16y.jpg",
                                     [TestBundle imageNamed:@"test.gif"],
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
    [self photoBrowser:self.photoBrowser scrollToIndex:self.photoBrowser.currentIndex];
    // [self.photoBrowser showFromView:cell.myImageView];
    [self.photoBrowser show];
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
        button.hidden = YES;
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
    
    // 仅供参考视图
    UILabel *tipLabel = [photoView.imageView viewWithTag:102];
    if (!tipLabel) {
        tipLabel = [UILabel new];
        tipLabel.tag = 102;
        tipLabel.hidden = YES;
        tipLabel.fwContentInset = UIEdgeInsetsMake(2, 8, 2, 8);
        [tipLabel fwSetCornerRadius:12.5];
        tipLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.5];
        tipLabel.text = @"图片仅供参考";
        tipLabel.font = FWFontRegular(12);
        tipLabel.textColor = [UIColor whiteColor];
        [photoView.imageView addSubview:tipLabel];
        tipLabel.fwLayoutChain.bottomWithInset(16).rightWithInset(16);
    }
}

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser finishLoadPhotoView:(FWPhotoView *)photoView {
    UIButton *button = [photoView viewWithTag:101];
    button.hidden = !photoView.imageLoaded;
    
    UILabel *tipLabel = [photoView.imageView viewWithTag:102];
    tipLabel.hidden = !photoView.imageLoaded;
}

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser scrollToIndex:(NSInteger)index {
    // 创建标题Label
    UILabel *label = [photoBrowser viewWithTag:103];
    if (!label) {
        label = [UILabel new];
        label.tag = 103;
        label.alpha = 0;
        label.textColor = [UIColor whiteColor];
        [photoBrowser addSubview:label];
        [label fwAlignAxis:NSLayoutAttributeCenterX toView:photoBrowser];
        [label fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:photoBrowser.pageTextLabel withOffset:-20];
    }
    
    id urlString = [photoBrowser.pictureUrls fwObjectAtIndex:index];
    if ([urlString isKindOfClass:[NSString class]]) {
        label.text = FWSafeURL(urlString).pathComponents.lastObject;
    } else {
        label.text = FWSafeString(@([urlString hash]));
    }
}

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser willShowPhotoView:(FWPhotoView *)photoView {
    UILabel *label = [photoBrowser viewWithTag:103];
    label.alpha = 1;
    
    UIButton *button = [photoView viewWithTag:101];
    button.alpha = 1;
    UILabel *tipLabel = [photoView.imageView viewWithTag:102];
    tipLabel.alpha = 1;
}

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser willDismissPhotoView:(FWPhotoView *)photoView {
    UILabel *label = [photoBrowser viewWithTag:103];
    label.alpha = 0;

    UIButton *button = [photoView viewWithTag:101];
    button.alpha = 0;
    UILabel *tipLabel = [photoView.imageView viewWithTag:102];
    tipLabel.alpha = 0;
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
