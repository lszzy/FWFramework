//
//  TestTableScrollViewController.m
//  Example
//
//  Created by wuyong on 2018/12/13.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestTableScrollViewController.h"

@interface TestTableScrollObject : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) UIImage *image;

@end

@implementation TestTableScrollObject

@end

@interface TestTableScrollCell : UITableViewCell

@property (nonatomic, strong) TestTableScrollObject *object;

@property (nonatomic, strong) UILabel *myTitleLabel;

@property (nonatomic, strong) UILabel *myTextLabel;

@property (nonatomic, strong) UIImageView *myImageView;

@end

@implementation TestTableScrollCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.fwSeparatorInset = UIEdgeInsetsZero;
        
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

- (void)setObject:(TestTableScrollObject *)object
{
    _object = object;
    // 自动收缩
    self.myTitleLabel.text = object.title;
    self.myImageView.image = object.image;
    // 手工收缩
    self.myTextLabel.text = object.text;
    if (object.text.length > 0) {
        self.myTextLabel.fwCollapsed = NO;
    } else {
        self.myTextLabel.fwCollapsed = YES;
    }
}

@end

@interface TestTableScrollViewController ()

@end

@implementation TestTableScrollViewController

- (void)renderView
{
    FWInfiniteScrollView.height = 64;
    [self.tableView fwAddPullRefreshWithTarget:self action:@selector(onRefreshing)];
    [self.tableView fwAddInfiniteScrollWithTarget:self action:@selector(onLoading)];
    
    UIImageView *pullView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    pullView.fwImage = [UIImage fwImageMake:@"loading.gif"];
    [self.tableView.fwPullRefreshView setCustomView:pullView forState:FWPullRefreshStateAll];
    
    UIImageView *infiniteView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    infiniteView.fwImage = [UIImage fwImageMake:@"LoadingPlaceholder.gif"];
    [self.tableView.fwInfiniteScrollView setCustomView:infiniteView forState:FWInfiniteScrollStateAll];
}

- (void)renderData
{
    [self.tableView fwTriggerInfiniteScroll];
}

#pragma mark - TableView

- (void)renderTableView
{
    [super renderTableView];
    [self.tableView registerClass:[TestTableScrollCell class] forCellReuseIdentifier:@"Cell"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 渲染可重用Cell
    TestTableScrollCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TestTableScrollObject *object = [self.tableData objectAtIndex:indexPath.row];
    cell.object = object;
    return cell;
}

- (TestTableScrollObject *)randomObject
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
                                 @"tabbar_settings",
                                 @"public_picture",
                                 ]];
    });
    
    TestTableScrollObject *object = [TestTableScrollObject new];
    object.title = [[randomArray objectAtIndex:0] fwRandomObject];
    object.text = [[randomArray objectAtIndex:1] fwRandomObject];
    NSString *imageName =[[randomArray objectAtIndex:2] fwRandomObject];
    if (imageName.length > 0) {
        object.image = [UIImage imageNamed:imageName];
    }
    return object;
}

- (void)onRefreshing
{
    NSLog(@"开始刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        for (int i = 0; i < 1; i++) {
            [self.tableData addObject:[self randomObject]];
        }
        [self.tableView reloadData];
        
        self.tableView.fwShowPullRefresh = self.tableData.count < 20 ? YES : NO;
        [self.tableView.fwPullRefreshView stopAnimating];
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
        
        self.tableView.fwShowInfiniteScroll = self.tableData.count < 20 ? YES : NO;
        [self.tableView.fwInfiniteScrollView stopAnimating];
    });
}

@end
