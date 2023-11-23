//
//  AttributedLabel.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, __FWAttributedAlignment) {
    __FWAttributedAlignmentTop,
    __FWAttributedAlignmentCenter,
    __FWAttributedAlignmentBottom
} NS_SWIFT_NAME(AttributedAlignment);

@class __FWAttributedLabel;
@class __FWAttributedLabelAttachment;
@protocol __FWAttributedLabelURLDetectorProtocol;

NS_SWIFT_NAME(AttributedLabelDelegate)
@protocol __FWAttributedLabelDelegate <NSObject>
- (void)attributedLabel:(__FWAttributedLabel *)label clickedOnLink:(id)linkData;
@end

#pragma mark - __FWAttributedLabel

/**
 __FWAttributedLabel
 
 @see https://github.com/xiangwangfeng/M80AttributedLabel
 */
NS_SWIFT_NAME(AttributedLabel)
@interface __FWAttributedLabel : UIView

@property (nonatomic,weak,nullable)         id<__FWAttributedLabelDelegate> delegate;
@property (nonatomic,strong,nullable)       UIFont *font;                          //字体
@property (nonatomic,strong,nullable)       UIColor *textColor;                    //文字颜色
@property (nonatomic,strong,nullable)       UIColor *highlightColor;               //链接点击时背景高亮色
@property (nonatomic,strong,nullable)       UIColor *linkColor;                    //链接色
@property (nonatomic,strong,nullable)       UIColor *shadowColor;                  //阴影颜色
@property (nonatomic,assign)                CGSize  shadowOffset;                   //阴影offset
@property (nonatomic,assign)                CGFloat shadowBlur;                     //阴影半径
@property (nonatomic,assign)                BOOL    underLineForLink;               //链接是否带下划线
@property (nonatomic,assign)                BOOL    autoDetectLinks;                //自动检测
@property (nonatomic,strong)                id<__FWAttributedLabelURLDetectorProtocol> linkDetector; //自定义链接检测器，默认shared
@property (nonatomic,copy,nullable)         void (^clickedOnLink)(id linkData);     //链接点击句柄
@property (nonatomic,assign)                NSInteger   numberOfLines;              //行数
@property (nonatomic,assign)                CTTextAlignment textAlignment;          //文字排版样式
@property (nonatomic,assign)                CTLineBreakMode lineBreakMode;          //LineBreakMode
@property (nonatomic,assign)                CGFloat lineSpacing;                    //行间距
@property (nonatomic,assign)                CGFloat paragraphSpacing;               //段间距
@property (nonatomic,copy,nullable)         NSString *text;                         //普通文本，设置nil可重置
@property (nonatomic,copy,nullable)         NSAttributedString *attributedText;     //属性文本，设置nil可重置
//最后一行截断之后留白的宽度，默认0不生效，仅lineBreakMode为TruncatingTail且发生截断时生效
@property (nonatomic,assign)                CGFloat lineTruncatingSpacing;
@property (nonatomic,strong,nullable)       __FWAttributedLabelAttachment *lineTruncatingAttachment;

//添加文本
- (void)appendText:(NSString *)text;
- (void)appendAttributedText:(NSAttributedString *)attributedText;

//图片
- (void)appendImage:(UIImage *)image;
- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize;
- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize
             margin:(UIEdgeInsets)margin;
- (void)appendImage:(UIImage *)image
            maxSize:(CGSize)maxSize
             margin:(UIEdgeInsets)margin
          alignment:(__FWAttributedAlignment)alignment;

//UI控件
- (void)appendView:(UIView *)view;
- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin;
- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin
         alignment:(__FWAttributedAlignment)alignment;

//添加自定义链接
- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range;

- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range
            linkColor:(UIColor *)color;

//大小
- (CGSize)sizeThatFits:(CGSize)size;

@end

#pragma mark - __FWAttributedLabelURL

NS_SWIFT_NAME(AttributedLabelURL)
@interface __FWAttributedLabelURL : NSObject

@property (nonatomic,strong)          id      linkData;
@property (nonatomic,assign)          NSRange range;
@property (nonatomic,strong,nullable) UIColor *color;

+ (__FWAttributedLabelURL *)urlWithLinkData:(id)linkData
                                    range:(NSRange)range
                                    color:(nullable UIColor *)color;

@end

#pragma mark - __FWAttributedLabelURLDetector

typedef void(^__FWAttributedLinkDetectCompletion)(NSArray<__FWAttributedLabelURL *> * _Nullable links) NS_SWIFT_NAME(AttributedLinkDetectCompletion);

NS_SWIFT_NAME(AttributedLabelURLDetectorProtocol)
@protocol __FWAttributedLabelURLDetectorProtocol <NSObject>
- (void)detectLinks:(nullable NSString *)plainText completion:(__FWAttributedLinkDetectCompletion)completion;
@end

NS_SWIFT_NAME(AttributedLabelDefaultURLDetector)
@interface __FWAttributedLabelDefaultURLDetector : NSObject <__FWAttributedLabelURLDetectorProtocol>
@property (nonatomic,strong,null_resettable) NSRegularExpression *dataDetector;
@end

NS_SWIFT_NAME(AttributedLabelURLDetector)
@interface __FWAttributedLabelURLDetector : NSObject <__FWAttributedLabelURLDetectorProtocol>
@property (nonatomic,strong,null_resettable) id<__FWAttributedLabelURLDetectorProtocol> detector;
+ (instancetype)shared;
@end

#pragma mark - __FWAttributedLabelAttachment

void __fw_attributedDeallocCallback(void* ref);
CGFloat __fw_attributedAscentCallback(void *ref);
CGFloat __fw_attributedDescentCallback(void *ref);
CGFloat __fw_attributedWidthCallback(void* ref);

NS_SWIFT_NAME(AttributedLabelAttachment)
@interface __FWAttributedLabelAttachment : NSObject

@property (nonatomic,strong) id                    content;
@property (nonatomic,assign) UIEdgeInsets          margin;
@property (nonatomic,assign) __FWAttributedAlignment alignment;
@property (nonatomic,assign) CGFloat               fontAscent;
@property (nonatomic,assign) CGFloat               fontDescent;
@property (nonatomic,assign) CGSize                maxSize;


+ (__FWAttributedLabelAttachment *)attachmentWith:(id)content
                                         margin:(UIEdgeInsets)margin
                                      alignment:(__FWAttributedAlignment)alignment
                                        maxSize:(CGSize)maxSize;

- (CGSize)boxSize;

@end

NS_ASSUME_NONNULL_END
