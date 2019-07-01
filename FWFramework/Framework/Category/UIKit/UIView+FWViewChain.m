/*!
 @header     UIView+FWViewChain.m
 @indexgroup FWFramework
 @brief      UIView+FWViewChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import "UIView+FWViewChain.h"
#import "UIImageView+FWNetwork.h"
#import "UITextField+FWFramework.h"
#import "UITextView+FWFramework.h"
#import <objc/runtime.h>

#pragma mark - FWViewChainObjc

@interface FWViewChainObjc : NSObject <FWViewChainProtocols, FWLabelChainProtocols, FWButtonChainProtocols, FWImageViewChainProtocols, FWScrollViewChainProtocols, FWTextFieldChainProtocols, FWTextViewChainProtocols>

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWViewChainObjc

#pragma mark - FWViewChainProtocols

- (id<FWViewChainProtocols> (^)(BOOL))userInteractionEnabled
{
    return ^id(BOOL enabled) {
        self.view.userInteractionEnabled = enabled;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(NSInteger))tag
{
    return ^id(NSInteger tag) {
        self.view.tag = tag;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGRect))frame
{
    return ^id(CGRect frame) {
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGRect))bounds
{
    return ^id(CGRect bounds) {
        self.view.bounds = bounds;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGPoint))center
{
    return ^id(CGPoint center) {
        self.view.center = center;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGPoint))origin
{
    return ^id(CGPoint origin) {
        CGRect frame = self.view.frame;
        frame.origin = origin;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGSize))size
{
    return ^id(CGSize size) {
        CGRect frame = self.view.frame;
        frame.size = size;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))x
{
    return ^id(CGFloat x) {
        CGRect frame = self.view.frame;
        frame.origin.x = x;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))y
{
    return ^id(CGFloat y) {
        CGRect frame = self.view.frame;
        frame.origin.y = y;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))width
{
    return ^id(CGFloat width) {
        CGRect frame = self.view.frame;
        frame.size.width = width;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))height
{
    return ^id(CGFloat height) {
        CGRect frame = self.view.frame;
        frame.size.height = height;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGAffineTransform))transform
{
    return ^id(CGAffineTransform transform) {
        self.view.transform = transform;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIViewAutoresizing))autoresizingMask
{
    return ^id(UIViewAutoresizing autoresizingMask) {
        self.view.autoresizingMask = autoresizingMask;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(BOOL))clipsToBounds
{
    return ^id(BOOL clipsToBounds) {
        self.view.clipsToBounds = clipsToBounds;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIColor *))backgroundColor
{
    return ^id(UIColor *backgroundColor) {
        self.view.backgroundColor = backgroundColor;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))alpha
{
    return ^id(CGFloat alpha) {
        self.view.alpha = alpha;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(BOOL))opaque
{
    return ^id(BOOL opaque) {
        self.view.opaque = opaque;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(BOOL))hidden
{
    return ^id(BOOL hidden) {
        self.view.hidden = hidden;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIViewContentMode))contentMode
{
    return ^id(UIViewContentMode contentMode) {
        self.view.contentMode = contentMode;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIColor *))tintColor
{
    return ^id(UIColor *tintColor) {
        self.view.tintColor = tintColor;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIView *))addSubview
{
    return ^id(UIView *view) {
        [self.view addSubview:view];
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIView *))moveToSuperview
{
    return ^id(UIView *view) {
        if (view) {
            [view addSubview:self.view];
        } else {
            [self.view removeFromSuperview];
        }
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(BOOL))masksToBounds
{
    return ^id(BOOL masksToBounds) {
        self.view.layer.masksToBounds = masksToBounds;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))cornerRadius
{
    return ^id(CGFloat cornerRadius) {
        self.view.layer.cornerRadius = cornerRadius;
        self.view.layer.masksToBounds = YES;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))borderWidth
{
    return ^id(CGFloat borderWidth) {
        self.view.layer.borderWidth = borderWidth;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIColor *))borderColor
{
    return ^id(UIColor *borderColor) {
        self.view.layer.borderColor = borderColor.CGColor;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(UIColor *))shadowColor
{
    return ^id(UIColor *shadowColor) {
        self.view.layer.shadowColor = shadowColor.CGColor;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(float))shadowOpacity
{
    return ^id(float shadowOpacity) {
        self.view.layer.shadowOpacity = shadowOpacity;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGSize))shadowOffset
{
    return ^id(CGSize shadowOffset) {
        self.view.layer.shadowOffset = shadowOffset;
        return self;
    };
}

- (id<FWViewChainProtocols> (^)(CGFloat))shadowRadius
{
    return ^id(CGFloat shadowRadius) {
        self.view.layer.shadowRadius = shadowRadius;
        return self;
    };
}

#pragma mark - FWLabelChainProtocols

- (id<FWLabelChainProtocols> (^)(NSString *))text
{
    return ^id(NSString *text) {
        ((UILabel *)self.view).text = text;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(UIFont *))font
{
    return ^id(UIFont *font) {
        ((UILabel *)self.view).font = font;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(UIColor *))textColor
{
    return ^id(UIColor *textColor) {
        ((UILabel *)self.view).textColor = textColor;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(NSTextAlignment))textAlignment
{
    return ^id(NSTextAlignment textAlignment) {
        ((UILabel *)self.view).textAlignment = textAlignment;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(NSAttributedString *))attributedText
{
    return ^id(NSAttributedString *attributedText) {
        ((UILabel *)self.view).attributedText = attributedText;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(NSLineBreakMode))lineBreakMode
{
    return ^id(NSLineBreakMode lineBreakMode) {
        ((UILabel *)self.view).lineBreakMode = lineBreakMode;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(UIColor *))highlightedTextColor
{
    return ^id(UIColor *highlightedTextColor) {
        ((UILabel *)self.view).highlightedTextColor = highlightedTextColor;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(BOOL))highlighted
{
    return ^id(BOOL highlighted) {
        ((UILabel *)self.view).highlighted = highlighted;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(BOOL))enabled
{
    return ^id(BOOL enabled) {
        ((UILabel *)self.view).enabled = enabled;
        return self;
    };
}

- (id<FWLabelChainProtocols> (^)(NSInteger))numberOfLines
{
    return ^id(NSInteger numberOfLines) {
        ((UILabel *)self.view).numberOfLines = numberOfLines;
        return self;
    };
}

#pragma mark - FWButtonChainProtocols

- (id<FWButtonChainProtocols> (^)(UIEdgeInsets))contentEdgeInsets
{
    return ^id(UIEdgeInsets contentEdgeInsets) {
        ((UIButton *)self.view).contentEdgeInsets = contentEdgeInsets;
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIEdgeInsets))titleEdgeInsets
{
    return ^id(UIEdgeInsets titleEdgeInsets) {
        ((UIButton *)self.view).titleEdgeInsets = titleEdgeInsets;
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIEdgeInsets))imageEdgeInsets
{
    return ^id(UIEdgeInsets imageEdgeInsets) {
        ((UIButton *)self.view).imageEdgeInsets = imageEdgeInsets;
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(BOOL))selected
{
    return ^id(BOOL selected) {
        ((UIButton *)self.view).selected = selected;
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(NSString *, UIControlState))titleForState
{
    return ^id(NSString *title, UIControlState state) {
        [(UIButton *)self.view setTitle:title forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIColor *, UIControlState))titleColorForState
{
    return ^id(UIColor *titleColor, UIControlState state) {
        [(UIButton *)self.view setTitleColor:titleColor forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIImage *, UIControlState))imageForState
{
    return ^id(UIImage *image, UIControlState state) {
        [(UIButton *)self.view setImage:image forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIImage *, UIControlState))backgroundImageForState
{
    return ^id(UIImage *backgroundImage, UIControlState state) {
        [(UIButton *)self.view setBackgroundImage:backgroundImage forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(NSAttributedString *, UIControlState))attributedTitleForState
{
    return ^id(NSAttributedString *attributedTitle, UIControlState state) {
        [(UIButton *)self.view setAttributedTitle:attributedTitle forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(NSString *))titleForStateNormal
{
    return ^id(NSString *title) {
        [(UIButton *)self.view setTitle:title forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIColor *))titleColorForStateNormal
{
    return ^id(UIColor *titleColor) {
        [(UIButton *)self.view setTitleColor:titleColor forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIImage *))imageForStateNormal
{
    return ^id(UIImage *image) {
        [(UIButton *)self.view setImage:image forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIImage *))backgroundImageForStateNormal
{
    return ^id(UIImage *backgroundImage) {
        [(UIButton *)self.view setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(NSAttributedString *))attributedTitleForStateNormal
{
    return ^id(NSAttributedString *attributedTitle) {
        [(UIButton *)self.view setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocols> (^)(UIFont *))titleLabelFont
{
    return ^id(UIFont *font) {
        ((UIButton *)self.view).titleLabel.font = font;
        return self;
    };
}

#pragma mark - FWImageViewChainProtocols

- (id<FWImageViewChainProtocols> (^)(UIImage *))image
{
    return ^id(UIImage *image) {
        ((UIImageView *)self.view).image = image;
        return self;
    };
}

- (id<FWImageViewChainProtocols> (^)(UIImage *))highlightedImage
{
    return ^id(UIImage *highlightedImage) {
        ((UIImageView *)self.view).highlightedImage = highlightedImage;
        return self;
    };
}

- (id<FWImageViewChainProtocols> (^)(void))contentModeAspectFill
{
    return ^id(void) {
        self.view.contentMode = UIViewContentModeScaleAspectFill;
        self.view.layer.masksToBounds = YES;
        return self;
    };
}

- (id<FWImageViewChainProtocols> (^)(NSURL *))imageUrl
{
    return ^id(NSURL *imageUrl) {
        [((UIImageView *)self.view) fwSetImageWithURL:imageUrl];
        return self;
    };
}

- (id<FWImageViewChainProtocols> (^)(NSURL *, UIImage *))imageUrlWithPlaceholder
{
    return ^id(NSURL *imageUrl, UIImage *placeholderImage) {
        [((UIImageView *)self.view) fwSetImageWithURL:imageUrl placeholderImage:placeholderImage];
        return self;
    };
}

#pragma mark - FWScrollViewChainProtocols

- (id<FWScrollViewChainProtocols> (^)(CGPoint))contentOffset
{
    return ^id(CGPoint contentOffset) {
        ((UIScrollView *)self.view).contentOffset = contentOffset;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(CGSize))contentSize
{
    return ^id(CGSize contentSize) {
        ((UIScrollView *)self.view).contentSize = contentSize;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(UIEdgeInsets))contentInset
{
    return ^id(UIEdgeInsets contentInset) {
        ((UIScrollView *)self.view).contentInset = contentInset;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))directionalLockEnabled
{
    return ^id(BOOL directionalLockEnabled) {
        ((UIScrollView *)self.view).directionalLockEnabled = directionalLockEnabled;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))bounces
{
    return ^id(BOOL bounces) {
        ((UIScrollView *)self.view).bounces = bounces;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))alwaysBounceVertical
{
    return ^id(BOOL alwaysBounceVertical) {
        ((UIScrollView *)self.view).alwaysBounceVertical = alwaysBounceVertical;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))alwaysBounceHorizontal
{
    return ^id(BOOL alwaysBounceHorizontal) {
        ((UIScrollView *)self.view).alwaysBounceHorizontal = alwaysBounceHorizontal;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))pagingEnabled
{
    return ^id(BOOL pagingEnabled) {
        ((UIScrollView *)self.view).pagingEnabled = pagingEnabled;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))scrollEnabled
{
    return ^id(BOOL scrollEnabled) {
        ((UIScrollView *)self.view).scrollEnabled = scrollEnabled;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))showsHorizontalScrollIndicator
{
    return ^id(BOOL showsHorizontalScrollIndicator) {
        ((UIScrollView *)self.view).showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(BOOL))showsVerticalScrollIndicator
{
    return ^id(BOOL showsVerticalScrollIndicator) {
        ((UIScrollView *)self.view).showsVerticalScrollIndicator = showsVerticalScrollIndicator;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(void))keyboardDismissModeOnDrag
{
    return ^id(void) {
        ((UIScrollView *)self.view).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        return self;
    };
}

- (id<FWScrollViewChainProtocols> (^)(void))contentInsetAdjustmentNever
{
    return ^id(void) {
        if (@available(iOS 11.0, *)) {
            ((UIScrollView *)self.view).contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        return self;
    };
}

#pragma mark - FWTextFieldChainProtocols

- (id<FWTextFieldChainProtocols> (^)(NSString *))placeholder
{
    return ^id(NSString *placeholder) {
        if ([self.view isKindOfClass:[UITextField class]]) {
            ((UITextField *)self.view).placeholder = placeholder;
        } else if ([self.view isKindOfClass:[UITextView class]]) {
            ((UITextView *)self.view).fwPlaceholder = placeholder;
        }
        return self;
    };
}

- (id<FWTextFieldChainProtocols> (^)(NSAttributedString *))attributedPlaceholder
{
    return ^id(NSAttributedString *attributedPlaceholder) {
        if ([self.view isKindOfClass:[UITextField class]]) {
            ((UITextField *)self.view).attributedPlaceholder = attributedPlaceholder;
        } else if ([self.view isKindOfClass:[UITextView class]]) {
            ((UITextView *)self.view).fwAttributedPlaceholder = attributedPlaceholder;
        }
        return self;
    };
}

- (id<FWTextFieldChainProtocols> (^)(NSInteger))maxLength
{
    return ^id(NSInteger maxLength) {
        if ([self.view isKindOfClass:[UITextField class]]) {
            ((UITextField *)self.view).fwMaxLength = maxLength;
        } else if ([self.view isKindOfClass:[UITextView class]]) {
            ((UITextView *)self.view).fwMaxLength = maxLength;
        }
        return self;
    };
}

- (id<FWTextFieldChainProtocols> (^)(NSInteger))maxUnicodeLength
{
    return ^id(NSInteger maxUnicodeLength) {
        if ([self.view isKindOfClass:[UITextField class]]) {
            ((UITextField *)self.view).fwMaxUnicodeLength = maxUnicodeLength;
        } else if ([self.view isKindOfClass:[UITextView class]]) {
            ((UITextView *)self.view).fwMaxUnicodeLength = maxUnicodeLength;
        }
        return self;
    };
}

#pragma mark - FWTextViewChainProtocols

- (id<FWTextViewChainProtocols> (^)(BOOL))editable
{
    return ^id(BOOL editable) {
        ((UITextView *)self.view).editable = editable;
        return self;
    };
}

@end

#pragma mark - UIView+FWViewChain

@implementation UIView (FWViewChain)

- (id<FWViewChainProtocols>)fwViewChain
{
    FWViewChainObjc *viewChain = objc_getAssociatedObject(self, _cmd);
    if (!viewChain) {
        viewChain = [[FWViewChainObjc alloc] init];
        viewChain.view = self;
        objc_setAssociatedObject(self, _cmd, viewChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return viewChain;
}

@end
