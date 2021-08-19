/*!
 @header     Icon.h
 @indexgroup Example
 @brief      Icon
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import <FWFramework/FWFramework.h>

NS_ASSUME_NONNULL_BEGIN

@interface Octicons : FWIcon

@end

@interface MaterialIcons : FWIcon

@end

@interface FontAwesome : FWIcon

@end

@interface FoundationIcons : FWIcon

@end

@interface IonIcons : FWIcon

@end

@interface FWIcon (Core)

@property (class, nonatomic, strong, readonly, nullable) UIImage *refreshImage;
@property (class, nonatomic, strong, readonly, nullable) UIImage *playImage;
@property (class, nonatomic, strong, readonly, nullable) UIImage *stopImage;
@property (class, nonatomic, strong, readonly, nullable) UIImage *actionImage;
@property (class, nonatomic, strong, readonly, nullable) UIImage *addImage;
@property (class, nonatomic, strong, readonly, nullable) UIImage *backImage;
@property (class, nonatomic, strong, readonly, nullable) UIImage *closeImage;

@end

NS_ASSUME_NONNULL_END
