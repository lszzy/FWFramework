//
//  FWFoundation.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSArray+FWFoundation

@interface NSArray<__covariant ObjectType> (FWFoundation)

/// 过滤数组元素，返回YES的obj重新组装成一个数组
- (NSArray<ObjectType> *)fw_filterWithBlock:(BOOL (^)(ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 映射数组元素，返回的obj重新组装成一个数组
- (NSArray *)fw_mapWithBlock:(id _Nullable (^)(ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 匹配数组第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)fw_matchWithBlock:(BOOL (^)(ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 从数组中随机取出对象，如@[@"a", @"b", @"c"]随机取出@"b"
@property (nullable, nonatomic, readonly) ObjectType fw_randomObject NS_REFINED_FOR_SWIFT;

/// 从数组中按照权重随机取出对象，如@[@"a", @"b", @"c"]按照@[@0, @8, @02]大概率取出@"b"，不会取出@"a"
- (nullable ObjectType)fw_randomObject:(NSArray *)weights NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSAttributedString+FWFoundation

@class FWThemeObject<__covariant ObjectType>;

/**
 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可。
 注意iOS在后台运行时，如果调用NSAttributedString解析html会导致崩溃(如动态切换深色模式时在后台解析html)。解决方法是提前在前台解析好或者后台异步到下一个主线程RunLoop
 */
@interface NSAttributedString (FWFoundation)

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fw_htmlString NS_REFINED_FOR_SWIFT;

/// 计算所占尺寸，需设置Font等
@property (nonatomic, assign, readonly) CGSize fw_textSize NS_REFINED_FOR_SWIFT;

/// 计算在指定绘制区域内所占尺寸，需设置Font等
- (CGSize)fw_textSizeWithDrawSize:(CGSize)drawSize NS_REFINED_FOR_SWIFT;

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fw_attributedStringWithHtmlString:(NSString *)htmlString NS_REFINED_FOR_SWIFT;

/// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：(font.capHeight - image.size.height) / 2.0
+ (NSAttributedString *)fw_attributedStringWithImage:(nullable UIImage *)image bounds:(CGRect)bounds NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString并指定单个高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
+ (NSAttributedString *)fw_attributedStringWithString:(NSString *)string attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes highlight:(NSString *)highlight highlightAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)highlightAttributes NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString并指定所有高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
+ (NSAttributedString *)fw_attributedStringWithString:(NSString *)string attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes highlights:(NSDictionary<NSString *, NSDictionary<NSAttributedStringKey, id> *> *)highlights NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString，自定义字体
+ (instancetype)fw_attributedString:(NSString *)string withFont:(nullable UIFont *)font NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString，自定义字体和颜色
+ (instancetype)fw_attributedString:(NSString *)string withFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString，自定义字体、颜色、行高、对齐方式和换行模式
+ (instancetype)fw_attributedString:(NSString *)string withFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor lineHeight:(CGFloat)lineHeight textAlignment:(NSTextAlignment)textAlignment lineBreakMode:(NSLineBreakMode)lineBreakMode attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes NS_REFINED_FOR_SWIFT;

/// 快速创建指定行高、对齐方式和换行模式的段落样式对象
+ (NSMutableParagraphStyle *)fw_paragraphStyleWithLineHeight:(CGFloat)lineHeight textAlignment:(NSTextAlignment)textAlignment lineBreakMode:(NSLineBreakMode)lineBreakMode NS_REFINED_FOR_SWIFT;

/// html字符串转换为NSAttributedString对象，可设置默认系统字体和颜色(附加CSS方式)
+ (nullable instancetype)fw_attributedStringWithHtmlString:(NSString *)htmlString defaultAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes NS_REFINED_FOR_SWIFT;

/// html字符串转换为NSAttributedString主题对象，可设置默认系统字体和动态颜色，详见FWThemeObject
+ (FWThemeObject<NSAttributedString *> *)fw_themeObjectWithHtmlString:(NSString *)htmlString defaultAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes NS_REFINED_FOR_SWIFT;

// 获取颜色对应CSS字符串(rgb|rgba格式)
+ (NSString *)fw_CSSStringWithColor:(UIColor *)color NS_REFINED_FOR_SWIFT;

// 获取系统字体对应CSS字符串(family|style|weight|size)
+ (NSString *)fw_CSSStringWithFont:(UIFont *)font NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSData+FWFoundation

@interface NSData (FWFoundation)

/// 使用NSKeyedUnarchiver解压数据
- (nullable id)fw_unarchiveObject:(Class)clazz NS_REFINED_FOR_SWIFT;

/// 使用NSKeyedArchiver压缩对象
+ (nullable NSData *)fw_archiveObject:(id)object NS_REFINED_FOR_SWIFT;

/// 保存对象归档
+ (BOOL)fw_archiveObject:(id)object toFile:(NSString *)path NS_REFINED_FOR_SWIFT;

/// 读取对象归档
+ (nullable id)fw_unarchiveObject:(Class)clazz withFile:(NSString *)path NS_REFINED_FOR_SWIFT;

#pragma mark - Encrypt

/// 利用AES加密数据
- (nullable NSData *)fw_AESEncryptWithKey:(NSString *)key andIV:(NSData *)iv NS_REFINED_FOR_SWIFT;

/// 利用AES解密数据
- (nullable NSData *)fw_AESDecryptWithKey:(NSString *)key andIV:(NSData *)iv NS_REFINED_FOR_SWIFT;

/// 利用3DES加密数据
- (nullable NSData *)fw_DES3EncryptWithKey:(NSString *)key andIV:(NSData *)iv NS_REFINED_FOR_SWIFT;

/// 利用3DES解密数据
- (nullable NSData *)fw_DES3DecryptWithKey:(NSString *)key andIV:(NSData *)iv NS_REFINED_FOR_SWIFT;

#pragma mark - RSA

/// RSA公钥加密，数据传输安全，使用默认标签，执行base64编码
- (nullable NSData *)fw_RSAEncryptWithPublicKey:(NSString *)publicKey NS_REFINED_FOR_SWIFT;

/// RSA公钥加密，数据传输安全，可自定义标签，指定base64编码
- (nullable NSData *)fw_RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode NS_REFINED_FOR_SWIFT;

/// RSA私钥解密，数据传输安全，使用默认标签，执行base64解密
- (nullable NSData *)fw_RSADecryptWithPrivateKey:(NSString *)privateKey NS_REFINED_FOR_SWIFT;

/// RSA私钥解密，数据传输安全，可自定义标签，指定base64解码
- (nullable NSData *)fw_RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode NS_REFINED_FOR_SWIFT;

/// RSA私钥加签，防篡改防否认，使用默认标签，执行base64编码
- (nullable NSData *)fw_RSASignWithPrivateKey:(NSString *)privateKey NS_REFINED_FOR_SWIFT;

/// RSA私钥加签，防篡改防否认，可自定义标签，指定base64编码
- (nullable NSData *)fw_RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode NS_REFINED_FOR_SWIFT;

/// RSA公钥验签，防篡改防否认，使用默认标签，执行base64解密
- (nullable NSData *)fw_RSAVerifyWithPublicKey:(NSString *)publicKey NS_REFINED_FOR_SWIFT;

/// RSA公钥验签，防篡改防否认，可自定义标签，指定base64解码
- (nullable NSData *)fw_RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSDate+FWFoundation

@interface NSDate (FWFoundation)

/// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
@property (nonatomic, copy, readonly) NSString *fw_stringValue NS_REFINED_FOR_SWIFT;

/// 转化为字符串，默认当前时区，自定义格式
- (NSString *)fw_stringWithFormat:(NSString *)format NS_REFINED_FOR_SWIFT;

/// 转化为字符串，自定义格式和时区
- (NSString *)fw_stringWithFormat:(NSString *)format timeZone:(nullable NSTimeZone *)timeZone NS_REFINED_FOR_SWIFT;

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fw_currentTime NS_REFINED_FOR_SWIFT;

/// 从字符串初始化日期，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
+ (nullable NSDate *)fw_dateWithString:(NSString *)string NS_REFINED_FOR_SWIFT;

/// 从字符串初始化日期，默认当前时区，自定义格式
+ (nullable NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format NS_REFINED_FOR_SWIFT;

/// 从字符串初始化日期，自定义格式和时区
+ (nullable NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format timeZone:(nullable NSTimeZone *)timeZone NS_REFINED_FOR_SWIFT;

/// 格式化时长，格式"00:00"或"00:00:00"
+ (NSString *)fw_formatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour NS_REFINED_FOR_SWIFT;

/// 格式化16位、13位时间戳为10位(秒)
+ (NSTimeInterval)fw_formatTimestamp:(NSTimeInterval)timestamp NS_REFINED_FOR_SWIFT;

/// 是否是闰年
@property (nonatomic, assign, readonly) BOOL fw_isLeapYear NS_REFINED_FOR_SWIFT;

/// 是否是同一天
- (BOOL)fw_isSameDay:(NSDate *)date NS_REFINED_FOR_SWIFT;

/// 添加指定日期，如year:1|month:-1|day:1等
- (nullable NSDate *)fw_dateByAdding:(NSDateComponents *)components NS_REFINED_FOR_SWIFT;

/// 与指定日期相隔天数
- (NSInteger)fw_daysFrom:(NSDate *)date NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSNumber+FWFoundation

@interface NSNumber (FWFoundation)

/// 转换为CGFloat
@property (nonatomic, assign, readonly) CGFloat fw_CGFloatValue NS_REFINED_FOR_SWIFT;

/// 快捷创建NumberFormatter对象，默认numberStyle为decimal
+ (NSNumberFormatter *)fw_numberFormatter:(NSInteger)digit roundingMode:(NSNumberFormatterRoundingMode)roundingMode fractionZero:(BOOL)fractionZero groupingSeparator:(NSString *)groupingSeparator currencySymbol:(NSString *)currencySymbol NS_REFINED_FOR_SWIFT;

/// 快捷四舍五入格式化为字符串，默认numberStyle为decimal
- (NSString *)fw_roundString:(NSInteger)digit fractionZero:(BOOL)fractionZero groupingSeparator:(NSString *)groupingSeparator currencySymbol:(NSString *)currencySymbol NS_REFINED_FOR_SWIFT;

/// 快捷取上整格式化为字符串，默认numberStyle为decimal
- (NSString *)fw_ceilString:(NSInteger)digit fractionZero:(BOOL)fractionZero groupingSeparator:(NSString *)groupingSeparator currencySymbol:(NSString *)currencySymbol NS_REFINED_FOR_SWIFT;

/// 快捷取下整格式化为字符串，默认numberStyle为decimal
- (NSString *)fw_floorString:(NSInteger)digit fractionZero:(BOOL)fractionZero groupingSeparator:(NSString *)groupingSeparator currencySymbol:(NSString *)currencySymbol NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSDictionary+FWFoundation

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWFoundation)

/// 过滤字典元素，如果block返回NO，则去掉该元素
- (NSDictionary<KeyType, ObjectType> *)fw_filterWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 映射字典元素，返回的obj重新组装成一个字典
- (NSDictionary *)fw_mapWithBlock:(id _Nullable (^)(KeyType key, ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 匹配字典第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)fw_matchWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSObject+FWFoundation

@interface NSObject (FWFoundation)

/// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
- (void)fw_lock NS_REFINED_FOR_SWIFT;

/// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
- (void)fw_unlock NS_REFINED_FOR_SWIFT;

/// 延迟delay秒后主线程执行，返回可取消的block，对象范围
- (id)fw_performBlock:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay NS_REFINED_FOR_SWIFT;

/// 延迟delay秒后后台线程执行，返回可取消的block，对象范围
- (id)fw_performBlockInBackground:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay NS_REFINED_FOR_SWIFT;

/// 延迟delay秒后指定线程执行，返回可取消的block，对象范围
- (id)fw_performBlock:(void (^)(id obj))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay NS_REFINED_FOR_SWIFT;

/// 同一个identifier仅执行一次block，对象范围
- (void)fw_performOnce:(NSString *)identifier withBlock:(void (^)(void))block NS_REFINED_FOR_SWIFT;

/// 延迟delay秒后主线程执行，返回可取消的block，全局范围
+ (id)fw_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay NS_SWIFT_NAME(__fw_perform(with:afterDelay:)) NS_REFINED_FOR_SWIFT;

/// 延迟delay秒后后台线程执行，返回可取消的block，全局范围
+ (id)fw_performBlockInBackground:(void (^)(void))block afterDelay:(NSTimeInterval)delay NS_SWIFT_NAME(__fw_perform(inBackground:afterDelay:)) NS_REFINED_FOR_SWIFT;

/// 延迟delay秒后指定线程执行，返回可取消的block，全局范围
+ (id)fw_performBlock:(void (^)(void))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay NS_SWIFT_NAME(__fw_perform(with:on:afterDelay:)) NS_REFINED_FOR_SWIFT;

/// 取消指定延迟block，全局范围
+ (void)fw_cancelBlock:(id)block NS_REFINED_FOR_SWIFT;

/// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
+ (void)fw_syncPerformAsyncBlock:(void (^)(void (^completionHandler)(void)))asyncBlock NS_REFINED_FOR_SWIFT;

/// 同一个identifier仅执行一次block，全局范围
+ (void)fw_performOnce:(NSString *)identifier withBlock:(void (^)(void))block NS_REFINED_FOR_SWIFT;

/// 重试方式执行异步block，直至成功或者次数为0(小于0不限)或者超时(小于等于0不限)，完成后回调completion。block必须调用completionHandler，参数示例：重试4次|超时8秒|延迟2秒
+ (void)fw_performBlock:(void (^)(void (^completionHandler)(BOOL success, id _Nullable obj)))block completion:(void (^)(BOOL success, id _Nullable obj))completion retryCount:(NSInteger)retryCount timeoutInterval:(NSTimeInterval)timeoutInterval delayInterval:(NSTimeInterval (^)(NSInteger count))delayInterval isCancelled:(nullable BOOL (^)(void))isCancelled NS_REFINED_FOR_SWIFT;

/// 执行轮询block任务，返回任务Id可取消
+ (NSString *)fw_performTask:(void (^)(void))task start:(NSTimeInterval)start interval:(NSTimeInterval)interval repeats:(BOOL)repeats async:(BOOL)async NS_REFINED_FOR_SWIFT;

/// 指定任务Id取消轮询任务
+ (void)fw_cancelTask:(NSString *)taskId NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSString+FWFoundation

@interface NSString (FWFoundation)

/// 计算单行字符串指定字体所占尺寸
- (CGSize)fw_sizeWithFont:(UIFont *)font NS_REFINED_FOR_SWIFT;

/// 计算多行字符串指定字体在指定绘制区域内所占尺寸
- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize NS_REFINED_FOR_SWIFT;

/// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes NS_REFINED_FOR_SWIFT;

/// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
- (BOOL)fw_matchesRegex:(NSString *)regex NS_REFINED_FOR_SWIFT;

/// 格式化文件大小为".0K/.1M/.1G"
+ (NSString *)fw_sizeString:(NSUInteger)fileSize NS_REFINED_FOR_SWIFT;

/**
 *  安全截取字符串。解决末尾半个Emoji问题(半个Emoji调UTF8String为NULL，导致MD5签名等失败)
 *
 *  @param index 目标索引
 */
- (NSString *)fw_emojiSubstring:(NSUInteger)index NS_REFINED_FOR_SWIFT;

/**
 *  正则搜索子串
 *
 *  @param regex 正则表达式
 */
- (nullable NSString *)fw_regexSubstring:(NSString *)regex NS_REFINED_FOR_SWIFT;

/**
 *  正则替换字符串
 *
 *  @param regex  正则表达式
 *  @param string 替换模板，如"头部$1中部$2尾部"
 *
 *  @return 替换后的字符串
 */
- (NSString *)fw_regexReplace:(NSString *)regex withString:(NSString *)string NS_REFINED_FOR_SWIFT;

/**
 *  正则匹配回调
 *
 *  @param regex 正则表达式
 *  @param block 回调句柄。range从大至小，方便replace
 */
- (void)fw_regexMatches:(NSString *)regex withBlock:(void (^)(NSRange range))block NS_REFINED_FOR_SWIFT;

/**
 转义Html，如"a<"转义为"a&lt;"
 */
@property (nonatomic, copy, readonly) NSString *fw_escapeHtml NS_REFINED_FOR_SWIFT;

/**
 *  是否符合正则表达式
 *  示例：用户名：^[a-zA-Z][a-zA-Z0-9_]{4,13}$
 *       密码：^[a-zA-Z0-9_]{6,20}$
 *       昵称：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
 *
 *  @param regex 正则表达式
 */
- (BOOL)fw_isFormatRegex:(NSString *)regex NS_REFINED_FOR_SWIFT;

/**
 *  是否是手机号
 */
- (BOOL)fw_isFormatMobile NS_REFINED_FOR_SWIFT;

/**
 *  是否是座机号
 */
- (BOOL)fw_isFormatTelephone NS_REFINED_FOR_SWIFT;

/**
 *  是否是整数
 */
- (BOOL)fw_isFormatInteger NS_REFINED_FOR_SWIFT;

/**
 *  是否是数字
 */
- (BOOL)fw_isFormatNumber NS_REFINED_FOR_SWIFT;

/**
 *  是否是合法金额，两位小数点
 */
- (BOOL)fw_isFormatMoney NS_REFINED_FOR_SWIFT;

/**
 *  是否是身份证号
 */
- (BOOL)fw_isFormatIdcard NS_REFINED_FOR_SWIFT;

/**
 *  是否是银行卡号
 */
- (BOOL)fw_isFormatBankcard NS_REFINED_FOR_SWIFT;

/**
 *  是否是车牌号
 */
- (BOOL)fw_isFormatCarno NS_REFINED_FOR_SWIFT;

/**
 *  是否是邮政编码
 */
- (BOOL)fw_isFormatPostcode NS_REFINED_FOR_SWIFT;

/**
 *  是否是邮箱
 */
- (BOOL)fw_isFormatEmail NS_REFINED_FOR_SWIFT;

/**
 *  是否是URL
 */
- (BOOL)fw_isFormatUrl NS_REFINED_FOR_SWIFT;

/**
 *  是否是HTML
 */
- (BOOL)fw_isFormatHtml NS_REFINED_FOR_SWIFT;

/**
 *  是否是IP
 */
- (BOOL)fw_isFormatIp NS_REFINED_FOR_SWIFT;

/**
 *  是否全是中文
 */
- (BOOL)fw_isFormatChinese NS_REFINED_FOR_SWIFT;

/**
 *  是否是合法时间，格式：yyyy-MM-dd HH:mm:ss
 */
- (BOOL)fw_isFormatDatetime NS_REFINED_FOR_SWIFT;

/**
 *  是否是合法时间戳，格式：1301234567
 */
- (BOOL)fw_isFormatTimestamp NS_REFINED_FOR_SWIFT;

/**
 *  是否是坐标点字符串，格式：latitude,longitude
 */
- (BOOL)fw_isFormatCoordinate NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSFileManager+FWFoundation

@interface NSFileManager (FWFoundation)

/// 搜索路径，参数为NSSearchPathDirectory
+ (NSString *)fw_pathSearch:(NSSearchPathDirectory)directory NS_REFINED_FOR_SWIFT;

/// 沙盒路径
@property (class, nonatomic, copy, readonly) NSString *fw_pathHome NS_REFINED_FOR_SWIFT;

/// 文档路径，iTunes会同步备份
@property (class, nonatomic, copy, readonly) NSString *fw_pathDocument NS_REFINED_FOR_SWIFT;

/// 缓存路径，系统不会删除，iTunes会删除
@property (class, nonatomic, copy, readonly) NSString *fw_pathCaches NS_REFINED_FOR_SWIFT;

/// Library路径
@property (class, nonatomic, copy, readonly) NSString *fw_pathLibrary NS_REFINED_FOR_SWIFT;

/// 配置路径，配置文件保存位置
@property (class, nonatomic, copy, readonly) NSString *fw_pathPreference NS_REFINED_FOR_SWIFT;

/// 临时路径，App退出后可能会删除
@property (class, nonatomic, copy, readonly) NSString *fw_pathTmp NS_REFINED_FOR_SWIFT;

/// bundle路径，不可写
@property (class, nonatomic, copy, readonly) NSString *fw_pathBundle NS_REFINED_FOR_SWIFT;

/// 资源路径，不可写
@property (class, nonatomic, copy, readonly) NSString *fw_pathResource NS_REFINED_FOR_SWIFT;

/// 获取目录大小，单位：B
+ (unsigned long long)fw_folderSize:(NSString *)folderPath NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSURL+FWFoundation

@interface NSURL (FWFoundation)

/**
 生成App Store外部URL
 
 @param appId 应用Id
 @return NSURL
 */
+ (NSURL *)fw_appStoreURL:(NSString *)appId NS_REFINED_FOR_SWIFT;

/**
 生成苹果地图地址外部URL
 
 @param addr 显示地址，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
 @return NSURL
 */
+ (nullable NSURL *)fw_appleMapsURLWithAddr:(nullable NSString *)addr options:(nullable NSDictionary *)options NS_REFINED_FOR_SWIFT;

/**
 生成苹果地图导航外部URL
 
 @param saddr 导航起始点，格式latitude,longitude或搜索地址
 @param daddr 导航结束点，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
 @return NSURL
 */
+ (nullable NSURL *)fw_appleMapsURLWithSaddr:(nullable NSString *)saddr daddr:(nullable NSString *)daddr options:(nullable NSDictionary *)options NS_REFINED_FOR_SWIFT;

/**
 生成谷歌地图外部URL，URL SCHEME为：comgooglemaps
 
 @param addr 显示地址，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14"}
 @return NSURL
 */
+ (nullable NSURL *)fw_googleMapsURLWithAddr:(nullable NSString *)addr options:(nullable NSDictionary *)options NS_REFINED_FOR_SWIFT;

/**
 生成谷歌地图导航外部URL，URL SCHEME为：comgooglemaps
 
 @param saddr 导航起始点，格式latitude,longitude或搜索地址
 @param daddr 导航结束点，格式latitude,longitude或搜索地址
 @param mode 导航模式，支持driving|transit|bicycling|walking，默认driving
 @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14", @"dirflg": @"t,h"}
 @return NSURL
 */
+ (nullable NSURL *)fw_googleMapsURLWithSaddr:(nullable NSString *)saddr daddr:(nullable NSString *)daddr mode:(nullable NSString *)mode options:(nullable NSDictionary *)options NS_REFINED_FOR_SWIFT;

/**
 生成百度地图外部URL，URL SCHEME为：baidumap
 
 @param addr 显示地址，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
 @return NSURL
 */
+ (nullable NSURL *)fw_baiduMapsURLWithAddr:(nullable NSString *)addr options:(nullable NSDictionary *)options NS_REFINED_FOR_SWIFT;

/**
 生成百度地图导航外部URL，URL SCHEME为：baidumap
 
 @param saddr 导航起始点，格式latitude,longitude或搜索地址
 @param daddr 导航结束点，格式latitude,longitude或搜索地址
 @param mode 导航模式，支持driving|transit|navigation|riding|walking，默认driving
 @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
 @return NSURL
 */
+ (nullable NSURL *)fw_baiduMapsURLWithSaddr:(nullable NSString *)saddr daddr:(nullable NSString *)daddr mode:(nullable NSString *)mode options:(nullable NSDictionary *)options NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSUserDefaults+FWFoundation

@interface NSUserDefaults (FWFoundation)

/// 读取对象，支持unarchive对象
- (nullable id)fw_objectForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 保存对象，支持archive对象
- (void)fw_setObject:(nullable id)object forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 从standard读取对象，支持unarchive对象
+ (nullable id)fw_objectForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 保存对象到standard，支持archive对象
+ (void)fw_setObject:(nullable id)object forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
