//
//  TestPopupMenuViewController.m
//  Example
//
//  Created by wuyong on 2020/5/9.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestPopupMenuViewController.h"

#define TITLES @[@"修改", @"删除", @"扫一扫",@"付款"]
#define ICONS  @[[TestBundle imageNamed:@"icon_modify"],[TestBundle imageNamed:@"icon_delete"],[TestBundle imageNamed:@"icon_scan"],[TestBundle imageNamed:@"icon_pay"]]

@interface TestPopupMenuViewController () <FWPopupMenuDelegate,UITextFieldDelegate>

@property (weak, nonatomic) UITextField *textField;
@property (weak, nonatomic) UILabel *customCellView;

@property (nonatomic, strong) FWPopupMenu *popupMenu;

@end

@implementation TestPopupMenuViewController

- (void)renderView
{
    UIButton *button = [UIButton fwButtonWithImage:[TestBundle imageNamed:@"icon_scan"]];
    [button fwAddTouchTarget:self action:@selector(onPopupClick:)];
    [self.fwView addSubview:button];
    button.fwLayoutChain.leftWithInset(10).topWithInset(10).size(CGSizeMake(44, 44));
    
    button = [UIButton fwButtonWithImage:[TestBundle imageNamed:@"icon_scan"]];
    [button fwAddTouchTarget:self action:@selector(onPopupClick:)];
    [self.fwView addSubview:button];
    button.fwLayoutChain.rightWithInset(10).topWithInset(10).size(CGSizeMake(44, 44));
    
    button = [UIButton fwButtonWithImage:[TestBundle imageNamed:@"icon_scan"]];
    [button fwAddTouchTarget:self action:@selector(onPopupClick:)];
    [self.fwView addSubview:button];
    button.fwLayoutChain.leftWithInset(10).bottomWithInset(10).size(CGSizeMake(44, 44));
    
    button = [UIButton fwButtonWithImage:[TestBundle imageNamed:@"icon_scan"]];
    [button fwAddTouchTarget:self action:@selector(onPopupClick:)];
    [self.fwView addSubview:button];
    button.fwLayoutChain.rightWithInset(10).bottomWithInset(10).size(CGSizeMake(44, 44));
    
    UITextField *textField = [UITextField new];
    textField.placeholder = @"我是输入框";
    textField.textColor = [Theme textColor];
    [textField fwSetBorderColor:[Theme borderColor] width:0.5 cornerRadius:5];
    _textField = textField;
    textField.delegate = self;
    [self.fwView addSubview:textField];
    textField.fwLayoutChain.leftWithInset(50).rightWithInset(50).topWithInset(200).height(45);
    
    UILabel *customLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:16] textColor:[Theme textColor] text:@"我是自定义标签"];
    _customCellView = customLabel;
    customLabel.backgroundColor = [Theme cellColor];
    [self.fwView addSubview:customLabel];
    customLabel.fwLayoutChain.centerX().topToBottomOfViewWithOffset(textField, 50).size(CGSizeMake(200, 50));
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)onPopupClick:(UIButton *)sender {
    [FWPopupMenu showRelyOnView:sender titles:TITLES icons:ICONS menuWidth:120 otherSettings:^(FWPopupMenu *popupMenu) {
        popupMenu.delegate = self;
    }];
}

- (void)onTestClick:(UIButton *)sender {
    [FWPopupMenu showRelyOnView:sender titles:@[@"111",@"222",@"333",@"444",@"555",@"666",@"777",@"888"] icons:nil menuWidth:100 otherSettings:^(FWPopupMenu *popupMenu) {
        popupMenu.priorityDirection = FWPopupMenuPriorityDirectionLeft;
        popupMenu.borderWidth = 1;
        popupMenu.borderColor = [UIColor redColor];
        popupMenu.arrowPosition = 22;
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *t = touches.anyObject;
    CGPoint p = [t locationInView: self.view.window];
    
    CGRect customFrame = [self.customCellView.superview convertRect:self.customCellView.frame toView:self.view.window];
    if (CGRectContainsPoint(customFrame, p)) {
        [self showCustomPopupMenuWithPoint:p];
    }else {
        [self showDarkPopupMenuWithPoint:p];
    }
}

- (void)showDarkPopupMenuWithPoint:(CGPoint)point
{
    [FWPopupMenu showAtPoint:point titles:TITLES icons:nil menuWidth:110 otherSettings:^(FWPopupMenu *popupMenu) {
        popupMenu.dismissOnSelected = NO;
        popupMenu.isShowShadow = YES;
        popupMenu.delegate = self;
        popupMenu.offset = 10;
        popupMenu.type = FWPopupMenuTypeDark;
        popupMenu.rectCorner = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }];
}

- (void)showCustomPopupMenuWithPoint:(CGPoint)point
{
    [FWPopupMenu showAtPoint:point titles:TITLES icons:nil menuWidth:110 otherSettings:^(FWPopupMenu *popupMenu) {
        popupMenu.dismissOnSelected = YES;
        popupMenu.isShowShadow = YES;
        popupMenu.delegate = self;
        popupMenu.type = FWPopupMenuTypeDefault;
        popupMenu.cornerRadius = 8;
        popupMenu.rectCorner = UIRectCornerTopLeft| UIRectCornerTopRight;
        popupMenu.tag = 100;
        //如果不加这句默认是 UITableViewCellSeparatorStyleNone 的
        popupMenu.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }];
}

#pragma mark - FWPopupMenuDelegate
- (void)popupMenu:(FWPopupMenu *)popupMenu didSelectedAtIndex:(NSInteger)index
{
    //推荐回调
    NSLog(@"点击了 %@ 选项",popupMenu.titles[index]);
}

- (void)popupMenuBeganDismiss:(FWPopupMenu *)popupMenu
{
    if (self.textField.isFirstResponder) {
        [self.textField resignFirstResponder];
    }
}

- (UITableViewCell *)popupMenu:(FWPopupMenu *)popupMenu cellForRowAtIndex:(NSInteger)index
{
    if (popupMenu.tag != 100) {
        return nil;
    }
    static NSString * identifier = @"customCell";
    UITableViewCell * cell = [popupMenu.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"customCell"];
    }
    
    cell.textLabel.text = TITLES[index];
    cell.imageView.image = ICONS[index];
    return cell;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _popupMenu = [FWPopupMenu showRelyOnView:textField titles:@[@"密码必须为数字、大写字母、小写字母和特殊字符中至少三种的组合，长度不少于8且不大于20"] icons:nil menuWidth:textField.bounds.size.width otherSettings:^(FWPopupMenu *popupMenu) {
        popupMenu.delegate = self;
        popupMenu.showMaskView = NO;
        popupMenu.priorityDirection = FWPopupMenuPriorityDirectionBottom;
        popupMenu.maxVisibleCount = 1;
        popupMenu.itemHeight = 60;
        popupMenu.borderWidth = 1;
        popupMenu.fontSize = 12;
        popupMenu.dismissOnTouchOutside = YES;
        popupMenu.dismissOnSelected = NO;
        popupMenu.borderColor = [UIColor brownColor];
        popupMenu.textColor = [UIColor brownColor];
        popupMenu.animationManager.style = FWPopupMenuAnimationStyleFade;
        popupMenu.animationManager.duration = 0.15;
    }];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_popupMenu dismiss];
    return YES;
}

@end
