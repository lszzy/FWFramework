//
//  FWToolkit.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWToolkit.h"

#if FWMacroSPM

@interface UIFont ()

+ (UIFont *)fw_thinFontOfSize:(CGFloat)size;
+ (UIFont *)fw_lightFontOfSize:(CGFloat)size;
+ (UIFont *)fw_fontOfSize:(CGFloat)size;
+ (UIFont *)fw_mediumFontOfSize:(CGFloat)size;
+ (UIFont *)fw_semiboldFontOfSize:(CGFloat)size;
+ (UIFont *)fw_boldFontOfSize:(CGFloat)size;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

UIFont * FWFontThin(CGFloat size) { return [UIFont fw_thinFontOfSize:size]; }
UIFont * FWFontLight(CGFloat size) { return [UIFont fw_lightFontOfSize:size]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont fw_fontOfSize:size]; }
UIFont * FWFontMedium(CGFloat size) { return [UIFont fw_mediumFontOfSize:size]; }
UIFont * FWFontSemibold(CGFloat size) { return [UIFont fw_semiboldFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont fw_boldFontOfSize:size]; }
