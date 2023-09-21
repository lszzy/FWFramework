//
//  Bridge.h
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "ObjC.h"
#import "HTTPSessionManager.h"
#import "RequestManager.h"
#import "Database.h"
#import "WebImage.h"
#import "AttributedLabel.h"
#import "BarrageView.h"
#import "CollectionViewFlowLayout.h"
#import "PopupMenu.h"
#import "SegmentedControl.h"
#import "TagCollectionView.h"
#import "ToolbarView.h"
#import "ImagePlugin.h"
#import "AlertController.h"
#import "ImagePickerController.h"
#import "ImagePreviewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWEncrypt

@interface NSData (__FWEncrypt)

- (nullable NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey;

- (nullable NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

- (nullable NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey;

- (nullable NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

- (nullable NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey;

- (nullable NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

- (nullable NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey;

- (nullable NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

@end

#pragma mark - UIImage+__FWBridge

@interface UIImage (__FWBridge)

- (nullable UIImage *)__fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(nullable UIColor *)tintColor maskImage:(nullable UIImage *)maskImage;

@end

NS_ASSUME_NONNULL_END
