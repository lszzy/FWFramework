/*!
 @header     FWQrcodeScanView.h
 @indexgroup FWFramework
 @brief      FWQrcodeScanView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/21
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/*!
 @brief FWQrcodeScanManager
 
 @see https://github.com/kingsic/SGQRCode
 */
@interface FWQrcodeScanManager : NSObject

#pragma mark - Scan

/** 会话预置，默认为：AVCaptureSessionPreset1920x1080 */
@property (nonatomic, copy) NSString *sessionPreset;
/** 元对象类型，默认为：AVMetadataObjectTypeQRCode */
@property (nonatomic, strong) NSArray *metadataObjectTypes;
/** 扫描范围，默认整个视图（每一个取值 0 ～ 1，以屏幕右上角为坐标原点）*/
@property (nonatomic, assign) CGRect rectOfInterest;
/** 是否需要样本缓冲代理（光线强弱），默认为：NO */
@property (nonatomic, assign) BOOL sampleBufferDelegate;
// 扫描二维码回调方法
@property (nonatomic, copy) void(^scanResultBlock)(NSString *result);
// 扫描二维码光线强弱回调方法；调用之前配置属性 sampleBufferDelegate 必须为 YES
@property (nonatomic, copy) void(^scanBrightnessBlock)(CGFloat brightness);

/** 创建扫描二维码方法 */
- (void)scanQrcodeWithView:(UIView *)view;

/** 开启扫描回调方法 */
- (void)startRunning;

/** 停止扫描方法 */
- (void)stopRunning;

/** 打开手电筒 */
+ (void)openFlashlight;

/** 关闭手电筒 */
+ (void)closeFlashlight;

#pragma mark - Image

// 扫描图片二维码，识别失败返回nil
+ (NSString *)scanQrcodeWithImage:(UIImage *)image;

#pragma mark - Generate

/**
 *  生成二维码
 *
 *  @param data    二维码数据
 *  @param size    二维码大小
 */
+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size;

/**
 *  生成二维码（自定义颜色）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param color    二维码颜色
 *  @param backgroundColor    二维码背景颜色
 */
+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size
                              color:(UIColor *)color
                    backgroundColor:(UIColor *)backgroundColor;

/**
 *  生成带 logo 的二维码（推荐使用）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param logoImage    logo
 *  @param ratio        logo 相对二维码的比例（取值范围 0.0 ～ 0.5f）
 */
+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size
                          logoImage:(UIImage *)logoImage
                              ratio:(CGFloat)ratio;

/**
 *  生成带 logo 的二维码（拓展）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param logoImage    logo
 *  @param ratio        logo 相对二维码的比例（取值范围 0.0 ～ 0.5f）
 *  @param logoImageCornerRadius    logo 外边框圆角（取值范围 0.0 ～ 10.0f）
 *  @param logoImageBorderWidth     logo 外边框宽度（取值范围 0.0 ～ 10.0f）
 *  @param logoImageBorderColor     logo 外边框颜色
 */
+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size
                          logoImage:(UIImage *)logoImage
                              ratio:(CGFloat)ratio
              logoImageCornerRadius:(CGFloat)logoImageCornerRadius
               logoImageBorderWidth:(CGFloat)logoImageBorderWidth
               logoImageBorderColor:(UIColor *)logoImageBorderColor;

@end

typedef NS_ENUM(NSUInteger, FWQrcodeCornerLoaction) {
    /// 默认与边框线同中心点
    FWQrcodeCornerLoactionDefault,
    /// 在边框线内部
    FWQrcodeCornerLoactionInside,
    /// 在边框线外部
    FWQrcodeCornerLoactionOutside
};

typedef NS_ENUM(NSUInteger, FWQrcodeScanAnimationStyle) {
    /// 单线扫描样式
    FWQrcodeScanAnimationStyleDefault,
    /// 网格扫描样式
    FWQrcodeScanAnimationStyleGrid
};

/*!
 @brief FWQrcodeScanView
 */
@interface FWQrcodeScanView : UIView

/** 扫描样式，默认 ScanAnimationStyleDefault */
@property (nonatomic, assign) FWQrcodeScanAnimationStyle scanAnimationStyle;
/** 扫描线名 */
@property (nonatomic, copy) NSString *scanImageName;
/** 边框颜色，默认白色 */
@property (nonatomic, strong) UIColor *borderColor;
/** 边角位置，默认 CornerLoactionDefault */
@property (nonatomic, assign) FWQrcodeCornerLoaction cornerLocation;
/** 边角颜色，默认微信颜色 */
@property (nonatomic, strong) UIColor *cornerColor;
/** 边角宽度，默认 2.f */
@property (nonatomic, assign) CGFloat cornerWidth;
/** 扫描区周边颜色的 alpha 值，默认 0.2f */
@property (nonatomic, assign) CGFloat backgroundAlpha;
/** 扫描线动画时间，默认 0.02s */
@property (nonatomic, assign) NSTimeInterval animationTimeInterval;

/** 添加定时器 */
- (void)addTimer;
/** 移除定时器 */
- (void)removeTimer;

@end
