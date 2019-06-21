/*!
 @header     UIView+FWChain.h
 @indexgroup FWFramework
 @brief      UIView+FWChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWViewChain

/*!
 @brief UIView链式调用协议，不支持的属性不会生效
 */
@interface FWViewChain : NSObject

// UIView
@property (nonatomic, copy, readonly) FWViewChain *(^userInteractionEnabled)(BOOL enabled);
@property (nonatomic, copy, readonly) FWViewChain *(^tag)(NSInteger tag);
@property (nonatomic, copy, readonly) FWViewChain *(^frame)(CGRect frame);
@property (nonatomic, copy, readonly) FWViewChain *(^bounds)(CGRect bounds);
@property (nonatomic, copy, readonly) FWViewChain *(^center)(CGPoint center);
@property (nonatomic, copy, readonly) FWViewChain *(^transform)(CGAffineTransform transform);
@property (nonatomic, copy, readonly) FWViewChain *(^autoresizingMask)(UIViewAutoresizing autoresizingMask);
@property (nonatomic, copy, readonly) FWViewChain *(^backgroundColor)(UIColor * _Nullable backgroundColor);
@property (nonatomic, copy, readonly) FWViewChain *(^alpha)(CGFloat alpha);
@property (nonatomic, copy, readonly) FWViewChain *(^opaque)(BOOL opaque);
@property (nonatomic, copy, readonly) FWViewChain *(^hidden)(BOOL hidden);
@property (nonatomic, copy, readonly) FWViewChain *(^contentMode)(UIViewContentMode contentMode);
@property (nonatomic, copy, readonly) FWViewChain *(^tintColor)(UIColor * _Nullable tintColor);

@property (nonatomic, copy, readonly) FWViewChain *(^addSubview)(UIView *view);
@property (nonatomic, copy, readonly) FWViewChain *(^moveToSuperview)(UIView * _Nullable view);
@property (nonatomic, copy, readonly) FWViewChain *(^becomeFirstResponder)(void);
@property (nonatomic, copy, readonly) FWViewChain *(^resignFirstResponder)(void);

@property (nonatomic, copy, readonly) FWViewChain *(^masksToBounds)(BOOL masksToBounds);
@property (nonatomic, copy, readonly) FWViewChain *(^cornerRadius)(CGFloat cornerRadius);
@property (nonatomic, copy, readonly) FWViewChain *(^borderWidth)(CGFloat borderWidth);
@property (nonatomic, copy, readonly) FWViewChain *(^borderColor)(UIColor * _Nullable borderColor);
@property (nonatomic, copy, readonly) FWViewChain *(^shadowColor)(UIColor * _Nullable shadowColor);
@property (nonatomic, copy, readonly) FWViewChain *(^shadowOpacity)(float shadowOpacity);
@property (nonatomic, copy, readonly) FWViewChain *(^shadowOffset)(CGSize shadowOffset);
@property (nonatomic, copy, readonly) FWViewChain *(^shadowRadius)(CGFloat shadowRadius);

// UILabel
@property (nonatomic, copy, readonly) FWViewChain *(^text)(NSString * _Nullable text);
@property (nonatomic, copy, readonly) FWViewChain *(^font)(UIFont * _Nullable font);
@property (nonatomic, copy, readonly) FWViewChain *(^textColor)(UIColor * _Nullable textColor);
@property (nonatomic, copy, readonly) FWViewChain *(^textAlignment)(NSTextAlignment textAlignment);
@property (nonatomic, copy, readonly) FWViewChain *(^lineBreakMode)(NSLineBreakMode lineBreakMode);
@property (nonatomic, copy, readonly) FWViewChain *(^attributedText)(NSAttributedString * _Nullable attributedText);
@property (nonatomic, copy, readonly) FWViewChain *(^highlightedTextColor)(UIColor * _Nullable highlightedTextColor);
@property (nonatomic, copy, readonly) FWViewChain *(^highlighted)(BOOL highlighted);
@property (nonatomic, copy, readonly) FWViewChain *(^enabled)(BOOL enabled);
@property (nonatomic, copy, readonly) FWViewChain *(^numberOfLines)(NSInteger numberOfLines);

// UIButton
@property (nonatomic, copy, readonly) FWViewChain *(^selected)(BOOL selected);
@property (nonatomic, copy, readonly) FWViewChain *(^titleForState)(NSString * _Nullable title, UIControlState state);
@property (nonatomic, copy, readonly) FWViewChain *(^titleColorForState)(UIColor * _Nullable titleColor, UIControlState state);
@property (nonatomic, copy, readonly) FWViewChain *(^imageForState)(UIImage * _Nullable image, UIControlState state);
@property (nonatomic, copy, readonly) FWViewChain *(^backgroundImageForState)(UIImage * _Nullable backgroundImage, UIControlState state);
@property (nonatomic, copy, readonly) FWViewChain *(^attributedTitleForState)(NSAttributedString * _Nullable attributedTitle, UIControlState state);
@property (nonatomic, copy, readonly) FWViewChain *(^titleForStateNormal)(NSString * _Nullable title);
@property (nonatomic, copy, readonly) FWViewChain *(^titleColorForStateNormal)(UIColor * _Nullable titleColor);
@property (nonatomic, copy, readonly) FWViewChain *(^imageForStateNormal)(UIImage * _Nullable image);
@property (nonatomic, copy, readonly) FWViewChain *(^backgroundImageForStateNormal)(UIImage * _Nullable backgroundImage);
@property (nonatomic, copy, readonly) FWViewChain *(^attributedTitleForStateNormal)(NSAttributedString * _Nullable attributedTitle);

// UIImageView
@property (nonatomic, copy, readonly) FWViewChain *(^image)(UIImage * _Nullable image);
@property (nonatomic, copy, readonly) FWViewChain *(^highlightedImage)(UIImage * _Nullable highlightedImage);
@property (nonatomic, copy, readonly) FWViewChain *(^contentModeAspectFill)(void);
@property (nonatomic, copy, readonly) FWViewChain *(^imageUrl)(NSURL * _Nullable imageUrl);
@property (nonatomic, copy, readonly) FWViewChain *(^imageUrlWithPlaceholder)(NSURL * _Nullable imageUrl, UIImage * _Nullable placeholderImage);

// UIScrollView
@property (nonatomic, copy, readonly) FWViewChain *(^contentOffset)(CGPoint contentOffset);
@property (nonatomic, copy, readonly) FWViewChain *(^contentSize)(CGSize contentSize);
@property (nonatomic, copy, readonly) FWViewChain *(^contentInset)(UIEdgeInsets contentInset);
@property (nonatomic, copy, readonly) FWViewChain *(^directionalLockEnabled)(BOOL directionalLockEnabled);
@property (nonatomic, copy, readonly) FWViewChain *(^bounces)(BOOL bounces);
@property (nonatomic, copy, readonly) FWViewChain *(^alwaysBounceVertical)(BOOL alwaysBounceVertical);
@property (nonatomic, copy, readonly) FWViewChain *(^alwaysBounceHorizontal)(BOOL alwaysBounceHorizontal);
@property (nonatomic, copy, readonly) FWViewChain *(^pagingEnabled)(BOOL pagingEnabled);
@property (nonatomic, copy, readonly) FWViewChain *(^scrollEnabled)(BOOL scrollEnabled);
@property (nonatomic, copy, readonly) FWViewChain *(^showsHorizontalScrollIndicator)(BOOL showsHorizontalScrollIndicator);
@property (nonatomic, copy, readonly) FWViewChain *(^showsVerticalScrollIndicator)(BOOL showsVerticalScrollIndicator);
@property (nonatomic, copy, readonly) FWViewChain *(^keyboardDismissModeOnDrag)(void);
@property (nonatomic, copy, readonly) FWViewChain *(^contentInsetAdjustmentNever)(void);

// UITextField
@property (nonatomic, copy, readonly) FWViewChain *(^placeholder)(NSString * _Nullable placeholder);
@property (nonatomic, copy, readonly) FWViewChain *(^attributedPlaceholder)(NSAttributedString * _Nullable attributedPlaceholder);

// UITextView
@property (nonatomic, copy, readonly) FWViewChain *(^editable)(BOOL editable);

@end

#pragma mark - UIView+FWViewChain

/*!
 @brief UIView链式调用协议，不支持的属性不会生效
 */
@interface UIView (FWViewChain)

@property (class, nonatomic, strong, readonly) __kindof UIView *(^fwNew)(void);
@property (class, nonatomic, strong, readonly) __kindof UIView *(^fwNewWithFrame)(CGRect frame);

@property (nonatomic, strong, readonly) FWViewChain *fwViewChain;

@end

NS_ASSUME_NONNULL_END
