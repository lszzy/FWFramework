/*!
 @header     FWViewModel.h
 @indexgroup FWFramework
 @brief      FWViewModel
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/10/11
 */

#import <Foundation/Foundation.h>

/*!
@brief MVVM架构ViewModel层协议
@discussion 建议Controller持有ViewModel，ViewModel不持有Controller和View，可视情况暴露DataModel(Entity)给Controller和View。Controller和View可使用RAC监听ViewModel，也可调用ViewModel方法并回调即可
*/
@protocol FWViewModel <NSObject>

@end
