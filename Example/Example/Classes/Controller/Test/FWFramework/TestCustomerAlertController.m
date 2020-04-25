//
//  TestCustomerAlertController.m
//  Example
//
//  Created by wuyong on 2020/4/25.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestCustomerAlertController.h"

// RGB颜色
#define FWColorRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define SYSTEM_COLOR [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]

// 随机色
#define FWRandomColor ZCColorRGBA(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256),1)

@interface TestCustomerAlertController ()

@property (nonatomic, assign) BOOL lookBlur;

@end

@implementation TestCustomerAlertController

- (void)renderData
{
    NSArray *tableData = @[
        @[@"actionSheet样式 默认动画(从底部弹出,有取消按钮)", @"actionSheetTest1"],
        @[@"actionSheet样式 默认动画(从底部弹出,无取消按钮)", @"actionSheetTest2"],
        @[@"actionSheet样式 从顶部弹出(无标题)", @"actionSheetTest3"],
        @[@"actionSheet样式 从顶部弹出(有标题)", @"actionSheetTest4"],
        @[@"actionSheet样式 水平排列（有取消样式按钮）", @"actionSheetTest5"],
        @[@"actionSheet样式 水平排列（无取消样式按钮)", @"actionSheetTest6"],
        @[@"actionSheet样式 action含图标", @"actionSheetTest7"],
        @[@"actionSheet样式 模拟多分区样式(>=iOS11才支持)", @"actionSheetTest8"],
    ];
    [self.tableData addObjectsFromArray:tableData];
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([rowData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector];
        FWIgnoredEnd();
    }
}

#pragma mark - Action

// 示例1:actionSheet的默认动画样式(从底部弹出，有取消按钮)
- (void)actionSheetTest1 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet];
    alertController.needDialogBlur = _lookBlur;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"Default" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Default ");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"Destructive" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Destructive");
    }];

    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"Cancel" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Cancel");
    }];
    [alertController addAction:action1];
    [alertController addAction:action3]; // 取消按钮一定排在最底部
    [alertController addAction:action2];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 示例2:actionSheet的默认动画(从底部弹出,无取消按钮)
- (void)actionSheetTest2 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet];
    alertController.needDialogBlur = _lookBlur;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"Default" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Default ");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"Destructive" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Destructive");
    }];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

// 示例3:actionSheet从顶部弹出(无标题)
- (void)actionSheetTest3 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:nil message:nil preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromTop];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例4:actionSheet从顶部弹出(有标题)
- (void)actionSheetTest4 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:nil message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromTop];
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    action3.titleColor = FWColorRGBA(30, 170, 40, 1);
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例5:actionSheet 水平排列（有取消按钮）
- (void)actionSheetTest5 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    alertController.actionAxis = UILayoutConstraintAxisHorizontal;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    FWAlertAction *action5 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    [alertController addAction:action5];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例6:actionSheet 水平排列（无取消按钮）
- (void)actionSheetTest6 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    alertController.actionAxis = UILayoutConstraintAxisHorizontal;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例7:actionSheet action上有图标
- (void)actionSheetTest7 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:nil message:nil preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"视频通话" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了‘视频通话’");
    }];
    action1.image = [UIImage imageNamed:@"public_icon"];
    action1.imageTitleSpacing = 5;
    
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"语音通话" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了‘语音通话’");
    }];
    action2.image = [UIImage imageNamed:@"public_icon"];
    action2.imageTitleSpacing = 5;
    
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例8:actionSheet 模拟多分区样式
- (void)actionSheetTest8 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    action1.titleColor = [UIColor orangeColor];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    action2.titleColor = [UIColor orangeColor];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    FWAlertAction *action5 = [FWAlertAction actionWithTitle:@"第5个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第5个");
    }];
    FWAlertAction *action6 = [FWAlertAction actionWithTitle:@"第6个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第6个");
    }];
    FWAlertAction *action7 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    action7.titleColor = SYSTEM_COLOR;
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    [alertController addAction:action5];
    [alertController addAction:action6];
    [alertController addAction:action7];
    
    if (@available(iOS 11.0, *)) {
        [alertController setCustomSpacing:6.0 afterAction:action2]; // 设置第2个action之后的间隙
    }
    if (@available(iOS 11.0, *)) {
        [alertController setCustomSpacing:6.0 afterAction:action4];  // 设置第4个action之后的间隙
    }
   
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
