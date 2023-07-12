//
//  QrcodeScanView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, __FWQrcodeCornerLocation) {
    /// 默认与边框线同中心点
    __FWQrcodeCornerLocationDefault,
    /// 在边框线内部
    __FWQrcodeCornerLocationInside,
    /// 在边框线外部
    __FWQrcodeCornerLocationOutside
} NS_SWIFT_NAME(QrcodeCornerLocation);

typedef NS_ENUM(NSUInteger, __FWQrcodeScanAnimationStyle) {
    /// 单线扫描样式
    __FWQrcodeScanAnimationStyleDefault,
    /// 网格扫描样式
    __FWQrcodeScanAnimationStyleGrid
} NS_SWIFT_NAME(QrcodeScanAnimationStyle);

/**
 __FWQrcodeScanView
 */
NS_SWIFT_NAME(QrcodeScanView)
@interface __FWQrcodeScanView : UIView

/** 扫描样式，默认 ScanAnimationStyleDefault */
@property (nonatomic, assign) __FWQrcodeScanAnimationStyle scanAnimationStyle;
/** 扫描线名，支持NSString和UIImage，默认无 */
@property (nonatomic, strong, nullable) id scanImageName;
/** 边框颜色，默认白色 */
@property (nonatomic, strong) UIColor *borderColor;
/** 边框frame，默认视图宽度*0.7，居中 */
@property (nonatomic, assign) CGRect borderFrame;
/** 边框宽度，默认0.2f */
@property (nonatomic, assign) CGFloat borderWidth;
/** 边角位置，默认 CornerLocationDefault */
@property (nonatomic, assign) __FWQrcodeCornerLocation cornerLocation;
/** 边角颜色，默认微信颜色 */
@property (nonatomic, strong) UIColor *cornerColor;
/** 边角宽度，默认 2.f */
@property (nonatomic, assign) CGFloat cornerWidth;
/** 边角长度，默认20.f */
@property (nonatomic, assign) CGFloat cornerLength;
/** 扫描区周边颜色的 alpha 值，默认 0.2f */
@property (nonatomic, assign) CGFloat backgroundAlpha;
/** 扫描线动画时间，默认 0.02s */
@property (nonatomic, assign) NSTimeInterval animationTimeInterval;

/** 添加定时器 */
- (void)addTimer;
/** 移除定时器 */
- (void)removeTimer;

@end

NS_ASSUME_NONNULL_END
