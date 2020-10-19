//
//  TestTableCreateViewController.m
//  Example
//
//  Created by wuyong on 2020/9/27.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestTableCreateViewController.h"

@interface TestTableCreateCell : UITableViewCell

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *iconLabel;

@end

@implementation TestTableCreateCell

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
        
        UILabel *iconLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlack] text:@"我是文本"];
        _iconLabel = iconLabel;
        [self.contentView addSubview:iconLabel];
        iconLabel.fwLayoutChain.centerY().rightWithInset(20).leftToRightOfViewWithOffset(iconView, 20);
    }
    return self;
}

- (void)setFwViewModel:(id)fwViewModel
{
    [super setFwViewModel:fwViewModel];
    self.iconLabel.text = [NSString stringWithFormat:@"我是文本%@", fwViewModel];
}

@end

@interface TestTableCreateHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) id object;

@end

@implementation TestTableCreateHeaderView

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
        
        UILabel *iconLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlack] text:@"我是头视图"];
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

@interface TestTableCreateFooterView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) id object;

@end

@implementation TestTableCreateFooterView

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
        
        UILabel *iconLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlack] text:@"我是尾视图"];
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

@interface TestTableCreateTableHeaderView : UIView

@property (nonatomic, strong) UIView *testView;
@property (nonatomic, strong) UIView *childView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation TestTableCreateTableHeaderView

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
        childView.backgroundColor = [UIColor blueColor];
        [rightView addSubview:childView];
        childView.fwLayoutChain.edgesWithInsets(UIEdgeInsetsMake(10, 10, 10, 10));
        
        UIImageView *imageView = [UIImageView new];
        _imageView = imageView;
        imageView.image = [UIImage imageNamed:@"test_scale"];
        [imageView fwSetContentModeAspectFill];
        [imageView fwSetCornerRadius:5];
        [self addSubview:imageView];
        imageView.fwLayoutChain.centerXToView(testView)
            .topToBottomOfViewWithOffset(testView, 20).size(CGSizeMake(50, 50));
        
        UIView *childView2 = [UIView new];
        childView2.backgroundColor = [UIColor blueColor];
        [self addSubview:childView2];
        childView2.fwLayoutChain.centerXToView(childView)
            .centerYToView(imageView).sizeToView(childView)
            .bottomWithInset(20);
    }
    return self;
}

@end

@interface TestTableCreateTableFooterView : UIView

@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UILabel *label2;
@property (nonatomic, strong) UITextView *textView1;
@property (nonatomic, strong) UITextView *textView2;

@end

@implementation TestTableCreateTableFooterView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *label1 = [UILabel new];
        _label1 = label1;
        label1.textColor = [UIColor blueColor];
        label1.text = @"我是Label1";
        [self addSubview:label1];
        label1.fwLayoutChain.leftWithInset(20).topWithInset(20);
        
        UILabel *label2 = [UILabel new];
        _label2 = label2;
        label2.font = [UIFont systemFontOfSize:12];
        label2.textColor = [UIColor blueColor];
        label2.numberOfLines = 0;
        label2.text = @"我是Label2222222222\n我是Label22222\n我是Label2";
        [self addSubview:label2];
        label2.fwLayoutChain.topWithInset(20).rightWithInset(20)
            .size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
        
        UITextView *textView1 = [UITextView new];
        _textView1 = textView1;
        textView1.editable = NO;
        textView1.textColor = [UIColor blueColor];
        textView1.text = @"我是TextView1";
        [self addSubview:textView1];
        textView1.fwLayoutChain.leftWithInset(20)
            .topToBottomOfViewWithOffset(label1, 20)
            .size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
        
        UITextView *textView2 = [UITextView new];
        _textView2 = textView2;
        textView2.font = [UIFont systemFontOfSize:12];
        textView2.editable = NO;
        textView2.textColor = [UIColor blueColor];
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

@interface TestTableCreateViewController ()

@property (nonatomic, strong) FWTableView *tableView;

@end

@implementation TestTableCreateViewController

- (void)renderView
{
    self.tableView = [[FWTableView alloc] init];
    FWWeakifySelf();
    self.tableView.cellClassForRow = ^Class _Nonnull(NSIndexPath * indexPath) {
        return [TestTableCreateCell class];
    };
    self.tableView.didSelectRow = ^(NSIndexPath * indexPath) {
        FWStrongifySelf();
        [self fwShowAlertWithTitle:nil message:[NSString stringWithFormat:@"点击了%@", @(indexPath.row)] cancel:@"关闭" cancelBlock:nil];
    };
    
    self.tableView.viewClassForHeader = ^id _Nullable(NSInteger section) {
        FWStrongifySelf();
        TestTableCreateHeaderView *viewForHeader = [TestTableCreateHeaderView fwHeaderFooterViewWithTableView:self.tableView.tableView];
        viewForHeader.object = @1;
        
        CGFloat height = [self.tableView.tableView fwHeightWithHeaderFooterViewClass:[TestTableCreateHeaderView class] type:FWHeaderFooterViewTypeHeader configuration:^(TestTableCreateHeaderView * _Nonnull headerFooterView) {
            headerFooterView.object = @1;
        }];
        viewForHeader.frame = CGRectMake(0, 0, self.tableView.tableView.fwWidth, height);
        return viewForHeader;
    };
    self.tableView.viewClassForFooter = ^id _Nullable(NSInteger section) {
        return [TestTableCreateFooterView class];
    };
    self.tableView.viewForFooter = ^(TestTableCreateFooterView * _Nonnull headerFooterView, NSInteger section) {
        headerFooterView.object = @1;
    };
    
    UIView *headerView = [[TestTableCreateTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 0)];
    UIView *footerView = [[TestTableCreateTableFooterView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 0)];
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = footerView;
    [headerView fwAutoLayoutSubviews];
    [footerView fwAutoLayoutSubviews];
    
    [self.view addSubview:self.tableView];
    [self.tableView fwPinEdgesToSuperview];
    
    [self.tableView.tableView fwSetRefreshingTarget:self action:@selector(onRefreshing)];
    [self.tableView.tableView fwSetLoadingTarget:self action:@selector(onLoading)];
}

- (void)renderModel
{
    FWWeakifySelf();
    [self fwSetRightBarItem:@(UIBarButtonSystemItemAdd) block:^(id sender) {
        FWStrongifySelf();
        NSMutableArray *sectionData = self.tableView.tableData[0].mutableCopy;
        NSInteger lastIndex = [sectionData.lastObject fwAsInteger];
        [sectionData addObjectsFromArray:@[@(lastIndex + 1), @(lastIndex + 2)]];
        self.tableView.tableData = @[sectionData];
        [self.tableView reloadData];
    }];
}

- (void)renderData
{
    [self.tableView.tableView fwBeginRefreshing];
}

- (void)onRefreshing
{
    NSLog(@"开始刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"刷新完成");
        
        self.tableView.tableData = @[@[@1, @2]];
        [self.tableView reloadData];
        
        [self.tableView.tableView fwEndRefreshing];
    });
}

- (void)onLoading
{
    NSLog(@"开始加载");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"加载完成");
        
        NSMutableArray *sectionData = self.tableView.tableData[0].mutableCopy;
        NSInteger lastIndex = [sectionData.lastObject fwAsInteger];
        [sectionData addObjectsFromArray:@[@(lastIndex + 1), @(lastIndex + 2)]];
        self.tableView.tableData = @[sectionData];
        [self.tableView reloadData];
        
        [self.tableView.tableView fwEndLoading];
    });
}

@end
