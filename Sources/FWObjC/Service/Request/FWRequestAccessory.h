//
//  FWRequestAccessory.h
//  FWNetwork
//
//  Created by Chuanren Shang on 2020/8/17.
//

#import "FWBaseRequest.h"
#import "FWBatchRequest.h"
#import "FWChainRequest.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RequestAccessory)
@interface FWRequestAccessory : NSObject <FWRequestAccessory>

@property (nonatomic, copy, nullable) void (^willStartBlock)(id);
@property (nonatomic, copy, nullable) void (^willStopBlock)(id);
@property (nonatomic, copy, nullable) void (^didStopBlock)(id);

@end

@interface FWBaseRequest (FWRequestAccessory)

- (void)startWithWillStart:(nullable FWRequestCompletionBlock)willStart
                  willStop:(nullable FWRequestCompletionBlock)willStop
                   success:(nullable FWRequestCompletionBlock)success
                   failure:(nullable FWRequestCompletionBlock)failure
                   didStop:(nullable FWRequestCompletionBlock)didStop;

@end

@interface FWBatchRequest (FWRequestAccessory)

- (void)startWithWillStart:(nullable void (^)(FWBatchRequest *batchRequest))willStart
                  willStop:(nullable void (^)(FWBatchRequest *batchRequest))willStop
                   success:(nullable void (^)(FWBatchRequest *batchRequest))success
                   failure:(nullable void (^)(FWBatchRequest *batchRequest))failure
                   didStop:(nullable void (^)(FWBatchRequest *batchRequest))didStop;

@end

@interface FWChainRequest (FWRequestAccessory)

- (void)startWithWillStart:(nullable void (^)(FWChainRequest *chainRequest))willStart
                  willStop:(nullable void (^)(FWChainRequest *chainRequest))willStop
                   success:(nullable void (^)(FWChainRequest *chainRequest))success
                   failure:(nullable void (^)(FWChainRequest *chainRequest))failure
                   didStop:(nullable void (^)(FWChainRequest *chainRequest))didStop;

@end

NS_ASSUME_NONNULL_END
