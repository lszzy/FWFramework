//
//  TestCollectionDynamicLayoutViewController.m
//  Example
//
//  Created by wuyong on 2020/10/12.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestCollectionDynamicLayoutViewController.h"

static BOOL isExpanded = NO;

@interface TestCollectionDynamicLayoutObject : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSString *imageUrl;

@end

@implementation TestCollectionDynamicLayoutObject

@end

@interface TestCollectionDynamicLayoutCell : UICollectionViewCell

@property (nonatomic, strong) TestCollectionDynamicLayoutObject *object;

@property (nonatomic, strong) UILabel *myTitleLabel;

@property (nonatomic, strong) UILabel *myTextLabel;

@property (nonatomic, strong) UIImageView *myImageView;

@end

@implementation TestCollectionDynamicLayoutCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
        [imageView fwSetContentModeAspectFill];
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

- (void)setObject:(TestCollectionDynamicLayoutObject *)object
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

@end

@interface TestCollectionDynamicLayoutHeaderView : UICollectionReusableView

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation TestCollectionDynamicLayoutHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = Theme.cellColor;
        self.fwMaxYViewPadding = 15;
        
        UILabel *titleLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:nil];
        titleLabel.numberOfLines = 0;
        _titleLabel = titleLabel;
        [self addSubview:titleLabel];
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

@interface TestCollectionDynamicLayoutViewController () <FWCollectionViewController, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@end

@implementation TestCollectionDynamicLayoutViewController

- (UICollectionViewLayout *)renderCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    self.flowLayout = layout;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    return layout;
}

- (void)renderView
{
    FWWeakifySelf();
    self.collectionView.backgroundColor = [Theme tableColor];
    [self.collectionView fwSetRefreshingBlock:^{
        FWStrongifySelf();
        
        [self onRefreshing];
    }];
    [self.collectionView fwSetLoadingBlock:^{
        FWStrongifySelf();
        
        [self onLoading];
    }];
}

- (void)renderModel
{
    FWWeakifySelf();
    isExpanded = NO;
    [self fwSetRightBarItem:FWIcon.refreshImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"不固定宽高", @"固定宽度", @"固定高度", @"布局撑开", @"布局不撑开"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            if (index < 3) {
                self.mode = index;
            } else {
                isExpanded = index == 3 ? YES : NO;
            }
            [self renderData];
        }];
    }];
}

- (void)renderData
{
    if (self.mode == 2) {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    } else {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
    [self.collectionView fwBeginRefreshing];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.collectionData.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 渲染可重用Cell
    TestCollectionDynamicLayoutCell *cell = [TestCollectionDynamicLayoutCell fwCellWithCollectionView:collectionView indexPath:indexPath];
    cell.object = [self.collectionData objectAtIndex:indexPath.row];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        TestCollectionDynamicLayoutHeaderView *reusableView = [TestCollectionDynamicLayoutHeaderView fwReusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath];
        reusableView.fwViewModel = @"我是集合Header\n我是集合Header";
        return reusableView;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        TestCollectionDynamicLayoutHeaderView *reusableView = [TestCollectionDynamicLayoutHeaderView fwReusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath];
        reusableView.fwViewModel = @"我是集合Footer\n我是集合Footer\n我是集合Footer";
        return reusableView;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.mode == 0) {
        return [collectionView fwSizeWithCellClass:[TestCollectionDynamicLayoutCell class]
                                  cacheByIndexPath:indexPath
                                     configuration:^(TestCollectionDynamicLayoutCell *cell) {
            cell.object = [self.collectionData objectAtIndex:indexPath.row];
        }];
    } else if (self.mode == 1) {
        return [collectionView fwSizeWithCellClass:[TestCollectionDynamicLayoutCell class]
                                             width:FWScreenWidth - 30
                                  cacheByIndexPath:indexPath
                                     configuration:^(TestCollectionDynamicLayoutCell *cell) {
            cell.object = [self.collectionData objectAtIndex:indexPath.row];
        }];
    } else {
        return [collectionView fwSizeWithCellClass:[TestCollectionDynamicLayoutCell class]
                                            height:FWScreenHeight - FWTopBarHeight
                                  cacheByIndexPath:indexPath
                                     configuration:^(TestCollectionDynamicLayoutCell *cell) {
            cell.object = [self.collectionData objectAtIndex:indexPath.row];
        }];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.mode == 0) {
        return [collectionView fwSizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                      kind:UICollectionElementKindSectionHeader
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            reusableView.fwViewModel = @"我是集合Header\n我是集合Header";
        }];
    } else if (self.mode == 1) {
        return [collectionView fwSizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                     width:FWScreenWidth - 30
                                                      kind:UICollectionElementKindSectionHeader
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            reusableView.fwViewModel = @"我是集合Header\n我是集合Header";
        }];
    } else {
        return [collectionView fwSizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                    height:FWScreenHeight - FWTopBarHeight
                                                      kind:UICollectionElementKindSectionHeader
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            reusableView.fwViewModel = @"我是集合Header\n我是集合Header";
        }];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if (self.mode == 0) {
        return [collectionView fwSizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                      kind:UICollectionElementKindSectionFooter
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            reusableView.fwViewModel = @"我是集合Footer\n我是集合Footer\n我是集合Footer";
        }];
    } else if (self.mode == 1) {
        return [collectionView fwSizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                     width:FWScreenWidth - 30
                                                      kind:UICollectionElementKindSectionFooter
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            reusableView.fwViewModel = @"我是集合Footer\n我是集合Footer\n我是集合Footer";
        }];
    } else {
        return [collectionView fwSizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                    height:FWScreenHeight - FWTopBarHeight
                                                      kind:UICollectionElementKindSectionFooter
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            reusableView.fwViewModel = @"我是集合Footer\n我是集合Footer\n我是集合Footer";
        }];
    }
}

- (TestCollectionDynamicLayoutObject *)randomObject
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
    
    TestCollectionDynamicLayoutObject *object = [TestCollectionDynamicLayoutObject new];
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
        
        [self.collectionData removeAllObjects];
        for (int i = 0; i < 4; i++) {
            [self.collectionData addObject:[self randomObject]];
        }
        [self.collectionView fwClearSizeCache];
        [self.collectionView fwReloadDataWithoutAnimation];
        
        self.collectionView.fwShowRefreshing = self.collectionData.count < 20 ? YES : NO;
        [self.collectionView fwEndRefreshing];
        if (!self.collectionView.fwShowRefreshing) {
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
            [self.collectionData addObject:[self randomObject]];
        }
        [self.collectionView fwReloadDataWithoutAnimation];
        
        self.collectionView.fwShowLoading = self.collectionData.count < 20 ? YES : NO;
        [self.collectionView fwEndLoading];
    });
}

@end
