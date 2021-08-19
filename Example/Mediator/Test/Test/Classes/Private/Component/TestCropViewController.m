//
//  TestCropViewController.m
//  Example
//
//  Created by wuyong on 2020/6/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestCropViewController.h"

@interface TestCropViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, FWCropViewControllerDelegate>

@property (nonatomic, strong) UIImage *image;           // The image we'll be cropping
@property (nonatomic, strong) UIImageView *imageView;   // The image view to present the cropped image

@property (nonatomic, assign) FWCropViewCroppingStyle croppingStyle; //The cropping style
@property (nonatomic, assign) CGRect croppedFrame;
@property (nonatomic, assign) NSInteger angle;

@end

@implementation TestCropViewController

#pragma mark - Image Picker Delegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    FWCropViewController *cropController = [[FWCropViewController alloc] initWithCroppingStyle:self.croppingStyle image:image];
    cropController.delegate = self;

    // Uncomment this if you wish to provide extra instructions via a title label
    //cropController.title = @"Crop Image";

    // -- Uncomment these if you want to test out restoring to a previous crop setting --
    //cropController.angle = 90; // The initial angle in which the image will be rotated
    //cropController.imageCropFrame = CGRectMake(0,0,2848,4288); //The initial frame that the crop controller will have visible.
    
    // -- Uncomment the following lines of code to test out the aspect ratio features --
    //cropController.aspectRatioPreset = FWCropViewControllerAspectRatioPresetSquare; //Set the initial aspect ratio as a square
    //cropController.aspectRatioLockEnabled = YES; // The crop box is locked to the aspect ratio and can't be resized away from it
    //cropController.resetAspectRatioEnabled = NO; // When tapping 'reset', the aspect ratio will NOT be reset back to default
    //cropController.aspectRatioPickerButtonHidden = YES;

    // -- Uncomment this line of code to place the toolbar at the top of the view controller --
    //cropController.toolbarPosition = FWCropViewControllerToolbarPositionTop;
    
    // -- Uncomment this line of code to include only certain type of preset ratios
    //cropController.allowedAspectRatios = @[@(FWCropViewControllerAspectRatioPresetOriginal),
    //                                       @(FWCropViewControllerAspectRatioPresetSquare),
    //                                       @(FWCropViewControllerAspectRatioPreset3x2)];

    //cropController.rotateButtonsHidden = YES;
    //cropController.rotateClockwiseButtonHidden = NO;
    
    //cropController.doneButtonTitle = @"Title";
    //cropController.cancelButtonTitle = @"Title";

    // Uncomment this if you wish to always show grid
    //cropController.cropView.alwaysShowCroppingGrid = YES;

    // Uncomment this if you do not want translucency effect
    //cropController.cropView.translucencyAlwaysHidden = YES;

    self.image = image;
    
    //If profile picture, push onto the same navigation stack
    if (self.croppingStyle == FWCropViewCroppingStyleCircular) {
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            [picker dismissViewControllerAnimated:YES completion:^{
                [self presentViewController:cropController animated:YES completion:nil];
            }];
        } else {
            [picker pushViewController:cropController animated:YES];
        }
    }
    else { //otherwise dismiss, and then present from the main controller
        [picker dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:cropController animated:YES completion:nil];
            //[self.navigationController pushViewController:cropController animated:YES];
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Gesture Recognizer -
- (void)didTapImageView
{
    // When tapping the image view, restore the image to the previous cropping state
    FWCropViewController *cropController = [[FWCropViewController alloc] initWithCroppingStyle:self.croppingStyle image:self.image];
    cropController.delegate = self;
    [self presentViewController:cropController animated:YES completion:nil];
}

#pragma mark - Cropper Delegate -
- (void)cropViewController:(FWCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    self.croppedFrame = cropRect;
    self.angle = angle;
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}

- (void)cropViewController:(FWCropViewController *)cropViewController didCropToCircularImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    self.croppedFrame = cropRect;
    self.angle = angle;
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}

- (void)updateImageViewWithImage:(UIImage *)image fromCropViewController:(FWCropViewController *)cropViewController
{
    self.imageView.image = image;
    [self layoutImageView];
    
    if (cropViewController.croppingStyle != FWCropViewCroppingStyleCircular) {
        self.imageView.hidden = YES;
        [cropViewController dismissViewControllerAnimated:YES completion:^{
            self.imageView.hidden = NO;
        }];
    }
    else {
        self.imageView.hidden = NO;
        [cropViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Image Layout -
- (void)layoutImageView
{
    if (self.imageView.image == nil)
        return;
    
    CGFloat padding = 20.0f;
    
    CGRect viewFrame = self.view.bounds;
    viewFrame.size.width -= (padding * 2.0f);
    viewFrame.size.height -= ((padding * 2.0f));
    
    CGRect imageFrame = CGRectZero;
    imageFrame.size = self.imageView.image.size;
    
    if (self.imageView.image.size.width > viewFrame.size.width ||
        self.imageView.image.size.height > viewFrame.size.height)
    {
        CGFloat scale = MIN(viewFrame.size.width / imageFrame.size.width, viewFrame.size.height / imageFrame.size.height);
        imageFrame.size.width *= scale;
        imageFrame.size.height *= scale;
        imageFrame.origin.x = (CGRectGetWidth(self.view.bounds) - imageFrame.size.width) * 0.5f;
        imageFrame.origin.y = (CGRectGetHeight(self.view.bounds) - imageFrame.size.height) * 0.5f;
        self.imageView.frame = imageFrame;
    }
    else {
        self.imageView.frame = imageFrame;
        self.imageView.center = (CGPoint){CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)};
    }
}

#pragma mark - Bar Button Items -
- (void)showCropViewController
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Crop Image", @"")
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
                                               self.croppingStyle = FWCropViewCroppingStyleDefault;
                                               
                                               UIImagePickerController *standardPicker = [[UIImagePickerController alloc] init];
                                               standardPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                               standardPicker.allowsEditing = NO;
                                               standardPicker.delegate = self;
                                               [self presentViewController:standardPicker animated:YES completion:nil];
                                           }];
    
    UIAlertAction *profileAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Make Profile Picture", @"")
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action) {
                                             self.croppingStyle = FWCropViewCroppingStyleCircular;
                                             
                                             UIImagePickerController *profilePicker = [[UIImagePickerController alloc] init];
                                             profilePicker.modalPresentationStyle = UIModalPresentationPopover;
                                             profilePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                             profilePicker.allowsEditing = NO;
                                             profilePicker.delegate = self;
                                             profilePicker.preferredContentSize = CGSizeMake(512,512);
                                             profilePicker.popoverPresentationController.barButtonItem = self.fwNavigationItem.leftBarButtonItem;
                                             [self presentViewController:profilePicker animated:YES completion:nil];
                                         }];
    
    [alertController addAction:defaultAction];
    [alertController addAction:profileAction];
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
    popPresenter.barButtonItem = self.fwNavigationItem.leftBarButtonItem;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)sharePhoto:(id)sender
{
    if (self.imageView.image == nil)
        return;
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[self.imageView.image] applicationActivities:nil];
    activityController.modalPresentationStyle = UIModalPresentationPopover;
    activityController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Creation/Lifecycle -
- (void)viewDidLoad {
    [super viewDidLoad];
    self.fwNavigationItem.title = NSLocalizedString(@"FWCropViewController", @"");
    
    self.navigationController.navigationBar.translucent = NO;
    
    [self fwAddRightBarItem:FWIcon.addImage target:self action:@selector(showCropViewController)];
    [self fwAddRightBarItem:FWIcon.actionImage target:self action:@selector(sharePhoto:)];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.fwView addSubview:self.imageView];
    
    if (@available(iOS 11.0, *)) {
        self.imageView.accessibilityIgnoresInvertColors = YES;
    }
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapImageView)];
    [self.imageView addGestureRecognizer:tapRecognizer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutImageView];
}

@end
