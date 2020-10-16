//
//  FWRequestEventAccessory.h
//  FWNetwork
//
//  Created by Chuanren Shang on 2020/8/17.
//

#import "FWBaseRequest.h"
#import "FWBatchRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWRequestEventAccessory : NSObject <FWRequestAccessory>

@property (nonatomic, copy, nullable) void (^willStartBlock)(id);
@property (nonatomic, copy, nullable) void (^willStopBlock)(id);
@property (nonatomic, copy, nullable) void (^didStopBlock)(id);

@end

@interface FWBaseRequest (FWRequestEventAccessory)

- (void)startWithWillStart:(nullable FWRequestCompletionBlock)willStart
                  willStop:(nullable FWRequestCompletionBlock)willStop
                   success:(nullable FWRequestCompletionBlock)success
                   failure:(nullable FWRequestCompletionBlock)failure
                   didStop:(nullable FWRequestCompletionBlock)didStop;

@end

@interface FWBatchRequest (FWRequestEventAccessory)

- (void)startWithWillStart:(nullable void (^)(FWBatchRequest *batchRequest))willStart
                  willStop:(nullable void (^)(FWBatchRequest *batchRequest))willStop
                   success:(nullable void (^)(FWBatchRequest *batchRequest))success
                   failure:(nullable void (^)(FWBatchRequest *batchRequest))failure
                   didStop:(nullable void (^)(FWBatchRequest *batchRequest))didStop;

@end

NS_ASSUME_NONNULL_END
