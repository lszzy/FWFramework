//
//  TestCollectionController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestCollectionController.h"
#import "AppSwift.h"
@import FWFramework;

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
        [imageView fw_setContentModeAspectFill];
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

- (void)setObject:(TestCollectionDynamicLayoutObject *)object
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

@end

@interface TestCollectionDynamicLayoutHeaderView : UICollectionReusableView

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation TestCollectionDynamicLayoutHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = AppTheme.cellColor;
        self.fw_maxYViewPadding = 15;
        
        UILabel *titleLabel = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor]];
        titleLabel.numberOfLines = 0;
        _titleLabel = titleLabel;
        [self addSubview:titleLabel];
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

@interface TestCollectionController () <FWCollectionViewController, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@end

@implementation TestCollectionController

- (UICollectionViewLayout *)setupCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    self.flowLayout = layout;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    return layout;
}

- (void)setupCollectionView
{
    FWWeakifySelf();
    self.collectionView.backgroundColor = [AppTheme tableColor];
    [self.collectionView fw_setRefreshingBlock:^{
        FWStrongifySelf();
        
        [self onRefreshing];
    }];
    [self.collectionView fw_setLoadingBlock:^{
        FWStrongifySelf();
        
        [self onLoading];
    }];
}

- (void)setupCollectionLayout
{
    [self.collectionView fw_pinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
    [self.collectionView fw_pinEdgeToSafeArea:NSLayoutAttributeTop];
}

- (void)setupNavbar
{
    FWWeakifySelf();
    isExpanded = NO;
    [self fw_setRightBarItem:@(UIBarButtonSystemItemRefresh) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self fw_showSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"不固定宽高", @"固定宽度", @"固定高度", @"布局撑开", @"布局不撑开"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            if (index < 3) {
                self.mode = index;
            } else {
                isExpanded = index == 3 ? YES : NO;
            }
            [self setupSubviews];
        }];
    }];
}

- (void)setupSubviews
{
    if (self.mode == 2) {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    } else {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
    [self.collectionView fw_beginRefreshing];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.collectionData.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 渲染可重用Cell
    TestCollectionDynamicLayoutCell *cell = [TestCollectionDynamicLayoutCell fw_cellWithCollectionView:collectionView indexPath:indexPath];
    cell.object = [self.collectionData objectAtIndex:indexPath.row];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        TestCollectionDynamicLayoutHeaderView *reusableView = [TestCollectionDynamicLayoutHeaderView fw_reusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath];
        [reusableView renderData:@"我是集合Header\n我是集合Header"];
        return reusableView;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        TestCollectionDynamicLayoutHeaderView *reusableView = [TestCollectionDynamicLayoutHeaderView fw_reusableViewWithCollectionView:collectionView kind:kind indexPath:indexPath];
        [reusableView renderData:@"我是集合Footer\n我是集合Footer\n我是集合Footer"];
        return reusableView;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.mode == 0) {
        return [collectionView fw_sizeWithCellClass:[TestCollectionDynamicLayoutCell class]
                                  cacheByIndexPath:indexPath
                                     configuration:^(TestCollectionDynamicLayoutCell *cell) {
            cell.object = [self.collectionData objectAtIndex:indexPath.row];
        }];
    } else if (self.mode == 1) {
        return [collectionView fw_sizeWithCellClass:[TestCollectionDynamicLayoutCell class]
                                             width:FWScreenWidth - 30
                                  cacheByIndexPath:indexPath
                                     configuration:^(TestCollectionDynamicLayoutCell *cell) {
            cell.object = [self.collectionData objectAtIndex:indexPath.row];
        }];
    } else {
        return [collectionView fw_sizeWithCellClass:[TestCollectionDynamicLayoutCell class]
                                            height:FWScreenHeight - FWTopBarHeight
                                  cacheByIndexPath:indexPath
                                     configuration:^(TestCollectionDynamicLayoutCell *cell) {
            cell.object = [self.collectionData objectAtIndex:indexPath.row];
        }];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.collectionData.count < 1) {
        return CGSizeZero;
    }
    if (self.mode == 0) {
        return [collectionView fw_sizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                      kind:UICollectionElementKindSectionHeader
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            [reusableView renderData:@"我是集合Header\n我是集合Header"];
        }];
    } else if (self.mode == 1) {
        return [collectionView fw_sizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                     width:FWScreenWidth - 30
                                                      kind:UICollectionElementKindSectionHeader
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            [reusableView renderData:@"我是集合Header\n我是集合Header"];
        }];
    } else {
        return [collectionView fw_sizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                    height:FWScreenHeight - FWTopBarHeight
                                                      kind:UICollectionElementKindSectionHeader
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            [reusableView renderData:@"我是集合Header\n我是集合Header"];
        }];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if (self.collectionData.count < 1) {
        return CGSizeZero;
    }
    if (self.mode == 0) {
        return [collectionView fw_sizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                      kind:UICollectionElementKindSectionFooter
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            [reusableView renderData:@"我是集合Footer\n我是集合Footer\n我是集合Footer"];
        }];
    } else if (self.mode == 1) {
        return [collectionView fw_sizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                     width:FWScreenWidth - 30
                                                      kind:UICollectionElementKindSectionFooter
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            [reusableView renderData:@"我是集合Footer\n我是集合Footer\n我是集合Footer"];
        }];
    } else {
        return [collectionView fw_sizeWithReusableViewClass:[TestCollectionDynamicLayoutHeaderView class]
                                                    height:FWScreenHeight - FWTopBarHeight
                                                      kind:UICollectionElementKindSectionFooter
                                            cacheBySection:section
                                             configuration:^(TestCollectionDynamicLayoutHeaderView * _Nonnull reusableView) {
            [reusableView renderData:@"我是集合Footer\n我是集合Footer\n我是集合Footer"];
        }];
    }
}

- (TestCollectionDynamicLayoutObject *)randomObject
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
            @"Loading.gif",
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
    object.title = [[randomArray objectAtIndex:0] fw_randomObject];
    object.text = [[randomArray objectAtIndex:1] fw_randomObject];
    NSString *imageName =[[randomArray objectAtIndex:2] fw_randomObject];
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
        [self.collectionView fw_clearSizeCache];
        [self.collectionView fw_reloadDataWithoutAnimation];
        
        self.collectionView.fw_shouldRefreshing = self.collectionData.count < 20 ? YES : NO;
        [self.collectionView fw_endRefreshing];
        if (!self.collectionView.fw_shouldRefreshing) {
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
            [self.collectionData addObject:[self randomObject]];
        }
        [self.collectionView fw_reloadDataWithoutAnimation];
        
        self.collectionView.fw_loadingFinished = self.collectionData.count >= 20 ? YES : NO;
        [self.collectionView fw_endLoading];
    });
}

@end
