//
//  FWBlock.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWBlock

/**
 通用不带参数block
 */
typedef void (^FWBlockVoid)(void) NS_SWIFT_UNAVAILABLE("");

/**
 通用id参数block
 
 @param param id参数
 */
typedef void (^FWBlockParam)(id _Nullable param) NS_SWIFT_UNAVAILABLE("");

/**
 通用bool参数block
 
 @param isTrue bool参数
 */
typedef void (^FWBlockBool)(BOOL isTrue) NS_SWIFT_UNAVAILABLE("");

/**
 通用NSInteger参数block
 
 @param index NSInteger参数
 */
typedef void (^FWBlockInt)(NSInteger index) NS_SWIFT_UNAVAILABLE("");

/**
 通用double参数block
 
 @param value double参数
 */
typedef void (^FWBlockDouble)(double value) NS_SWIFT_UNAVAILABLE("");

/**
 通用(BOOL,id)参数block
 
 @param isTrue BOOL参数
 @param param id参数
 */
typedef void (^FWBlockBoolParam)(BOOL isTrue, id _Nullable param) NS_SWIFT_UNAVAILABLE("");

/**
 通用(NSInteger,id)参数block
 
 @param index NSInteger参数
 @param param id参数
 */
typedef void (^FWBlockIntParam)(NSInteger index, id _Nullable param) NS_SWIFT_UNAVAILABLE("");

NS_ASSUME_NONNULL_END
