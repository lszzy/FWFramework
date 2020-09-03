/*!
 @header     UIImage+FWAnimated.m
 @indexgroup FWFramework
 @brief      UIImage+FWAnimated
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import "UIImage+FWAnimated.h"

UIImage * FWImageName(NSString *name) {
    return [UIImage imageNamed:name];
}

UIImage * FWImageFile(NSString *path) {
    return [UIImage imageWithContentsOfFile:(path.isAbsolutePath ? path : [NSBundle.mainBundle pathForResource:path ofType:nil])];
}

@implementation UIImage (FWAnimated)

+ (UIImage *)fwImageWithName:(NSString *)name
{
    return [UIImage imageNamed:name];
}

+ (UIImage *)fwImageWithFile:(NSString *)path
{
    NSString *file = path;
    if (![file isAbsolutePath]) {
        file = [[NSBundle mainBundle] pathForResource:file ofType:nil];
    }
    return [UIImage imageWithContentsOfFile:file];
}

@end
