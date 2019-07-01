/*!
 @header     UIView+FWViewChain.h
 @indexgroup FWFramework
 @brief      UIView+FWViewChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/*!
 @brief 定义View链式调用协议
 */
#define FWDefViewChain_( protocol ) \
    @property (nonatomic, strong, readonly) id<protocol> fwViewChain;

#define FWDefViewChainProtocols_( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^userInteractionEnabled)(BOOL enabled); \
    @property (nonatomic, copy, readonly) id<protocol> (^tag)(NSInteger tag); \
    @property (nonatomic, copy, readonly) id<protocol> (^frame)(CGRect frame); \
    @property (nonatomic, copy, readonly) id<protocol> (^bounds)(CGRect bounds); \
    @property (nonatomic, copy, readonly) id<protocol> (^center)(CGPoint center); \
    @property (nonatomic, copy, readonly) id<protocol> (^origin)(CGPoint origin); \
    @property (nonatomic, copy, readonly) id<protocol> (^size)(CGSize size); \
    @property (nonatomic, copy, readonly) id<protocol> (^x)(CGFloat x); \
    @property (nonatomic, copy, readonly) id<protocol> (^y)(CGFloat y); \
    @property (nonatomic, copy, readonly) id<protocol> (^width)(CGFloat width); \
    @property (nonatomic, copy, readonly) id<protocol> (^height)(CGFloat height); \
    @property (nonatomic, copy, readonly) id<protocol> (^transform)(CGAffineTransform transform); \
    @property (nonatomic, copy, readonly) id<protocol> (^autoresizingMask)(UIViewAutoresizing autoresizingMask); \
    @property (nonatomic, copy, readonly) id<protocol> (^clipsToBounds)(BOOL clipsToBounds); \
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

#define FWDefLabelChainProtocols_( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^text)(NSString * _Nullable text); \
    @property (nonatomic, copy, readonly) id<protocol> (^font)(UIFont * _Nullable font); \
    @property (nonatomic, copy, readonly) id<protocol> (^textColor)(UIColor * _Nullable textColor); \
    @property (nonatomic, copy, readonly) id<protocol> (^textAlignment)(NSTextAlignment textAlignment); \
    @property (nonatomic, copy, readonly) id<protocol> (^attributedText)(NSAttributedString * _Nullable attributedText);

#define FWDefControlChainProtocols_( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^enabled)(BOOL enabled); \
    @property (nonatomic, copy, readonly) id<protocol> (^selected)(BOOL selected); \
    @property (nonatomic, copy, readonly) id<protocol> (^highlighted)(BOOL highlighted);

#define FWDefScrollViewChainProtocols_( protocol ) \
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

#define FWDefInputChainProtocols_( protocol ) \
    @property (nonatomic, copy, readonly) id<protocol> (^placeholder)(NSString * _Nullable placeholder); \
    @property (nonatomic, copy, readonly) id<protocol> (^attributedPlaceholder)(NSAttributedString * _Nullable attributedPlaceholder); \
    @property (nonatomic, copy, readonly) id<protocol> (^maxLength)(NSInteger maxLength); \
    @property (nonatomic, copy, readonly) id<protocol> (^maxUnicodeLength)(NSInteger maxUnicodeLength);

#pragma mark - FWViewChainProtocols

/*!
 @brief UIView链式调用协议
 */
@protocol FWViewChainProtocols <NSObject>

@required
FWDefViewChainProtocols_(FWViewChainProtocols);

@end

@protocol FWLabelChainProtocols <NSObject>

@required
FWDefViewChainProtocols_(FWLabelChainProtocols);
FWDefLabelChainProtocols_(FWLabelChainProtocols);

@property (nonatomic, copy, readonly) id<FWLabelChainProtocols> (^lineBreakMode)(NSLineBreakMode lineBreakMode);
@property (nonatomic, copy, readonly) id<FWLabelChainProtocols> (^highlightedTextColor)(UIColor * _Nullable highlightedTextColor);
@property (nonatomic, copy, readonly) id<FWLabelChainProtocols> (^highlighted)(BOOL highlighted);
@property (nonatomic, copy, readonly) id<FWLabelChainProtocols> (^enabled)(BOOL enabled);
@property (nonatomic, copy, readonly) id<FWLabelChainProtocols> (^numberOfLines)(NSInteger numberOfLines);

@end

@protocol FWButtonChainProtocols <NSObject>

@required
FWDefViewChainProtocols_(FWButtonChainProtocols);
FWDefControlChainProtocols_(FWButtonChainProtocols);

@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^contentEdgeInsets)(UIEdgeInsets contentEdgeInsets);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^titleEdgeInsets)(UIEdgeInsets titleEdgeInsets);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^imageEdgeInsets)(UIEdgeInsets imageEdgeInsets);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^titleForState)(NSString * _Nullable title, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^titleColorForState)(UIColor * _Nullable titleColor, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^imageForState)(UIImage * _Nullable image, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^backgroundImageForState)(UIImage * _Nullable backgroundImage, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^attributedTitleForState)(NSAttributedString * _Nullable attributedTitle, UIControlState state);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^titleForStateNormal)(NSString * _Nullable title);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^titleColorForStateNormal)(UIColor * _Nullable titleColor);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^imageForStateNormal)(UIImage * _Nullable image);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^backgroundImageForStateNormal)(UIImage * _Nullable backgroundImage);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^attributedTitleForStateNormal)(NSAttributedString * _Nullable attributedTitle);
@property (nonatomic, copy, readonly) id<FWButtonChainProtocols> (^titleLabelFont)(UIFont * _Nullable font);

@end

@protocol FWImageViewChainProtocols <NSObject>

@required
FWDefViewChainProtocols_(FWImageViewChainProtocols);

@property (nonatomic, copy, readonly) id<FWImageViewChainProtocols> (^image)(UIImage * _Nullable image);
@property (nonatomic, copy, readonly) id<FWImageViewChainProtocols> (^highlightedImage)(UIImage * _Nullable highlightedImage);
@property (nonatomic, copy, readonly) id<FWImageViewChainProtocols> (^contentModeAspectFill)(void);
@property (nonatomic, copy, readonly) id<FWImageViewChainProtocols> (^imageUrl)(NSURL * _Nullable imageUrl);
@property (nonatomic, copy, readonly) id<FWImageViewChainProtocols> (^imageUrlWithPlaceholder)(NSURL * _Nullable imageUrl, UIImage * _Nullable placeholderImage);

@end

@protocol FWScrollViewChainProtocols <NSObject>

@required
FWDefViewChainProtocols_(FWScrollViewChainProtocols);
FWDefScrollViewChainProtocols_(FWScrollViewChainProtocols);

@end

@protocol FWTextFieldChainProtocols <NSObject>

@required
FWDefViewChainProtocols_(FWTextFieldChainProtocols);
FWDefControlChainProtocols_(FWTextFieldChainProtocols);
FWDefLabelChainProtocols_(FWTextFieldChainProtocols);
FWDefInputChainProtocols_(FWTextFieldChainProtocols);

@end

@protocol FWTextViewChainProtocols <NSObject>

@required
FWDefViewChainProtocols_(FWTextViewChainProtocols);
FWDefLabelChainProtocols_(FWTextViewChainProtocols);
FWDefScrollViewChainProtocols_(FWTextViewChainProtocols);
FWDefInputChainProtocols_(FWTextViewChainProtocols);

@property (nonatomic, copy, readonly) id<FWTextViewChainProtocols> (^editable)(BOOL editable);

@end

#pragma mark - UIView+FWViewChain

/*!
 @brief UIView链式调用分类，注意每个分类都声明fwViewChain是为了防止调用不支持的方法
 */
@interface UIView (FWViewChain)

// 链式调用对象，注意view强引用viewChain，viewChain弱引用view
FWDefViewChain_(FWViewChainProtocols);

@end

@interface UILabel (FWViewChain)

FWDefViewChain_(FWLabelChainProtocols);

@end

@interface UIButton (FWViewChain)

FWDefViewChain_(FWButtonChainProtocols);

@end

@interface UIImageView (FWViewChain)

FWDefViewChain_(FWImageViewChainProtocols);

@end

@interface UIScrollView (FWViewChain)

FWDefViewChain_(FWScrollViewChainProtocols);

@end

@interface UITextField (FWViewChain)

FWDefViewChain_(FWTextFieldChainProtocols);

@end

@interface UITextView (FWViewChain)

FWDefViewChain_(FWTextViewChainProtocols);

@end

NS_ASSUME_NONNULL_END
