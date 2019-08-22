/*!
 @header     NSAttributedString+FWOption.m
 @indexgroup FWFramework
 @brief      NSAttributedString+FWOption
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "NSAttributedString+FWOption.h"

#pragma mark - FWAttributedOption

static FWAttributedOption *appearance = nil;

@interface FWAttributedOption ()

@end

@implementation FWAttributedOption

#pragma mark - Lifecycle

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self appearance];
    });
}

+ (instancetype)appearance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearance = [[self alloc] init];
    });
    return appearance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (appearance) {
            self.font = appearance.font;
            self.paragraphStyle = [appearance.paragraphStyle mutableCopy];
            self.foregroundColor = appearance.foregroundColor;
            self.backgroundColor = appearance.backgroundColor;
            self.ligature = appearance.ligature;
            self.kern = appearance.kern;
            self.strikethroughStyle = appearance.strikethroughStyle;
            self.strikethroughColor = appearance.strikethroughColor;
            self.underlineStyle = appearance.underlineStyle;
            self.underlineColor = appearance.underlineColor;
            self.strokeWidth = appearance.strokeWidth;
            self.strokeColor = appearance.strokeColor;
            self.shadow = appearance.shadow;
            self.textEffect = appearance.textEffect;
            self.baselineOffset = appearance.baselineOffset;
            self.obliqueness = appearance.obliqueness;
            self.expansion = appearance.expansion;
            self.writingDirection = appearance.writingDirection;
            self.verticalGlyphForm = appearance.verticalGlyphForm;
            self.link = appearance.link;
            self.attachment = appearance.attachment;
            self.lineHeightMultiplier = appearance.lineHeightMultiplier;
            self.lineSpacingMultiplier = appearance.lineSpacingMultiplier;
        }
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    FWAttributedOption *option = [[[self class] allocWithZone:zone] init];
    option.font = self.font;
    option.paragraphStyle = [self.paragraphStyle mutableCopy];
    option.foregroundColor = self.foregroundColor;
    option.backgroundColor = self.backgroundColor;
    option.ligature = self.ligature;
    option.kern = self.kern;
    option.strikethroughStyle = self.strikethroughStyle;
    option.strikethroughColor = self.strikethroughColor;
    option.underlineStyle = self.underlineStyle;
    option.underlineColor = self.underlineColor;
    option.strokeWidth = self.strokeWidth;
    option.strokeColor = self.strokeColor;
    option.shadow = self.shadow;
    option.textEffect = self.textEffect;
    option.baselineOffset = self.baselineOffset;
    option.obliqueness = self.obliqueness;
    option.expansion = self.expansion;
    option.writingDirection = self.writingDirection;
    option.verticalGlyphForm = self.verticalGlyphForm;
    option.link = self.link;
    option.attachment = self.attachment;
    option.lineHeightMultiplier = self.lineHeightMultiplier;
    option.lineSpacingMultiplier = self.lineSpacingMultiplier;
    return option;
}

#pragma mark - Dictionary

- (NSDictionary<NSAttributedStringKey,id> *)toDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.font) dictionary[NSFontAttributeName] = self.font;
    if (self.paragraphStyle) dictionary[NSParagraphStyleAttributeName] = self.paragraphStyle;
    if (self.foregroundColor) dictionary[NSForegroundColorAttributeName] = self.foregroundColor;
    if (self.backgroundColor) dictionary[NSBackgroundColorAttributeName] = self.backgroundColor;
    if (self.ligature) dictionary[NSLigatureAttributeName] = @(self.ligature);
    if (self.kern) dictionary[NSKernAttributeName] = @(self.kern);
    if (self.strikethroughStyle) dictionary[NSStrikethroughStyleAttributeName] = @(self.strikethroughStyle);
    if (self.strikethroughColor) dictionary[NSStrikethroughColorAttributeName] = self.strikethroughColor;
    if (self.underlineStyle) dictionary[NSUnderlineStyleAttributeName] = @(self.underlineStyle);
    if (self.underlineColor) dictionary[NSUnderlineColorAttributeName] = self.underlineColor;
    if (self.strokeWidth) dictionary[NSStrokeWidthAttributeName] = @(self.strokeWidth);
    if (self.strokeColor) dictionary[NSStrokeColorAttributeName] = self.strokeColor;
    if (self.shadow) dictionary[NSShadowAttributeName] = self.shadow;
    if (self.textEffect) dictionary[NSTextEffectAttributeName] = self.textEffect;
    if (self.baselineOffset) dictionary[NSBaselineOffsetAttributeName] = @(self.baselineOffset);
    if (self.obliqueness) dictionary[NSObliquenessAttributeName] = @(self.obliqueness);
    if (self.expansion) dictionary[NSExpansionAttributeName] = @(self.expansion);
    if (self.writingDirection) dictionary[NSWritingDirectionAttributeName] = @(self.writingDirection);
    if (self.verticalGlyphForm) dictionary[NSVerticalGlyphFormAttributeName] = @(self.verticalGlyphForm);
    if (self.link) dictionary[NSLinkAttributeName] = self.link;
    if (self.attachment) dictionary[NSAttachmentAttributeName] = self.attachment;
    
    if (self.lineHeightMultiplier && self.font) {
        CGFloat lineHeight = self.font.pointSize * self.lineHeightMultiplier;
        NSMutableParagraphStyle *paragraphStyle = [self.paragraphStyle mutableCopy];
        if (!paragraphStyle) paragraphStyle = [NSMutableParagraphStyle new];
        if (!paragraphStyle.maximumLineHeight) paragraphStyle.maximumLineHeight = lineHeight;
        if (!paragraphStyle.minimumLineHeight) paragraphStyle.minimumLineHeight = lineHeight;
        dictionary[NSParagraphStyleAttributeName] = paragraphStyle;
        if (!self.baselineOffset) {
            CGFloat baselineOffset = (lineHeight - self.font.lineHeight) / 4;
            dictionary[NSBaselineOffsetAttributeName] = @(baselineOffset);
        }
    }
    
    if (self.lineSpacingMultiplier && self.font) {
        CGFloat lineSpacing = self.font.pointSize * self.lineSpacingMultiplier - (self.font.lineHeight - self.font.pointSize);
        NSMutableParagraphStyle *paragraphStyle = [self.paragraphStyle mutableCopy];
        if (!paragraphStyle) paragraphStyle = [NSMutableParagraphStyle new];
        if (!paragraphStyle.lineSpacing) paragraphStyle.lineSpacing = lineSpacing;
        dictionary[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    return dictionary;
}

@end

#pragma mark - NSAttributedString+FWOption

@implementation NSAttributedString (FWOption)

+ (instancetype)fwAttributedString:(NSString *)string withOption:(FWAttributedOption *)option
{
    return [[self alloc] initWithString:string attributes:[option toDictionary]];
}

@end
