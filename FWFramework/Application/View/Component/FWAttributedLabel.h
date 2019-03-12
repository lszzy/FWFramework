/*!
 @header     FWAttributedLabel.h
 @indexgroup FWFramework
 @brief      FWAttributedLabel
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, FWAttributedAlignment) {
    FWAttributedAlignmentTop,
    FWAttributedAlignmentCenter,
    FWAttributedAlignmentBottom
};

@class FWAttributedLabel;

@protocol FWAttributedLabelDelegate <NSObject>
- (void)attributedLabel:(FWAttributedLabel *)label
          clickedOnLink:(id)linkData;

@end

typedef NSArray * _Nullable (^FWCustomDetectLinkBlock)(NSString * _Nullable text);

@class FWAttributedLabelURL;

#pragma mark - FWAttributedLabel

/*!
 @brief FWAttributedLabel
 
 @see https://github.com/xiangwangfeng/M80AttributedLabel
 */
@interface FWAttributedLabel : UIView

@property (nonatomic,weak,nullable)         id<FWAttributedLabelDelegate> delegate;
@property (nonatomic,strong,nullable)       UIFont *font;                          //字体
@property (nonatomic,strong,nullable)       UIColor *textColor;                    //文字颜色
@property (nonatomic,strong,nullable)       UIColor *highlightColor;               //链接点击时背景高亮色
@property (nonatomic,strong,nullable)       UIColor *linkColor;                    //链接色
@property (nonatomic,strong,nullable)       UIColor *shadowColor;                  //阴影颜色
@property (nonatomic,assign)                CGSize  shadowOffset;                   //阴影offset
@property (nonatomic,assign)                CGFloat shadowBlur;                     //阴影半径
@property (nonatomic,assign)                BOOL    underLineForLink;               //链接是否带下划线
@property (nonatomic,assign)                BOOL    autoDetectLinks;                //自动检测
@property (nonatomic,assign)                NSInteger   numberOfLines;              //行数
@property (nonatomic,assign)                CTTextAlignment textAlignment;          //文字排版样式
@property (nonatomic,assign)                CTLineBreakMode lineBreakMode;          //LineBreakMode
@property (nonatomic,assign)                CGFloat lineSpacing;                    //行间距
@property (nonatomic,assign)                CGFloat paragraphSpacing;               //段间距
@property (nonatomic,copy,nullable)         NSString *text;                         //普通文本
@property (nonatomic,copy,nullable)         NSAttributedString *attributedText;     //属性文本
@property (nonatomic,assign)                NSUInteger maxSyncDetectLength;         //UI 线程做 link 检查的文字最大长度

//重置标签
- (void)resetAll;

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
          alignment:(FWAttributedAlignment)alignment;

//UI控件
- (void)appendView:(UIView *)view;
- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin;
- (void)appendView:(UIView *)view
            margin:(UIEdgeInsets)margin
         alignment:(FWAttributedAlignment)alignment;


//添加自定义链接
- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range;

- (void)addCustomLink:(id)linkData
             forRange:(NSRange)range
            linkColor:(UIColor *)color;


//大小
- (CGSize)sizeThatFits:(CGSize)size;

//设置全局的自定义Link检测Block(详见M80AttributedLabelURL)
+ (void)setCustomDetectMethod:(nullable FWCustomDetectLinkBlock)block;

@end

#pragma mark - FWAttributedLabelURL

@interface FWAttributedLabelURL : NSObject
@property (nonatomic,strong)                id      linkData;
@property (nonatomic,assign)                NSRange range;
@property (nonatomic,strong,nullable)       UIColor *color;

+ (FWAttributedLabelURL *)urlWithLinkData:(id)linkData
                                    range:(NSRange)range
                                    color:(nullable UIColor *)color;


+ (nullable NSArray *)detectLinks:(nullable NSString *)plainText;

+ (void)setCustomDetectMethod:(nullable FWCustomDetectLinkBlock)block;
@end

#pragma mark - FWAttributedLabelAttachment

void fwAttributedDeallocCallback(void* ref);
CGFloat fwAttributedAscentCallback(void *ref);
CGFloat fwAttributedDescentCallback(void *ref);
CGFloat fwAttributedWidthCallback(void* ref);

@interface FWAttributedLabelAttachment : NSObject
@property (nonatomic,strong)    id                  content;
@property (nonatomic,assign)    UIEdgeInsets        margin;
@property (nonatomic,assign)    FWAttributedAlignment   alignment;
@property (nonatomic,assign)    CGFloat             fontAscent;
@property (nonatomic,assign)    CGFloat             fontDescent;
@property (nonatomic,assign)    CGSize              maxSize;


+ (FWAttributedLabelAttachment *)attachmentWith:(id)content
                                         margin:(UIEdgeInsets)margin
                                      alignment:(FWAttributedAlignment)alignment
                                        maxSize:(CGSize)maxSize;

- (CGSize)boxSize;

@end

#pragma mark - NSMutableAttributedString+FWAttributedLabel

@interface NSMutableAttributedString (FWAttributedLabel)

- (void)fwSetTextColor:(UIColor*)color;
- (void)fwSetTextColor:(UIColor*)color range:(NSRange)range;

- (void)fwSetFont:(UIFont*)font;
- (void)fwSetFont:(UIFont*)font range:(NSRange)range;

- (void)fwSetUnderlineStyle:(CTUnderlineStyle)style
                   modifier:(CTUnderlineStyleModifiers)modifier;
- (void)fwSetUnderlineStyle:(CTUnderlineStyle)style
                   modifier:(CTUnderlineStyleModifiers)modifier
                      range:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
