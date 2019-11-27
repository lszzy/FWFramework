/*!
 @header     UITableView+FWBackgroundView.h
 @indexgroup FWFramework
 @brief      UITableView+FWBackgroundView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/11/25
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief TableViewCell背景视图，处理section圆角、阴影等
 */
@interface FWTableViewCellBackgroundView : UIView

// 背景内容视图，此视图用于设置圆角，阴影等
@property (nonatomic, strong, readonly) UIView *contentView;

// 内容视图间距，处理section圆角时该值可能为负。默认zoro占满
@property (nonatomic, assign) UIEdgeInsets contentInset;

// 设置section内容间距，设置后再设置圆角，阴影即可。第一个顶部间距(底部超出)，最后一个底部间距(顶部超出)，中间无上下间距(上下超出)
- (void)setSectionContentInset:(UIEdgeInsets)contentInset tableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;

@end

/*!
 @brief UITableViewCell+FWBackgroundView
 @discussion backgroundView不会影响contentView布局等，如果设置了contentInset，注意布局时留出对应间距
 */
@interface UITableViewCell (FWBackgroundView)

// 延迟加载背景视图，处理section圆角、阴影等。会自动设置backgroundView
@property (nonatomic, strong, readonly) FWTableViewCellBackgroundView *fwBackgroundView;

@end

NS_ASSUME_NONNULL_END
