/*!
 @header     NSString+FWFramework.h
 @indexgroup FWFramework
 @brief      NSString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 @brief NSString+FWFramework
 */
@interface NSString (FWFramework)

#pragma mark - Convert

/**
 *  去掉空白字符
 */
- (NSString *)fwTrimString;

/**
 *  首字母大写
 */
- (NSString *)fwUcfirstString;

/**
 *  首字母小写
 */
- (NSString *)fwLcfirstString;

/**
 *  驼峰转下划线
 */
- (NSString *)fwUnderlineString;

/**
 *  下划线转驼峰
 */
- (NSString *)fwCamelString;

#pragma mark - Pinyin

/**
 *  转拼音
 */
- (NSString *)fwPinyinString;

/**
 *  中文转拼音并进行比较
 *
 *  @param string 中文字符串
 */
- (NSComparisonResult)fwPinyinCompare:(NSString *)string;

#pragma mark - Regex

/**
 *  安全截取字符串。解决末尾半个Emoji问题(半个Emoji调UTF8String为NULL，导致MD5签名等失败)
 *
 *  @param index 目标索引
 */
- (NSString *)fwEmojiSubstring:(NSUInteger)index;

/**
 *  正则搜索子串
 *
 *  @param regex 正则表达式
 */
- (NSString *)fwRegexSubstring:(NSString *)regex;

/**
 *  正则替换字符串
 *
 *  @param regex  正则表达式
 *  @param string 替换模板，如"头部$1中部$2尾部"
 *
 *  @return 替换后的字符串
 */
- (NSString *)fwRegexReplace:(NSString *)regex withString:(NSString *)string;

/**
 *  正则匹配回调
 *
 *  @param regex 正则表达式
 *  @param block 回调句柄。range从大至小，方便replace
 */
- (void)fwRegexMatches:(NSString *)regex withBlock:(void (^)(NSRange range))block;

#pragma mark - Html

/**
 转义Html，如"a<"转义为"a&lt;"
 
 @return 转义后的字符串
 */
- (NSString *)fwEscapeHtml;

#pragma mark - Number

// 字符串转NSNumber
- (NSNumber *)fwNumberValue;

#pragma mark - Static

// 创建一个UUID字符串，示例："D1178E50-2A4D-4F1F-9BD3-F6AAB00E06B1"
+ (NSString *)fwUUIDString;

// 格式化文件大小为".0K/.1M/.1G"
+ (NSString *)fwSizeString:(NSUInteger)aFileSize;

#pragma mark - Size

// 计算单行字符串指定字体所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font;

// 计算多行字符串指定字体在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize;

// 计算多行字符串指定字体、指定换行样式在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize lineBreak:(NSLineBreakMode)breakMode;

@end
