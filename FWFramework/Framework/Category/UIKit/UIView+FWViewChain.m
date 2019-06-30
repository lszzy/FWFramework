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

@interface FWViewChainObjc : NSObject <FWViewChainProtocol, FWLabelChainProtocol, FWButtonChainProtocol, FWImageViewChainProtocol, FWScrollViewChainProtocol, FWTextFieldChainProtocol, FWTextViewChainProtocol>

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWViewChainObjc

#pragma mark - FWViewChainProtocol

- (id<FWViewChainProtocol> (^)(BOOL))userInteractionEnabled
{
    return ^id(BOOL enabled) {
        self.view.userInteractionEnabled = enabled;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(NSInteger))tag
{
    return ^id(NSInteger tag) {
        self.view.tag = tag;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGRect))frame
{
    return ^id(CGRect frame) {
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGRect))bounds
{
    return ^id(CGRect bounds) {
        self.view.bounds = bounds;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGPoint))center
{
    return ^id(CGPoint center) {
        self.view.center = center;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGPoint))origin
{
    return ^id(CGPoint origin) {
        CGRect frame = self.view.frame;
        frame.origin = origin;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGSize))size
{
    return ^id(CGSize size) {
        CGRect frame = self.view.frame;
        frame.size = size;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))x
{
    return ^id(CGFloat x) {
        CGRect frame = self.view.frame;
        frame.origin.x = x;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))y
{
    return ^id(CGFloat y) {
        CGRect frame = self.view.frame;
        frame.origin.y = y;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))width
{
    return ^id(CGFloat width) {
        CGRect frame = self.view.frame;
        frame.size.width = width;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))height
{
    return ^id(CGFloat height) {
        CGRect frame = self.view.frame;
        frame.size.height = height;
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGAffineTransform))transform
{
    return ^id(CGAffineTransform transform) {
        self.view.transform = transform;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIViewAutoresizing))autoresizingMask
{
    return ^id(UIViewAutoresizing autoresizingMask) {
        self.view.autoresizingMask = autoresizingMask;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(BOOL))clipsToBounds
{
    return ^id(BOOL clipsToBounds) {
        self.view.clipsToBounds = clipsToBounds;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIColor *))backgroundColor
{
    return ^id(UIColor *backgroundColor) {
        self.view.backgroundColor = backgroundColor;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))alpha
{
    return ^id(CGFloat alpha) {
        self.view.alpha = alpha;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(BOOL))opaque
{
    return ^id(BOOL opaque) {
        self.view.opaque = opaque;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(BOOL))hidden
{
    return ^id(BOOL hidden) {
        self.view.hidden = hidden;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIViewContentMode))contentMode
{
    return ^id(UIViewContentMode contentMode) {
        self.view.contentMode = contentMode;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIColor *))tintColor
{
    return ^id(UIColor *tintColor) {
        self.view.tintColor = tintColor;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIView *))addSubview
{
    return ^id(UIView *view) {
        [self.view addSubview:view];
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIView *))moveToSuperview
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

- (id<FWViewChainProtocol> (^)(BOOL))masksToBounds
{
    return ^id(BOOL masksToBounds) {
        self.view.layer.masksToBounds = masksToBounds;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))cornerRadius
{
    return ^id(CGFloat cornerRadius) {
        self.view.layer.cornerRadius = cornerRadius;
        self.view.layer.masksToBounds = YES;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))borderWidth
{
    return ^id(CGFloat borderWidth) {
        self.view.layer.borderWidth = borderWidth;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIColor *))borderColor
{
    return ^id(UIColor *borderColor) {
        self.view.layer.borderColor = borderColor.CGColor;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(UIColor *))shadowColor
{
    return ^id(UIColor *shadowColor) {
        self.view.layer.shadowColor = shadowColor.CGColor;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(float))shadowOpacity
{
    return ^id(float shadowOpacity) {
        self.view.layer.shadowOpacity = shadowOpacity;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGSize))shadowOffset
{
    return ^id(CGSize shadowOffset) {
        self.view.layer.shadowOffset = shadowOffset;
        return self;
    };
}

- (id<FWViewChainProtocol> (^)(CGFloat))shadowRadius
{
    return ^id(CGFloat shadowRadius) {
        self.view.layer.shadowRadius = shadowRadius;
        return self;
    };
}

#pragma mark - FWLabelChainProtocol

- (id<FWLabelChainProtocol> (^)(NSString *))text
{
    return ^id(NSString *text) {
        ((UILabel *)self.view).text = text;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(UIFont *))font
{
    return ^id(UIFont *font) {
        ((UILabel *)self.view).font = font;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(UIColor *))textColor
{
    return ^id(UIColor *textColor) {
        ((UILabel *)self.view).textColor = textColor;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(NSTextAlignment))textAlignment
{
    return ^id(NSTextAlignment textAlignment) {
        ((UILabel *)self.view).textAlignment = textAlignment;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(NSAttributedString *))attributedText
{
    return ^id(NSAttributedString *attributedText) {
        ((UILabel *)self.view).attributedText = attributedText;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(NSLineBreakMode))lineBreakMode
{
    return ^id(NSLineBreakMode lineBreakMode) {
        ((UILabel *)self.view).lineBreakMode = lineBreakMode;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(UIColor *))highlightedTextColor
{
    return ^id(UIColor *highlightedTextColor) {
        ((UILabel *)self.view).highlightedTextColor = highlightedTextColor;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(BOOL))highlighted
{
    return ^id(BOOL highlighted) {
        ((UILabel *)self.view).highlighted = highlighted;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(BOOL))enabled
{
    return ^id(BOOL enabled) {
        ((UILabel *)self.view).enabled = enabled;
        return self;
    };
}

- (id<FWLabelChainProtocol> (^)(NSInteger))numberOfLines
{
    return ^id(NSInteger numberOfLines) {
        ((UILabel *)self.view).numberOfLines = numberOfLines;
        return self;
    };
}

#pragma mark - FWButtonChainProtocol

- (id<FWButtonChainProtocol> (^)(UIEdgeInsets))contentEdgeInsets
{
    return ^id(UIEdgeInsets contentEdgeInsets) {
        ((UIButton *)self.view).contentEdgeInsets = contentEdgeInsets;
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIEdgeInsets))titleEdgeInsets
{
    return ^id(UIEdgeInsets titleEdgeInsets) {
        ((UIButton *)self.view).titleEdgeInsets = titleEdgeInsets;
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIEdgeInsets))imageEdgeInsets
{
    return ^id(UIEdgeInsets imageEdgeInsets) {
        ((UIButton *)self.view).imageEdgeInsets = imageEdgeInsets;
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(BOOL))selected
{
    return ^id(BOOL selected) {
        ((UIButton *)self.view).selected = selected;
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(NSString *, UIControlState))titleForState
{
    return ^id(NSString *title, UIControlState state) {
        [(UIButton *)self.view setTitle:title forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIColor *, UIControlState))titleColorForState
{
    return ^id(UIColor *titleColor, UIControlState state) {
        [(UIButton *)self.view setTitleColor:titleColor forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIImage *, UIControlState))imageForState
{
    return ^id(UIImage *image, UIControlState state) {
        [(UIButton *)self.view setImage:image forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIImage *, UIControlState))backgroundImageForState
{
    return ^id(UIImage *backgroundImage, UIControlState state) {
        [(UIButton *)self.view setBackgroundImage:backgroundImage forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(NSAttributedString *, UIControlState))attributedTitleForState
{
    return ^id(NSAttributedString *attributedTitle, UIControlState state) {
        [(UIButton *)self.view setAttributedTitle:attributedTitle forState:state];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(NSString *))titleForStateNormal
{
    return ^id(NSString *title) {
        [(UIButton *)self.view setTitle:title forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIColor *))titleColorForStateNormal
{
    return ^id(UIColor *titleColor) {
        [(UIButton *)self.view setTitleColor:titleColor forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIImage *))imageForStateNormal
{
    return ^id(UIImage *image) {
        [(UIButton *)self.view setImage:image forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIImage *))backgroundImageForStateNormal
{
    return ^id(UIImage *backgroundImage) {
        [(UIButton *)self.view setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(NSAttributedString *))attributedTitleForStateNormal
{
    return ^id(NSAttributedString *attributedTitle) {
        [(UIButton *)self.view setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        return self;
    };
}

- (id<FWButtonChainProtocol> (^)(UIFont *))titleLabelFont
{
    return ^id(UIFont *font) {
        ((UIButton *)self.view).titleLabel.font = font;
        return self;
    };
}

#pragma mark - FWImageViewChainProtocol

- (id<FWImageViewChainProtocol> (^)(UIImage *))image
{
    return ^id(UIImage *image) {
        ((UIImageView *)self.view).image = image;
        return self;
    };
}

- (id<FWImageViewChainProtocol> (^)(UIImage *))highlightedImage
{
    return ^id(UIImage *highlightedImage) {
        ((UIImageView *)self.view).highlightedImage = highlightedImage;
        return self;
    };
}

- (id<FWImageViewChainProtocol> (^)(void))contentModeAspectFill
{
    return ^id(void) {
        self.view.contentMode = UIViewContentModeScaleAspectFill;
        self.view.layer.masksToBounds = YES;
        return self;
    };
}

- (id<FWImageViewChainProtocol> (^)(NSURL *))imageUrl
{
    return ^id(NSURL *imageUrl) {
        [((UIImageView *)self.view) fwSetImageWithURL:imageUrl];
        return self;
    };
}

- (id<FWImageViewChainProtocol> (^)(NSURL *, UIImage *))imageUrlWithPlaceholder
{
    return ^id(NSURL *imageUrl, UIImage *placeholderImage) {
        [((UIImageView *)self.view) fwSetImageWithURL:imageUrl placeholderImage:placeholderImage];
        return self;
    };
}

#pragma mark - FWScrollViewChainProtocol

- (id<FWScrollViewChainProtocol> (^)(CGPoint))contentOffset
{
    return ^id(CGPoint contentOffset) {
        ((UIScrollView *)self.view).contentOffset = contentOffset;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(CGSize))contentSize
{
    return ^id(CGSize contentSize) {
        ((UIScrollView *)self.view).contentSize = contentSize;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(UIEdgeInsets))contentInset
{
    return ^id(UIEdgeInsets contentInset) {
        ((UIScrollView *)self.view).contentInset = contentInset;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))directionalLockEnabled
{
    return ^id(BOOL directionalLockEnabled) {
        ((UIScrollView *)self.view).directionalLockEnabled = directionalLockEnabled;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))bounces
{
    return ^id(BOOL bounces) {
        ((UIScrollView *)self.view).bounces = bounces;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))alwaysBounceVertical
{
    return ^id(BOOL alwaysBounceVertical) {
        ((UIScrollView *)self.view).alwaysBounceVertical = alwaysBounceVertical;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))alwaysBounceHorizontal
{
    return ^id(BOOL alwaysBounceHorizontal) {
        ((UIScrollView *)self.view).alwaysBounceHorizontal = alwaysBounceHorizontal;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))pagingEnabled
{
    return ^id(BOOL pagingEnabled) {
        ((UIScrollView *)self.view).pagingEnabled = pagingEnabled;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))scrollEnabled
{
    return ^id(BOOL scrollEnabled) {
        ((UIScrollView *)self.view).scrollEnabled = scrollEnabled;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))showsHorizontalScrollIndicator
{
    return ^id(BOOL showsHorizontalScrollIndicator) {
        ((UIScrollView *)self.view).showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(BOOL))showsVerticalScrollIndicator
{
    return ^id(BOOL showsVerticalScrollIndicator) {
        ((UIScrollView *)self.view).showsVerticalScrollIndicator = showsVerticalScrollIndicator;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(void))keyboardDismissModeOnDrag
{
    return ^id(void) {
        ((UIScrollView *)self.view).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        return self;
    };
}

- (id<FWScrollViewChainProtocol> (^)(void))contentInsetAdjustmentNever
{
    return ^id(void) {
        if (@available(iOS 11.0, *)) {
            ((UIScrollView *)self.view).contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        return self;
    };
}

#pragma mark - FWTextFieldChainProtocol

- (id<FWTextFieldChainProtocol> (^)(NSString *))placeholder
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

- (id<FWTextFieldChainProtocol> (^)(NSAttributedString *))attributedPlaceholder
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

- (id<FWTextFieldChainProtocol> (^)(NSInteger))maxLength
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

- (id<FWTextFieldChainProtocol> (^)(NSInteger))maxUnicodeLength
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

#pragma mark - FWTextViewChainProtocol

- (id<FWTextViewChainProtocol> (^)(BOOL))editable
{
    return ^id(BOOL editable) {
        ((UITextView *)self.view).editable = editable;
        return self;
    };
}

@end

#pragma mark - UIView+FWViewChain

@implementation UIView (FWViewChain)

- (id<FWViewChainProtocol>)fwViewChain
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
