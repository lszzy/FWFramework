//
//  Icon.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "Icon.h"
#import <CoreText/CoreText.h>

@interface __FWIcon ()

@property (nonatomic, strong) NSMutableAttributedString *mutableAttributedString;

//@property (nonatomic, strong) __FWLoader<NSString *, Class> *iconLoader;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *iconMapper;

@end

@implementation __FWIcon

#pragma mark - Static

+ (__FWIcon *)sharedInstance
{
    static __FWIcon *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWIcon alloc] init];
        //instance.iconLoader = [[__FWLoader<NSString *, Class> alloc] init];
        instance.iconMapper = [[NSMutableDictionary<NSString *, Class> alloc] init];
    });
    return instance;
}

/*
+ (__FWLoader<NSString *,Class> *)sharedLoader
{
    return [self sharedInstance].iconLoader;
}*/

+ (BOOL)registerClass:(Class)iconClass
{
    if (!iconClass || ![iconClass isSubclassOfClass:[__FWIcon class]]) return NO;
    [[iconClass iconMapper] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [__FWIcon sharedInstance].iconMapper[key] = iconClass;
    }];
    return YES;
}

+ (__FWIcon *)iconNamed:(NSString *)name size:(CGFloat)size
{
    Class iconClass = [[self sharedInstance].iconMapper objectForKey:name];
    if (!iconClass) {
        //iconClass = [[self sharedInstance].iconLoader load:name];
        if (!iconClass || ![self registerClass:iconClass]) return nil;
    }
    return [[iconClass alloc] initWithName:name size:size];
}

+ (UIImage *)iconImage:(NSString *)name size:(CGFloat)size
{
    return [self iconNamed:name size:size].image;
}

+ (BOOL)installIconFont:(NSURL *)fileURL
{
    if (!fileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) return NO;
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fileURL);
    CGFontRef newFont = CGFontCreateWithDataProvider(dataProvider);
    CGDataProviderRelease(dataProvider);
    BOOL result = CTFontManagerRegisterGraphicsFont(newFont, NULL);
    CGFontRelease(newFont);
    return result;
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
    NSString *code = [[[self class] iconMapper] objectForKey:name];
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

- (UIColor *)backgroundColor
{
    return [self attribute:NSBackgroundColorAttributeName];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (backgroundColor) {
        [self addAttribute:NSBackgroundColorAttributeName value:backgroundColor];
    } else {
        [self removeAttribute:NSBackgroundColorAttributeName];
    }
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
    [[[self class] iconMapper] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
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
    
    // backgroundColor为整个图片背景色
    NSMutableAttributedString *attributedString = self.mutableAttributedString;
    if (self.backgroundColor) {
        [self.backgroundColor setFill];
        CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
        attributedString = [self.mutableAttributedString mutableCopy];
        [attributedString removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, [attributedString length])];
    }
    
    CGSize iconSize = [attributedString size];
    CGFloat xOffset = (imageSize.width - iconSize.width) / 2.0;
    xOffset += self.imageOffset.horizontal;
    CGFloat yOffset = (imageSize.height - iconSize.height) / 2.0;
    yOffset += self.imageOffset.vertical;
    CGRect drawRect = CGRectMake(xOffset, yOffset, iconSize.width, iconSize.height);
    [attributedString drawInRect:drawRect];
    
    UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return iconImage;
}

#pragma mark - Attribute

- (NSAttributedString *)attributedString
{
    return [self.mutableAttributedString copy];
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs
{
    if (!attrs[NSFontAttributeName]) {
        NSMutableDictionary *mutableAttrs = [attrs mutableCopy];
        mutableAttrs[NSFontAttributeName] = self.iconFont;
        attrs = [mutableAttrs copy];
    }
    [self.mutableAttributedString setAttributes:attrs range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (void)addAttribute:(NSAttributedStringKey)name value:(id)value
{
    [self.mutableAttributedString addAttribute:name value:value range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (void)addAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs
{
    [self.mutableAttributedString addAttributes:attrs range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (void)removeAttribute:(NSAttributedStringKey)name
{
    [self.mutableAttributedString removeAttribute:name range:NSMakeRange(0, [self.mutableAttributedString length])];
}

- (NSDictionary<NSAttributedStringKey,id> *)attributes
{
    return [self.mutableAttributedString attributesAtIndex:0 effectiveRange:NULL];
}

- (id)attribute:(NSAttributedStringKey)name
{
    return [self.mutableAttributedString attribute:name atIndex:0 effectiveRange:NULL];
}

#pragma mark - Protected

+ (NSDictionary<NSString *,NSString *> *)iconMapper
{
    @throw [NSException exceptionWithName:@"FWIcon"
                                   reason:@"You need to implement this method in subclass."
                                 userInfo:nil];
}

+ (UIFont *)iconFontWithSize:(CGFloat)size
{
    @throw [NSException exceptionWithName:@"FWIcon"
                                   reason:@"You need to implement this method in subclass."
                                 userInfo:nil];
}

@end
