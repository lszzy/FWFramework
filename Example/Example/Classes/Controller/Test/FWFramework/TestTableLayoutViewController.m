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

@interface TestTableLayoutCell : UITableViewCell

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
        
        UILabel *titleLabel = [UILabel fwAutoLayoutView];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont appFontNormal];
        titleLabel.textColor = [UIColor appColorBlackOpacityHuge];
        self.myTitleLabel = titleLabel;
        [self.contentView addSubview:titleLabel]; {
            [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:kAppPaddingLarge];
            [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:kAppPaddingLarge];
            NSLayoutConstraint *constraint = [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:kAppPaddingLarge];
            [titleLabel fwAddCollapseConstraint:constraint];
            titleLabel.fwAutoCollapse = YES;
        }
        
        UILabel *textLabel = [UILabel fwAutoLayoutView];
        textLabel.numberOfLines = 0;
        textLabel.font = [UIFont appFontSmall];
        textLabel.textColor = [UIColor appColorBlackOpacityLarge];
        self.myTextLabel = textLabel;
        [self.contentView addSubview:textLabel]; {
            [textLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:kAppPaddingLarge];
            [textLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:kAppPaddingLarge];
            NSLayoutConstraint *constraint = [textLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:titleLabel withOffset:kAppPaddingNormal];
            [textLabel fwAddCollapseConstraint:constraint];
        }
        
        UIImageView *imageView = [UIImageView fwAutoLayoutView];
        self.myImageView = imageView;
        imageView.userInteractionEnabled = YES;
        [imageView fwAddTapGestureWithTarget:self action:@selector(onImageClick:)];
        [self.contentView addSubview:imageView]; {
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:kAppPaddingLarge];
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:kAppPaddingLarge relation:NSLayoutRelationGreaterThanOrEqual];
            [imageView fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:kAppPaddingLarge];
            NSLayoutConstraint *constraint = [imageView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:kAppPaddingNormal];
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
        [self.myImageView fwSetImageWithURL:[NSURL URLWithString:object.imageUrl] placeholderImage:[UIImage imageNamed:@"public_icon"]];
    } else {
        self.myImageView.image = [UIImage imageNamed:object.imageUrl];
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

@interface TestTableLayoutViewController () <FWPhotoBrowserDelegate>

@property (nonatomic, strong) NSArray *browserImages;

@end

@implementation TestTableLayoutViewController

- (void)renderView
{
    FWWeakifySelf();
    [self.tableView fwAddPullRefreshWithBlock:^{
        FWStrongifySelf();
        
        [self onRefreshing];
    }];
    
    [self.tableView fwAddInfiniteScrollWithBlock:^{
        FWStrongifySelf();
        
        [self onLoading];
    }];
}

- (void)renderData
{
    [self.tableView fwTriggerPullRefresh];
}

#pragma mark - TableView

- (UITableView *)renderTableView
{
    UITableView *tableView = [super renderTableView];
    [tableView registerClass:[TestTableLayoutCell class] forCellReuseIdentifier:@"Cell"];
    return tableView;
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
    TestTableLayoutObject *object = [self.dataList objectAtIndex:indexPath.row];
    cell.object = object;
    return cell;
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
                                 @"tabbar_home",
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        for (int i = 0; i < 10; i++) {
            [self.dataList addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
        self.tableView.fwShowPullRefresh = self.dataList.count < 5000 ? YES : NO;
        [self.tableView.fwPullRefreshView stopAnimating];
    });
}

- (void)onLoading
{
    NSLog(@"开始加载");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"加载完成");
        
        for (int i = 0; i < 10; i++) {
            [self.dataList addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
        self.tableView.fwShowInfiniteScroll = self.dataList.count < 5000 ? YES : NO;
        [self.tableView.fwInfiniteScrollView stopAnimating];
    });
}

#pragma mark - FWPhotoBrowserDelegate

- (void)onPhotoBrowser:(TestTableLayoutCell *)cell
{
    // 移除所有缓存
    // [[FWImageDownloader defaultInstance].imageCache removeAllImages];
    // [[FWImageDownloader defaultURLCache] removeAllCachedResponses];
    
    self.browserImages = @[
                           @"http://ww2.sinaimg.cn/bmiddle/9ecab84ejw1emgd5nd6eaj20c80c8q4a.jpg",
                           @"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif",
                           @"http://ww4.sinaimg.cn/bmiddle/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
                           @"public_picture",
                           @"https://pic3.zhimg.com/b471eb23a_im.jpg",
                           @"http://ww4.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
                           @"public_icon",
                           @"http://ww3.sinaimg.cn/bmiddle/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                           @"http://ww2.sinaimg.cn/bmiddle/677febf5gw1erma104rhyj20k03dz16y.jpg",
                           @"tabbar_home",
                           @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg"
                           ];
    
    FWPhotoBrowser *photoBrowser = [FWPhotoBrowser new];
    photoBrowser.delegate = self;
    photoBrowser.pictureUrls = self.browserImages;
    photoBrowser.longPressBlock = ^(NSInteger index) {
        NSLog(@"%zd", index);
    };
    NSString *fromImageUrl = [cell.object.imageUrl stringByReplacingOccurrencesOfString:@"thumbnail" withString:@"bmiddle"];
    NSInteger currentIndex = [self.browserImages indexOfObject:fromImageUrl];
    photoBrowser.currentIndex = currentIndex != NSNotFound ? currentIndex : 0;
    [photoBrowser showFromView:cell.myImageView];
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
 - (UIImage *)photoBrowser:(FWPhotoBrowser *)photoBrowser defaultImageForIndex:(NSInteger)index {
 return [UIImage imageNamed:@"public_icon"];
 }*/

/*
- (NSString *)photoBrowser:(FWPhotoBrowser *)photoBrowser highQualityUrlStringForIndex:(NSInteger)index {
    return self.browserImages[index];
}*/

- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser scrollToIndex:(NSInteger)index {
    NSLog(@"%ld", index);
}

@end
