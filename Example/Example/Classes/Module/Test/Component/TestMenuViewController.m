//
//  TestMenuViewController.m
//  Example
//
//  Created by wuyong on 2019/5/9.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestMenuViewController.h"

@interface TestMenuViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation TestMenuViewController

- (void)renderInit
{
    [self fwSetBarExtendEdge:UIRectEdgeTop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fwSetLeftBarItem:@"Menu" block:^(id sender) {
        FWStrongifySelf();
        FWDrawerView *drawerView = self.contentView.fwDrawerView;
        CGFloat position = (drawerView.position == drawerView.openPosition) ? drawerView.closePosition : drawerView.openPosition;
        [drawerView setPosition:position animated:YES];
    }];
    
    UIBarButtonItem *systemItem = [UIBarButtonItem fwBarItemWithObject:@"系统" target:self action:@selector(onSystemSheet:)];
    UIBarButtonItem *customItem = [UIBarButtonItem fwBarItemWithObject:@"自定义" target:self action:@selector(onPhotoSheet:)];
    self.navigationItem.rightBarButtonItems = @[systemItem, customItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar fwSetBackgroundClear];
}

- (void)renderView
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(-FWScreenWidth / 2.0, 0, FWScreenWidth / 2.0, self.view.fwHeight)];
    _contentView = contentView;
    contentView.backgroundColor = [UIColor brownColor];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 200, 100, 30)];
    topLabel.text = @"Menu 1";
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 250, 100, 30)];
    middleLabel.text = @"Menu 2";
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 300, 100, 30)];
    bottomLabel.text = @"Menu 3";
    [contentView addSubview:bottomLabel];
    UILabel *closeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 400, 100, 30)];
    closeLabel.text = @"Back";
    FWWeakifySelf();
    closeLabel.userInteractionEnabled = YES;
    [closeLabel fwAddTapGestureWithBlock:^(id sender) {
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:YES];
    }];
    [contentView addSubview:closeLabel];
    [self.view addSubview:contentView];
    
    [contentView fwDrawerView:UISwipeGestureRecognizerDirectionRight
                    positions:@[@(-FWScreenWidth / 2.0), @(0)]
               kickbackHeight:25
                     callback:nil];
    
    UIImageView *imageView = [UIImageView new];
    _imageView = imageView;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    imageView.fwLayoutChain.center().size(CGSizeMake(200, 200));
}

- (void)onSystemSheet:(UIBarButtonItem *)sender
{
    FWWeakifySelf();
    [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"拍照", @"选择照片", @"选取相册"] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index == 0) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController *pickerController = [UIImagePickerController fwPickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera completion:^(NSDictionary * _Nonnull info, BOOL cancel) {
                    [self onPickerResult:cancel ? nil : info[UIImagePickerControllerEditedImage] cancelled:cancel];
                }];
                pickerController.allowsEditing = YES;
                [self presentViewController:pickerController animated:YES completion:nil];
            } else {
                [self fwShowAlertWithTitle:@"未检测到您的摄像头" message:nil cancel:@"关闭" cancelBlock:nil];
            }
        } else {
            UIImagePickerController *pickerController = [UIImagePickerController fwPickerControllerWithSourceType:(index == 1) ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeSavedPhotosAlbum completion:^(NSDictionary * _Nonnull info, BOOL cancel) {
                [self onPickerResult:cancel ? nil : info[UIImagePickerControllerEditedImage] cancelled:cancel];
            }];
            pickerController.allowsEditing = YES;
            [self presentViewController:pickerController animated:YES completion:nil];
        }
    }];
}

- (void)onPhotoSheet:(UIBarButtonItem *)sender
{
    FWWeakifySelf();
    [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"拍照", @"选择照片", @"选取相册"] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index == 0) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController *pickerController = [UIImagePickerController fwPickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera cropController:nil completion:^(UIImage * _Nonnull image, BOOL cancel) {
                    [self onPickerResult:cancel ? nil : image cancelled:cancel];
                }];
                [self presentViewController:pickerController animated:YES completion:nil];
            } else {
                [self fwShowAlertWithTitle:@"未检测到您的摄像头" message:nil cancel:@"关闭" cancelBlock:nil];
            }
        } else {
            UIImagePickerController *pickerController = [UIImagePickerController fwPickerControllerWithSourceType:(index == 1) ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeSavedPhotosAlbum cropController:nil completion:^(UIImage * _Nullable image, BOOL cancel) {
                [self onPickerResult:cancel ? nil : image cancelled:cancel];
            }];
            [self presentViewController:pickerController animated:YES completion:nil];
        }
    }];
}

- (void)onPickerResult:(UIImage *)image cancelled:(BOOL)cancelled
{
    self.imageView.image = cancelled ? nil : image;
}

@end
