/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <FWFramework/FWFramework.h>

#if APP_TARGET == 2

/**
 Built in coder that supports WebP and animated WebP
 */
@interface FWImageWebPCoder : NSObject <FWProgressiveImageCoder, FWAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) FWImageWebPCoder *sharedCoder;

@end

#endif
