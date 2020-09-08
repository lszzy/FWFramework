/*!
 @header     UITableView+FWBackgroundView.m
 @indexgroup FWFramework
 @brief      UITableView+FWBackgroundView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/11/25
 */

#import "UITableView+FWBackgroundView.h"
#import "FWLayoutManager.h"
#import <objc/runtime.h>

@implementation FWTableViewCellBackgroundView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.layer.masksToBounds = NO;
        [self addSubview:_contentView];
        [_contentView fwPinEdgesToSuperview];
    }
    return self;
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    
    [self.contentView fwPinEdgesToSuperviewWithInsets:contentInset];
}

- (void)setSectionContentInset:(UIEdgeInsets)contentInset tableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionRows = [tableView numberOfRowsInSection:indexPath.section];
    BOOL isFirstRow = (indexPath.row == 0);
    BOOL isLastRow = (indexPath.row == sectionRows - 1);
    if (isFirstRow && isLastRow) {
        self.contentInset = contentInset;
    } else if (isFirstRow) {
        self.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, -contentInset.bottom, contentInset.right);
    } else if (isLastRow) {
        self.contentInset = UIEdgeInsetsMake(-contentInset.top, contentInset.left, contentInset.bottom, contentInset.right);
    } else {
        self.contentInset = UIEdgeInsetsMake(-contentInset.top, contentInset.left, -contentInset.bottom, contentInset.right);
    }
}

@end

@implementation UITableViewCell (FWBackgroundView)

- (FWTableViewCellBackgroundView *)fwBackgroundView
{
    FWTableViewCellBackgroundView *backgroundView = objc_getAssociatedObject(self, _cmd);
    if (!backgroundView) {
        backgroundView = [[FWTableViewCellBackgroundView alloc] initWithFrame:CGRectZero];
        objc_setAssociatedObject(self, _cmd, backgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // 需设置cell背景色为透明
        self.backgroundColor = [UIColor clearColor];
        self.backgroundView = backgroundView;
    }
    return backgroundView;
}

@end
