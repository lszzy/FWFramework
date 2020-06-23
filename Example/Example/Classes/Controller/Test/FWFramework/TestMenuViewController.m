//
//  TestMenuViewController.m
//  Example
//
//  Created by wuyong on 2019/5/9.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestMenuViewController.h"

@interface TestMenuViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, FWCropViewControllerDelegate>

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
    
    UIBarButtonItem *systemItem = [UIBarButtonItem fwBarItemWithObject:@"系统" target:self action:@selector(onPhotoSheet:)];
    systemItem.fwTempObject = @NO;
    UIBarButtonItem *customItem = [UIBarButtonItem fwBarItemWithObject:@"自定义" target:self action:@selector(onPhotoSheet:)];
    customItem.fwTempObject = @YES;
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

- (void)onPhotoSheet:(UIBarButtonItem *)sender
{
    FWWeakifySelf();
    [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"拍照", @"选择照片", @"选取相册"] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index == 0) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
                pickerController.delegate = self;
                pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                if ([sender.fwTempObject fwAsBool]) {
                    pickerController.allowsEditing = NO;
                } else {
                    pickerController.allowsEditing = YES;
                }
                pickerController.fwTempObject = sender.fwTempObject;
                [self presentViewController:pickerController animated:YES completion:nil];
            } else {
                [self fwShowAlertWithTitle:@"未检测到您的摄像头" message:nil cancel:@"关闭" cancelBlock:nil];
            }
        } else {
            UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
            pickerController.delegate = self;
            pickerController.sourceType = (index == 1) ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            if ([sender.fwTempObject fwAsBool]) {
                pickerController.allowsEditing = NO;
            } else {
                pickerController.allowsEditing = YES;
            }
            pickerController.fwTempObject = sender.fwTempObject;
            [self presentViewController:pickerController animated:YES completion:nil];
        }
    }];
}

- (void)onPickerResult:(UIImage *)image cancelled:(BOOL)cancelled
{
    self.imageView.image = cancelled ? nil : image;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    if ([picker.fwTempObject fwAsBool]) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        FWCropViewController *cropController = [[FWCropViewController alloc] initWithCroppingStyle:FWCropViewCroppingStyleDefault image:image];
        cropController.aspectRatioPreset = FWCropViewControllerAspectRatioPresetSquare;
        cropController.aspectRatioLockEnabled = YES;
        cropController.resetAspectRatioEnabled = NO;
        cropController.aspectRatioPickerButtonHidden = YES;
        cropController.delegate = self;
        [picker pushViewController:cropController animated:YES];
    } else {
        UIImage *image = info[UIImagePickerControllerEditedImage];
        [picker dismissViewControllerAnimated:YES completion:^{
            [self onPickerResult:image cancelled:NO];
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self onPickerResult:nil cancelled:YES];
    }];
}

#pragma mark - FWCropViewControllerDelegate

- (void)cropViewController:(FWCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    [cropViewController dismissViewControllerAnimated:YES completion:^{
        [self onPickerResult:image cancelled:NO];
    }];
}

@end
