/*!
 @header     FWIcon.m
 @indexgroup FWFramework
 @brief      FWIcon
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "FWIcon.h"
#import "FWLoader.h"
#import <CoreText/CoreText.h>

FWIcon * FWIconNamed(NSString *name, CGFloat size) {
    return [FWIcon iconNamed:name size:size];
}

UIImage * FWIconImage(NSString *name, CGFloat size) {
    return [FWIcon iconImage:name size:size];
}

@interface FWIcon ()

@property (nonatomic, strong) NSMutableAttributedString *mutableAttributedString;
@property (nonatomic, strong) FWLoader<NSString *, Class> *iconLoader;

@end

@implementation FWIcon

#pragma mark - Static

+ (FWIcon *)sharedInstance
{
    static FWIcon *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWIcon alloc] init];
        instance.iconLoader = [[FWLoader<NSString *, Class> alloc] init];
    });
    return instance;
}

+ (FWLoader<NSString *,Class> *)sharedLoader
{
    return [self sharedInstance].iconLoader;
}

+ (BOOL)registerIconFont:(NSURL *)url
{
    if (!url || !url.isFileURL) return NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) return NO;
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)url);
    CGFontRef newFont = CGFontCreateWithDataProvider(dataProvider);
    CGDataProviderRelease(dataProvider);
    BOOL result = CTFontManagerRegisterGraphicsFont(newFont, NULL);
    CGFontRelease(newFont);
    return result;
}

+ (FWIcon *)iconNamed:(NSString *)name size:(CGFloat)size
{
    Class iconClass = [[self sharedInstance].iconLoader load:name];
    if (!iconClass || ![iconClass isSubclassOfClass:[FWIcon class]]) return nil;
    return [[iconClass alloc] initWithName:name size:size];
}

+ (UIImage *)iconImage:(NSString *)name size:(CGFloat)size
{
    return [self iconNamed:name size:size].image;
}

#pragma mark - Lifecycle

- (instancetype)initWithCode:(NSString *)code size:(CGFloat)size
{
    self = [super init];
    if (self) {
        UIFont *font = [[self class] iconFontWithSize:size];
        _mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:code attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name size:(CGFloat)size
{
    NSString *code = [[[self class] allIcons] objectForKey:name];
    if (!code) return nil;
    return [self initWithCode:code size:size];
}

- (CGFloat)fontSize
{
    return [self iconFont].pointSize;
}

- (void)setFontSize:(CGFloat)fontSize
{
    [self addAttribute:NSFontAttributeName value:[[self iconFont] fontWithSize:fontSize]];
}

- (UIColor *)foregroundColor
{
    return [self attribute:NSForegroundColorAttributeName];
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    if (foregroundColor) {
        [self addAttribute:NSForegroundColorAttributeName value:foregroundColor];
    } else {
        [self removeAttribute:NSForegroundColorAttributeName];
    }
}

- (NSString *)characterCode
{
    return [self.mutableAttributedString string];
}

- (NSString *)iconName
{
    __block NSString *name = nil;
    [[[self class] allIcons] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        if ([obj isEqualToString:self.characterCode]) {
            name = key;
            *stop = YES;
        }
    }];
    return name ?: @"";
}

- (UIFont *)iconFont
{
    return [self attribute:NSFontAttributeName] ?: [[self class] iconFontWithSize:[UIFont systemFontSize]];
}

- (UIImage *)image
{
    CGFloat fontSize = self.fontSize;
    return [self imageWithSize:CGSizeMake(fontSize, fontSize)];
}

- (UIImage *)imageWithSize:(CGSize)imageSize
{
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.backgroundColor) {
        [self.backgroundColor setFill];
        CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
    }
    
    CGSize iconSize = [self.mutableAttributedString size];
    CGFloat xOffset = (imageSize.width - iconSize.width) / 2.0;
    xOffset += self.positionAdjustment.horizontal;
    CGFloat yOffset = (imageSize.height - iconSize.height) / 2.0;
    yOffset += self.positionAdjustment.vertical;
    CGRect drawRect = CGRectMake(xOffset, yOffset, iconSize.width, iconSize.height);
    [self.mutableAttributedString drawInRect:drawRect];
    
    UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return iconImage;
}

#pragma mark - Attribute

- (NSAttributedString *)attributedString
{
    return [self.mutableAttributedString copy];
}

- (void)setAttributes:(NSDictionary *)attrs
{
    if (!attrs[NSFontAttributeName]) {
        NSMutableDictionary *mutableAttrs = [attrs mutableCopy];
        mutableAttrs[NSFontAttributeName] = self.iconFont;
        attrs = [mutableAttrs copy];
    }
    [self.mutableAttributedString setAttributes:attrs range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (void)addAttribute:(NSString *)name value:(id)value
{
    [self.mutableAttributedString addAttribute:name value:value range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (void)addAttributes:(NSDictionary *)attrs
{
    [self.mutableAttributedString addAttributes:attrs range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (void)removeAttribute:(NSString *)name
{
    [self.mutableAttributedString removeAttribute:name range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (NSDictionary *)attributes
{
    return [self.mutableAttributedString attributesAtIndex:0 effectiveRange:NULL];
}

- (id)attribute:(NSString *)name
{
    return [self.mutableAttributedString attribute:name atIndex:0 effectiveRange:NULL];
}

#pragma mark - Protected

+ (NSDictionary<NSString *,NSString *> *)allIcons
{
    @throw [NSException exceptionWithName:@"FWFramework"
                                   reason:@"You need to implement this method in subclass."
                                 userInfo:nil];
}

+ (UIFont *)iconFontWithSize:(CGFloat)size
{
    @throw [NSException exceptionWithName:@"FWFramework"
                                   reason:@"You need to implement this method in subclass."
                                 userInfo:nil];
}

@end
