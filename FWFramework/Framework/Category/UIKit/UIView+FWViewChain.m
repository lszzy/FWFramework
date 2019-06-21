/*!
 @header     UIView+FWChain.m
 @indexgroup FWFramework
 @brief      UIView+FWChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import "UIView+FWViewChain.h"
#import "UIImageView+FWNetwork.h"
#import "UITextView+FWPlaceholder.h"
#import <objc/runtime.h>

#pragma mark - FWViewChain

@interface FWViewChain : NSObject <FWViewChain, FWLabelChain, FWButtonChain, FWImageViewChain, FWScrollViewChain, FWTextFieldChain, FWTextViewChain>

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWViewChain

#pragma mark - FWViewChain

- (id<FWViewChain> (^)(BOOL))userInteractionEnabled
{
    return ^id(BOOL enabled) {
        self.view.userInteractionEnabled = enabled;
        return self;
    };
}

- (id<FWViewChain> (^)(NSInteger))tag
{
    return ^id(NSInteger tag) {
        self.view.tag = tag;
        return self;
    };
}

- (id<FWViewChain> (^)(CGRect))frame
{
    return ^id(CGRect frame) {
        self.view.frame = frame;
        return self;
    };
}

- (id<FWViewChain> (^)(CGRect))bounds
{
    return ^id(CGRect bounds) {
        self.view.bounds = bounds;
        return self;
    };
}

- (id<FWViewChain> (^)(CGPoint))center
{
    return ^id(CGPoint center) {
        self.view.center = center;
        return self;
    };
}

- (id<FWViewChain> (^)(CGAffineTransform))transform
{
    return ^id(CGAffineTransform transform) {
        self.view.transform = transform;
        return self;
    };
}

- (id<FWViewChain> (^)(UIViewAutoresizing))autoresizingMask
{
    return ^id(UIViewAutoresizing autoresizingMask) {
        self.view.autoresizingMask = autoresizingMask;
        return self;
    };
}

- (id<FWViewChain> (^)(UIColor *))backgroundColor
{
    return ^id(UIColor *backgroundColor) {
        self.view.backgroundColor = backgroundColor;
        return self;
    };
}

- (id<FWViewChain> (^)(CGFloat))alpha
{
    return ^id(CGFloat alpha) {
        self.view.alpha = alpha;
        return self;
    };
}

- (id<FWViewChain> (^)(BOOL))opaque
{
    return ^id(BOOL opaque) {
        self.view.opaque = opaque;
        return self;
    };
}

- (id<FWViewChain> (^)(BOOL))hidden
{
    return ^id(BOOL hidden) {
        self.view.hidden = hidden;
        return self;
    };
}

- (id<FWViewChain> (^)(UIViewContentMode))contentMode
{
    return ^id(UIViewContentMode contentMode) {
        self.view.contentMode = contentMode;
        return self;
    };
}

- (id<FWViewChain> (^)(UIColor *))tintColor
{
    return ^id(UIColor *tintColor) {
        self.view.tintColor = tintColor;
        return self;
    };
}

- (id<FWViewChain> (^)(UIView *))addSubview
{
    return ^id(UIView *view) {
        [self.view addSubview:view];
        return self;
    };
}

- (id<FWViewChain> (^)(UIView *))moveToSuperview
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

- (id<FWViewChain> (^)(BOOL))masksToBounds
{
    return ^id(BOOL masksToBounds) {
        self.view.layer.masksToBounds = masksToBounds;
        return self;
    };
}

- (id<FWViewChain> (^)(CGFloat))cornerRadius
{
    return ^id(CGFloat cornerRadius) {
        self.view.layer.cornerRadius = cornerRadius;
        self.view.layer.masksToBounds = YES;
        return self;
    };
}

- (id<FWViewChain> (^)(CGFloat))borderWidth
{
    return ^id(CGFloat borderWidth) {
        self.view.layer.borderWidth = borderWidth;
        return self;
    };
}

- (id<FWViewChain> (^)(UIColor *))borderColor
{
    return ^id(UIColor *borderColor) {
        self.view.layer.borderColor = borderColor.CGColor;
        return self;
    };
}

- (id<FWViewChain> (^)(UIColor *))shadowColor
{
    return ^id(UIColor *shadowColor) {
        self.view.layer.shadowColor = shadowColor.CGColor;
        return self;
    };
}

- (id<FWViewChain> (^)(float))shadowOpacity
{
    return ^id(float shadowOpacity) {
        self.view.layer.shadowOpacity = shadowOpacity;
        return self;
    };
}

- (id<FWViewChain> (^)(CGSize))shadowOffset
{
    return ^id(CGSize shadowOffset) {
        self.view.layer.shadowOffset = shadowOffset;
        return self;
    };
}

- (id<FWViewChain> (^)(CGFloat))shadowRadius
{
    return ^id(CGFloat shadowRadius) {
        self.view.layer.shadowRadius = shadowRadius;
        return self;
    };
}

#pragma mark - FWLabelChain

- (id<FWLabelChain> (^)(NSString *))text
{
    return ^id(NSString *text) {
        if ([self.view respondsToSelector:@selector(setText:)]) {
            ((UILabel *)self.view).text = text;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(UIFont *))font
{
    return ^id(UIFont *font) {
        if ([self.view respondsToSelector:@selector(setFont:)]) {
            ((UILabel *)self.view).font = font;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(UIColor *))textColor
{
    return ^id(UIColor *textColor) {
        if ([self.view respondsToSelector:@selector(setTextColor:)]) {
            ((UILabel *)self.view).textColor = textColor;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(NSTextAlignment))textAlignment
{
    return ^id(NSTextAlignment textAlignment) {
        if ([self.view respondsToSelector:@selector(setTextAlignment:)]) {
            ((UILabel *)self.view).textAlignment = textAlignment;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(NSLineBreakMode))lineBreakMode
{
    return ^id(NSLineBreakMode lineBreakMode) {
        if ([self.view respondsToSelector:@selector(setLineBreakMode:)]) {
            ((UILabel *)self.view).lineBreakMode = lineBreakMode;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(NSAttributedString *))attributedText
{
    return ^id(NSAttributedString *attributedText) {
        if ([self.view respondsToSelector:@selector(setAttributedText:)]) {
            ((UILabel *)self.view).attributedText = attributedText;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(UIColor *))highlightedTextColor
{
    return ^id(UIColor *highlightedTextColor) {
        if ([self.view respondsToSelector:@selector(setHighlightedTextColor:)]) {
            ((UILabel *)self.view).highlightedTextColor = highlightedTextColor;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(BOOL))highlighted
{
    return ^id(BOOL highlighted) {
        if ([self.view respondsToSelector:@selector(setHighlighted:)]) {
            ((UILabel *)self.view).highlighted = highlighted;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(BOOL))enabled
{
    return ^id(BOOL enabled) {
        if ([self.view respondsToSelector:@selector(setEnabled:)]) {
            ((UILabel *)self.view).enabled = enabled;
        }
        return self;
    };
}

- (id<FWLabelChain> (^)(NSInteger))numberOfLines
{
    return ^id(NSInteger numberOfLines) {
        if ([self.view respondsToSelector:@selector(setNumberOfLines:)]) {
            ((UILabel *)self.view).numberOfLines = numberOfLines;
        }
        return self;
    };
}

#pragma mark - FWButtonChain

- (id<FWButtonChain> (^)(UIEdgeInsets))contentEdgeInsets
{
    return ^id(UIEdgeInsets contentEdgeInsets) {
        if ([self.view respondsToSelector:@selector(setContentEdgeInsets:)]) {
            ((UIButton *)self.view).contentEdgeInsets = contentEdgeInsets;
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIEdgeInsets))titleEdgeInsets
{
    return ^id(UIEdgeInsets titleEdgeInsets) {
        if ([self.view respondsToSelector:@selector(setTitleEdgeInsets:)]) {
            ((UIButton *)self.view).titleEdgeInsets = titleEdgeInsets;
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIEdgeInsets))imageEdgeInsets
{
    return ^id(UIEdgeInsets imageEdgeInsets) {
        if ([self.view respondsToSelector:@selector(setImageEdgeInsets:)]) {
            ((UIButton *)self.view).imageEdgeInsets = imageEdgeInsets;
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(BOOL))selected
{
    return ^id(BOOL selected) {
        if ([self.view respondsToSelector:@selector(setSelected:)]) {
            ((UIButton *)self.view).selected = selected;
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(NSString *, UIControlState))titleForState
{
    return ^id(NSString *title, UIControlState state) {
        if ([self.view respondsToSelector:@selector(setTitle:forState:)]) {
            [(UIButton *)self.view setTitle:title forState:state];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIColor *, UIControlState))titleColorForState
{
    return ^id(UIColor *titleColor, UIControlState state) {
        if ([self.view respondsToSelector:@selector(setTitleColor:forState:)]) {
            [(UIButton *)self.view setTitleColor:titleColor forState:state];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIImage *, UIControlState))imageForState
{
    return ^id(UIImage *image, UIControlState state) {
        if ([self.view respondsToSelector:@selector(setImage:forState:)]) {
            [(UIButton *)self.view setImage:image forState:state];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIImage *, UIControlState))backgroundImageForState
{
    return ^id(UIImage *backgroundImage, UIControlState state) {
        if ([self.view respondsToSelector:@selector(setBackgroundImage:forState:)]) {
            [(UIButton *)self.view setBackgroundImage:backgroundImage forState:state];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(NSAttributedString *, UIControlState))attributedTitleForState
{
    return ^id(NSAttributedString *attributedTitle, UIControlState state) {
        if ([self.view respondsToSelector:@selector(setAttributedTitle:forState:)]) {
            [(UIButton *)self.view setAttributedTitle:attributedTitle forState:state];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(NSString *))titleForStateNormal
{
    return ^id(NSString *title) {
        if ([self.view respondsToSelector:@selector(setTitle:forState:)]) {
            [(UIButton *)self.view setTitle:title forState:UIControlStateNormal];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIColor *))titleColorForStateNormal
{
    return ^id(UIColor *titleColor) {
        if ([self.view respondsToSelector:@selector(setTitleColor:forState:)]) {
            [(UIButton *)self.view setTitleColor:titleColor forState:UIControlStateNormal];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIImage *))imageForStateNormal
{
    return ^id(UIImage *image) {
        if ([self.view respondsToSelector:@selector(setImage:forState:)]) {
            [(UIButton *)self.view setImage:image forState:UIControlStateNormal];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(UIImage *))backgroundImageForStateNormal
{
    return ^id(UIImage *backgroundImage) {
        if ([self.view respondsToSelector:@selector(setBackgroundImage:forState:)]) {
            [(UIButton *)self.view setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        }
        return self;
    };
}

- (id<FWButtonChain> (^)(NSAttributedString *))attributedTitleForStateNormal
{
    return ^id(NSAttributedString *attributedTitle) {
        if ([self.view respondsToSelector:@selector(setAttributedTitle:forState:)]) {
            [(UIButton *)self.view setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        }
        return self;
    };
}

#pragma mark - FWImageViewChain

- (id<FWImageViewChain> (^)(UIImage *))image
{
    return ^id(UIImage *image) {
        if ([self.view respondsToSelector:@selector(setImage:)]) {
            ((UIImageView *)self.view).image = image;
        }
        return self;
    };
}

- (id<FWImageViewChain> (^)(UIImage *))highlightedImage
{
    return ^id(UIImage *highlightedImage) {
        if ([self.view respondsToSelector:@selector(setHighlightedImage:)]) {
            ((UIImageView *)self.view).highlightedImage = highlightedImage;
        }
        return self;
    };
}

- (id<FWImageViewChain> (^)(void))contentModeAspectFill
{
    return ^id(void) {
        self.view.contentMode = UIViewContentModeScaleAspectFill;
        self.view.layer.masksToBounds = YES;
        return self;
    };
}

- (id<FWImageViewChain> (^)(NSURL *))imageUrl
{
    return ^id(NSURL *imageUrl) {
        if ([self.view respondsToSelector:@selector(fwSetImageWithURL:)]) {
            [((UIImageView *)self.view) fwSetImageWithURL:imageUrl];
        }
        return self;
    };
}

- (id<FWImageViewChain> (^)(NSURL *, UIImage *))imageUrlWithPlaceholder
{
    return ^id(NSURL *imageUrl, UIImage *placeholderImage) {
        if ([self.view respondsToSelector:@selector(fwSetImageWithURL:placeholderImage:)]) {
            [((UIImageView *)self.view) fwSetImageWithURL:imageUrl placeholderImage:placeholderImage];
        }
        return self;
    };
}

#pragma mark - FWScrollViewChain

- (id<FWScrollViewChain> (^)(CGPoint))contentOffset
{
    return ^id(CGPoint contentOffset) {
        if ([self.view respondsToSelector:@selector(setContentOffset:)]) {
            ((UIScrollView *)self.view).contentOffset = contentOffset;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(CGSize))contentSize
{
    return ^id(CGSize contentSize) {
        if ([self.view respondsToSelector:@selector(setContentSize:)]) {
            ((UIScrollView *)self.view).contentSize = contentSize;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(UIEdgeInsets))contentInset
{
    return ^id(UIEdgeInsets contentInset) {
        if ([self.view respondsToSelector:@selector(setContentInset:)]) {
            ((UIScrollView *)self.view).contentInset = contentInset;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))directionalLockEnabled
{
    return ^id(BOOL directionalLockEnabled) {
        if ([self.view respondsToSelector:@selector(setDirectionalLockEnabled:)]) {
            ((UIScrollView *)self.view).directionalLockEnabled = directionalLockEnabled;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))bounces
{
    return ^id(BOOL bounces) {
        if ([self.view respondsToSelector:@selector(setBounces:)]) {
            ((UIScrollView *)self.view).bounces = bounces;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))alwaysBounceVertical
{
    return ^id(BOOL alwaysBounceVertical) {
        if ([self.view respondsToSelector:@selector(setAlwaysBounceVertical:)]) {
            ((UIScrollView *)self.view).alwaysBounceVertical = alwaysBounceVertical;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))alwaysBounceHorizontal
{
    return ^id(BOOL alwaysBounceHorizontal) {
        if ([self.view respondsToSelector:@selector(setAlwaysBounceHorizontal:)]) {
            ((UIScrollView *)self.view).alwaysBounceHorizontal = alwaysBounceHorizontal;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))pagingEnabled
{
    return ^id(BOOL pagingEnabled) {
        if ([self.view respondsToSelector:@selector(setPagingEnabled:)]) {
            ((UIScrollView *)self.view).pagingEnabled = pagingEnabled;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))scrollEnabled
{
    return ^id(BOOL scrollEnabled) {
        if ([self.view respondsToSelector:@selector(setScrollEnabled:)]) {
            ((UIScrollView *)self.view).scrollEnabled = scrollEnabled;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))showsHorizontalScrollIndicator
{
    return ^id(BOOL showsHorizontalScrollIndicator) {
        if ([self.view respondsToSelector:@selector(setShowsHorizontalScrollIndicator:)]) {
            ((UIScrollView *)self.view).showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(BOOL))showsVerticalScrollIndicator
{
    return ^id(BOOL showsVerticalScrollIndicator) {
        if ([self.view respondsToSelector:@selector(setShowsVerticalScrollIndicator:)]) {
            ((UIScrollView *)self.view).showsVerticalScrollIndicator = showsVerticalScrollIndicator;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(void))keyboardDismissModeOnDrag
{
    return ^id(void) {
        if ([self.view respondsToSelector:@selector(setKeyboardDismissMode:)]) {
            ((UIScrollView *)self.view).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        }
        return self;
    };
}

- (id<FWScrollViewChain> (^)(void))contentInsetAdjustmentNever
{
    return ^id(void) {
        if (@available(iOS 11.0, *)) {
            if ([self.view isKindOfClass:[UIScrollView class]]) {
                ((UIScrollView *)self.view).contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
        return self;
    };
}

#pragma mark - FWTextFieldChain

- (id<FWTextFieldChain> (^)(NSString *))placeholder
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

- (id<FWTextFieldChain> (^)(NSAttributedString *))attributedPlaceholder
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

#pragma mark - FWTextViewChain

- (id<FWTextViewChain> (^)(BOOL))editable
{
    return ^id(BOOL editable) {
        if ([self.view respondsToSelector:@selector(setEditable:)]) {
            ((UITextView *)self.view).editable = editable;
        }
        return self;
    };
}

@end

#pragma mark - UIView+FWViewChain

@implementation UIView (FWViewChain)

+ (__kindof UIView *(^)(void))fwView
{
    return ^id(void) {
        return [[self alloc] init];
    };
}

+ (__kindof UIView *(^)(CGRect))fwViewWithFrame
{
    return ^id(CGRect frame) {
        return [[self alloc] initWithFrame:frame];
    };
}

- (FWViewChain *)fwViewChain
{
    FWViewChain *viewChain = objc_getAssociatedObject(self, _cmd);
    if (!viewChain) {
        viewChain = [[FWViewChain alloc] init];
        viewChain.view = self;
        objc_setAssociatedObject(self, _cmd, viewChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return viewChain;
}

@end

@implementation UIButton (FWViewChain)

+ (__kindof UIButton *(^)(UIButtonType))fwButtonWithType
{
    return ^id(UIButtonType type) {
        return [self buttonWithType:type];
    };
}

@end
