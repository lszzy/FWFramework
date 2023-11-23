//
//  AttributedLabel.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AttributedLabel.h"
#import <objc/runtime.h>

#pragma mark - __FWAttributedLabel

static NSString* const FWEllipsesCharacter = @"\u2026";

@interface __FWAttributedLabel ()

@property (nonatomic,strong)    NSMutableAttributedString   *attributedString;
@property (nonatomic,strong)    NSMutableArray              *attachments;
@property (nonatomic,strong)    NSMutableArray              *linkLocations;
@property (nonatomic,strong)    __FWAttributedLabelURL        *touchedLink;
@property (nonatomic,assign)    CTFrameRef textFrame;
@property (nonatomic,assign)    CGFloat fontAscent;
@property (nonatomic,assign)    CGFloat fontDescent;
@property (nonatomic,assign)    CGFloat fontHeight;
@property (nonatomic,assign)    BOOL linkDetected;
@property (nonatomic,assign)    BOOL ignoreRedraw;
@property (nonatomic,strong)    UIView *lineTruncatingView;

@end

@implementation __FWAttributedLabel

@synthesize linkDetector = _linkDetector;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    if (_textFrame)
    {
        CFRelease(_textFrame);
    }
}

#pragma mark - 初始化
- (void)commonInit
{
    _attributedString       = [[NSMutableAttributedString alloc]init];
    _attachments                 = [[NSMutableArray alloc]init];
    _linkLocations          = [[NSMutableArray alloc]init];
    _textFrame              = nil;
    _linkColor              = [UIColor blueColor];
    _font                   = [UIFont systemFontOfSize:15];
    _textColor              = [UIColor blackColor];
    _highlightColor         = [UIColor colorWithRed:0xd7/255.0
                                              green:0xf2/255.0
                                               blue:0xff/255.0
                                              alpha:1];
    _lineBreakMode          = kCTLineBreakByWordWrapping;
    _underLineForLink       = YES;
    _autoDetectLinks        = YES;
    _lineSpacing            = 0.0;
    _paragraphSpacing       = 0.0;

    if (self.backgroundColor == nil)
    {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    self.userInteractionEnabled = YES;
    [self resetFont];
}

- (void)cleanAll
{
    _ignoreRedraw = NO;
    _linkDetected = NO;
    [_attachments removeAllObjects];
    [_linkLocations removeAllObjects];
    self.touchedLink = nil;
    for (UIView *subView in self.subviews)
    {
        [subView removeFromSuperview];
    }
    [self resetTextFrame];
}

- (void)resetTextFrame
{
    if (_textFrame)
    {
        CFRelease(_textFrame);
        _textFrame = nil;
    }
    if ([NSThread isMainThread])
    {
        if (self.lineTruncatingView) {
            [self.lineTruncatingView removeFromSuperview];
            self.lineTruncatingView = nil;
        }
        
        if (!_ignoreRedraw) {
            [self invalidateIntrinsicContentSize];
            [self setNeedsDisplay];
        }
    }
}

- (void)resetFont
{
    CTFontRef fontRef = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)self.font.fontDescriptor, self.font.pointSize, NULL);
    if (fontRef)
    {
        _fontAscent     = CTFontGetAscent(fontRef);
        _fontDescent    = CTFontGetDescent(fontRef);
        _fontHeight     = CTFontGetSize(fontRef);
        CFRelease(fontRef);
    }
}

#pragma mark - 属性设置
- (void)setFont:(UIFont *)font
{
    if (font && _font != font)
    {
        _font = font;
        if (font) {
            [_attributedString removeAttribute:(NSString*)kCTFontAttributeName range:NSMakeRange(0, [_attributedString length])];
            CTFontRef fontRef = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)font.fontDescriptor, font.pointSize, nil);
            if (nil != fontRef) {
                [_attributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:NSMakeRange(0, [_attributedString length])];
                CFRelease(fontRef);
            }
        }
        [self resetFont];
        for (__FWAttributedLabelAttachment *attachment in _attachments)
        {
            attachment.fontAscent = _fontAscent;
            attachment.fontDescent = _fontDescent;
        }
        [self resetTextFrame];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    if (textColor && _textColor != textColor)
    {
        _textColor = textColor;
        [_attributedString removeAttribute:(NSString *)kCTForegroundColorAttributeName range:NSMakeRange(0, [_attributedString length])];
        if (textColor.CGColor) [_attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)textColor.CGColor range:NSMakeRange(0, [_attributedString length])];
        [self resetTextFrame];
    }
}

- (void)setHighlightColor:(UIColor *)highlightColor
{
    if (_highlightColor != highlightColor)
    {
        _highlightColor = highlightColor;
        [self resetTextFrame];
    }
}

- (void)setLinkColor:(UIColor *)linkColor
{
    if (_linkColor != linkColor)
    {
        _linkColor = linkColor;
        [self resetTextFrame];
    }
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    if (_shadowColor != shadowColor)
    {
        _shadowColor = shadowColor;
        [self resetTextFrame];
    }
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    if (!CGSizeEqualToSize(_shadowOffset, shadowOffset))
    {
        _shadowOffset = shadowOffset;
        [self resetTextFrame];
    }
}

- (void)setShadowBlur:(CGFloat)shadowBlur
{
    if (_shadowBlur != shadowBlur)
    {
        _shadowBlur = shadowBlur;
        [self resetTextFrame];
    }
}

- (void)setUnderLineForLink:(BOOL)underLineForLink
{
    if (_underLineForLink != underLineForLink)
    {
        _underLineForLink = underLineForLink;
        [self resetTextFrame];
    }
}

- (void)setAutoDetectLinks:(BOOL)autoDetectLinks
{
    if (_autoDetectLinks != autoDetectLinks)
    {
        _autoDetectLinks = autoDetectLinks;
        [self resetTextFrame];
    }
}

- (id<__FWAttributedLabelURLDetectorProtocol>)linkDetector
{
    if (_linkDetector == nil) {
        _linkDetector = __FWAttributedLabelURLDetector.shared;
    }
    return _linkDetector;
}

- (void)setLinkDetector:(id<__FWAttributedLabelURLDetectorProtocol>)linkDetector
{
    if (_linkDetector != linkDetector)
    {
        _linkDetector = linkDetector;
        [self resetTextFrame];
    }
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    if (_numberOfLines != numberOfLines)
    {
        _numberOfLines = numberOfLines;
        [self resetTextFrame];
    }
}

- (void)setTextAlignment:(CTTextAlignment)textAlignment
{
    if (_textAlignment != textAlignment)
    {
        _textAlignment = textAlignment;
        [self resetTextFrame];
    }
}

- (void)setLineBreakMode:(CTLineBreakMode)lineBreakMode
{
    if (_lineBreakMode != lineBreakMode)
    {
        _lineBreakMode = lineBreakMode;
        [self resetTextFrame];
    }
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
    if (_lineSpacing != lineSpacing)
    {
        _lineSpacing = lineSpacing;
        [self resetTextFrame];
    }
}

- (void)setParagraphSpacing:(CGFloat)paragraphSpacing
{
    if (_paragraphSpacing != paragraphSpacing)
    {
        _paragraphSpacing = paragraphSpacing;
        [self resetTextFrame];
    }
}

- (void)setLineTruncatingSpacing:(CGFloat)lineTruncatingSpacing
{
    if (_lineTruncatingSpacing != lineTruncatingSpacing)
    {
        _lineTruncatingSpacing = lineTruncatingSpacing;
        [self resetTextFrame];
    }
}

- (void)setLineTruncatingAttachment:(__FWAttributedLabelAttachment *)lineTruncatingAttachment
{
    if (_lineTruncatingAttachment != lineTruncatingAttachment)
    {
        _lineTruncatingAttachment = lineTruncatingAttachment;
        [self resetTextFrame];
    }
}

#pragma mark - frame
- (void)setFrame:(CGRect)frame
{
    CGRect oldRect = self.bounds;
    [super setFrame:frame];
    
    if (!CGRectEqualToRect(self.bounds, oldRect))
    {
        [self resetTextFrame];
    }
}

- (void)setBounds:(CGRect)bounds
{
    CGRect oldRect = self.bounds;
    [super setBounds:bounds];
    
    if (!CGRectEqualToRect(self.bounds, oldRect))
    {
        [self resetTextFrame];
    }
}

#pragma mark - 辅助方法
- (NSAttributedString *)attributedString:(NSString *)text
{
    if ([text length])
    {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc]initWithString:text];
        if (self.font) {
            [string removeAttribute:(NSString*)kCTFontAttributeName range:NSMakeRange(0, [string length])];
            CTFontRef fontRef = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)self.font.fontDescriptor, self.font.pointSize, nil);
            if (nil != fontRef) {
                [string addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:NSMakeRange(0, [string length])];
                CFRelease(fontRef);
            }
        }
        [string removeAttribute:(NSString *)kCTForegroundColorAttributeName range:NSMakeRange(0, [string length])];
        if (self.textColor.CGColor) [string addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)self.textColor.CGColor range:NSMakeRange(0, [string length])];
        return string;
    }
    else
    {
        return [[NSAttributedString alloc] init];
    }
}

- (NSInteger)numberOfDisplayedLines
{
    CFArrayRef lines = CTFrameGetLines(_textFrame);
    return _numberOfLines > 0 ? MIN(CFArrayGetCount(lines), _numberOfLines) : CFArrayGetCount(lines);
}

- (NSAttributedString *)attributedStringForDraw
{
    if (_attributedString)
    {
        //添加排版格式
        NSMutableAttributedString *drawString = [_attributedString mutableCopy];
        
        //如果LineBreakMode为TranncateTail,那么默认排版模式改成kCTLineBreakByCharWrapping,使得尽可能地显示所有文字
        CTLineBreakMode lineBreakMode = self.lineBreakMode;
        if (self.lineBreakMode == kCTLineBreakByTruncatingTail)
        {
            lineBreakMode = _numberOfLines == 1 ? kCTLineBreakByTruncatingTail : kCTLineBreakByWordWrapping;
        }
        CGFloat fontLineHeight = self.font.lineHeight;  //使用全局fontHeight作为最小lineHeight
        
        
        CTParagraphStyleSetting settings[] =
        {
            {kCTParagraphStyleSpecifierAlignment,sizeof(_textAlignment),&_textAlignment},
            {kCTParagraphStyleSpecifierLineBreakMode,sizeof(lineBreakMode),&lineBreakMode},
            {kCTParagraphStyleSpecifierMaximumLineSpacing,sizeof(_lineSpacing),&_lineSpacing},
            {kCTParagraphStyleSpecifierMinimumLineSpacing,sizeof(_lineSpacing),&_lineSpacing},
            {kCTParagraphStyleSpecifierParagraphSpacing,sizeof(_paragraphSpacing),&_paragraphSpacing},
            {kCTParagraphStyleSpecifierMinimumLineHeight,sizeof(fontLineHeight),&fontLineHeight},
        };
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings,sizeof(settings) / sizeof(settings[0]));
        [drawString addAttribute:(id)kCTParagraphStyleAttributeName
                           value:(__bridge id)paragraphStyle
                           range:NSMakeRange(0, [drawString length])];
        CFRelease(paragraphStyle);

        
        
        for (__FWAttributedLabelURL *url in _linkLocations)
        {
            if (url.range.location + url.range.length >[_attributedString length])
            {
                continue;
            }
            UIColor *drawLinkColor = url.color ?: self.linkColor;
            [drawString removeAttribute:(NSString *)kCTForegroundColorAttributeName range:url.range];
            if (drawLinkColor.CGColor) [drawString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)drawLinkColor.CGColor range:url.range];
            [drawString removeAttribute:(NSString *)kCTUnderlineColorAttributeName range:url.range];
            CTUnderlineStyle underlineStyle = _underLineForLink ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone;
            [drawString addAttribute:(NSString *)kCTUnderlineStyleAttributeName
                         value:[NSNumber numberWithInt:(underlineStyle|kCTUnderlinePatternSolid)]
                         range:url.range];
        }
        return drawString;
    }
    else
    {
        return nil;
    }
}

- (__FWAttributedLabelURL *)urlForPoint:(CGPoint)point
{
    static const CGFloat kVMargin = 5;
    if (!CGRectContainsPoint(CGRectInset(self.bounds, 0, -kVMargin), point)
        || _textFrame == nil)
    {
        return nil;
    }
    
    CFArrayRef lines = CTFrameGetLines(_textFrame);
    if (!lines)
        return nil;
    CFIndex count = CFArrayGetCount(lines);
    
    CGPoint origins[count];
    CTFrameGetLineOrigins(_textFrame, CFRangeMake(0,0), origins);
    
    CGAffineTransform transform = [self transformForCoreText];
    CGFloat verticalOffset = 0; //不像Nimbus一样设置文字的对齐方式，都统一是TOP,那么offset就为0
    
    for (int i = 0; i < count; i++)
    {
        CGPoint linePoint = origins[i];
        
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGRect flippedRect = [self getLineBounds:line point:linePoint];
        CGRect rect = CGRectApplyAffineTransform(flippedRect, transform);
        
        rect = CGRectInset(rect, 0, -kVMargin);
        rect = CGRectOffset(rect, 0, verticalOffset);
        
        if (CGRectContainsPoint(rect, point))
        {
            CGPoint relativePoint = CGPointMake(point.x-CGRectGetMinX(rect),
                                                point.y-CGRectGetMinY(rect));
            CFIndex idx = CTLineGetStringIndexForPosition(line, relativePoint);
            __FWAttributedLabelURL *url = [self linkAtIndex:idx];
            if (url)
            {
                return url;
            }
        }
    }
    return nil;
}

- (id)linkDataForPoint:(CGPoint)point
{
    __FWAttributedLabelURL *url = [self urlForPoint:point];
    return url ? url.linkData : nil;
}

- (CGAffineTransform)transformForCoreText
{
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f);
}

- (CGRect)getLineBounds:(CTLineRef)line point:(CGPoint) point
{
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGFloat height = ascent + descent;
    
    return CGRectMake(point.x, point.y - descent, width, height);
}

- (__FWAttributedLabelURL *)linkAtIndex:(CFIndex)index
{
    for (__FWAttributedLabelURL *url in _linkLocations)
    {
        if (NSLocationInRange(index, url.range))
        {
            return url;
        }
    }
    return nil;
}

- (CGRect)rectForRange:(NSRange)range
                inLine:(CTLineRef)line
            lineOrigin:(CGPoint)lineOrigin
{
    CGRect rectForRange = CGRectZero;
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CFIndex runCount = CFArrayGetCount(runs);
    
    for (CFIndex k = 0; k < runCount; k++)
    {
        CTRunRef run = CFArrayGetValueAtIndex(runs, k);
        
        CFRange stringRunRange = CTRunGetStringRange(run);
        NSRange lineRunRange = NSMakeRange(stringRunRange.location, stringRunRange.length);
        NSRange intersectedRunRange = NSIntersectionRange(lineRunRange, range);
        
        if (intersectedRunRange.length == 0)
        {
            continue;
        }
        
        CGFloat ascent = 0.0f;
        CGFloat descent = 0.0f;
        CGFloat leading = 0.0f;
        
        CGFloat width = (CGFloat)CTRunGetTypographicBounds(run,
                                                           CFRangeMake(0, 0),
                                                           &ascent,
                                                           &descent,
                                                           NULL);
        CGFloat height = ascent + descent;
        
        CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil);
        
        CGRect linkRect = CGRectMake(lineOrigin.x + xOffset - leading, lineOrigin.y - descent, width + leading, height);
        
        linkRect.origin.y = roundf(linkRect.origin.y);
        linkRect.origin.x = roundf(linkRect.origin.x);
        linkRect.size.width = roundf(linkRect.size.width);
        linkRect.size.height = roundf(linkRect.size.height);
        
        rectForRange = CGRectIsEmpty(rectForRange) ? linkRect : CGRectUnion(rectForRange, linkRect);
    }
    
    return rectForRange;
}

- (void)appendAttachment:(__FWAttributedLabelAttachment *)attachment
{
    attachment.fontAscent                   = _fontAscent;
    attachment.fontDescent                  = _fontDescent;
    unichar objectReplacementChar           = 0xFFFC;
    NSString *objectReplacementString       = [NSString stringWithCharacters:&objectReplacementChar length:1];
    NSMutableAttributedString *attachText   = [[NSMutableAttributedString alloc]initWithString:objectReplacementString];
    
    CTRunDelegateCallbacks callbacks;
    callbacks.version       = kCTRunDelegateVersion1;
    callbacks.getAscent     = __fw_attributedAscentCallback;
    callbacks.getDescent    = __fw_attributedDescentCallback;
    callbacks.getWidth      = __fw_attributedWidthCallback;
    callbacks.dealloc       = __fw_attributedDeallocCallback;
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (void *)attachment);
    NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegate,kCTRunDelegateAttributeName, nil];
    [attachText setAttributes:attr range:NSMakeRange(0, 1)];
    CFRelease(delegate);
    
    [_attachments addObject:attachment];
    [self appendAttributedText:attachText];
}

#pragma mark - 设置文本
- (void)setText:(NSString *)text
{
    NSAttributedString *attributedText = [self attributedString:text];
    [self setAttributedText:attributedText];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:attributedText];
    [self cleanAll];
}

- (NSString *)text
{
    return [_attributedString string];
}

- (NSAttributedString *)attributedText
{
    return [_attributedString copy];
}

#pragma mark - 添加文本
- (void)appendText:(NSString *)text
{
    NSAttributedString *attributedText = [self attributedString:text];
    [self appendAttributedText:attributedText];
}

- (void)appendAttributedText:(NSAttributedString *)attributedText
{
    [_attributedString appendAttributedString:attributedText];
    [self resetTextFrame];
}

#pragma mark - 添加图片
- (void)appendImage:(UIImage *)image
{
    [self appendImage:image
              maxSize:image.size];
}

- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize
{
    [self appendImage:image
              maxSize:maxSize
               margin:UIEdgeInsetsZero];
}

- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize
             margin:(UIEdgeInsets)margin
{
    [self appendImage:image
              maxSize:maxSize
               margin:margin
            alignment:__FWAttributedAlignmentCenter];
}

- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize
             margin:(UIEdgeInsets)margin
          alignment:(__FWAttributedAlignment)alignment
{
    __FWAttributedLabelAttachment *attachment = [__FWAttributedLabelAttachment attachmentWith:image
                                                                                   margin:margin
                                                                                alignment:alignment
                                                                                  maxSize:maxSize];
    [self appendAttachment:attachment];
}

#pragma mark - 添加UI控件
- (void)appendView:(UIView *)view
{
    [self appendView:view
              margin:UIEdgeInsetsZero];
}

- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin
{
    [self appendView:view
              margin:margin
           alignment:__FWAttributedAlignmentCenter];
}


- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin
         alignment:(__FWAttributedAlignment)alignment
{
    __FWAttributedLabelAttachment *attachment = [__FWAttributedLabelAttachment attachmentWith:view
                                                                                   margin:margin
                                                                                alignment:alignment
                                                                                  maxSize:CGSizeZero];
    [self appendAttachment:attachment];
}

#pragma mark - 添加链接
- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range
{
    [self addCustomLink:linkData
               forRange:range
              linkColor:self.linkColor];
}

- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range
            linkColor:(UIColor *)color
{
    __FWAttributedLabelURL *url = [__FWAttributedLabelURL urlWithLinkData:linkData
                                                                  range:range
                                                                  color:color];
    [_linkLocations addObject:url];
    [self resetTextFrame];
}

#pragma mark - 计算大小
- (CGSize)sizeThatFits:(CGSize)size
{
    NSAttributedString *drawString = [self attributedStringForDraw];
    if (drawString == nil)
    {
        return CGSizeZero;
    }
    size = CGSizeMake(size.width > 0 ? size.width : CGFLOAT_MAX, size.height > 0 ? size.height : CGFLOAT_MAX);
    CFAttributedStringRef attributedStringRef = (__bridge CFAttributedStringRef)drawString;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedStringRef);
    CFRange range = CFRangeMake(0, 0);
    if (_numberOfLines > 0 && framesetter)
    {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        
        if (nil != lines && CFArrayGetCount(lines) > 0)
        {
            NSInteger lastVisibleLineIndex = MIN(_numberOfLines, CFArrayGetCount(lines)) - 1;
            CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);
            
            CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
            range = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        }
        CFRelease(frame);
        CFRelease(path);
    }
    
    CFRange fitCFRange = CFRangeMake(0, 0);
    CGSize newSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, NULL, size, &fitCFRange);
    if (framesetter)
    {
        CFRelease(framesetter);
    }
    
    return CGSizeMake(MIN(ceilf(newSize.width), size.width), MIN(ceilf(newSize.height), size.height));
}

- (CGSize)intrinsicContentSize
{
    return [self sizeThatFits:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX)];
}

#pragma mark - 绘制方法
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == nil) { return; }
    CGContextSaveGState(ctx);
    CGAffineTransform transform = [self transformForCoreText];
    CGContextConcatCTM(ctx, transform);
    
    [self recomputeLinksIfNeeded];
    
    NSAttributedString *drawString = [self attributedStringForDraw];
    if (drawString)
    {
        [self prepareTextFrame:drawString rect:rect];
        [self drawHighlightWithRect:rect];
        [self drawAttachments];
        [self drawShadow:ctx];
        [self drawText:drawString rect:rect context:ctx];
        if (@available(iOS 15.0, *)) {} else {
            [self drawStrikethroughWithRect:rect context:ctx];
        }
    }
    CGContextRestoreGState(ctx);
}

- (void)prepareTextFrame:(NSAttributedString *)string
                    rect:(CGRect)rect
{
    if (_textFrame == nil)
    {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, nil,rect);
        _textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CGPathRelease(path);
        CFRelease(framesetter);
    }
}

- (void)drawHighlightWithRect:(CGRect)rect
{
    if (self.touchedLink && self.highlightColor)
    {
        [self.highlightColor setFill];
        NSRange linkRange = self.touchedLink.range;
        
        CFArrayRef lines = CTFrameGetLines(_textFrame);
        CFIndex count = CFArrayGetCount(lines);
        CGPoint lineOrigins[count];
        CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, 0), lineOrigins);
        NSInteger numberOfLines = [self numberOfDisplayedLines];
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        for (CFIndex i = 0; i < numberOfLines; i++)
        {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            
            CFRange stringRange = CTLineGetStringRange(line);
            NSRange lineRange = NSMakeRange(stringRange.location, stringRange.length);
            NSRange intersectedRange = NSIntersectionRange(lineRange, linkRange);
            if (intersectedRange.length == 0) {
                continue;
            }
            
            CGRect highlightRect = [self rectForRange:linkRange
                                               inLine:line
                                           lineOrigin:lineOrigins[i]];
            
            highlightRect = CGRectOffset(highlightRect, 0, -rect.origin.y);
            if (!CGRectIsEmpty(highlightRect))
            {
                CGFloat pi = (CGFloat)M_PI;
                
                CGFloat radius = 1.0f;
                CGContextMoveToPoint(ctx, highlightRect.origin.x, highlightRect.origin.y + radius);
                CGContextAddLineToPoint(ctx, highlightRect.origin.x, highlightRect.origin.y + highlightRect.size.height - radius);
                CGContextAddArc(ctx, highlightRect.origin.x + radius, highlightRect.origin.y + highlightRect.size.height - radius,
                                radius, pi, pi / 2.0f, 1.0f);
                CGContextAddLineToPoint(ctx, highlightRect.origin.x + highlightRect.size.width - radius,
                                        highlightRect.origin.y + highlightRect.size.height);
                CGContextAddArc(ctx, highlightRect.origin.x + highlightRect.size.width - radius,
                                highlightRect.origin.y + highlightRect.size.height - radius, radius, pi / 2, 0.0f, 1.0f);
                CGContextAddLineToPoint(ctx, highlightRect.origin.x + highlightRect.size.width, highlightRect.origin.y + radius);
                CGContextAddArc(ctx, highlightRect.origin.x + highlightRect.size.width - radius, highlightRect.origin.y + radius,
                                radius, 0.0f, -pi / 2.0f, 1.0f);
                CGContextAddLineToPoint(ctx, highlightRect.origin.x + radius, highlightRect.origin.y);
                CGContextAddArc(ctx, highlightRect.origin.x + radius, highlightRect.origin.y + radius, radius,
                                -pi / 2, pi, 1);
                CGContextFillPath(ctx);
            }
        }
        
    }
}

- (void)drawShadow:(CGContextRef)ctx
{
    if (self.shadowColor)
    {
        CGContextSetShadowWithColor(ctx, self.shadowOffset, self.shadowBlur, self.shadowColor.CGColor);
    }
}

- (void)drawText:(NSAttributedString *)attributedString
            rect:(CGRect)rect
         context:(CGContextRef)context
{
    if (_textFrame)
    {
        if (_numberOfLines > 0)
        {
            CFArrayRef lines = CTFrameGetLines(_textFrame);
            NSInteger numberOfLines = [self numberOfDisplayedLines];
            
            CGPoint lineOrigins[numberOfLines];
            CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, numberOfLines), lineOrigins);
            
            for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++)
            {
                CGPoint lineOrigin = lineOrigins[lineIndex];
                CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
                CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
                
                BOOL shouldDrawLine = YES;
                if (lineIndex == numberOfLines - 1 &&
                    _lineBreakMode == kCTLineBreakByTruncatingTail)
                {
                    //找到最后一行并检查是否需要 truncatingTail
                    CFRange lastLineRange = CTLineGetStringRange(line);
                    if (lastLineRange.location + lastLineRange.length < attributedString.length)
                    {
                        CTLineTruncationType truncationType = kCTLineTruncationEnd;
                        NSUInteger truncationAttributePosition = lastLineRange.location + lastLineRange.length - 1;
                        
                        NSDictionary *tokenAttributes = [attributedString attributesAtIndex:truncationAttributePosition
                                                                             effectiveRange:NULL];
                        NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:FWEllipsesCharacter
                                                                                          attributes:tokenAttributes];
                        CTLineRef truncationToken = CTLineCreateWithAttributedString((CFAttributedStringRef)tokenString);
                        
                        NSMutableAttributedString *truncationString = [[attributedString attributedSubstringFromRange:NSMakeRange(lastLineRange.location, lastLineRange.length)] mutableCopy];
                        
                        if (lastLineRange.length > 0)
                        {
                            //移除掉最后一个对象...
                            //其实这个地方有点问题,也有可能需要移除最后 2 个对象，因为 attachment 宽度的关系
                            [truncationString deleteCharactersInRange:NSMakeRange(lastLineRange.length - 1, 1)];
                        }
                        [truncationString appendAttributedString:tokenString];

                        double truncationWidth = rect.size.width;
                        if (self.lineTruncatingSpacing > 0) {
                            truncationWidth -= self.lineTruncatingSpacing;
                            
                            __FWAttributedLabelAttachment *attributedImage = self.lineTruncatingAttachment;
                            if (attributedImage) {
                                CGFloat lineAscent;
                                CGFloat lineDescent;
                                CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, NULL);
                                CGFloat lineHeight = lineAscent + lineDescent;
                                CGFloat lineBottomY = lineOrigin.y - lineDescent;
                                
                                CGSize boxSize = [attributedImage boxSize];
                                CGFloat imageBoxHeight = boxSize.height;
                                CGFloat xOffset = truncationWidth;
                                
                                CGFloat imageBoxOriginY = 0.0f;
                                switch (attributedImage.alignment)
                                {
                                    case __FWAttributedAlignmentTop:
                                        imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight);
                                        break;
                                    case __FWAttributedAlignmentCenter:
                                        imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight) / 2.0;
                                        break;
                                    case __FWAttributedAlignmentBottom:
                                        imageBoxOriginY = lineBottomY;
                                        break;
                                }
                                
                                CGRect imageRect = CGRectMake(lineOrigin.x + xOffset, imageBoxOriginY, boxSize.width, imageBoxHeight);
                                UIEdgeInsets flippedMargins = attributedImage.margin;
                                CGFloat top = flippedMargins.top;
                                flippedMargins.top = flippedMargins.bottom;
                                flippedMargins.bottom = top;
                                
                                CGRect attatchmentRect = UIEdgeInsetsInsetRect(imageRect, flippedMargins);
                                
                                id content = attributedImage.content;
                                if ([content isKindOfClass:[UIImage class]])
                                {
                                    CGContextDrawImage(context, attatchmentRect, ((UIImage *)content).CGImage);
                                }
                                else if ([content isKindOfClass:[UIView class]])
                                {
                                    UIView *view = (UIView *)content;
                                    self.lineTruncatingView = view;
                                    if (view.superview == nil)
                                    {
                                        [self addSubview:view];
                                    }
                                    CGRect viewFrame = CGRectMake(attatchmentRect.origin.x,
                                                                  self.bounds.size.height - attatchmentRect.origin.y - attatchmentRect.size.height,
                                                                  attatchmentRect.size.width,
                                                                  attatchmentRect.size.height);
                                    [view setFrame:viewFrame];
                                }
                            }
                        }
                        
                        CTLineRef truncationLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncationString);
                        CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, truncationWidth, truncationType, truncationToken);
                        if (!truncatedLine)
                        {
                            truncatedLine = CFRetain(truncationToken);
                        }
                        CFRelease(truncationLine);
                        CFRelease(truncationToken);
                        
                        CTLineDraw(truncatedLine, context);
                        CFRelease(truncatedLine);
                        
                        
                        shouldDrawLine = NO;
                    }
                }
                if(shouldDrawLine)
                {
                    CTLineDraw(line, context);
                }
            }
        }
        else
        {
            CTFrameDraw(_textFrame,context);
        }
    }
}

- (void)drawStrikethroughWithRect:(CGRect)rect
                          context:(CGContextRef)context
{
    if (!_textFrame) return;
    CFArrayRef lines = CTFrameGetLines(_textFrame);
    NSInteger numberOfLines = [self numberOfDisplayedLines];
    CGFloat scale = UIScreen.mainScreen.scale;
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, numberOfLines), lineOrigins);
    
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++)
    {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        
        for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runs); runIndex ++) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, runIndex);
            CFIndex glyphCount = CTRunGetGlyphCount(run);
            if (glyphCount <= 0) continue;
            
            NSDictionary *attrs = (id)CTRunGetAttributes(run);
            NSNumber *strikethrough = attrs[NSStrikethroughStyleAttributeName];
            if (!strikethrough || ![strikethrough isKindOfClass:[NSNumber class]]) continue;
            NSUnderlineStyle style = strikethrough.integerValue;
            NSUInteger styleBase = style & 0xFF;
            if (styleBase == 0) continue;
            
            CGColorRef color = (__bridge CGColorRef)attrs[NSStrikethroughColorAttributeName];
            if (!color) color = (__bridge CGColorRef)(attrs[(id)kCTForegroundColorAttributeName]);
            if (!color) color = (__bridge CGColorRef)(attrs[NSForegroundColorAttributeName]) ?: UIColor.blackColor.CGColor;
            if ([((__bridge NSObject *)color) respondsToSelector:@selector(CGColor)]) {
                color = ((__bridge UIColor *)color).CGColor;
            }
            
            CGFloat xHeight = 0, underLinePosition = 0, lineThickness = 0;
            [self drawMaxMetric:runs xHeight:&xHeight underlinePosition:&underLinePosition lineThickness:&lineThickness];
            
            CGPoint position = CGPointMake(lineOrigin.x - underLinePosition, lineOrigin.y + xHeight / 2);
            CGPoint runPosition = CGPointZero;
            CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition);
            position.x = lineOrigin.x + runPosition.x;
            CGFloat width = lineThickness;
            CGFloat length = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), NULL, NULL, NULL);
            CGFloat phase = position.x;
            
            CGFloat x1, x2, y, w;
            x1 = round(position.x * scale) / scale;
            x2 = round((position.x + length) * scale) / scale;
            w = (styleBase == NSUnderlineStyleThick) ? width * 2 : width;
            CGFloat linePixel = w * scale;
            if (fabs(linePixel - floor(linePixel)) < 0.1) {
                int iPixel = linePixel;
                if (iPixel == 0 || (iPixel % 2)) {
                    y = (floor(position.y * scale) + 0.5) / scale;
                } else {
                    y = floor(position.y * scale) / scale;
                }
            } else {
                y = position.y;
            }
            
            CGContextSetStrokeColorWithColor(context, color);
            CGContextSetLineWidth(context, width);
            CGContextSetLineCap(context, kCGLineCapButt);
            CGContextSetLineJoin(context, kCGLineJoinMiter);
            CGFloat dash = 12, dot = 5, space = 3;
            NSUInteger pattern = style & 0xF00;
            if (pattern == NSUnderlinePatternSolid) {
                CGContextSetLineDash(context, phase, NULL, 0);
            } else if (pattern == NSUnderlinePatternDot) {
                CGFloat lengths[2] = {width * dot, width * space};
                CGContextSetLineDash(context, phase, lengths, 2);
            } else if (pattern == NSUnderlinePatternDash) {
                CGFloat lengths[2] = {width * dash, width * space};
                CGContextSetLineDash(context, phase, lengths, 2);
            } else if (pattern == NSUnderlinePatternDashDot) {
                CGFloat lengths[4] = {width * dash, width * space, width * dot, width * space};
                CGContextSetLineDash(context, phase, lengths, 4);
            } else if (pattern == NSUnderlinePatternDashDotDot) {
                CGFloat lengths[6] = {width * dash, width * space, width * dot, width * space, width * dot, width * space};
                CGContextSetLineDash(context, phase, lengths, 6);
            }
            
            CGContextSetLineWidth(context, w);
            if (styleBase == NSUnderlineStyleSingle) {
                CGContextMoveToPoint(context, x1, y);
                CGContextAddLineToPoint(context, x2, y);
                CGContextStrokePath(context);
            } else if (styleBase == NSUnderlineStyleThick) {
                CGContextMoveToPoint(context, x1, y);
                CGContextAddLineToPoint(context, x2, y);
                CGContextStrokePath(context);
            } else if (styleBase == NSUnderlineStyleDouble) {
                CGContextMoveToPoint(context, x1, y - w);
                CGContextAddLineToPoint(context, x2, y - w);
                CGContextStrokePath(context);
                CGContextMoveToPoint(context, x1, y + w);
                CGContextAddLineToPoint(context, x2, y + w);
                CGContextStrokePath(context);
            }
        }
    }
}

- (void)drawMaxMetric:(CFArrayRef)runs xHeight:(CGFloat *)xHeight underlinePosition:(CGFloat *)underlinePosition lineThickness:(CGFloat *)lineThickness
{
    CGFloat maxXHeight = 0;
    CGFloat maxUnderlinePos = 0;
    CGFloat maxLineThickness = 0;
    for (NSUInteger i = 0, max = CFArrayGetCount(runs); i < max; i++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, i);
        CFDictionaryRef attrs = CTRunGetAttributes(run);
        if (attrs) {
            CTFontRef font = CFDictionaryGetValue(attrs, kCTFontAttributeName);
            if (font) {
                CGFloat xHeight = CTFontGetXHeight(font);
                if (xHeight > maxXHeight) maxXHeight = xHeight;
                CGFloat underlinePos = CTFontGetUnderlinePosition(font);
                if (underlinePos < maxUnderlinePos) maxUnderlinePos = underlinePos;
                CGFloat lineThickness = CTFontGetUnderlineThickness(font);
                if (lineThickness > maxLineThickness) maxLineThickness = lineThickness;
            }
        }
    }
    if (xHeight) *xHeight = maxXHeight;
    if (underlinePosition) *underlinePosition = maxUnderlinePos;
    if (lineThickness) *lineThickness = maxLineThickness;
}

- (void)drawAttachments
{
    if ([_attachments count] == 0)
    {
        return;
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == nil)
    {
        return;
    }
    
    CFArrayRef lines = CTFrameGetLines(_textFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, 0), lineOrigins);
    NSInteger numberOfLines = [self numberOfDisplayedLines];
    for (CFIndex i = 0; i < numberOfLines; i++)
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CFIndex runCount = CFArrayGetCount(runs);
        CGPoint lineOrigin = lineOrigins[i];
        CGFloat lineAscent;
        CGFloat lineDescent;
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, NULL);
        CGFloat lineHeight = lineAscent + lineDescent;
        CGFloat lineBottomY = lineOrigin.y - lineDescent;
        
        //遍历找到对应的 attachment 进行绘制
        for (CFIndex k = 0; k < runCount; k++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, k);
            NSDictionary *runAttributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[runAttributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (nil == delegate)
            {
                continue;
            }
            __FWAttributedLabelAttachment* attributedImage = (__FWAttributedLabelAttachment *)CTRunDelegateGetRefCon(delegate);
            
            CGFloat ascent = 0.0f;
            CGFloat descent = 0.0f;
            CGFloat width = (CGFloat)CTRunGetTypographicBounds(run,
                                                               CFRangeMake(0, 0),
                                                               &ascent,
                                                               &descent,
                                                               NULL);
            
            CGFloat imageBoxHeight = [attributedImage boxSize].height;
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil);
            
            CGFloat imageBoxOriginY = 0.0f;
            switch (attributedImage.alignment)
            {
                case __FWAttributedAlignmentTop:
                    imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight);
                    break;
                case __FWAttributedAlignmentCenter:
                    imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight) / 2.0;
                    break;
                case __FWAttributedAlignmentBottom:
                    imageBoxOriginY = lineBottomY;
                    break;
            }
            
            CGRect imageRect = CGRectMake(lineOrigin.x + xOffset, imageBoxOriginY, width, imageBoxHeight);
            UIEdgeInsets flippedMargins = attributedImage.margin;
            CGFloat top = flippedMargins.top;
            flippedMargins.top = flippedMargins.bottom;
            flippedMargins.bottom = top;
            
            CGRect attatchmentRect = UIEdgeInsetsInsetRect(imageRect, flippedMargins);
            
            if (i == numberOfLines - 1 &&
                k >= runCount - 2 &&
                 _lineBreakMode == kCTLineBreakByTruncatingTail)
            {
                //最后行最后的2个CTRun需要做额外判断
                CGFloat attachmentWidth = CGRectGetWidth(attatchmentRect);
                const CGFloat kMinEllipsesWidth = attachmentWidth;
                if (CGRectGetWidth(self.bounds) - CGRectGetMinX(attatchmentRect) - attachmentWidth <  kMinEllipsesWidth)
                {
                    continue;
                }
            }
            
            id content = attributedImage.content;
            if ([content isKindOfClass:[UIImage class]])
            {
                CGContextDrawImage(ctx, attatchmentRect, ((UIImage *)content).CGImage);
            }
            else if ([content isKindOfClass:[UIView class]])
            {
                UIView *view = (UIView *)content;
                if (view.superview == nil)
                {
                    [self addSubview:view];
                }
                CGRect viewFrame = CGRectMake(attatchmentRect.origin.x,
                                              self.bounds.size.height - attatchmentRect.origin.y - attatchmentRect.size.height,
                                              attatchmentRect.size.width,
                                              attatchmentRect.size.height);
                [view setFrame:viewFrame];
            }
        }
    }
}


#pragma mark - 点击事件处理
- (BOOL)onLabelClick:(CGPoint)point
{
    id linkData = [self linkDataForPoint:point];
    if (linkData)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(attributedLabel:clickedOnLink:)])
        {
            [_delegate attributedLabel:self clickedOnLink:linkData];
        }
        else if (self.clickedOnLink)
        {
            self.clickedOnLink(linkData);
        }
        else
        {
            NSURL *url = nil;
            if ([linkData isKindOfClass:[NSString class]])
            {
                url = [NSURL URLWithString:linkData];
                if (!url && [linkData length] > 0) {
                    url = [NSURL URLWithString:[linkData stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                }
            }
            else if([linkData isKindOfClass:[NSURL class]])
            {
                url = linkData;
            }
            if (url)
            {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            }
        }
        return YES;
    }
    
    return NO;
}


#pragma mark - 链接处理
- (void)recomputeLinksIfNeeded
{
    const NSInteger kMinHttpLinkLength = 5;
    if (!_autoDetectLinks || _linkDetected)
    {
        return;
    }
    NSString *text = [[_attributedString string] copy];
    NSUInteger length = [text length];
    if (length <= kMinHttpLinkLength)
    {
        return;
    }
    [self computeLink:text];
}

- (void)computeLink:(NSString *)text
{
    __weak typeof(self) weakSelf = self;
    self.ignoreRedraw = YES;
    
    [self.linkDetector detectLinks:text
                        completion:^(NSArray<__FWAttributedLabelURL *> * _Nullable links) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            NSString *plainText = [[strongSelf attributedString] string];
                            if ([text isEqualToString:plainText])
                            {
                                strongSelf.linkDetected = YES;
                                if ([links count])
                                {
                                    for (__FWAttributedLabelURL *link in links)
                                    {
                                        [strongSelf addAutoDetectedLink:link];
                                    }
                                    [strongSelf resetTextFrame];
                                }
                                strongSelf.ignoreRedraw = NO;
                            }
                        }];
}

- (void)addAutoDetectedLink:(__FWAttributedLabelURL *)link
{
    NSRange range = link.range;
    for (__FWAttributedLabelURL *url in _linkLocations)
    {
        if (NSIntersectionRange(range, url.range).length != 0)
        {
            return;
        }
    }
    [self addCustomLink:link.linkData
               forRange:link.range];
}

#pragma mark - 点击事件相应
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchedLink == nil)
    {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        self.touchedLink =  [self urlForPoint:point];
    }
    
    if (self.touchedLink)
    {
          [self setNeedsDisplay];
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    __FWAttributedLabelURL *touchedLink = [self urlForPoint:point];
    if (self.touchedLink != touchedLink)
    {
        self.touchedLink = touchedLink;
        [self setNeedsDisplay];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (self.touchedLink)
    {
        self.touchedLink = nil;
        [self setNeedsDisplay];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if(![self onLabelClick:point])
    {
        [super touchesEnded:touches withEvent:event];
    }
    if (self.touchedLink)
    {
        self.touchedLink = nil;
        [self setNeedsDisplay];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    __FWAttributedLabelURL *touchedLink = [self urlForPoint:point];
    if (touchedLink == nil)
    {
        NSArray *subViews = [self subviews];
        for (UIView *view in subViews)
        {
            CGPoint hitPoint = [view convertPoint:point
                                         fromView:self];
            
            UIView *hitTestView = [view hitTest:hitPoint
                                      withEvent:event];
            if (hitTestView)
            {
                return hitTestView;
            }
        }
        return nil;
    }
    else
    {
        return self;
    }
}

@end

#pragma mark - __FWAttributedLabelURL

@implementation __FWAttributedLabelURL

+ (__FWAttributedLabelURL *)urlWithLinkData:(id)linkData
                                     range:(NSRange)range
                                     color:(UIColor *)color
{
    __FWAttributedLabelURL *url  = [[__FWAttributedLabelURL alloc]init];
    url.linkData                = linkData;
    url.range                   = range;
    url.color                   = color;
    return url;
    
}

@end

#pragma mark - __FWAttributedLabelDefaultURLDetector

@implementation __FWAttributedLabelDefaultURLDetector

- (NSRegularExpression *)dataDetector
{
    if (_dataDetector == nil) {
        _dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink | NSTextCheckingTypePhoneNumber error:nil];
    }
    return _dataDetector;
}

- (void)detectLinks:(nullable NSString *)plainText
         completion:(__FWAttributedLinkDetectCompletion)completion
{
    if (completion == nil) { return; }
    
    NSMutableArray *links = nil;
    if ([plainText length])
    {
        links = [NSMutableArray array];
        [self.dataDetector enumerateMatchesInString:plainText
                                   options:0
                                     range:NSMakeRange(0, [plainText length])
                                usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
                                    NSRange range = result.range;
                                    NSString *text = [plainText substringWithRange:range];
                                    __FWAttributedLabelURL *link = [__FWAttributedLabelURL urlWithLinkData:text
                                                                                                   range:range
                                                                                                   color:nil];
                                    [links addObject:link];
                                }];
    }
    completion(links);
}

@end

#pragma mark - __FWAttributedLabelURLDetector

@implementation __FWAttributedLabelURLDetector

+ (instancetype)shared
{
    static __FWAttributedLabelURLDetector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [__FWAttributedLabelURLDetector new];
    });
    return instance;
}

- (id<__FWAttributedLabelURLDetectorProtocol>)detector
{
    if (_detector == nil) {
        _detector = [[__FWAttributedLabelDefaultURLDetector alloc] init];
    }
    return _detector;
}

- (void)detectLinks:(nullable NSString *)plainText
         completion:(__FWAttributedLinkDetectCompletion)completion
{
    if (completion == nil) { return; }
    
    [self.detector detectLinks:plainText completion:completion];
}

@end

#pragma mark - __FWAttributedLabelAttachment

void __fw_attributedDeallocCallback(void* ref)
{
    
}

CGFloat __fw_attributedAscentCallback(void *ref)
{
    __FWAttributedLabelAttachment *image = (__bridge __FWAttributedLabelAttachment *)ref;
    CGFloat ascent = 0;
    CGFloat height = [image boxSize].height;
    switch (image.alignment)
    {
        case __FWAttributedAlignmentTop:
            ascent = image.fontAscent;
            break;
        case __FWAttributedAlignmentCenter:
        {
            CGFloat fontAscent  = image.fontAscent;
            CGFloat fontDescent = image.fontDescent;
            CGFloat baseLine = (fontAscent + fontDescent) / 2 - fontDescent;
            ascent = height / 2 + baseLine;
        }
            break;
        case __FWAttributedAlignmentBottom:
            ascent = height - image.fontDescent;
            break;
        default:
            break;
    }
    return ascent;
}

CGFloat __fw_attributedDescentCallback(void *ref)
{
    __FWAttributedLabelAttachment *image = (__bridge __FWAttributedLabelAttachment *)ref;
    CGFloat descent = 0;
    CGFloat height = [image boxSize].height;
    switch (image.alignment)
    {
        case __FWAttributedAlignmentTop:
        {
            descent = height - image.fontAscent;
            break;
        }
        case __FWAttributedAlignmentCenter:
        {
            CGFloat fontAscent  = image.fontAscent;
            CGFloat fontDescent = image.fontDescent;
            CGFloat baseLine = (fontAscent + fontDescent) / 2 - fontDescent;
            descent = height / 2 - baseLine;
        }
            break;
        case __FWAttributedAlignmentBottom:
        {
            descent = image.fontDescent;
            break;
        }
        default:
            break;
    }
    
    return descent;
}

CGFloat __fw_attributedWidthCallback(void* ref)
{
    __FWAttributedLabelAttachment *image  = (__bridge __FWAttributedLabelAttachment *)ref;
    return [image boxSize].width;
}

@interface __FWAttributedLabelAttachment ()
- (CGSize)calculateContentSize;
- (CGSize)attachmentSize;
@end

@implementation __FWAttributedLabelAttachment

+ (__FWAttributedLabelAttachment *)attachmentWith:(id)content
                                          margin:(UIEdgeInsets)margin
                                       alignment:(__FWAttributedAlignment)alignment
                                         maxSize:(CGSize)maxSize
{
    __FWAttributedLabelAttachment *attachment    = [[__FWAttributedLabelAttachment alloc]init];
    attachment.content                          = content;
    attachment.margin                           = margin;
    attachment.alignment                        = alignment;
    attachment.maxSize                          = maxSize;
    return attachment;
}

- (CGSize)boxSize
{
    CGSize contentSize = [self attachmentSize];
    if (_maxSize.width > 0 &&_maxSize.height > 0 &&
        contentSize.width > 0 && contentSize.height > 0)
    {
        contentSize = [self calculateContentSize];
    }
    return CGSizeMake(contentSize.width + _margin.left + _margin.right,
                      contentSize.height+ _margin.top  + _margin.bottom);
}


#pragma mark - 辅助方法
- (CGSize)calculateContentSize
{
    CGSize attachmentSize   = [self attachmentSize];
    CGFloat width           = attachmentSize.width;
    CGFloat height          = attachmentSize.height;
    CGFloat newWidth        = _maxSize.width;
    CGFloat newHeight       = _maxSize.height;
    if (width <= newWidth &&
        height<= newHeight)
    {
        return attachmentSize;
    }
    CGSize size;
    if (width / height > newWidth / newHeight)
    {
        size = CGSizeMake(newWidth, newWidth * height / width);
    }
    else
    {
        size = CGSizeMake(newHeight * width / height, newHeight);
    }
    return size;
}

- (CGSize)attachmentSize
{
    CGSize size = CGSizeZero;
    if ([_content isKindOfClass:[UIImage class]])
    {
        size = [((UIImage *)_content) size];
    }
    else if ([_content isKindOfClass:[UIView class]])
    {
        size = [((UIView *)_content) bounds].size;
    }
    return size;
}

@end
