//
//  FWDatabase.m
//  FWDatabase
//
//  Created by admin on 16/5/28.
//  Copyright © 2016年 WHC. All rights reserved.
//
// Github <https://github.com/netyouli/WHC_ModelSqliteKit>

#import "FWDatabase.h"
#import "FWLog.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <CommonCrypto/CommonDigest.h>
#ifdef SQLITE_HAS_CODEC
#import "sqlite3.h"
#else
#import <sqlite3.h>
#endif

static const NSString * FWDatabaseSqliteString            = @"TEXT";
static const NSString * FWDatabaseSqliteInt               = @"INTERGER";
static const NSString * FWDatabaseSqliteBoolean           = @"INTERGER";
static const NSString * FWDatabaseSqliteDouble            = @"DOUBLE";
static const NSString * FWDatabaseSqliteFloat             = @"DOUBLE";
static const NSString * FWDatabaseSqliteChar              = @"NVARCHAR";
static const NSString * FWDatabaseSqliteData              = @"BLOB";
static const NSString * FWDatabaseSqliteArray             = @"BLOB";
static const NSString * FWDatabaseSqliteDictionary        = @"BLOB";
static const NSString * FWDatabaseSqliteMutableArray      = @"BLOB";
static const NSString * FWDatabaseSqliteMutableDictionary = @"BLOB";
static const NSString * FWDatabaseSqliteDate              = @"DOUBLE";

typedef enum : NSUInteger {
    FWDatabaseFieldTypeString,
    FWDatabaseFieldTypeInt,
    FWDatabaseFieldTypeBoolean,
    FWDatabaseFieldTypeDouble,
    FWDatabaseFieldTypeFloat,
    FWDatabaseFieldTypeChar,
    FWDatabaseFieldTypeNumber,
    FWDatabaseFieldTypeData,
    FWDatabaseFieldTypeDate,
    FWDatabaseFieldTypeArray,
    FWDatabaseFieldTypeDictionary,
    FWDatabaseFieldTypeMutableArray,
    FWDatabaseFieldTypeMutableDictionary,
} FWDatabaseFieldType;

typedef enum : NSUInteger {
    FWDatabaseQueryTypeWhere,
    FWDatabaseQueryTypeOrder,
    FWDatabaseQueryTypeLimit,
    FWDatabaseQueryTypeWhereOrder,
    FWDatabaseQueryTypeWhereLimit,
    FWDatabaseQueryTypeOrderLimit,
    FWDatabaseQueryTypeWhereOrderLimit
} FWDatabaseQueryType;

static sqlite3 * _fw_database;

@interface FWDatabasePropertyInfo : NSObject

@property (nonatomic, assign, readonly) FWDatabaseFieldType type;
@property (nonatomic, copy, readonly) NSString * name;
@property (nonatomic, assign, readonly) SEL setter;
@property (nonatomic, assign, readonly) SEL getter;

@end

@implementation FWDatabasePropertyInfo

+ (SEL)setterWithProperyName:(NSString *)property_name {
    if (property_name.length > 1) {
        return NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [property_name substringToIndex:1].uppercaseString, [property_name substringFromIndex:1]]);
    } else {
        return NSSelectorFromString([NSString stringWithFormat:@"set%@:", property_name.uppercaseString]);
    }
}

- (FWDatabasePropertyInfo *)initWithType:(FWDatabaseFieldType)type
                      propertyName:(NSString *)property_name
                              name:(NSString *)name {
    self = [super init];
    if (self) {
        _name = name.mutableCopy;
        _type = type;
        _setter = [FWDatabasePropertyInfo setterWithProperyName:property_name];
        _getter = NSSelectorFromString(property_name);
    }
    return self;
}

@end

@interface FWDatabase ()

@property (nonatomic, strong) dispatch_semaphore_t dsema;
@property (nonatomic, assign) BOOL check_update;
@property (nonatomic, copy) NSString *version;

@end

@implementation FWDatabase

- (FWDatabase *)init {
    self = [super init];
    if (self) {
        _dsema = dispatch_semaphore_create(1);
        _check_update = YES;
        _version = @"1.0";
    }
    return self;
}

+ (FWDatabase *)shareInstance {
    static FWDatabase * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FWDatabase new];
    });
    return instance;
}

+ (NSString *)version {
    return [self shareInstance].version;
}

+ (void)setVersion:(NSString *)version {
    if (version && version.length > 0) {
        [self shareInstance].version = version;
    }
}

+ (NSString *)databaseCacheDirectory:(Class)model_class {
    if (model_class) {
        NSString * custom_path = [self exceSelector:@selector(fwDatabasePath) modelClass:model_class];
        if (custom_path != nil && custom_path.length > 0) {
            return custom_path;
        }
    }
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    return [NSString stringWithFormat:@"%@/FWDatabase/", cacheDirectory];
}

+ (FWDatabaseFieldType)parserFieldTypeWithAttr:(NSString *)attr {
    NSArray * sub_attrs = [attr componentsSeparatedByString:@","];
    NSString * first_sub_attr = sub_attrs.firstObject;
    first_sub_attr = [first_sub_attr substringFromIndex:1];
    FWDatabaseFieldType field_type = FWDatabaseFieldTypeString;
    const char type = *[first_sub_attr UTF8String];
    switch (type) {
        case 'B':
            field_type = FWDatabaseFieldTypeBoolean;
            break;
        case 'c':
        case 'C':
            field_type = FWDatabaseFieldTypeChar;
            break;
        case 's':
        case 'S':
        case 'i':
        case 'I':
        case 'l':
        case 'L':
        case 'q':
        case 'Q':
            field_type = FWDatabaseFieldTypeInt;
            break;
        case 'f':
            field_type = FWDatabaseFieldTypeFloat;
            break;
        case 'd':
        case 'D':
            field_type = FWDatabaseFieldTypeDouble;
            break;
        default:
            break;
    }
    return field_type;
}

+ (const NSString *)databaseFieldTypeWithType:(FWDatabaseFieldType)type {
    switch (type) {
        case FWDatabaseFieldTypeString:
            return FWDatabaseSqliteString;
        case FWDatabaseFieldTypeInt:
            return FWDatabaseSqliteInt;
        case FWDatabaseFieldTypeNumber:
            return FWDatabaseSqliteDouble;
        case FWDatabaseFieldTypeDouble:
            return FWDatabaseSqliteDouble;
        case FWDatabaseFieldTypeFloat:
            return FWDatabaseSqliteFloat;
        case FWDatabaseFieldTypeChar:
            return FWDatabaseSqliteChar;
        case FWDatabaseFieldTypeBoolean:
            return FWDatabaseSqliteBoolean;
        case FWDatabaseFieldTypeData:
            return FWDatabaseSqliteData;
        case FWDatabaseFieldTypeDate:
            return FWDatabaseSqliteDate;
        case FWDatabaseFieldTypeArray:
            return FWDatabaseSqliteArray;
        case FWDatabaseFieldTypeDictionary:
            return FWDatabaseSqliteDictionary;
        case FWDatabaseFieldTypeMutableArray:
            return FWDatabaseSqliteMutableArray;
        case FWDatabaseFieldTypeMutableDictionary:
            return FWDatabaseSqliteMutableDictionary;
        default:
            break;
    }
    return FWDatabaseSqliteString;
}

+ (NSDictionary *)parserModelObjectFieldsWithModelClass:(Class)model_class hasPrimary:(BOOL)hasPrimary {
    return [self parserSubModelObjectFieldsWithModelClass:model_class propertyName:nil hasPrimary:hasPrimary complete:nil];
}

+ (NSDictionary *)parserSubModelObjectFieldsWithModelClass:(Class)model_class propertyName:(NSString *)main_property_name hasPrimary:(BOOL)hasPrimary complete:(void(^)(NSString * key, FWDatabasePropertyInfo * property_object))complete {
    BOOL need_dictionary_save = !main_property_name && !complete;
    NSMutableDictionary * fields = need_dictionary_save ? [NSMutableDictionary dictionary] : nil;
    Class super_class = class_getSuperclass(model_class);
    if (super_class != nil &&
        super_class != [NSObject class]) {
        NSDictionary * super_fields = [self parserSubModelObjectFieldsWithModelClass:super_class propertyName:main_property_name hasPrimary:hasPrimary complete:complete];
        if (need_dictionary_save) [fields setValuesForKeysWithDictionary:super_fields];
    }
    SEL selector = @selector(fwTablePropertyBlacklist);
    NSArray * ignore_propertys;
    if ([model_class respondsToSelector:selector]) {
        IMP sqlite_info_func = [model_class methodForSelector:selector];
        NSArray * (*func)(id, SEL) = (void *)sqlite_info_func;
        ignore_propertys = func(model_class, selector);
    }
    SEL all_selector = @selector(fwTablePropertyWhitelist);
    NSArray * all_propertys;
    if ([model_class respondsToSelector:all_selector]) {
        IMP sqlite_info_func = [model_class methodForSelector:all_selector];
        NSArray * (*func)(id, SEL) = (void *)sqlite_info_func;
        all_propertys = func(model_class, all_selector);
    }
    unsigned int property_count = 0;
    objc_property_t * propertys = class_copyPropertyList(model_class, &property_count);
    for (int i = 0; i < property_count; i++) {
        objc_property_t property = propertys[i];
        const char * property_name = property_getName(property);
        const char * property_attributes = property_getAttributes(property);
        NSString * property_name_string = [NSString stringWithUTF8String:property_name];
        if ((ignore_propertys && [ignore_propertys containsObject:property_name_string]) ||
            (all_propertys.count > 0 && ![all_propertys containsObject:property_name_string]) ||
            ([property_name_string isEqualToString:[self getPrimaryKeyWithClass:model_class]] && !hasPrimary)) {
            continue;
        }
        NSString * property_attributes_string = [NSString stringWithUTF8String:property_attributes];
        NSArray * property_attributes_list = [property_attributes_string componentsSeparatedByString:@"\""];
        NSString * name = property_name_string;
        
        SEL property_setter = [FWDatabasePropertyInfo setterWithProperyName:property_name_string];
        if (![model_class instancesRespondToSelector:property_setter]) {
            continue;
        }
        if (!need_dictionary_save) {
            name = [NSString stringWithFormat:@"%@$%@",main_property_name,property_name_string];
        }
        FWDatabasePropertyInfo * property_info = nil;
        if (property_attributes_list.count == 1) {
            // base type
            FWDatabaseFieldType type = [self parserFieldTypeWithAttr:property_attributes_list[0]];
            property_info = [[FWDatabasePropertyInfo alloc] initWithType:type propertyName:property_name_string name:name];
        }else {
            // refernece type
            Class class_type = NSClassFromString(property_attributes_list[1]);
            if (class_type == [NSNumber class]) {
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeNumber propertyName:property_name_string name:name];
            }else if (class_type == [NSString class]) {
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeString propertyName:property_name_string name:name];
            }else if (class_type == [NSData class]) {
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeData propertyName:property_name_string name:name];
            }else if (class_type == [NSArray class]) {
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeArray propertyName:property_name_string name:name];
            }else if (class_type == [NSDictionary class]) {
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeDictionary propertyName:property_name_string name:name];
            }else if (class_type == [NSDate class]) {
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeDate propertyName:property_name_string name:name];
            }else if (class_type == [NSMutableArray class]){
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeMutableArray propertyName:property_name_string name:name];
            }else if (class_type == [NSMutableDictionary class]){
                property_info = [[FWDatabasePropertyInfo alloc] initWithType:FWDatabaseFieldTypeMutableDictionary propertyName:property_name_string name:name];
            }else if (class_type == [NSSet class] ||
                      class_type == [NSValue class] ||
                      class_type == [NSError class] ||
                      class_type == [NSURL class] ||
                      class_type == [NSStream class] ||
                      class_type == [NSScanner class] ||
                      class_type == [NSException class] ||
                      class_type == [NSBundle class]) {
                [self log:@"检查模型类异常数据类型"];
            }else {
                if (need_dictionary_save) {
                    [self parserSubModelObjectFieldsWithModelClass:class_type propertyName:name hasPrimary:hasPrimary complete:^(NSString * key, FWDatabasePropertyInfo *property_object) {
                        [fields setObject:property_object forKey:key];
                    }];
                }else {
                    [self parserSubModelObjectFieldsWithModelClass:class_type propertyName:name hasPrimary:hasPrimary complete:complete];
                }
            }
        }
        if (need_dictionary_save && property_info) [fields setObject:property_info forKey:name];
        if (property_info && complete) {
            complete(name,property_info);
        }
    }
    free(propertys);
    return fields;
}

+ (BOOL)isSubModelWithClass:(Class)model_class {
    return (model_class != [NSString class] &&
            model_class != [NSNumber class] &&
            model_class != [NSArray class] &&
            model_class != [NSSet class] &&
            model_class != [NSData class] &&
            model_class != [NSDate class] &&
            model_class != [NSDictionary class] &&
            model_class != [NSValue class] &&
            model_class != [NSError class] &&
            model_class != [NSURL class] &&
            model_class != [NSStream class] &&
            model_class != [NSURLRequest class] &&
            model_class != [NSURLResponse class] &&
            model_class != [NSBundle class] &&
            model_class != [NSScanner class] &&
            model_class != [NSException class]);
}

+ (NSDictionary *)scanCommonSubModel:(id)model isClass:(BOOL)is_class {
    Class model_class = is_class ? model : [model class];
    NSMutableDictionary * sub_model_info = [NSMutableDictionary dictionary];
    Class super_class = class_getSuperclass(model_class);
    if (super_class != nil &&
        super_class != [NSObject class]) {
        [sub_model_info setValuesForKeysWithDictionary:[self scanCommonSubModel:is_class ? super_class : super_class.new isClass:is_class]];
    }
    unsigned int property_count = 0;
    objc_property_t * propertys = class_copyPropertyList(model_class, &property_count);
    for (int i = 0; i < property_count; i++) {
        objc_property_t property = propertys[i];
        const char * property_name = property_getName(property);
        const char * property_attributes = property_getAttributes(property);
        NSString * property_name_string = [NSString stringWithUTF8String:property_name];
        NSString * property_attributes_string = [NSString stringWithUTF8String:property_attributes];
        NSArray * property_attributes_list = [property_attributes_string componentsSeparatedByString:@"\""];
        if (property_attributes_list.count > 1) {
            Class class_type = NSClassFromString(property_attributes_list[1]);
            if ([self isSubModelWithClass:class_type]) {
                if (is_class) {
                    [sub_model_info setObject:property_attributes_list[1] forKey:property_name_string];
                }else {
                    id sub_model = [model valueForKey:property_name_string];
                    if (sub_model) {
                        [sub_model_info setObject:sub_model forKey:property_name_string];
                    }
                }
            }
        }
    }
    free(propertys);
    return sub_model_info;
}

+ (NSArray *)getModelFieldNameWithClass:(Class)model_class {
    NSMutableArray * field_name_array = [NSMutableArray array];
    if (_fw_database) {
        NSString *sql = [NSString stringWithFormat:@"pragma table_info ('%@')",[self getTableName:model_class]];
        sqlite3_stmt *pp_stmt;
        if(sqlite3_prepare_v2(_fw_database, [sql UTF8String], -1, &pp_stmt, NULL) == SQLITE_OK){
            while(sqlite3_step(pp_stmt) == SQLITE_ROW) {
                int cols = sqlite3_column_count(pp_stmt);
                if (cols > 1) {
                    NSString *name = [NSString stringWithCString:(const char *)sqlite3_column_text(pp_stmt, 1) encoding:NSUTF8StringEncoding];
                    [field_name_array addObject:name];
                }
            }
            sqlite3_finalize(pp_stmt);
        }
    }
    return field_name_array;
}

+ (void)updateTableFieldWithModel:(Class)model_class
                       newVersion:(NSString *)newVersion
                   localModelName:(NSString *)local_model_name {
    @autoreleasepool {
        NSString * table_name = [self getTableName:model_class];
        NSString * cache_directory = [self databaseCacheDirectory: model_class];
        NSString * database_cache_path = [NSString stringWithFormat:@"%@%@",cache_directory,local_model_name];
        if (sqlite3_open([database_cache_path UTF8String], &_fw_database) == SQLITE_OK) {
            [self decryptionSqlite:model_class];
            NSArray * old_model_field_name_array = [self getModelFieldNameWithClass:model_class];
            NSDictionary * new_model_info = [self parserModelObjectFieldsWithModelClass:model_class hasPrimary:NO];
            NSMutableString * delete_field_names = [NSMutableString string];
            NSMutableString * add_field_names = [NSMutableString string];
            [old_model_field_name_array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (new_model_info[obj] == nil) {
                    [delete_field_names appendString:obj];
                    [delete_field_names appendString:@","];
                }
            }];
            [new_model_info enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, FWDatabasePropertyInfo * obj, BOOL * _Nonnull stop) {
                if (![old_model_field_name_array containsObject:key]) {
                    [add_field_names appendFormat:@"%@ %@,",key,[self databaseFieldTypeWithType:obj.type]];
                }
            }];
            if (add_field_names.length > 0) {
                NSArray * add_field_name_array = [add_field_names componentsSeparatedByString:@","];
                [add_field_name_array enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.length > 0) {
                        NSString * add_field_name_sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@",table_name,obj];
                        [self execSql:add_field_name_sql];
                    }
                }];
            }
            if (delete_field_names.length > 0) {
                [delete_field_names deleteCharactersInRange:NSMakeRange(delete_field_names.length - 1, 1)];
                NSString * default_key = [self getPrimaryKeyWithClass:model_class];
                if (![default_key isEqualToString:delete_field_names]) {
                    [self shareInstance].check_update = NO;
                    NSArray * old_model_data_array = [self commonQuery:model_class conditions:@[@""] queryType:FWDatabaseQueryTypeWhere];
                    [self close];
                    NSFileManager * file_manager = [NSFileManager defaultManager];
                    NSString * file_path = [self localPathWithModel:model_class];
                    if (file_path) {
                        [file_manager removeItemAtPath:file_path error:nil];
                    }
                    
                    if ([self openTable:model_class]) {
                        [self execSql:@"BEGIN TRANSACTION"];
                        [old_model_data_array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            [self commonInsert:obj isReplace:NO];
                        }];
                        [self execSql:@"COMMIT"];
                        [self close];
                        return;
                    }
                }
            }
            [self close];
            NSString * new_database_cache_path = [NSString stringWithFormat:@"%@%@_v%@.sqlite",cache_directory,NSStringFromClass(model_class),newVersion];
            NSFileManager * file_manager = [NSFileManager defaultManager];
            [file_manager moveItemAtPath:database_cache_path toPath:new_database_cache_path error:nil];
        }
    }
}

+ (BOOL)setKey:(NSString*)key {
    NSData *keyData = [NSData dataWithBytes:[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
    return [self setKeyWithData:keyData];
}

+ (BOOL)setKeyWithData:(NSData *)keyData {
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    
    int rc = sqlite3_key(_fw_database, [keyData bytes], (int)[keyData length]);
    
    return (rc == SQLITE_OK);
#else
    return NO;
#endif
}

+ (BOOL)rekey:(NSString*)key {
    NSData *keyData = [NSData dataWithBytes:(void *)[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
    return [self rekeyWithData:keyData];
}

+ (BOOL)rekeyWithData:(NSData *)keyData {
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    
    int rc = sqlite3_rekey(_fw_database, [keyData bytes], (int)[keyData length]);
    
    return (rc == SQLITE_OK);
#else
    return NO;
#endif
}

+ (NSString *)exceSelector:(SEL)selector modelClass:(Class)model_class {
    if ([model_class respondsToSelector:selector]) {
        IMP sqlite_info_func = [model_class methodForSelector:selector];
        NSString * (*func)(id, SEL) = (void *)sqlite_info_func;
        return func(model_class, selector);
    }
    return nil;
}

+ (NSString *)getPrimaryKeyWithClass:(Class)model_class {
    NSString * primary_key = [self exceSelector:@selector(fwTablePrimaryKey) modelClass:model_class];
    if (!primary_key || primary_key.length == 0) {
        primary_key = @"pkid";
    }
    return primary_key;
}

+ (NSInteger)getPrimaryValueWithObject:(id)model_object {
    if (!model_object) return -1;
    SEL primary_getter = NSSelectorFromString([self getPrimaryKeyWithClass:[model_object class]]);
    if ([model_object respondsToSelector:primary_getter]) {
        return ((NSInteger (*)(id, SEL))(void *) objc_msgSend)(model_object, primary_getter);
    }
    return -1;
}

+ (NSString *)md5:(NSString *)psw {
    if (psw && psw.length > 0) {
        NSMutableString * encrypt = [NSMutableString string];
        const char * cStr = psw.UTF8String;
        unsigned char buffer[CC_MD5_DIGEST_LENGTH];
        memset(buffer, 0x00, CC_MD5_DIGEST_LENGTH);
        CC_MD5(cStr, (CC_LONG)(strlen(cStr)), buffer);
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [encrypt appendFormat:@"%02x",buffer[i]];
        }
        return encrypt;
    }
    return psw;
}

+ (NSString *)pswWithModel:(Class)model {
    NSString * psw = nil;
    if (model) {
        NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
        NSString * model_name = NSStringFromClass(model);
        NSData * psw_data = [ud objectForKey:[self md5:model_name]];
        if (psw_data) {
            psw = [[NSString alloc] initWithData:psw_data encoding:NSUTF8StringEncoding];
        }
    }
    return psw;
}

+ (void)saveModel:(Class)model psw:(NSString *)psw {
    if (model && psw && psw.length > 0) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
            NSString * model_name = NSStringFromClass(model);
            NSData * psw_data = [psw dataUsingEncoding:NSUTF8StringEncoding];
            [ud setObject:psw_data forKey:[self md5:model_name]];
            [ud synchronize];
        });
    }
}

+ (void)decryptionSqlite:(Class)model_class {
#ifdef SQLITE_HAS_CODEC
    NSString * psw_key = [self exceSelector:@selector(fwDatabasePasswordKey) modelClass:model_class];
    if (psw_key && psw_key.length > 0) {
        NSString * old_psw = [self pswWithModel:model_class];
        BOOL is_update_psw = (old_psw && ![old_psw isEqualToString:psw_key]);
        if (![self setKey:is_update_psw ? old_psw : psw_key]) {
            [self log:@"给数据库加密失败, 请引入SQLCipher库并配置SQLITE_HAS_CODEC或者pod 'Component/SQLCipher'"];
        }else {
            if (is_update_psw) [self rekey:psw_key];
            [self saveModel:model_class psw:psw_key];
        }
    }
#endif
}

+ (NSString *)getTableName:(Class)model_class {
    SEL selector = @selector(fwTableName);
    if ([model_class respondsToSelector:selector]) {
        NSString * table_name = [self exceSelector:selector modelClass:model_class];
        if (table_name && table_name.length > 0) {
            return table_name;
        }
    }
    NSString *tableName = NSStringFromClass(model_class);
    if ([tableName containsString:@"."]) {
        tableName = [tableName componentsSeparatedByString:@"."].lastObject;
    }
    return tableName;
}

+ (void)createFloder:(NSString *)path {
    BOOL is_directory = YES;
    NSFileManager * file_manager = [NSFileManager defaultManager];
    if (![file_manager fileExistsAtPath:path isDirectory:&is_directory]) {
        [file_manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSString *)getSqlitePath:(Class)model_class {
    SEL selector = @selector(fwDatabaseVendorPath);
    if ([model_class respondsToSelector:selector]) {
        NSString * sqlite_path = [self exceSelector:selector modelClass:model_class];
        if (sqlite_path && sqlite_path.length > 0) {
            return sqlite_path;
        }
    }
    return nil;
}

+ (NSString *)autoHandleOldSqlite:(Class)model_class {
    NSString * cache_directory = [self databaseCacheDirectory: model_class];
    [self createFloder:cache_directory];
    NSString * sqlite_path = [self getSqlitePath:model_class];
    if (sqlite_path && sqlite_path.length > 0) {
        BOOL is_directory = NO;
        NSString * version = [self exceSelector:@selector(fwDatabaseVersion) modelClass:model_class];
        if (!version || version.length == 0) { version = [self shareInstance].version; }
        NSString * model_sqlite_path = [NSString stringWithFormat:@"%@%@_v%@.sqlite",cache_directory,NSStringFromClass(model_class),version];
        NSFileManager * file_manager = [NSFileManager defaultManager];
        if ([file_manager fileExistsAtPath:sqlite_path isDirectory:&is_directory] &&
            ![file_manager fileExistsAtPath:model_sqlite_path isDirectory:&is_directory]) {
            [file_manager copyItemAtPath:sqlite_path toPath:model_sqlite_path error:nil];
        }
    }
    return cache_directory;
}

+ (BOOL)openTable:(Class)model_class {
    NSString * cache_directory = [self autoHandleOldSqlite:model_class];
    NSString * version = [self exceSelector:@selector(fwDatabaseVersion) modelClass:model_class];
    if (!version || version.length == 0) { version = [self shareInstance].version; }
    if ([self shareInstance].check_update) {
        NSString * local_model_name = [self localNameWithModel:model_class];
        if (local_model_name != nil &&
            [local_model_name rangeOfString:version].location == NSNotFound) {
            [self updateTableFieldWithModel:model_class
                                 newVersion:version
                             localModelName:local_model_name];
        }
    }
    [self shareInstance].check_update = YES;
    NSString * database_cache_path = [NSString stringWithFormat:@"%@%@_v%@.sqlite",cache_directory,NSStringFromClass(model_class),version];
    if (sqlite3_open([database_cache_path UTF8String], &_fw_database) == SQLITE_OK) {
        [self decryptionSqlite:model_class];
        return [self createTable:model_class];
    }
    return NO;
}

+ (BOOL)createTable:(Class)model_class {
    NSString * table_name = [self getTableName:model_class];
    NSDictionary * field_dictionary = [self parserModelObjectFieldsWithModelClass:model_class hasPrimary:NO];
    if (field_dictionary.count > 0) {
        NSString * primary_key = [self getPrimaryKeyWithClass:model_class];
        __block NSString * create_table_sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,",table_name,primary_key];
        [field_dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * field, FWDatabasePropertyInfo * property_info, BOOL * _Nonnull stop) {
            create_table_sql = [create_table_sql stringByAppendingFormat:@"%@ %@ DEFAULT ",field, [self databaseFieldTypeWithType:property_info.type]];
            switch (property_info.type) {
                case FWDatabaseFieldTypeData:
                case FWDatabaseFieldTypeString:
                case FWDatabaseFieldTypeChar:
                case FWDatabaseFieldTypeDictionary:
                case FWDatabaseFieldTypeArray:
                case FWDatabaseFieldTypeMutableArray:
                case FWDatabaseFieldTypeMutableDictionary:
                    create_table_sql = [create_table_sql stringByAppendingString:@"NULL,"];
                    break;
                case FWDatabaseFieldTypeBoolean:
                case FWDatabaseFieldTypeInt:
                    create_table_sql = [create_table_sql stringByAppendingString:@"0,"];
                    break;
                case FWDatabaseFieldTypeFloat:
                case FWDatabaseFieldTypeDouble:
                case FWDatabaseFieldTypeNumber:
                case FWDatabaseFieldTypeDate:
                    create_table_sql = [create_table_sql stringByAppendingString:@"0.0,"];
                    break;
                default:
                    break;
            }
        }];
        create_table_sql = [create_table_sql substringWithRange:NSMakeRange(0, create_table_sql.length - 1)];
        create_table_sql = [create_table_sql stringByAppendingString:@")"];
        return [self execSql:create_table_sql];
    }
    return NO;
}

+ (BOOL)execSql:(NSString *)sql {
    BOOL result = sqlite3_exec(_fw_database, [sql UTF8String], nil, nil, nil) == SQLITE_OK;
    if (!result) {
        [self log:[NSString stringWithFormat:@"执行失败->%@", sql]];
    }
    return result;
}

+ (BOOL)commonInsert:(id)model_object isReplace:(BOOL)isReplace {
    sqlite3_stmt * pp_stmt = nil;
    NSInteger primary_value = [self getPrimaryValueWithObject:model_object];
    NSDictionary * field_dictionary = [self parserModelObjectFieldsWithModelClass:[model_object class] hasPrimary:primary_value > 0];
    NSString * table_name = [self getTableName:[model_object class]];
    __block NSString * insert_sql = [NSString stringWithFormat:@"%@ INTO %@ (", isReplace ? @"REPLACE" : @"INSERT", table_name];
    NSArray * field_array = field_dictionary.allKeys;
    NSMutableArray * value_array = [NSMutableArray array];
    NSMutableArray * insert_field_array = [NSMutableArray array];
    [field_array enumerateObjectsUsingBlock:^(NSString * field, NSUInteger idx, BOOL * _Nonnull stop) {
        FWDatabasePropertyInfo * property_info = field_dictionary[field];
        [insert_field_array addObject:field];
        insert_sql = [insert_sql stringByAppendingFormat:@"%@,",field];
        id value = nil;
        if ([field rangeOfString:@"$"].location == NSNotFound) {
            value = [model_object valueForKey:field];
        }else {
            value = [model_object valueForKeyPath:[field stringByReplacingOccurrencesOfString:@"$" withString:@"."]];
            if (!value) {
                switch (property_info.type) {
                    case FWDatabaseFieldTypeMutableDictionary:
                        value = [NSMutableDictionary dictionary];
                        break;
                    case FWDatabaseFieldTypeMutableArray:
                        value = [NSMutableArray array];
                        break;
                    case FWDatabaseFieldTypeDictionary:
                        value = [NSDictionary dictionary];
                        break;
                    case FWDatabaseFieldTypeArray:
                        value = [NSArray array];
                        break;
                    case FWDatabaseFieldTypeInt:
                    case FWDatabaseFieldTypeFloat:
                    case FWDatabaseFieldTypeDouble:
                    case FWDatabaseFieldTypeNumber:
                    case FWDatabaseFieldTypeChar:
                        value = @(0);
                        break;
                    case FWDatabaseFieldTypeData:
                        value = [NSData data];
                        break;
                    case FWDatabaseFieldTypeDate:
                        value = [NSDate date];
                        break;
                    case FWDatabaseFieldTypeString:
                        value = @"";
                        break;
                    case FWDatabaseFieldTypeBoolean:
                        value = @(NO);
                        break;
                    default:
                        [self log:@"子模型类数据类型异常并且不能为nil"];
                        return;
                }
            }
        }
        if (value) {
            [value_array addObject:value];
        }else {
            switch (property_info.type) {
                case FWDatabaseFieldTypeMutableArray: {
                    NSData * array_value = [NSKeyedArchiver archivedDataWithRootObject:[NSMutableArray array]];
                    [value_array addObject:array_value];
                }
                    break;
                case FWDatabaseFieldTypeMutableDictionary: {
                    NSData * dictionary_value = [NSKeyedArchiver archivedDataWithRootObject:[NSMutableDictionary dictionary]];
                    [value_array addObject:dictionary_value];
                }
                    break;
                case FWDatabaseFieldTypeArray: {
                    NSData * array_value = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
                    [value_array addObject:array_value];
                }
                    break;
                case FWDatabaseFieldTypeDictionary: {
                    NSData * dictionary_value = [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionary]];
                    [value_array addObject:dictionary_value];
                }
                    break;
                case FWDatabaseFieldTypeData: {
                    [value_array addObject:[NSData data]];
                }
                    break;
                case FWDatabaseFieldTypeString: {
                    [value_array addObject:@""];
                }
                    break;
                case FWDatabaseFieldTypeDate:
                case FWDatabaseFieldTypeNumber: {
                    [value_array addObject:@(0.0)];
                }
                    break;
                case FWDatabaseFieldTypeInt: {
                    NSNumber * value = @(((int64_t (*)(id, SEL))(void *) objc_msgSend)((id)model_object, property_info.getter));
                    [value_array addObject:value];
                }
                    break;
                case FWDatabaseFieldTypeBoolean: {
                    NSNumber * value = @(((Boolean (*)(id, SEL))(void *) objc_msgSend)((id)model_object, property_info.getter));
                    [value_array addObject:value];
                }
                    break;
                case FWDatabaseFieldTypeChar: {
                    NSNumber * value = @(((int8_t (*)(id, SEL))(void *) objc_msgSend)((id)model_object, property_info.getter));
                    [value_array addObject:value];
                }
                    break;
                case FWDatabaseFieldTypeDouble: {
                    NSNumber * value = @(((double (*)(id, SEL))(void *) objc_msgSend)((id)model_object, property_info.getter));
                    [value_array addObject:value];
                }
                    break;
                case FWDatabaseFieldTypeFloat: {
                    NSNumber * value = @(((float (*)(id, SEL))(void *) objc_msgSend)((id)model_object, property_info.getter));
                    [value_array addObject:value];
                }
                    break;
                default:
                    break;
            }
        }
    }];
    
    insert_sql = [insert_sql substringWithRange:NSMakeRange(0, insert_sql.length - 1)];
    insert_sql = [insert_sql stringByAppendingString:@") VALUES ("];
    
    [field_array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        insert_sql = [insert_sql stringByAppendingString:@"?,"];
    }];
    insert_sql = [insert_sql substringWithRange:NSMakeRange(0, insert_sql.length - 1)];
    insert_sql = [insert_sql stringByAppendingString:@")"];
    
    if (sqlite3_prepare_v2(_fw_database, [insert_sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
        [field_array enumerateObjectsUsingBlock:^(NSString *  _Nonnull field, NSUInteger idx, BOOL * _Nonnull stop) {
            FWDatabasePropertyInfo * property_info = field_dictionary[field];
            id value = value_array[idx];
            int index = (int)[insert_field_array indexOfObject:field] + 1;
            switch (property_info.type) {
                case FWDatabaseFieldTypeMutableDictionary:
                case FWDatabaseFieldTypeMutableArray:
                case FWDatabaseFieldTypeDictionary:
                case FWDatabaseFieldTypeArray: {
                    @try {
                        if ([value isKindOfClass:[NSArray class]] ||
                            [value isKindOfClass:[NSDictionary class]]) {
                            NSData * data = [NSKeyedArchiver archivedDataWithRootObject:value];
                            sqlite3_bind_blob(pp_stmt, index, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                        }else {
                            sqlite3_bind_blob(pp_stmt, index, [value bytes], (int)[value length], SQLITE_TRANSIENT);
                        }
                    } @catch (NSException *exception) {
                        [self log:[NSString stringWithFormat:@"insert 异常 Array/Dictionary类型元素未实现NSCoding协议归档失败"]];
                    }
                }
                    break;
                case FWDatabaseFieldTypeData:
                    sqlite3_bind_blob(pp_stmt, index, [value bytes], (int)[value length], SQLITE_TRANSIENT);
                    break;
                case FWDatabaseFieldTypeString:
                    if ([value respondsToSelector:@selector(UTF8String)]) {
                        sqlite3_bind_text(pp_stmt, index, [value UTF8String], -1, SQLITE_TRANSIENT);
                    }else {
                        sqlite3_bind_text(pp_stmt, index, [[NSString stringWithFormat:@"%@",value] UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    break;
                case FWDatabaseFieldTypeNumber:
                    sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                    break;
                case FWDatabaseFieldTypeInt:
                    sqlite3_bind_int64(pp_stmt, index, (sqlite3_int64)[value longLongValue]);
                    break;
                case FWDatabaseFieldTypeBoolean:
                    sqlite3_bind_int(pp_stmt, index, [value boolValue]);
                    break;
                case FWDatabaseFieldTypeChar:
                    sqlite3_bind_int(pp_stmt, index, [value intValue]);
                    break;
                case FWDatabaseFieldTypeFloat:
                    sqlite3_bind_double(pp_stmt, index, [value floatValue]);
                    break;
                case FWDatabaseFieldTypeDouble:
                    sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                    break;
                case FWDatabaseFieldTypeDate: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        sqlite3_bind_double(pp_stmt, index, [(NSDate *)value timeIntervalSince1970]);
                    }else {
                        sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                    }
                }
                    break;
                default:
                    break;
            }
        }];
        BOOL result = sqlite3_step(pp_stmt) == SQLITE_DONE;
        sqlite3_finalize(pp_stmt);
        return result;
    } else {
        [self log:@"Sorry存储数据失败,建议检查模型类属性类型是否符合规范"];
        return NO;
    }
}

+ (BOOL)insert:(id)model_object isReplace:(BOOL)isReplace {
    if (!model_object) return NO;
    __block BOOL result = NO;
    dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        if ([self openTable:[model_object class]]) {
            result = [self commonInsert:model_object isReplace:isReplace];
            NSInteger value = result ? [self getPrimaryValueWithObject:model_object] : -1;
            if (result && value == 0) {
                NSInteger rowid = (NSInteger)sqlite3_last_insert_rowid(_fw_database);
                SEL primary_setter = [FWDatabasePropertyInfo setterWithProperyName:[self getPrimaryKeyWithClass:[model_object class]]];
                if (primary_setter && [model_object respondsToSelector:primary_setter]) {
                    ((void (*)(id, SEL, NSInteger))(void *) objc_msgSend)(model_object, primary_setter, rowid);
                }
            }
            [self close];
        }
    }
    dispatch_semaphore_signal([self shareInstance].dsema);
    return result;
}

+ (BOOL)save:(id)model_object {
    return [self insert:model_object isReplace:YES];
}

+ (BOOL)inserts:(NSArray *)model_array {
    __block BOOL result = YES;
    dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        if (model_array != nil && model_array.count > 0) {
            if ([self openTable:[model_array.firstObject class]]) {
                [self execSql:@"BEGIN TRANSACTION"];
                [model_array enumerateObjectsUsingBlock:^(id model, NSUInteger idx, BOOL * _Nonnull stop) {
                    result = [self commonInsert:model isReplace:NO];
                    if (!result) {*stop = YES;}
                }];
                [self execSql:result ? @"COMMIT" : @"ROLLBACK"];
                [self close];
            }
        }
    }
    dispatch_semaphore_signal([self shareInstance].dsema);
    return result;
}

+ (BOOL)insert:(id)model_object {
    return [self insert:model_object isReplace:NO];
}

+ (id)autoNewSubmodelWithClass:(Class)model_class {
    if (model_class) {
        id model = model_class.new;
        unsigned int property_count = 0;
        objc_property_t * propertys = class_copyPropertyList(model_class, &property_count);
        for (int i = 0; i < property_count; i++) {
            objc_property_t property = propertys[i];
            const char * property_attributes = property_getAttributes(property);
            NSString * property_attributes_string = [NSString stringWithUTF8String:property_attributes];
            NSArray * property_attributes_list = [property_attributes_string componentsSeparatedByString:@"\""];
            if (property_attributes_list.count > 1) {
                // refernece type
                Class class_type = NSClassFromString(property_attributes_list[1]);
                if ([self isSubModelWithClass:class_type]) {
                    const char * property_name = property_getName(property);
                    NSString * property_name_string = [NSString stringWithUTF8String:property_name];
                    [model setValue:[self autoNewSubmodelWithClass:class_type] forKey:property_name_string];
                }
            }
        }
        free(propertys);
        return model;
    }
    return nil;
}

+ (BOOL)isNumber:(NSString *)cahr {
    int value;
    NSScanner *scan = [NSScanner scannerWithString:cahr];
    return [scan scanInt:&value] && [scan isAtEnd];
}

+ (NSString *)handleWhere:(NSString *)where {
    NSString * where_string = @"";
    if (where && where.length > 0) {
        NSArray * where_list = [where componentsSeparatedByString:@" "];
        NSMutableString * handle_where = [NSMutableString string];
        [where_list enumerateObjectsUsingBlock:^(NSString * sub_where, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange dot_range = [sub_where rangeOfString:@"."];
            if (dot_range.location != NSNotFound &&
                ![sub_where hasPrefix:@"'"] &&
                ![sub_where hasSuffix:@"'"]) {
                
                __block BOOL has_number = NO;
                NSArray * dot_sub_list = [sub_where componentsSeparatedByString:@"."];
                [dot_sub_list enumerateObjectsUsingBlock:^(NSString * dot_string, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString * before_char = nil;
                    if (dot_string.length > 0) {
                        before_char = [dot_string substringToIndex:1];
                        if ([self isNumber:before_char]) {
                            has_number = YES;
                            *stop = YES;
                        }
                    }
                }];
                if (!has_number) {
                    [handle_where appendFormat:@"%@ ",[sub_where stringByReplacingOccurrencesOfString:@"." withString:@"$"]];
                }else {
                    [handle_where appendFormat:@"%@ ",sub_where];
                }
            }else {
                [handle_where appendFormat:@"%@ ",sub_where];
            }
        }];
        if ([handle_where hasSuffix:@" "]) {
            [handle_where deleteCharactersInRange:NSMakeRange(handle_where.length - 1, 1)];
        }
        return handle_where;
    }
    return where_string;
}

+ (NSArray *)commonQuery:(Class)model_class conditions:(NSArray *)conditions queryType:(FWDatabaseQueryType)query_type {
    NSString * table_name = [self getTableName:model_class];
    NSString * select_sql = [NSString stringWithFormat:@"SELECT * FROM %@",table_name];
    NSString * where = nil;
    NSString * order = nil;
    NSString * limit = nil;
    if (conditions != nil && conditions.count > 0) {
        switch (query_type) {
            case FWDatabaseQueryTypeWhere: {
                where = [self handleWhere:conditions.firstObject];
                if (where.length > 0) {
                    select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                }
            }
                break;
            case FWDatabaseQueryTypeOrder: {
                order = [conditions.firstObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                if (order.length > 0) {
                    select_sql = [select_sql stringByAppendingFormat:@" ORDER BY %@",order];
                }
            }
                break;
            case FWDatabaseQueryTypeLimit:
                limit = [conditions.firstObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                if (limit.length > 0) {
                    select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                }
                break;
            case FWDatabaseQueryTypeWhereOrder: {
                if (conditions.count > 0) {
                    where = [self handleWhere:conditions.firstObject];
                    if (where.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                    }
                }
                if (conditions.count > 1) {
                    order = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (order.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" ORDER BY %@",order];
                    }
                }
            }
                break;
            case FWDatabaseQueryTypeWhereLimit: {
                if (conditions.count > 0) {
                    where = [self handleWhere:conditions.firstObject];
                    if (where.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                    }
                }
                if (conditions.count > 1) {
                    limit = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (limit.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                    }
                }
            }
                break;
            case FWDatabaseQueryTypeOrderLimit: {
                if (conditions.count > 0) {
                    order = [conditions.firstObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (order.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" ORDER BY %@",order];
                    }
                }
                if (conditions.count > 1) {
                    limit = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (limit.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                    }
                }
            }
                break;
            case FWDatabaseQueryTypeWhereOrderLimit: {
                if (conditions.count > 0) {
                    where = [self handleWhere:conditions.firstObject];
                    if (where.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                    }
                }
                if (conditions.count > 1) {
                    order = [conditions[1] stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (order.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" ORDER BY %@",order];
                    }
                }
                if (conditions.count > 2) {
                    limit = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (limit.length > 0) {
                        select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                    }
                }
            }
                break;
            default:
                break;
        }
    }
    return [self startSqlQuery:model_class sql:select_sql];
}

+ (NSArray *)startSqlQuery:(Class)model_class sql:(NSString *)sql {
    NSDictionary * field_dictionary = [self parserModelObjectFieldsWithModelClass:model_class hasPrimary:NO];
    NSMutableArray * model_object_array = [NSMutableArray array];
    sqlite3_stmt * pp_stmt = nil;
    if (sqlite3_prepare_v2(_fw_database, [sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
        int colum_count = sqlite3_column_count(pp_stmt);
        while (sqlite3_step(pp_stmt) == SQLITE_ROW) {
            id model_object = [self autoNewSubmodelWithClass:model_class];
            if (!model_object) {break;}
            SEL primary_setter = [FWDatabasePropertyInfo setterWithProperyName:[self getPrimaryKeyWithClass:model_class]];;
            if (primary_setter && [model_object respondsToSelector:primary_setter]) {
                sqlite3_int64 value = sqlite3_column_int64(pp_stmt, 0);
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model_object, primary_setter, value);
            }
            for (int column = 1; column < colum_count; column++) {
                NSString * field_name = [NSString stringWithCString:sqlite3_column_name(pp_stmt, column) encoding:NSUTF8StringEncoding];
                FWDatabasePropertyInfo * property_info = field_dictionary[field_name];
                if (property_info == nil) continue;
                id current_model_object = model_object;
                if ([field_name rangeOfString:@"$"].location != NSNotFound) {
                    NSString * handle_field_name = [field_name stringByReplacingOccurrencesOfString:@"$" withString:@"."];
                    NSRange backwards_range = [handle_field_name rangeOfString:@"." options:NSBackwardsSearch];
                    NSString * key_path = [handle_field_name substringWithRange:NSMakeRange(0, backwards_range.location)];
                    current_model_object = [model_object valueForKeyPath:key_path];
                    field_name = [handle_field_name substringFromIndex:backwards_range.length + backwards_range.location];
                    if (!current_model_object) continue;
                }
                switch (property_info.type) {
                    case FWDatabaseFieldTypeMutableArray:
                    case FWDatabaseFieldTypeMutableDictionary:
                    case FWDatabaseFieldTypeDictionary:
                    case FWDatabaseFieldTypeArray: {
                        int length = sqlite3_column_bytes(pp_stmt, column);
                        const void * blob = sqlite3_column_blob(pp_stmt, column);
                        if (blob != NULL) {
                            NSData * value = [NSData dataWithBytes:blob length:length];
                            @try {
                                id set_value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
                                if (set_value) {
                                    switch (property_info.type) {
                                        case FWDatabaseFieldTypeMutableArray:
                                            if ([set_value isKindOfClass:[NSArray class]]) {
                                                set_value = [NSMutableArray arrayWithArray:set_value];
                                            }
                                            break;
                                        case FWDatabaseFieldTypeMutableDictionary:
                                            if ([set_value isKindOfClass:[NSDictionary class]]) {
                                                set_value = [NSMutableDictionary dictionaryWithDictionary:set_value];
                                            }
                                            break;
                                        default:
                                            break;
                                    }
                                    [current_model_object setValue:set_value forKey:field_name];
                                }
                            } @catch (NSException *exception) {
                                [self log:@"query 查询异常 Array/Dictionary 元素没实现NSCoding协议解归档失败"];
                            }
                        }
                    }
                        break;
                    case FWDatabaseFieldTypeDate: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        if (value > 0) {
                            NSDate * date_value = [NSDate dateWithTimeIntervalSince1970:value];
                            if (date_value) {
                                [current_model_object setValue:date_value forKey:field_name];
                            }
                        }
                    }
                        break;
                    case FWDatabaseFieldTypeData: {
                        int length = sqlite3_column_bytes(pp_stmt, column);
                        const void * blob = sqlite3_column_blob(pp_stmt, column);
                        if (blob != NULL) {
                            NSData * value = [NSData dataWithBytes:blob length:length];
                            [current_model_object setValue:value forKey:field_name];
                        }
                    }
                        break;
                    case FWDatabaseFieldTypeString: {
                        const unsigned char * text = sqlite3_column_text(pp_stmt, column);
                        if (text != NULL) {
                            NSString * value = [NSString stringWithCString:(const char *)text encoding:NSUTF8StringEncoding];
                            [current_model_object setValue:value forKey:field_name];
                        }
                    }
                        break;
                    case FWDatabaseFieldTypeNumber: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        [current_model_object setValue:@(value) forKey:field_name];
                    }
                        break;
                    case FWDatabaseFieldTypeInt: {
                        sqlite3_int64 value = sqlite3_column_int64(pp_stmt, column);
                        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case FWDatabaseFieldTypeFloat: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case FWDatabaseFieldTypeDouble: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case FWDatabaseFieldTypeChar: {
                        int value = sqlite3_column_int(pp_stmt, column);
                        ((void (*)(id, SEL, int))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case FWDatabaseFieldTypeBoolean: {
                        int value = sqlite3_column_int(pp_stmt, column);
                        ((void (*)(id, SEL, int))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    default:
                        break;
                }
            }
            [model_object_array addObject:model_object];
        }
    }else {
        [self log:@"Sorry查询语句异常,建议检查查询条件Sql语句语法是否正确"];
    }
    sqlite3_finalize(pp_stmt);
    return model_object_array;
}

+ (NSArray *)startQuery:(Class)model_class conditions:(NSArray *)conditions queryType:(FWDatabaseQueryType)query_type {
    if (![self openTable:model_class]) return @[];
    NSArray * model_object_array = [self commonQuery:model_class conditions:conditions queryType:query_type];
    [self close];
    return model_object_array;
}

+ (NSArray *)queryModel:(Class)model_class conditions:(NSArray *)conditions queryType:(FWDatabaseQueryType)query_type {
    if (![self localNameWithModel:model_class]) {return @[];}
    dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    NSArray * model_array = [self startQuery:model_class conditions:conditions queryType:query_type];
    dispatch_semaphore_signal([self shareInstance].dsema);
    return model_array;
}

+ (NSArray *)query:(Class)model_class {
    return [self query:model_class where:nil];
}

+ (NSArray *)query:(Class)model_class where:(NSString *)where {
    return [self queryModel:model_class conditions:@[where == nil ? @"" : where] queryType:FWDatabaseQueryTypeWhere];
}

+ (NSArray *)query:(Class)model_class order:(NSString *)order {
    return [self queryModel:model_class conditions:@[order == nil ? @"" : order] queryType:FWDatabaseQueryTypeOrder];
}


+ (NSArray *)query:(Class)model_class limit:(NSString *)limit {
    return [self queryModel:model_class conditions:@[limit == nil ? @"" : limit] queryType:FWDatabaseQueryTypeLimit];
}

+ (NSArray *)query:(Class)model_class where:(NSString *)where order:(NSString *)order {
    return [self queryModel:model_class conditions:@[where == nil ? @"" : where,
                                                     order == nil ? @"" : order] queryType:FWDatabaseQueryTypeWhereOrder];
}

+ (NSArray *)query:(Class)model_class where:(NSString *)where limit:(NSString *)limit {
    return [self queryModel:model_class conditions:@[where == nil ? @"" : where,
                                                     limit == nil ? @"" : limit] queryType:FWDatabaseQueryTypeWhereLimit];
}

+ (NSArray *)query:(Class)model_class order:(NSString *)order limit:(NSString *)limit {
    return [self queryModel:model_class conditions:@[order == nil ? @"" : order,
                                                     limit == nil ? @"" : limit] queryType:FWDatabaseQueryTypeOrderLimit];
}

+ (NSArray *)query:(Class)model_class where:(NSString *)where order:(NSString *)order limit:(NSString *)limit {
    return [self queryModel:model_class conditions:@[where == nil ? @"" : where,
                                                     order == nil ? @"" : order,
                                                     limit == nil ? @"" : limit] queryType:FWDatabaseQueryTypeWhereOrderLimit];
}

+ (id)query:(Class)model_class key:(NSInteger)key
{
    NSString *where = [NSString stringWithFormat:@"%@ = %ld", [self getPrimaryKeyWithClass:model_class], (long)key];
    return [self query:model_class where:where].firstObject;
}

+ (NSArray *)query:(Class)model_class sql:(NSString *)sql {
    if (sql && sql.length > 0) {
        if (![self localNameWithModel:model_class]) {return @[];}
        dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
        if (![self openTable:model_class]) return @[];
        NSArray * model_object_array = [self startSqlQuery:model_class sql:sql];
        [self close];
        dispatch_semaphore_signal([self shareInstance].dsema);
        return model_object_array;
    }
    [self log:@"sql 查询语句不能为空"];
    return @[];
}

+ (NSUInteger)count:(Class)model_class {
    NSNumber * count = [self query:model_class func:@"count(*)"];
    return count ? count.unsignedIntegerValue : 0;
}

+ (id)query:(Class)model_class func:(NSString *)func {
    return [self query:model_class func:func condition:nil];
}

+ (id)query:(Class)model_class func:(NSString *)func condition:(NSString *)condition {
    if (![self localNameWithModel:model_class]) {return nil;}
    dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    if (![self openTable:model_class]) return @[];
    NSMutableArray * result_array = [NSMutableArray array];
    @autoreleasepool {
        NSString * table_name = [self getTableName:model_class];
        if (func == nil || func.length == 0) {
            [self log:@"发现错误 Sqlite Func 不能为空"];
            return nil;
        }
        if (condition == nil) {
            condition = @"";
        }else {
            condition = [self handleWhere:condition];
        }
        NSString * select_sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@",func,table_name,condition];
        sqlite3_stmt * pp_stmt = nil;
        if (sqlite3_prepare_v2(_fw_database, [select_sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
            int colum_count = sqlite3_column_count(pp_stmt);
            while (sqlite3_step(pp_stmt) == SQLITE_ROW) {
                NSMutableArray * row_result_array = [NSMutableArray array];
                for (int column = 0; column < colum_count; column++) {
                    int column_type = sqlite3_column_type(pp_stmt, column);
                    switch (column_type) {
                        case SQLITE_INTEGER: {
                            sqlite3_int64 value = sqlite3_column_int64(pp_stmt, column);
                            [row_result_array addObject:@(value)];
                        }
                            break;
                        case SQLITE_FLOAT: {
                            double value = sqlite3_column_double(pp_stmt, column);
                            [row_result_array addObject:@(value)];
                        }
                            break;
                        case SQLITE_TEXT: {
                            const unsigned char * text = sqlite3_column_text(pp_stmt, column);
                            if (text != NULL) {
                                NSString * value = [NSString stringWithCString:(const char *)text encoding:NSUTF8StringEncoding];
                                [row_result_array addObject:value];
                            }
                        }
                            break;
                        case SQLITE_BLOB: {
                            int length = sqlite3_column_bytes(pp_stmt, column);
                            const void * blob = sqlite3_column_blob(pp_stmt, column);
                            if (blob != NULL) {
                                NSData * value = [NSData dataWithBytes:blob length:length];
                                [row_result_array addObject:value];
                            }
                        }
                            break;
                        default:
                            break;
                    }
                }
                if (row_result_array.count > 0) {
                    [result_array addObject:row_result_array];
                }
            }
            sqlite3_finalize(pp_stmt);
        }else {
            [self log:@"Sorry 查询失败, 建议检查sqlite 函数书写格式是否正确！"];
        }
        [self close];
        if (result_array.count > 0) {
            NSMutableDictionary * handle_result_dict = [NSMutableDictionary dictionary];
            [result_array enumerateObjectsUsingBlock:^(NSArray * row_result_array, NSUInteger idx, BOOL * _Nonnull stop) {
                [row_result_array enumerateObjectsUsingBlock:^(id _Nonnull column_value, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString * column_array_key = @(idx).stringValue;
                    NSMutableArray * column_value_array = handle_result_dict[column_array_key];
                    if (!column_value_array) {
                        column_value_array = [NSMutableArray array];
                        handle_result_dict[column_array_key] = column_value_array;
                    }
                    [column_value_array addObject:column_value];
                }];
            }];
            NSArray * all_keys = handle_result_dict.allKeys;
            NSArray * handle_column_array_key = [all_keys sortedArrayUsingComparator:^NSComparisonResult(NSString * key1, NSString * key2) {
                NSComparisonResult result = [key1 compare:key2];
                return result == NSOrderedDescending ? NSOrderedAscending : result;
            }];
            [result_array removeAllObjects];
            if (handle_column_array_key) {
                [handle_column_array_key enumerateObjectsUsingBlock:^(NSString * key, NSUInteger idx, BOOL * _Nonnull stop) {
                    [result_array addObject:handle_result_dict[key]];
                }];
            }
        }
    }
    dispatch_semaphore_signal([self shareInstance].dsema);
    if (result_array.count == 1) {
        NSArray * element = result_array.firstObject;
        if (element.count > 1){
            return element;
        }
        return element.firstObject;
    }else if (result_array.count > 1) {
        return result_array;
    }
    return nil;
}

+ (BOOL)updateModel:(id)model_object where:(NSString *)where {
    if (model_object == nil) return NO;
    Class model_class = [model_object class];
    if (![self openTable:model_class]) return NO;
    sqlite3_stmt * pp_stmt = nil;
    NSDictionary * field_dictionary = [self parserModelObjectFieldsWithModelClass:model_class hasPrimary:NO];
    NSString * table_name = [self getTableName:model_class];
    __block NSString * update_sql = [NSString stringWithFormat:@"UPDATE %@ SET ",table_name];
    
    NSArray * field_array = field_dictionary.allKeys;
    NSMutableArray * update_field_array = [NSMutableArray array];
    [field_array enumerateObjectsUsingBlock:^(id  _Nonnull field, NSUInteger idx, BOOL * _Nonnull stop) {
        update_sql = [update_sql stringByAppendingFormat:@"%@ = ?,",field];
        [update_field_array addObject:field];
    }];
    update_sql = [update_sql substringWithRange:NSMakeRange(0, update_sql.length - 1)];
    if (where != nil && where.length > 0) {
        update_sql = [update_sql stringByAppendingFormat:@" WHERE %@", [self handleWhere:where]];
    }
    if (sqlite3_prepare_v2(_fw_database, [update_sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
        [field_array enumerateObjectsUsingBlock:^(id  _Nonnull field, NSUInteger idx, BOOL * _Nonnull stop) {
            FWDatabasePropertyInfo * property_info = field_dictionary[field];
            id current_model_object = model_object;
            NSString * actual_field = field;
            if ([field rangeOfString:@"$"].location != NSNotFound) {
                NSString * handle_field_name = [field stringByReplacingOccurrencesOfString:@"$" withString:@"."];
                NSRange backwards_range = [handle_field_name rangeOfString:@"." options:NSBackwardsSearch];
                NSString * key_path = [handle_field_name substringWithRange:NSMakeRange(0, backwards_range.location)];
                current_model_object = [model_object valueForKeyPath:key_path];
                actual_field = [handle_field_name substringFromIndex:backwards_range.location + backwards_range.length];
                if (!current_model_object) {*stop = YES;}
            }
            int index = (int)[update_field_array indexOfObject:field] + 1;
            switch (property_info.type) {
                case FWDatabaseFieldTypeMutableDictionary:
                case FWDatabaseFieldTypeMutableArray: {
                    id value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = property_info.type == FWDatabaseFieldTypeMutableDictionary ? [NSMutableDictionary dictionary] : [NSMutableArray array];
                    }
                    @try {
                        NSData * set_value = [NSKeyedArchiver archivedDataWithRootObject:value];
                        sqlite3_bind_blob(pp_stmt, index, [set_value bytes], (int)[set_value length], SQLITE_TRANSIENT);
                    } @catch (NSException *exception) {
                        [self log:@"update 操作异常 Array/Dictionary 元素没实现NSCoding协议归档失败"];
                    }
                }
                    break;
                case FWDatabaseFieldTypeDictionary:
                case FWDatabaseFieldTypeArray: {
                    id value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = property_info.type == FWDatabaseFieldTypeDictionary ? [NSDictionary dictionary] : [NSArray array];
                    }
                    @try {
                        NSData * set_value = [NSKeyedArchiver archivedDataWithRootObject:value];
                        sqlite3_bind_blob(pp_stmt, index, [set_value bytes], (int)[set_value length], SQLITE_TRANSIENT);
                    } @catch (NSException *exception) {
                        [self log:@"update 操作异常 Array/Dictionary 元素没实现NSCoding协议归档失败"];
                    }
                }
                    break;
                case FWDatabaseFieldTypeDate: {
                    NSDate * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        sqlite3_bind_double(pp_stmt, index, 0.0);
                    }else {
                        sqlite3_bind_double(pp_stmt, index, [value timeIntervalSince1970]);
                    }
                }
                    break;
                case FWDatabaseFieldTypeData: {
                    NSData * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = [NSData data];
                    }
                    sqlite3_bind_blob(pp_stmt, index, [value bytes], (int)[value length], SQLITE_TRANSIENT);
                }
                    break;
                case FWDatabaseFieldTypeString: {
                    NSString * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = @"";
                    }
                    if ([value respondsToSelector:@selector(UTF8String)]) {
                        sqlite3_bind_text(pp_stmt, index, [value UTF8String], -1, SQLITE_TRANSIENT);
                    }else {
                        sqlite3_bind_text(pp_stmt, index, [[NSString stringWithFormat:@"%@",value] UTF8String], -1, SQLITE_TRANSIENT);
                    }
                }
                    break;
                case FWDatabaseFieldTypeNumber: {
                    NSNumber * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = @(0.0);
                    }
                    sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                }
                    break;
                case FWDatabaseFieldTypeInt: {
                    NSNumber * value = [current_model_object valueForKey:actual_field];
                    sqlite3_bind_int64(pp_stmt, index, (sqlite3_int64)[value longLongValue]);
                }
                    break;
                case FWDatabaseFieldTypeChar: {
                    char value = ((char (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, property_info.getter);
                    sqlite3_bind_int(pp_stmt, index, value);
                }
                    break;
                case FWDatabaseFieldTypeFloat: {
                    float value = ((float (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, property_info.getter);
                    sqlite3_bind_double(pp_stmt, index, value);
                }
                    break;
                case FWDatabaseFieldTypeDouble: {
                    double value = ((double (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, property_info.getter);
                    sqlite3_bind_double(pp_stmt, index, value);
                }
                    break;
                case FWDatabaseFieldTypeBoolean: {
                    BOOL value = ((BOOL (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, property_info.getter);
                    sqlite3_bind_int(pp_stmt, index, value);
                }
                    break;
                default:
                    break;
            }
        }];
        BOOL result = sqlite3_step(pp_stmt) == SQLITE_DONE;
        sqlite3_finalize(pp_stmt);
        [self close];
        return result;
    } else {
        [self log:@"更新失败"];
        [self close];
        return NO;
    }
}

+ (BOOL)update:(id)model_object where:(NSString *)where {
    BOOL result = YES;
    if (model_object && [self localNameWithModel:[model_object class]]) {
        dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
        @autoreleasepool {
            result = [self updateModel:model_object where:where];
        }
        dispatch_semaphore_signal([self shareInstance].dsema);
    }else {
        result = NO;
    }
    return result;
}

+ (BOOL)update:(Class)model_class value:(NSString *)value where:(NSString *)where {
    if (model_class == nil) return NO;
    BOOL result = YES;
    if ([self localNameWithModel:model_class]) {
        dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
        @autoreleasepool {
            if (value != nil && value.length > 0) {
                if ([self openTable:model_class]) {
                    NSString * table_name = [self getTableName:model_class];
                    NSString * update_sql = [NSString stringWithFormat:@"UPDATE %@ SET %@",table_name,value];
                    if (where != nil && where.length > 0) {
                        update_sql = [update_sql stringByAppendingFormat:@" WHERE %@", [self handleWhere:where]];
                    }
                    result = [self execSql:update_sql];
                    [self close];
                }else {
                    result = NO;
                }
            }else {
                result = NO;
            }
        }
        dispatch_semaphore_signal([self shareInstance].dsema);
    }else {
        result = NO;
    }
    return result;
}

+ (BOOL)clear:(Class)model_class {
    return [self delete:model_class where:nil];
}

+ (BOOL)delete:(id)model_object
{
    if (!model_object) return NO;
    Class model_class = [model_object class];
    NSString *primary_key = [self getPrimaryKeyWithClass:model_class];
    NSInteger primary_value = [self getPrimaryValueWithObject:model_object];
    if (primary_value <= 0) return NO;
    NSString *where = [NSString stringWithFormat:@"%@ = %ld", primary_key, (long)primary_value];
    return [self delete:model_class where:where];
}

+ (BOOL)commonDeleteModel:(Class)model_class where:(NSString *)where {
    BOOL result = YES;
    if ([self localNameWithModel:model_class]) {
        if ([self openTable:model_class]) {
            NSString * table_name = [self getTableName:model_class];
            NSString * delete_sql = [NSString stringWithFormat:@"DELETE FROM %@",table_name];
            if (where != nil && where.length > 0) {
                delete_sql = [delete_sql stringByAppendingFormat:@" WHERE %@",[self handleWhere:where]];
            }
            result = [self execSql:delete_sql];
            [self close];
        }else {
            result = NO;
        }
    }else {
        result = NO;
    }
    return result;
}

+ (BOOL)delete:(Class)model_class where:(NSString *)where {
    BOOL result = YES;
    dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        result = [self commonDeleteModel:model_class where:where];
    }
    dispatch_semaphore_signal([self shareInstance].dsema);
    return result;
}

+ (void)close {
    if (_fw_database) {
        sqlite3_close(_fw_database);
        _fw_database = nil;
    }
}

+ (void)removeAllModel {
    dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSFileManager * file_manager = [NSFileManager defaultManager];
        NSString * cache_path = [self databaseCacheDirectory: nil];
        BOOL is_directory = YES;
        if ([file_manager fileExistsAtPath:cache_path isDirectory:&is_directory]) {
            NSArray * file_array = [file_manager contentsOfDirectoryAtPath:cache_path error:nil];
            [file_array enumerateObjectsUsingBlock:^(id  _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![file isEqualToString:@".DS_Store"]) {
                    NSString * file_path = [NSString stringWithFormat:@"%@%@",cache_path,file];
                    [file_manager removeItemAtPath:file_path error:nil];
                    [self log:[NSString stringWithFormat:@"已经删除了数据库 ->%@",file_path]];
                }
            }];
        }
    }
    dispatch_semaphore_signal([self shareInstance].dsema);
}

+ (void)removeModel:(Class)model_class {
    dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSFileManager * file_manager = [NSFileManager defaultManager];
        NSString * file_path = [self localPathWithModel:model_class];
        if (file_path) {
            [file_manager removeItemAtPath:file_path error:nil];
        }
    }
    dispatch_semaphore_signal([self shareInstance].dsema);
}

+ (NSString *)commonLocalPathWithModel:(Class)model_class isPath:(BOOL)isPath {
    NSString * class_name = NSStringFromClass(model_class);
    NSFileManager * file_manager = [NSFileManager defaultManager];
    NSString * file_directory = [self databaseCacheDirectory: model_class];
    BOOL isDirectory = YES;
    __block NSString * file_path = nil;
    if ([file_manager fileExistsAtPath:file_directory isDirectory:&isDirectory]) {
        NSArray <NSString *> * file_name_array = [file_manager contentsOfDirectoryAtPath:file_directory error:nil];
        if (file_name_array != nil && file_name_array.count > 0) {
            [file_name_array enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj rangeOfString:[class_name stringByAppendingString:@"_v"]].location != NSNotFound) {
                    if (isPath) {
                        file_path = [NSString stringWithFormat:@"%@%@",file_directory,obj];
                    }else {
                        file_path = [obj mutableCopy];
                    }
                    *stop = YES;
                }
            }];
        }
    }
    return file_path;
}

+ (NSString *)localNameWithModel:(Class)model_class {
    return [self commonLocalPathWithModel:model_class isPath:NO];
}

+ (NSString *)localPathWithModel:(Class)model_class {
    return [self commonLocalPathWithModel:model_class isPath:YES];
}

+ (NSString *)versionWithModel:(Class)model_class {
    NSString * model_version = nil;
    NSString * model_name = [self localNameWithModel:model_class];
    if (model_name) {
        NSRange end_range = [model_name rangeOfString:@"." options:NSBackwardsSearch];
        NSRange start_range = [model_name rangeOfString:@"v" options:NSBackwardsSearch];
        if (end_range.location != NSNotFound &&
            start_range.location != NSNotFound) {
            model_version = [model_name substringWithRange:NSMakeRange(start_range.length + start_range.location, end_range.location - (start_range.length + start_range.location))];
        }
    }
    return model_version;
}

+ (void)log:(NSString *)msg {
    FWLogDebug(@"FWDatabase: [%@]", msg);
}

@end
