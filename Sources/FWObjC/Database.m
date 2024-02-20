//
//  Database.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "Database.h"
#import "ObjC.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <sqlite3.h>

@implementation FWDatabaseManager

+ (void)updateTableFieldWithModel:(Class)model_class
                       newVersion:(NSString *)newVersion
                   localModelName:(NSString *)local_model_name {
    @autoreleasepool {
        NSString * table_name = [self getTableName:model_class];
        NSString * cache_directory = [self databaseCacheDirectory: model_class];
        NSString * database_cache_path = [NSString stringWithFormat:@"%@%@",cache_directory,local_model_name];
        if (sqlite3_open([database_cache_path UTF8String], &_fw_database) == SQLITE_OK) {
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

+ (BOOL)openTable:(Class)model_class {
    NSString * cache_directory = [self autoHandleOldSqlite:model_class];
    NSString * version = [self exceSelector:@selector(databaseVersion) modelClass:model_class];
    if (!version || version.length == 0) { version = [self shareInstance].version; }
    if ([self shareInstance].check_update) {
        NSString * local_model_name = [self localNameWithModel:model_class];
        if (local_model_name != nil &&
            [local_model_name rangeOfString:version].location == NSNotFound) {
            [self updateTableFieldWithModel:model_class
                                 newVersion:version
                             localModelName:local_model_name];
            
            NSString *oldVersion = [self versionWithModelName:local_model_name];
            SEL selector = @selector(databaseMigration:);
            if (oldVersion.length > 0 && [model_class respondsToSelector:selector]) {
                [self shareInstance].is_migration = YES;
                IMP sqlite_info_func = [model_class methodForSelector:selector];
                void (*func)(id, SEL, NSString *) = (void *)sqlite_info_func;
                func(model_class, selector, oldVersion);
                [self shareInstance].is_migration = NO;
            }
        }
    }
    [self shareInstance].check_update = YES;
    NSString * database_cache_path = [NSString stringWithFormat:@"%@%@_v%@.sqlite",cache_directory,NSStringFromClass(model_class),version];
    if (sqlite3_open([database_cache_path UTF8String], &_fw_database) == SQLITE_OK) {
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

+ (id)query:(Class)model_class func:(NSString *)func condition:(NSString *)condition {
    if (![self localNameWithModel:model_class]) {return nil;}
    if (![self shareInstance].is_migration) {
        dispatch_semaphore_wait([self shareInstance].dsema, DISPATCH_TIME_FOREVER);
    }
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
    if (![self shareInstance].is_migration) {
        dispatch_semaphore_signal([self shareInstance].dsema);
    }
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

@end
