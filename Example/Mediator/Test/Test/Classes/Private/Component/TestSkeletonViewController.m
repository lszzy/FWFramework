//
//  TestSkeletonViewController.m
//  Example
//
//  Created by wuyong on 2020/7/29.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestSkeletonViewController.h"

@interface TestSkeletonCell : UITableViewCell

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) id object;

@end

@implementation TestSkeletonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.fwMaxYViewPadding = 20;
        
        UIImageView *iconView = [UIImageView new];
        _iconView = iconView;
        iconView.image = [UIImage fwImageWithAppIcon];
        [self.contentView addSubview:iconView];
        iconView.fwLayoutChain.topWithInset(20).leftWithInset(20).size(CGSizeMake(50, 50));
        
        UILabel *iconLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:@"我是文本"];
        _iconLabel = iconLabel;
        [self.contentView addSubview:iconLabel];
        iconLabel.fwLayoutChain.centerY().rightWithInset(20).leftToRightOfViewWithOffset(iconView, 20);
    }
    return self;
}

- (void)setObject:(id)object
{
    _object = object;
    self.iconLabel.text = [NSString stringWithFormat:@"我是文本%@", object];
}

@end

@interface TestSkeletonHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) id object;

@end

@implementation TestSkeletonHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.fwMaxYViewPadding = 20;
        
        UIImageView *iconView = [UIImageView new];
        _iconView = iconView;
        iconView.image = [UIImage fwImageWithAppIcon];
        [self.contentView addSubview:iconView];
        iconView.fwLayoutChain.topWithInset(20).leftWithInset(20).size(CGSizeMake(20, 20));
        
        UILabel *iconLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:@"我是头视图"];
        _iconLabel = iconLabel;
        [self.contentView addSubview:iconLabel];
        iconLabel.fwLayoutChain.rightWithInset(20).centerYToView(iconView).leftToRightOfViewWithOffset(iconView, 20);
    }
    return self;
}

- (void)setObject:(id)object
{
    _object = object;
    self.iconLabel.text = [NSString stringWithFormat:@"我是头视图%@", object];
}

@end

@interface TestSkeletonFooterView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) id object;

@end

@implementation TestSkeletonFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.fwMaxYViewPadding = 20;
        
        UIImageView *iconView = [UIImageView new];
        _iconView = iconView;
        iconView.image = [UIImage fwImageWithAppIcon];
        [self.contentView addSubview:iconView];
        iconView.fwLayoutChain.topWithInset(20).leftWithInset(20).size(CGSizeMake(20, 20));
        
        UILabel *iconLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:@"我是尾视图"];
        _iconLabel = iconLabel;
        [self.contentView addSubview:iconLabel];
        iconLabel.fwLayoutChain.rightWithInset(20).centerYToView(iconView).leftToRightOfViewWithOffset(iconView, 20);
    }
    return self;
}

- (void)setObject:(id)object
{
    _object = object;
    self.iconLabel.text = [NSString stringWithFormat:@"我是尾视图%@", object];
}

@end

@interface TestSkeletonTableHeaderView : UIView

@property (nonatomic, strong) UIView *testView;
@property (nonatomic, strong) UIView *childView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation TestSkeletonTableHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *testView = [UIView new];
        _testView = testView;
        testView.backgroundColor = [UIColor redColor];
        [testView fwSetCornerRadius:5];
        [self addSubview:testView];
        testView.fwLayoutChain.leftWithInset(20).topWithInset(20)
            .size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
        
        UIView *rightView = [UIView new];
        rightView.backgroundColor = [UIColor redColor];
        [rightView fwSetCornerRadius:5];
        [self addSubview:rightView];
        rightView.fwLayoutChain.rightWithInset(20).topWithInset(20)
            .size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
        
        UIView *childView = [UIView new];
        _childView = childView;
        childView.backgroundColor = [UIColor yellowColor];
        [rightView addSubview:childView];
        childView.fwLayoutChain.edgesWithInsets(UIEdgeInsetsMake(10, 10, 10, 10));
        
        UIImageView *imageView = [UIImageView new];
        _imageView = imageView;
        imageView.image = [TestBundle imageNamed:@"test_scale"];
        [imageView fwSetContentModeAspectFill];
        [imageView fwSetCornerRadius:5];
        [self addSubview:imageView];
        imageView.fwLayoutChain.centerXToView(testView)
            .topToBottomOfViewWithOffset(testView, 20).size(CGSizeMake(50, 50));
        
        UIView *childView2 = [UIView new];
        childView2.backgroundColor = [UIColor yellowColor];
        [self addSubview:childView2];
        childView2.fwLayoutChain.centerXToView(childView)
            .centerYToView(imageView).sizeToView(childView)
            .bottomWithInset(20);
    }
    return self;
}

@end

@interface TestSkeletonTableFooterView : UIView

@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UILabel *label2;
@property (nonatomic, strong) UITextView *textView1;
@property (nonatomic, strong) UITextView *textView2;

@end

@implementation TestSkeletonTableFooterView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *label1 = [UILabel new];
        _label1 = label1;
        label1.textColor = [Theme textColor];
        label1.text = @"我是Label1";
        [self addSubview:label1];
        label1.fwLayoutChain.leftWithInset(20).topWithInset(20);
        
        UILabel *label2 = [UILabel new];
        _label2 = label2;
        label2.font = [UIFont systemFontOfSize:12];
        label2.textColor = [Theme textColor];
        label2.numberOfLines = 0;
        label2.text = @"我是Label2222222222\n我是Label22222\n我是Label2";
        [self addSubview:label2];
        label2.fwLayoutChain.topWithInset(20).rightWithInset(20)
            .size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
        
        UITextView *textView1 = [UITextView new];
        _textView1 = textView1;
        textView1.editable = NO;
        textView1.textColor = [Theme textColor];
        textView1.text = @"我是TextView1";
        [self addSubview:textView1];
        textView1.fwLayoutChain.leftWithInset(20)
            .topToBottomOfViewWithOffset(label1, 20)
            .size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
        
        UITextView *textView2 = [UITextView new];
        _textView2 = textView2;
        textView2.font = [UIFont systemFontOfSize:12];
        textView2.editable = NO;
        textView2.textColor = [Theme textColor];
        textView2.text = @"我是TextView2222\n我是TextView2\n我是TextView";
        [self addSubview:textView2];
        textView2.fwLayoutChain.rightWithInset(20)
            .topToBottomOfViewWithOffset(label2, 20)
            .size(CGSizeMake(FWScreenWidth / 2 - 40, 50))
            .bottomWithInset(20);
    }
    return self;
}

@end

@interface TestSkeletonViewController () <FWTableViewController, FWSkeletonViewDelegate>

@property (nonatomic, strong) TestSkeletonTableHeaderView *headerView;
@property (nonatomic, strong) TestSkeletonTableFooterView *footerView;
@property (nonatomic, assign) NSInteger scrollStyle;

@end

@implementation TestSkeletonViewController

- (void)renderTableView
{
    self.headerView = [[TestSkeletonTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 0)];
    self.footerView = [[TestSkeletonTableFooterView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 0)];
    
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
    [self.headerView fwAutoLayoutSubviews];
    [self.footerView fwAutoLayoutSubviews];
    
    [self.tableView fwSetRefreshingTarget:self action:@selector(onRefreshing)];
    [self.tableView fwSetLoadingTarget:self action:@selector(onLoading)];
}

- (void)renderModel
{
    FWWeakifySelf();
    [self fwSetRightBarItem:FWIcon.refreshImage block:^(id sender) {
        FWStrongifySelf();
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"shimmer", @"solid", @"scale", @"none", @"tableView滚动", @"scrollView滚动", @"添加数据"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            
            // tableView滚动
            if (index == 4) {
                self.scrollStyle = self.scrollStyle != 0 ? 0 : 1;
                [self renderData];
                return;
            }
            
            // scrollView滚动
            if (index == 5) {
                self.scrollStyle = self.scrollStyle != 0 ? 0 : 2;
                [self renderData];
                return;
            }
            
            // 添加数据
            if (index == 6) {
                NSInteger lastIndex = [self.tableData.lastObject fwAsInteger];
                [self.tableData addObjectsFromArray:@[@(lastIndex + 1), @(lastIndex + 2)]];
                [self.tableView reloadData];
                [self renderData];
                return;
            }
            
            // 切换动画
            FWSkeletonAnimation *animation = nil;
            if (index == 0) {
                animation = FWSkeletonAnimation.shimmer;
            } else if (index == 1) {
                animation = FWSkeletonAnimation.solid;
            } else if (index == 2) {
                animation = FWSkeletonAnimation.scale;
            }
            FWSkeletonAppearance.appearance.animation = animation;
            [self renderData];
        }];
    }];
}

- (void)renderData
{
    [self.tableView fwBeginRefreshing];
}

- (void)onRefreshing
{
    self.headerView.hidden = YES;
    self.footerView.hidden = YES;
    
    NSLog(@"开始刷新");
    [self fwShowSkeleton];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        [self fwHideSkeleton];
        
        self.headerView.hidden = NO;
        self.footerView.hidden = NO;
        
        [self.tableData removeAllObjects];
        [self.tableView reloadData];
        
        [self.tableView fwEndRefreshing];
    });
}

- (void)onLoading
{
    NSLog(@"开始加载");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"加载完成");
        
        NSInteger lastIndex = [self.tableData.lastObject fwAsInteger];
        [self.tableData addObjectsFromArray:@[@(lastIndex + 1), @(lastIndex + 2)]];
        [self.tableView reloadData];
        
        [self.tableView fwEndLoading];
    });
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView fwHeightWithCellClass:[TestSkeletonCell class] configuration:^(TestSkeletonCell * _Nonnull cell) {
        cell.object = self.tableData[indexPath.row];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TestSkeletonCell *cell = [TestSkeletonCell fwCellWithTableView:tableView];
    cell.object = self.tableData[indexPath.row];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TestSkeletonHeaderView *headerView = [TestSkeletonHeaderView fwHeaderFooterViewWithTableView:tableView];
    headerView.object = @1;
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [tableView fwHeightWithHeaderFooterViewClass:[TestSkeletonHeaderView class] type:FWHeaderFooterViewTypeHeader configuration:^(TestSkeletonHeaderView * _Nonnull headerFooterView) {
        headerFooterView.object = @1;
    }];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    TestSkeletonFooterView *footerView = [TestSkeletonFooterView fwHeaderFooterViewWithTableView:tableView];
    footerView.object = @1;
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [tableView fwHeightWithHeaderFooterViewClass:[TestSkeletonHeaderView class] type:FWHeaderFooterViewTypeFooter configuration:^(TestSkeletonHeaderView * _Nonnull headerFooterView) {
        headerFooterView.object = @1;
    }];
}

#pragma mark - FWSkeletonViewDelegate

- (void)skeletonViewLayout:(FWSkeletonLayout *)layout
{
    [layout setScrollView:self.tableView scrollBlock:nil];
    
    if (self.scrollStyle == 0) {
        FWSkeletonTableView *tableView = (FWSkeletonTableView *)[layout addSkeletonView:self.tableView];
        // 没有数据时需要指定cell，有数据时无需指定
        tableView.tableDelegate.cellClass = [TestSkeletonCell class];
        // 测试header直接指定类时自动计算高度
        tableView.tableDelegate.headerViewClass = [TestSkeletonHeaderView class];
    } else if (self.scrollStyle == 1) {
        FWSkeletonTableView *tableView = (FWSkeletonTableView *)[layout addSkeletonView:self.tableView];
        // 没有数据时需要指定cell，有数据时无需指定
        tableView.tableDelegate.cellClass = [TestSkeletonCell class];
        tableView.tableView.scrollEnabled = YES;
    } else {
        UIScrollView *scrollView = [UIScrollView fwScrollView];
        [layout addSubview:scrollView];
        scrollView.fwLayoutChain.edges();
        
        FWSkeletonTableView *tableView = (FWSkeletonTableView *)[FWSkeletonLayout parseSkeletonView:self.tableView];
        // 没有数据时需要指定cell，有数据时无需指定
        tableView.tableDelegate.cellClass = [TestSkeletonCell class];
        [layout addAnimationView:tableView];
        [scrollView.fwContentView addSubview:tableView];
        tableView.fwLayoutChain.edges();
    }
}

@end
