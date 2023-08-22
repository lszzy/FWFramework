//
//  FWAppBundle.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWAppBundle.h"
#import "FWLanguage.h"
#import "FWToolkit.h"

@implementation FWAppBundle

+ (NSBundle *)bundle
{
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [[NSBundle fw_bundleWithName:@"FWFramework"] fw_localizedBundle];
        if (!bundle) bundle = [NSBundle mainBundle];
    });
    return bundle;
}

+ (UIImage *)imageNamed:(NSString *)name
{
    UIImage *image = [super imageNamed:name];
    if (image) return image;
    
    if ([name isEqualToString:@"fw.navBack"]) {
        CGSize size = CGSizeMake(12, 20);
        return [UIImage fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(size.width - lineWidth / 2, lineWidth / 2)];
            [path addLineToPoint:CGPointMake(0 + lineWidth / 2, size.height / 2.0)];
            [path addLineToPoint:CGPointMake(size.width - lineWidth / 2, size.height - lineWidth / 2)];
            [path setLineWidth:lineWidth];
            [path stroke];
        }];
    } else if ([name isEqualToString:@"fw.navClose"]) {
        CGSize size = CGSizeMake(16, 16);
        return [UIImage fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(0, 0)];
            [path addLineToPoint:CGPointMake(size.width, size.height)];
            [path closePath];
            [path moveToPoint:CGPointMake(size.width, 0)];
            [path addLineToPoint:CGPointMake(0, size.height)];
            [path closePath];
            [path setLineWidth:lineWidth];
            [path setLineCapStyle:kCGLineCapRound];
            [path stroke];
        }];
    } else if ([name isEqualToString:@"fw.videoPlay"]) {
        CGSize size = CGSizeMake(60, 60);
        return [UIImage fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            UIColor *fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.25];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            CGFloat lineWidth = 1;
            UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(lineWidth / 2, lineWidth / 2, size.width - lineWidth, size.width - lineWidth)];
            [circle setLineWidth:lineWidth];
            [circle stroke];
            [circle fill];
            
            CGContextSetFillColorWithColor(contextRef, color.CGColor);
            CGFloat triangleLength = size.width / 2.5;
            UIBezierPath *triangle = [UIBezierPath bezierPath];
            [triangle moveToPoint:CGPointZero];
            [triangle addLineToPoint:CGPointMake(triangleLength * cos(M_PI / 6), triangleLength / 2)];
            [triangle addLineToPoint:CGPointMake(0, triangleLength)];
            [triangle closePath];
            UIOffset offset = UIOffsetMake(size.width / 2 - triangleLength * tan(M_PI / 6) / 2, size.width / 2 - triangleLength / 2);
            [triangle applyTransform:CGAffineTransformMakeTranslation(offset.horizontal, offset.vertical)];
            [triangle fill];
        }];
    } else if ([name isEqualToString:@"fw.videoPause"]) {
        CGSize size = CGSizeMake(12, 18);
        return [UIImage fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(lineWidth / 2, 0)];
            [path addLineToPoint:CGPointMake(lineWidth / 2, size.height)];
            [path moveToPoint:CGPointMake(size.width - lineWidth / 2, 0)];
            [path addLineToPoint:CGPointMake(size.width - lineWidth / 2, size.height)];
            [path setLineWidth:lineWidth];
            [path stroke];
        }];
    } else if ([name isEqualToString:@"fw.videoStart"]) {
        CGSize size = CGSizeMake(17, 17);
        return [UIImage fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetFillColorWithColor(contextRef, color.CGColor);
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointZero];
            [path addLineToPoint:CGPointMake(size.width * cos(M_PI / 6), size.width / 2)];
            [path addLineToPoint:CGPointMake(0, size.width)];
            [path closePath];
            [path fill];
        }];
    } else if ([name isEqualToString:@"fw.pickerCheck"]) {
        CGSize size = CGSizeMake(20, 20);
        return [UIImage fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            UIColor *fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.25];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(lineWidth / 2, lineWidth / 2, size.width - lineWidth, size.width - lineWidth)];
            [circle setLineWidth:lineWidth];
            [circle stroke];
            [circle fill];
        }];
    } else if ([name isEqualToString:@"fw.pickerChecked"]) {
        CGSize size = CGSizeMake(20, 20);
        return [UIImage fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
            UIColor *fillColor = [UIColor colorWithRed:7/255.f green:193/255.f blue:96/255.f alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, size.width, size.width)];
            [circle fill];
            
            CGSize checkSize = CGSizeMake(9, 7);
            CGPoint checkOrigin = CGPointMake((size.width - checkSize.width) / 2.0, (size.height - checkSize.height) / 2.0);
            CGFloat lineWidth = 1;
            CGFloat lineAngle = M_PI_4;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(checkOrigin.x, checkOrigin.y + checkSize.height / 2)];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width / 3, checkOrigin.y + checkSize.height)];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width, checkOrigin.y + lineWidth * sin(lineAngle))];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width - lineWidth * cos(lineAngle), checkOrigin.y + 0)];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width / 3, checkOrigin.y + checkSize.height - lineWidth / sin(lineAngle))];
            [path addLineToPoint:CGPointMake(checkOrigin.x + lineWidth * sin(lineAngle), checkOrigin.y + checkSize.height / 2 - lineWidth * sin(lineAngle))];
            [path closePath];
            [path setLineWidth:lineWidth];
            [path stroke];
        }];
    }
    return nil;
}

+ (NSString *)localizedString:(NSString *)key table:(NSString *)table
{
    if (table) return [super localizedString:key table:table];
    NSString *localized = [[self bundle] localizedStringForKey:key value:@" " table:table];
    if (![localized isEqualToString:@" "]) return localized;
    
    static NSDictionary *localizedStrings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localizedStrings = @{
            @"zh-Hans": @{
                @"fw.done": @"完成",
                @"fw.close": @"好的",
                @"fw.confirm": @"确定",
                @"fw.cancel": @"取消",
                @"fw.more": @"更多",
                @"fw.original": @"原图",
                @"fw.edit": @"编辑",
                @"fw.preview": @"预览",
                @"fw.pickerAlbum": @"相册",
                @"fw.pickerEmpty": @"无照片",
                @"fw.pickerDenied": @"请在iPhone的\"设置-隐私-照片\"选项中，允许%@访问你的照片",
                @"fw.pickerExceed": @"最多只能选择%@张图片",
                @"fw.refreshIdle": @"下拉可以刷新   ",
                @"fw.refreshTriggered": @"松开立即刷新   ",
                @"fw.refreshLoading": @"正在刷新数据...",
                @"fw.refreshFinished": @"已经全部加载完毕",
            },
            @"zh-Hant": @{
                @"fw.done": @"完成",
                @"fw.close": @"好的",
                @"fw.confirm": @"確定",
                @"fw.cancel": @"取消",
                @"fw.more": @"更多",
                @"fw.original": @"原圖",
                @"fw.edit": @"編輯",
                @"fw.preview": @"預覽",
                @"fw.pickerAlbum": @"相冊",
                @"fw.pickerEmpty": @"無照片",
                @"fw.pickerDenied": @"請在iPhone的\"設置-隱私-相冊\"選項中，允許%@訪問你的照片",
                @"fw.pickerExceed": @"最多只能選擇%@張圖片",
                @"fw.refreshIdle": @"下拉可以刷新   ",
                @"fw.refreshTriggered": @"鬆開立即刷新   ",
                @"fw.refreshLoading": @"正在刷新數據...",
                @"fw.refreshFinished": @"已經全部加載完畢",
            },
            @"en": @{
                @"fw.done": @"Done",
                @"fw.close": @"OK",
                @"fw.confirm": @"Confirm",
                @"fw.cancel": @"Cancel",
                @"fw.more": @"More",
                @"fw.original": @"Original",
                @"fw.edit": @"Edit",
                @"fw.preview": @"Preview",
                @"fw.pickerAlbum": @"Album",
                @"fw.pickerEmpty": @"No Photo",
                @"fw.pickerDenied": @"Please allow %@ to access your album in \"Settings\"->\"Privacy\"->\"Photos\"",
                @"fw.pickerExceed": @"Max count for selection: %@",
                @"fw.refreshIdle": @"Pull down to refresh",
                @"fw.refreshTriggered": @"Release to refresh",
                @"fw.refreshLoading": @"Loading...",
                @"fw.refreshFinished": @"No more data",
            },
        };
    });
    
    NSString *language = [NSBundle fw_currentLanguage];
    NSDictionary *strings = localizedStrings[language] ?: localizedStrings[@"en"];
    return strings[key] ?: key;
}

#pragma mark - Image

+ (UIImage *)navBackImage
{
    return [self imageNamed:@"fw.navBack"];
}

+ (UIImage *)navCloseImage
{
    return [self imageNamed:@"fw.navClose"];
}

+ (UIImage *)videoPlayImage
{
    return [self imageNamed:@"fw.videoPlay"];
}

+ (UIImage *)videoPauseImage
{
    return [self imageNamed:@"fw.videoPause"];
}

+ (UIImage *)videoStartImage
{
    return [self imageNamed:@"fw.videoStart"];
}

+ (UIImage *)pickerCheckImage
{
    return [self imageNamed:@"fw.pickerCheck"];
}

+ (UIImage *)pickerCheckedImage
{
    return [self imageNamed:@"fw.pickerChecked"];
}

#pragma mark - String

+ (NSString *)cancelButton
{
    return [self localizedString:@"fw.cancel"];
}

+ (NSString *)confirmButton
{
    return [self localizedString:@"fw.confirm"];
}

+ (NSString *)doneButton
{
    return [self localizedString:@"fw.done"];
}

+ (NSString *)moreButton
{
    return [self localizedString:@"fw.more"];
}

+ (NSString *)closeButton
{
    return [self localizedString:@"fw.close"];
}

+ (NSString *)editButton
{
    return [self localizedString:@"fw.edit"];
}

+ (NSString *)previewButton
{
    return [self localizedString:@"fw.preview"];
}

+ (NSString *)originalButton
{
    return [self localizedString:@"fw.original"];
}

+ (NSString *)pickerAlbumTitle
{
    return [self localizedString:@"fw.pickerAlbum"];
}

+ (NSString *)pickerEmptyTitle
{
    return [self localizedString:@"fw.pickerEmpty"];
}

+ (NSString *)pickerDeniedTitle
{
    return [self localizedString:@"fw.pickerDenied"];
}

+ (NSString *)pickerExceedTitle
{
    return [self localizedString:@"fw.pickerExceed"];
}

+ (NSString *)refreshIdleTitle
{
    return [self localizedString:@"fw.refreshIdle"];
}

+ (NSString *)refreshTriggeredTitle
{
    return [self localizedString:@"fw.refreshTriggered"];
}

+ (NSString *)refreshLoadingTitle
{
    return [self localizedString:@"fw.refreshLoading"];
}

+ (NSString *)refreshFinishedTitle
{
    return [self localizedString:@"fw.refreshFinished"];
}

@end
