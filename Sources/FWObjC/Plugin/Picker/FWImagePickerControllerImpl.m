//
//  FWImagePickerControllerImpl.m
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePickerControllerImpl.h"

#pragma mark - FWImagePickerControllerImpl

@implementation FWImagePickerControllerImpl

+ (FWImagePickerControllerImpl *)sharedInstance
{
    static FWImagePickerControllerImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWImagePickerControllerImpl alloc] init];
    });
    return instance;
}

- (void)viewController:(UIViewController *)viewController
         showImagePicker:(FWImagePickerFilterType)filterType
          selectionLimit:(NSInteger)selectionLimit
           allowsEditing:(BOOL)allowsEditing
             customBlock:(void (^)(id _Nonnull))customBlock
              completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    if (self.showsAlbumController) {
        FWImageAlbumController *albumController = [self albumControllerWithFilterType:filterType];
        __weak __typeof__(self) self_weak_ = self;
        albumController.pickerControllerBlock = ^FWImagePickerController * _Nonnull{
            __typeof__(self) self = self_weak_;
            return [self pickerControllerWithFilterType:filterType selectionLimit:selectionLimit allowsEditing:allowsEditing customBlock:customBlock completion:completion];
        };
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:albumController];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [viewController presentViewController:navigationController animated:YES completion:NULL];
    } else {
        FWImagePickerController *pickerController = [self pickerControllerWithFilterType:filterType selectionLimit:selectionLimit allowsEditing:allowsEditing customBlock:customBlock completion:completion];
        __weak __typeof__(self) self_weak_ = self;
        pickerController.albumControllerBlock = ^FWImageAlbumController * _Nonnull{
            __typeof__(self) self = self_weak_;
            return [self albumControllerWithFilterType:filterType];
        };
        [pickerController refreshWithFilterType:filterType];

        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pickerController];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [viewController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (FWImagePickerController *)pickerControllerWithFilterType:(FWImagePickerFilterType)filterType
                                             selectionLimit:(NSInteger)selectionLimit
                                              allowsEditing:(BOOL)allowsEditing
                                                customBlock:(void (^)(id _Nonnull))customBlock
                                                 completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    FWImagePickerController *pickerController;
    if (self.pickerControllerBlock) {
        pickerController = self.pickerControllerBlock();
    } else {
        pickerController = [[FWImagePickerController alloc] init];
    }
    pickerController.allowsMultipleSelection = selectionLimit != 1;
    pickerController.maximumSelectImageCount = selectionLimit > 0 ? selectionLimit : INT_MAX;
    pickerController.shouldRequestImage = YES;
    pickerController.filterType = filterType;
    __weak __typeof__(self) self_weak_ = self;
    pickerController.previewControllerBlock = ^FWImagePickerPreviewController * _Nonnull{
        __typeof__(self) self = self_weak_;
        return [self previewControllerWithAllowsEditing:allowsEditing];
    };
    pickerController.didCancelPicking = ^{
        if (completion) completion(@[], @[], YES);
    };
    pickerController.didFinishPicking = ^(NSArray<FWAsset *> * _Nonnull imagesAssetArray) {
        NSMutableArray *objects = [NSMutableArray array];
        NSMutableArray *results = [NSMutableArray array];
        [imagesAssetArray enumerateObjectsUsingBlock:^(FWAsset *obj, NSUInteger idx, BOOL *stop) {
            if (obj.requestObject) {
                [objects addObject:obj.requestObject];
                [results addObject:obj.requestInfo ?: @{}];
            }
        }];
        if (completion) completion(objects.copy, results.copy, objects.count < 1);
    };
    
    if (self.customBlock) self.customBlock(pickerController);
    if (customBlock) customBlock(pickerController);
    return pickerController;
}

- (FWImageAlbumController *)albumControllerWithFilterType:(FWImagePickerFilterType)filterType
{
    FWImageAlbumController *albumController;
    if (self.albumControllerBlock) {
        albumController = self.albumControllerBlock();
    } else {
        albumController = [[FWImageAlbumController alloc] init];
        albumController.pickDefaultAlbumGroup = self.showsAlbumController;
    }
    albumController.contentType = [FWImagePickerController albumContentTypeWithFilterType:filterType];
    return albumController;
}

- (FWImagePickerPreviewController *)previewControllerWithAllowsEditing:(BOOL)allowsEditing
{
    FWImagePickerPreviewController *previewController;
    if (self.previewControllerBlock) {
        previewController = self.previewControllerBlock();
    } else {
        previewController = [[FWImagePickerPreviewController alloc] init];
    }
    previewController.showsEditButton = allowsEditing;
    if (!previewController.cropControllerBlock && self.cropControllerBlock) {
        previewController.cropControllerBlock = self.cropControllerBlock;
    }
    return previewController;
}

@end
