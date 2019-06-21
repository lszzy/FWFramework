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

#pragma mark - Macro

/*!
 @brief 定义View基础链式调用协议
 */
#define FWDefViewChain( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^userInteractionEnabled)(BOOL enabled); \
    @property (nonatomic, copy, readonly) id<protocol> (^tag)(NSInteger tag); \
    @property (nonatomic, copy, readonly) id<protocol> (^frame)(CGRect frame); \
    @property (nonatomic, copy, readonly) id<protocol> (^bounds)(CGRect bounds); \
    @property (nonatomic, copy, readonly) id<protocol> (^center)(CGPoint center); \
    @property (nonatomic, copy, readonly) id<protocol> (^transform)(CGAffineTransform transform); \
    @property (nonatomic, copy, readonly) id<protocol> (^autoresizingMask)(UIViewAutoresizing autoresizingMask); \
    @property (nonatomic, copy, readonly) id<protocol> (^backgroundColor)(UIColor * _Nullable backgroundColor); \
    @property (nonatomic, copy, readonly) id<protocol> (^alpha)(CGFloat alpha); \
    @property (nonatomic, copy, readonly) id<protocol> (^opaque)(BOOL opaque); \
    @property (nonatomic, copy, readonly) id<protocol> (^hidden)(BOOL hidden); \
    @property (nonatomic, copy, readonly) id<protocol> (^contentMode)(UIViewContentMode contentMode); \
    @property (nonatomic, copy, readonly) id<protocol> (^tintColor)(UIColor * _Nullable tintColor); \
    @property (nonatomic, copy, readonly) id<protocol> (^addSubview)(UIView *view); \
    @property (nonatomic, copy, readonly) id<protocol> (^moveToSuperview)(UIView * _Nullable view); \
    @property (nonatomic, copy, readonly) id<protocol> (^masksToBounds)(BOOL masksToBounds); \
    @property (nonatomic, copy, readonly) id<protocol> (^cornerRadius)(CGFloat cornerRadius); \
    @property (nonatomic, copy, readonly) id<protocol> (^borderWidth)(CGFloat borderWidth); \
    @property (nonatomic, copy, readonly) id<protocol> (^borderColor)(UIColor * _Nullable borderColor); \
    @property (nonatomic, copy, readonly) id<protocol> (^shadowColor)(UIColor * _Nullable shadowColor); \
    @property (nonatomic, copy, readonly) id<protocol> (^shadowOpacity)(float shadowOpacity); \
    @property (nonatomic, copy, readonly) id<protocol> (^shadowOffset)(CGSize shadowOffset); \
    @property (nonatomic, copy, readonly) id<protocol> (^shadowRadius)(CGFloat shadowRadius);

#define FWDefLabelChain( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^text)(NSString * _Nullable text); \
    @property (nonatomic, copy, readonly) id<protocol> (^font)(UIFont * _Nullable font); \
    @property (nonatomic, copy, readonly) id<protocol> (^textColor)(UIColor * _Nullable textColor); \
    @property (nonatomic, copy, readonly) id<protocol> (^textAlignment)(NSTextAlignment textAlignment); \
    @property (nonatomic, copy, readonly) id<protocol> (^attributedText)(NSAttributedString * _Nullable attributedText);

#define FWDefControlChain( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^enabled)(BOOL enabled); \
    @property (nonatomic, copy, readonly) id<protocol> (^selected)(BOOL selected); \
    @property (nonatomic, copy, readonly) id<protocol> (^highlighted)(BOOL highlighted);

#define FWDefScrollViewChain( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^contentOffset)(CGPoint contentOffset); \
    @property (nonatomic, copy, readonly) id<protocol> (^contentSize)(CGSize contentSize); \
    @property (nonatomic, copy, readonly) id<protocol> (^contentInset)(UIEdgeInsets contentInset); \
    @property (nonatomic, copy, readonly) id<protocol> (^directionalLockEnabled)(BOOL directionalLockEnabled); \
    @property (nonatomic, copy, readonly) id<protocol> (^bounces)(BOOL bounces); \
    @property (nonatomic, copy, readonly) id<protocol> (^alwaysBounceVertical)(BOOL alwaysBounceVertical); \
    @property (nonatomic, copy, readonly) id<protocol> (^alwaysBounceHorizontal)(BOOL alwaysBounceHorizontal); \
    @property (nonatomic, copy, readonly) id<protocol> (^pagingEnabled)(BOOL pagingEnabled); \
    @property (nonatomic, copy, readonly) id<protocol> (^scrollEnabled)(BOOL scrollEnabled); \
    @property (nonatomic, copy, readonly) id<protocol> (^showsHorizontalScrollIndicator)(BOOL showsHorizontalScrollIndicator); \
    @property (nonatomic, copy, readonly) id<protocol> (^showsVerticalScrollIndicator)(BOOL showsVerticalScrollIndicator); \
    @property (nonatomic, copy, readonly) id<protocol> (^keyboardDismissModeOnDrag)(void); \
    @property (nonatomic, copy, readonly) id<protocol> (^contentInsetAdjustmentNever)(void);

#pragma mark - FWViewChain

/*!
 @brief UIView链式调用协议
 */
@protocol FWViewChain <NSObject>

@required
FWDefViewChain(FWViewChain);

@end

@protocol FWLabelChain <NSObject>

@required
FWDefViewChain(FWLabelChain);
FWDefLabelChain(FWLabelChain);

@property (nonatomic, copy, readonly) id<FWLabelChain> (^lineBreakMode)(NSLineBreakMode lineBreakMode);
@property (nonatomic, copy, readonly) id<FWLabelChain> (^highlightedTextColor)(UIColor * _Nullable highlightedTextColor);
@property (nonatomic, copy, readonly) id<FWLabelChain> (^highlighted)(BOOL highlighted);
@property (nonatomic, copy, readonly) id<FWLabelChain> (^enabled)(BOOL enabled);
@property (nonatomic, copy, readonly) id<FWLabelChain> (^numberOfLines)(NSInteger numberOfLines);

@end

@protocol FWButtonChain <NSObject>

@required
FWDefViewChain(FWButtonChain);
FWDefControlChain(FWButtonChain);

@property (nonatomic, copy, readonly) id<FWButtonChain> (^contentEdgeInsets)(UIEdgeInsets contentEdgeInsets);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^titleEdgeInsets)(UIEdgeInsets titleEdgeInsets);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^imageEdgeInsets)(UIEdgeInsets imageEdgeInsets);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^titleForState)(NSString * _Nullable title, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^titleColorForState)(UIColor * _Nullable titleColor, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^imageForState)(UIImage * _Nullable image, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^backgroundImageForState)(UIImage * _Nullable backgroundImage, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^attributedTitleForState)(NSAttributedString * _Nullable attributedTitle, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^titleForStateNormal)(NSString * _Nullable title);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^titleColorForStateNormal)(UIColor * _Nullable titleColor);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^imageForStateNormal)(UIImage * _Nullable image);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^backgroundImageForStateNormal)(UIImage * _Nullable backgroundImage);
@property (nonatomic, copy, readonly) id<FWButtonChain> (^attributedTitleForStateNormal)(NSAttributedString * _Nullable attributedTitle);

@end

@protocol FWImageViewChain <NSObject>

@required
FWDefViewChain(FWImageViewChain);

@property (nonatomic, copy, readonly) id<FWImageViewChain> (^image)(UIImage * _Nullable image);
@property (nonatomic, copy, readonly) id<FWImageViewChain> (^highlightedImage)(UIImage * _Nullable highlightedImage);
@property (nonatomic, copy, readonly) id<FWImageViewChain> (^contentModeAspectFill)(void);
@property (nonatomic, copy, readonly) id<FWImageViewChain> (^imageUrl)(NSURL * _Nullable imageUrl);
@property (nonatomic, copy, readonly) id<FWImageViewChain> (^imageUrlWithPlaceholder)(NSURL * _Nullable imageUrl, UIImage * _Nullable placeholderImage);

@end

@protocol FWScrollViewChain <NSObject>

@required
FWDefViewChain(FWScrollViewChain);
FWDefScrollViewChain(FWScrollViewChain);

@end

@protocol FWTextFieldChain <NSObject>

@required
FWDefViewChain(FWTextFieldChain);
FWDefControlChain(FWTextFieldChain);
FWDefLabelChain(FWTextFieldChain);

@property (nonatomic, copy, readonly) id<FWTextFieldChain> (^placeholder)(NSString * _Nullable placeholder);
@property (nonatomic, copy, readonly) id<FWTextFieldChain> (^attributedPlaceholder)(NSAttributedString * _Nullable attributedPlaceholder);

@end

@protocol FWTextViewChain <NSObject>

@required
FWDefViewChain(FWTextViewChain);
FWDefLabelChain(FWTextViewChain);
FWDefScrollViewChain(FWTextViewChain);

@property (nonatomic, copy, readonly) id<FWTextViewChain> (^editable)(BOOL editable);
@property (nonatomic, copy, readonly) id<FWTextViewChain> (^placeholder)(NSString * _Nullable placeholder);
@property (nonatomic, copy, readonly) id<FWTextViewChain> (^attributedPlaceholder)(NSAttributedString * _Nullable attributedPlaceholder);

@end

#pragma mark - UIView+FWViewChain

/*!
 @brief UIView链式调用
 */
@interface UIView (FWViewChain)

@property (class, nonatomic, strong, readonly) __kindof UIView *(^fwView)(void);
@property (class, nonatomic, strong, readonly) __kindof UIView *(^fwViewWithFrame)(CGRect frame);

@property (nonatomic, strong, readonly) id<FWViewChain> fwViewChain;

@end

@interface UILabel (FWViewChain)

@property (nonatomic, strong, readonly) id<FWLabelChain> fwViewChain;

@end

@interface UIButton (FWViewChain)

@property (class, nonatomic, strong, readonly) __kindof UIButton *(^fwButtonWithType)(UIButtonType type);

@property (nonatomic, strong, readonly) id<FWButtonChain> fwViewChain;

@end

@interface UIImageView (FWViewChain)

@property (nonatomic, strong, readonly) id<FWImageViewChain> fwViewChain;

@end

@interface UIScrollView (FWViewChain)

@property (nonatomic, strong, readonly) id<FWScrollViewChain> fwViewChain;

@end

@interface UITextField (FWViewChain)

@property (nonatomic, strong, readonly) id<FWTextFieldChain> fwViewChain;

@end

@interface UITextView (FWViewChain)

@property (nonatomic, strong, readonly) id<FWTextViewChain> fwViewChain;

@end

NS_ASSUME_NONNULL_END
