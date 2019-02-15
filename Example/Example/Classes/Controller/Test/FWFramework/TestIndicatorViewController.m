/*!
 @header     TestIndicatorViewController.m
 @indexgroup Example
 @brief      TestIndicatorViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "TestIndicatorViewController.h"

@interface TestIndicatorPushViewController : BaseViewController

@end

@implementation TestIndicatorPushViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwRandomColor]];
}

@end

@implementation TestIndicatorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fwSetBackBarBlock:^BOOL{
        FWStrongifySelf();
        [self fwShowConfirmWithTitle:nil message:@"是否关闭" cancel:@"否" confirm:@"是" confirmBlock:^{
            FWStrongifySelf();
            [self fwCloseViewControllerAnimated:YES];
        }];
        return NO;
    }];
}

- (void)renderData
{
    [self.dataList addObjectsFromArray:@[
                                         @[@"上下无文本", @"onIndicator"],
                                         @[@"上下文本", @"onIndicator2"],
                                         @[@"左右无文本", @"onIndicator3"],
                                         @[@"左右文本", @"onIndicator4"],
                                         @[@"加载动画", @"onLoading"],
                                         @[@"进度动画", @"onProgress"],
                                         @[@"加载动画(window)", @"onLoadingWindow"],
                                         @[@"进度动画(window)", @"onProgressWindow"],
                                         @[@"单行吐司", @"onToast"],
                                         @[@"多行吐司", @"onToast2"],
                                         @[@"新开界面", @"onPush"],
                                         ]];
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.dataList objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.dataList objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([rowData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector];
        FWIgnoredEnd();
    }
}

#pragma mark - Action

- (void)onIndicator
{
    [self.view fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:nil backgroundColor:nil dimBackgroundColor:nil horizontalAlignment:NO contentInsets:UIEdgeInsetsMake(10, 10, 5, 10) cornerRadius:5];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideIndicator];
    });
}

- (void)onIndicator2
{
    [self.view fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:@"正在加载..."]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideIndicator];
    });
}

- (void)onIndicator3
{
    [self.view fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleGray attributedTitle:nil backgroundColor:[UIColor clearColor] dimBackgroundColor:[UIColor whiteColor] horizontalAlignment:YES contentInsets:UIEdgeInsetsMake(10, 10, 10, 5) cornerRadius:5];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideIndicator];
    });
}

- (void)onIndicator4
{
    [self.view fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:@"正在加载..."] backgroundColor:nil dimBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f] horizontalAlignment:YES contentInsets:UIEdgeInsetsMake(10, 10, 10, 10) cornerRadius:5];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideIndicator];
    });
}

- (void)onLoading
{
    [self.view fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:@"加载中\n请耐心等待"]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideIndicator];
    });
}

- (void)onProgress
{
    [self.view fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:@"上传中"]];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view fwHideIndicator];
        });
    });
}

- (void)mockProgress
{
    float progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.02f;
        BOOL finish = progress >= 1.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:finish ? @"上传完成" : [NSString stringWithFormat:@"上传中(%.0f%%)", progress * 100]]];
        });
        usleep(finish ? 2000000 : 50000);
    }
}

- (void)onLoadingWindow
{
    [self.view.window fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:@"加载中"]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.window fwHideIndicator];
    });
}

- (void)onProgressWindow
{
    [self.view.window fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:@"上传中"]];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgressWindow];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.window fwHideIndicator];
        });
    });
}

- (void)mockProgressWindow
{
    float progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.02f;
        BOOL finish = progress >= 1.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.window fwShowIndicatorWithStyle:UIActivityIndicatorViewStyleWhite attributedTitle:[[NSAttributedString alloc] initWithString:finish ? @"上传完成" : [NSString stringWithFormat:@"上传中(%.0f%%)", progress * 100]]];
        });
        usleep(finish ? 2000000 : 50000);
    }
}

- (void)onToast
{
    self.view.tag = 100;
    NSString *text = @"吐司消息";
    [self.view fwShowToastWithAttributedText:[[NSAttributedString alloc] initWithString:text ? text : @""]];
    [self.view fwHideToastAfterDelay:2.0 completion:nil];
}

- (void)onToast2
{
    NSString *text = @"我是很长很长很长很长很长很长很长很长很长很长很长的吐司消息";
    [self.view fwShowToastWithAttributedText:[[NSAttributedString alloc] initWithString:text ? text : @""]];
    FWWeakifySelf();
    [self.view fwHideToastAfterDelay:2.0 completion:^{
        FWStrongifySelf();
        
        [self onToast];
    }];
}

- (void)onPush
{
    TestIndicatorPushViewController *viewController = [TestIndicatorPushViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
