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
