/*!
 @header     NSString+FWFormat.m
 @indexgroup FWFramework
 @brief      NSString+FWFormat
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "NSString+FWFormat.h"

@implementation NSString (FWFormat)

- (BOOL)fwIsFormatRegex:(NSString *)regex
{
    NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [regexPredicate evaluateWithObject:self] == YES;
}

- (BOOL)fwIsFormatMobile
{
    return [self fwIsFormatRegex:@"^1\\d{10}$"];
}

- (BOOL)fwIsFormatTelephone
{
    return [self fwIsFormatRegex:@"^(\\d{3}\\-)?\\d{8}|(\\d{4}\\-)?\\d{7}$"];
}

- (BOOL)fwIsFormatInteger
{
    return [self fwIsFormatRegex:@"^\\-?\\d+$"];
}

- (BOOL)fwIsFormatNumber
{
    return [self fwIsFormatRegex:@"^\\-?\\d+\\.?\\d*$"];
}

- (BOOL)fwIsFormatMoney
{
    return [self fwIsFormatRegex:@"^\\d+\\.?\\d{0,2}$"];
}

- (BOOL)fwIsFormatIdcard
{
    // 简单版本
    // return [self fwIsFormatRegex:@"^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}(\\d|x|X)$"];
    
    // 复杂版本
    NSString *sPaperId = self;
    // 判断位数
    if ([sPaperId length] != 15 && [sPaperId length] != 18) {
        return NO;
    }
    
    NSString *carid = sPaperId;
    long lSumQT = 0;
    // 加权因子
    int R[] = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};
    // 校验码
    unsigned char sChecker[11] = {'1','0','X', '9', '8', '7', '6', '5', '4', '3', '2'};
    // 将15位身份证号转换成18位
    NSMutableString *mString = [NSMutableString stringWithString:sPaperId];
    if ([sPaperId length] == 15) {
        [mString insertString:@"19" atIndex:6];
        long p = 0;
        const char *pid = [mString UTF8String];
        for (int i = 0; i <= 16; i++) {
            p += (pid[i] - 48) * R[i];
        }
        int o = p % 11;
        NSString *string_content = [NSString stringWithFormat:@"%c", sChecker[o]];
        [mString insertString:string_content atIndex:[mString length]];
        carid = mString;
    }
    
    // 判断是否在地区码内
    NSString *sProvince = [carid substringToIndex:2];
    NSDictionary *dic = @{
                          @"11" : @"北京",
                          @"12" : @"天津",
                          @"13" : @"河北",
                          @"14" : @"山西",
                          @"15" : @"内蒙古",
                          @"21" : @"辽宁",
                          @"22" : @"吉林",
                          @"23" : @"黑龙江",
                          @"31" : @"上海",
                          @"32" : @"江苏",
                          @"33" : @"浙江",
                          @"34" : @"安徽",
                          @"35" : @"福建",
                          @"36" : @"江西",
                          @"37" : @"山东",
                          @"41" : @"河南",
                          @"42" : @"湖北",
                          @"43" : @"湖南",
                          @"44" : @"广东",
                          @"45" : @"广西",
                          @"46" : @"海南",
                          @"50" : @"重庆",
                          @"51" : @"四川",
                          @"52" : @"贵州",
                          @"53" : @"云南",
                          @"54" : @"西藏",
                          @"61" : @"陕西",
                          @"62" : @"甘肃",
                          @"63" : @"青海",
                          @"64" : @"宁夏",
                          @"65" : @"新疆",
                          @"71" : @"台湾",
                          @"81" : @"香港",
                          @"82" : @"澳门",
                          @"91" : @"国外",
                          };
    if ([dic objectForKey:sProvince] == nil) {
        return NO;
    }
    
    // 判断年月日是否有效
    int strYear = [[carid substringWithRange:NSMakeRange(6, 4)] intValue];
    int strMonth = [[carid substringWithRange:NSMakeRange(10, 2)] intValue];
    int strDay = [[carid substringWithRange:NSMakeRange(12, 2)] intValue];
    NSTimeZone *localZone = [NSTimeZone localTimeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeZone:localZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%d-%d-%d 12:01:01", strYear, strMonth, strDay]];
    if (date == nil) {
        return NO;
    }
    
    // 检验长度
    const char *PaperId  = [carid UTF8String];
    if( 18 != strlen(PaperId)) return NO;
    // 校验数字
    for (int i = 0; i < 18; i++) {
        if (!isdigit(PaperId[i]) && !(('X' == PaperId[i] || 'x' == PaperId[i]) && 17 == i)) {
            return NO;
        }
    }
    
    // 验证最末的校验码
    for (int i = 0; i <= 16; i++) {
        lSumQT += (PaperId[i] - 48) * R[i];
    }
    if (sChecker[lSumQT % 11] != PaperId[17]) {
        return NO;
    }
    
    // 校验通过
    return YES;
}

/**
 *  银行卡号有效性问题Luhn算法
 *  现行 16 位银联卡现行卡号开头 6 位是 622126～622925 之间的，7 到 15 位是银行自定义的，
 *  可能是发卡分行，发卡网点，发卡序号，第 16 位是校验码。
 *  16 位卡号校验位采用 Luhm 校验方法计算：
 *  1，将未带校验位的 15 位卡号从右依次编号 1 到 15，位于奇数位号上的数字乘以 2
 *  2，将奇位乘积的个十位全部相加，再加上所有偶数位上的数字
 *  3，将加法和加上校验位能被 10 整除。
 */
- (BOOL)fwIsFormatBankcard
{
    // 取出最后一位
    NSString *lastNum = [[self substringFromIndex:(self.length-1)] copy];
    // 前15或18位
    NSString *forwardNum = [[self substringToIndex:(self.length -1)] copy];
    
    NSMutableArray *forwardArr = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i = 0; i < forwardNum.length; i++) {
        NSString *subStr = [forwardNum substringWithRange:NSMakeRange(i, 1)];
        [forwardArr addObject:subStr];
    }
    
    NSMutableArray *forwardDescArr = [[NSMutableArray alloc] initWithCapacity:0];
    // 前15位或者前18位倒序存进数组
    for (int i = (int)(forwardArr.count - 1); i > -1; i--) {
        [forwardDescArr addObject:forwardArr[i]];
    }
    
    // 奇数位*2的积 < 9
    NSMutableArray *arrOddNum = [[NSMutableArray alloc] initWithCapacity:0];
    // 奇数位*2的积 > 9
    NSMutableArray *arrOddNum2 = [[NSMutableArray alloc] initWithCapacity:0];
    // 偶数位数组
    NSMutableArray *arrEvenNum = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (int i = 0; i < forwardDescArr.count; i++) {
        NSInteger num = [forwardDescArr[i] intValue];
        // 偶数位
        if (i % 2) {
            [arrEvenNum addObject:[NSNumber numberWithInteger:num]];
            // 奇数位
        } else {
            if (num * 2 < 9) {
                [arrOddNum addObject:[NSNumber numberWithInteger:num * 2]];
            } else {
                NSInteger decadeNum = (num * 2) / 10;
                NSInteger unitNum = (num * 2) % 10;
                [arrOddNum2 addObject:[NSNumber numberWithInteger:unitNum]];
                [arrOddNum2 addObject:[NSNumber numberWithInteger:decadeNum]];
            }
        }
    }
    
    __block NSInteger sumOddNumTotal = 0;
    [arrOddNum enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        sumOddNumTotal += [obj integerValue];
    }];
    
    __block NSInteger sumOddNum2Total = 0;
    [arrOddNum2 enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        sumOddNum2Total += [obj integerValue];
    }];
    
    __block NSInteger sumEvenNumTotal =0 ;
    [arrEvenNum enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        sumEvenNumTotal += [obj integerValue];
    }];
    
    NSInteger lastNumber = [lastNum integerValue];
    NSInteger luhmTotal = lastNumber + sumEvenNumTotal + sumOddNum2Total + sumOddNumTotal;
    return (luhmTotal % 10 == 0) ? YES : NO;
}

- (BOOL)fwIsFormatCarno
{
    // 车牌号:湘K-DE829 香港车牌号码:粤Z-J499港。\u4e00-\u9fa5表示unicode编码中汉字已编码部分，\u9fa5-\u9fff是保留部分
    NSString *regex = @"^[\u4e00-\u9fff]{1}[a-zA-Z]{1}[-][a-zA-Z_0-9]{4}[a-zA-Z_0-9_\u4e00-\u9fff]$";
    return [self fwIsFormatRegex:regex];
}

- (BOOL)fwIsFormatPostcode
{
    return [self fwIsFormatRegex:@"^[0-8]\\d{5}(?!\\d)$"];
}

- (BOOL)fwIsFormatTaxno
{
    return [self fwIsFormatRegex:@"[0-9]\\d{13}([0-9]|X)$"];
}

- (BOOL)fwIsFormatIp
{
    // 简单版本
    // return [self fwIsFormatRegex:@"^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$"];
    
    // 复杂版本
    NSArray *components = [self componentsSeparatedByString:@"."];
    NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
    
    if ([components count] == 4) {
        NSString *part1 = [components objectAtIndex:0];
        NSString *part2 = [components objectAtIndex:1];
        NSString *part3 = [components objectAtIndex:2];
        NSString *part4 = [components objectAtIndex:3];
        
        if ([part1 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part2 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part3 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part4 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound) {
            if ([part1 intValue] < 255 &&
                [part2 intValue] < 255 &&
                [part3 intValue] < 255 &&
                [part4 intValue] < 255) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)fwIsFormatUrl
{
    return [self hasPrefix:@"http://"] || [self hasPrefix:@"https://"];
}

- (BOOL)fwIsFormatEmail
{
    return [self fwIsFormatRegex:@"^[A-Z0-9a-z._\%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"];
}

- (BOOL)fwIsFormatChinese
{
    return [self fwIsFormatRegex:@"^[\\x{4e00}-\\x{9fa5}]+$"];
}

- (BOOL)fwIsFormatDatetime
{
    return [self fwIsFormatRegex:@"^\\d{4}\\-\\d{2}\\-\\d{2}\\s\\d{2}\\:\\d{2}\\:\\d{2}$"];
}

- (BOOL)fwIsFormatTimestamp
{
    return [self fwIsFormatRegex:@"^\\d{10}$"];
}

- (BOOL)fwIsFormatCoordinate
{
    return [self fwIsFormatRegex:@"^\\-?\\d+\\.?\\d*,\\-?\\d+\\.?\\d*$"];
}

@end
