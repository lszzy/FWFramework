/*!
 @header     NSObject+FWModel.h
 @indexgroup FWFramework
 @brief      NSObject+FWModel
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/9/26
 */

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define OMDateFormat @"yyyy-MM-dd'T'HH:mm:ss.SSS"
#define OMTimeZone @"UTC"

typedef NS_ENUM(NSInteger, CAPSDataType) {
    CAPSDataTypeJSON,
    CAPSDataTypeXML,
    CAPSDataTypeSOAP
};

/*!
 @brief NSObject模型解析，参考自NSObject-ObjectMap
 
 @see https://github.com/uacaps/NSObject-ObjectMap
 */
@interface NSObject (FWModel)

#pragma mark - Customer

+ (NSDictionary *)fwClassMapper;

+ (NSDictionary *)fwPropertyMapper;

+ (NSDateFormatter *)fwPropertyDateFormatter;

// 属性黑名单列表
+ (NSArray *)fwPropertyBlacklist;

// 属性白名单列表
+ (NSArray *)fwPropertyWhitelist;

#pragma mark - NSObject+ObjectMap

// Universal Method
-(NSDictionary *)propertyDictionary;
-(NSString *)nameOfClass;


#pragma mark - Init Methods
/**
 Initializes an instance of a new object using JSON.
 
 @param data The JSON data to deserialize into the returned object.
 
 @return The newly-initialized object.
 */
- (instancetype)initWithJSONData:(NSData *)data;


/**
 Initializes an instance of a new object using XML.
 
 @param data The XML data to deserialize into the returned object.
 
 @return The newly-initialized object.
 */
- (instancetype)initWithXMLData:(NSData *)data;


/**
 Initializes an instance of a new object using SOAP.
 
 @param data The SOAP data to deserialize into the returned object.
 
 @return The newly-initialized object.
 */
- (instancetype)initWithSOAPData:(NSData *)data;


/**
 Initializes an instance of a new object using unspecified object data and a specified type.
 
 @param data The unspecified data to deserialize into the returned object.
 @param type The type of unspecified data to deserialize.
 
 @return The newly-initialized object.
 */
- (instancetype)initWithObjectData:(NSData *)data type:(CAPSDataType)type;



#pragma mark - Top Level Array from JSON
/**
 Initializes an array of objects that are of a certain class from JSON data.
 
 @param objectClass The type of object to deserialize into.
 @param data The JSON data to deserialize into the array.
 
 @return The newly-initialized array.
 */
+ (NSArray *)arrayOfType:(Class)objectClass FromJSONData:(NSData *)data;



#pragma mark - Serialized Data/Strings from Objects
-(NSData *)JSONData;
-(NSString *)JSONString;
-(NSData *)XMLData;
-(NSString *)XMLString;
-(NSData *)SOAPData;
-(NSString *)SOAPString;
-(NSDictionary *)objectDictionary;


#pragma mark - New Object with properties of another Object
-(id)initWithObject:(NSObject *)oldObject error:(NSError **)error;

#pragma mark - Base64 Encode/Decode
+(NSString *)encodeBase64WithData:(NSData *)objData;
+(NSData *)base64DataFromString:(NSString *)string;

@end

@interface SOAPObject : NSObject
@property (nonatomic, retain) id Header;
@property (nonatomic, retain) id Body;
@end
