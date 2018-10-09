// FWNetworkActivityIndicatorManager.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "FWNetworkActivityIndicatorManager.h"

#if TARGET_OS_IOS
#import "FWURLSessionManager.h"

typedef NS_ENUM(NSInteger, FWNetworkActivityManagerState) {
    FWNetworkActivityManagerStateNotActive,
    FWNetworkActivityManagerStateDelayingStart,
    FWNetworkActivityManagerStateActive,
    FWNetworkActivityManagerStateDelayingEnd
};

static NSTimeInterval const kDefaultFWNetworkActivityManagerActivationDelay = 1.0;
static NSTimeInterval const kDefaultFWNetworkActivityManagerCompletionDelay = 0.17;

static NSURLRequest * FWNetworkRequestFromNotification(NSNotification *notification) {
    if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        return [(NSURLSessionTask *)[notification object] originalRequest];
    } else {
        return nil;
    }
}

typedef void (^FWNetworkActivityActionBlock)(BOOL networkActivityIndicatorVisible);

@interface FWNetworkActivityIndicatorManager ()
@property (readwrite, nonatomic, assign) NSInteger activityCount;
@property (readwrite, nonatomic, strong) NSTimer *activationDelayTimer;
@property (readwrite, nonatomic, strong) NSTimer *completionDelayTimer;
@property (readonly, nonatomic, getter = isNetworkActivityOccurring) BOOL networkActivityOccurring;
@property (nonatomic, copy) FWNetworkActivityActionBlock networkActivityActionBlock;
@property (nonatomic, assign) FWNetworkActivityManagerState currentState;
@property (nonatomic, assign, getter=isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;

- (void)updateCurrentStateForNetworkActivityChange;
@end

@implementation FWNetworkActivityIndicatorManager

+ (instancetype)sharedManager {
    static FWNetworkActivityIndicatorManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.currentState = FWNetworkActivityManagerStateNotActive;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:FWNetworkingTaskDidResumeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:FWNetworkingTaskDidSuspendNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:FWNetworkingTaskDidCompleteNotification object:nil];
    self.activationDelay = kDefaultFWNetworkActivityManagerActivationDelay;
    self.completionDelay = kDefaultFWNetworkActivityManagerCompletionDelay;

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_activationDelayTimer invalidate];
    [_completionDelayTimer invalidate];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if (enabled == NO) {
        [self setCurrentState:FWNetworkActivityManagerStateNotActive];
    }
}

- (void)setNetworkingActivityActionWithBlock:(void (^)(BOOL networkActivityIndicatorVisible))block {
    self.networkActivityActionBlock = block;
}

- (BOOL)isNetworkActivityOccurring {
    @synchronized(self) {
        return self.activityCount > 0;
    }
}

- (void)setNetworkActivityIndicatorVisible:(BOOL)networkActivityIndicatorVisible {
    if (_networkActivityIndicatorVisible != networkActivityIndicatorVisible) {
        [self willChangeValueForKey:@"networkActivityIndicatorVisible"];
        @synchronized(self) {
             _networkActivityIndicatorVisible = networkActivityIndicatorVisible;
        }
        [self didChangeValueForKey:@"networkActivityIndicatorVisible"];
        if (self.networkActivityActionBlock) {
            self.networkActivityActionBlock(networkActivityIndicatorVisible);
        } else {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
        }
    }
}

- (void)setActivityCount:(NSInteger)activityCount {
	@synchronized(self) {
		_activityCount = activityCount;
	}

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentStateForNetworkActivityChange];
    });
}

- (void)incrementActivityCount {
    [self willChangeValueForKey:@"activityCount"];
	@synchronized(self) {
		_activityCount++;
	}
    [self didChangeValueForKey:@"activityCount"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentStateForNetworkActivityChange];
    });
}

- (void)decrementActivityCount {
    [self willChangeValueForKey:@"activityCount"];
	@synchronized(self) {
		_activityCount = MAX(_activityCount - 1, 0);
	}
    [self didChangeValueForKey:@"activityCount"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentStateForNetworkActivityChange];
    });
}

- (void)networkRequestDidStart:(NSNotification *)notification {
    if ([FWNetworkRequestFromNotification(notification) URL]) {
        [self incrementActivityCount];
    }
}

- (void)networkRequestDidFinish:(NSNotification *)notification {
    if ([FWNetworkRequestFromNotification(notification) URL]) {
        [self decrementActivityCount];
    }
}

#pragma mark - Internal State Management
- (void)setCurrentState:(FWNetworkActivityManagerState)currentState {
    @synchronized(self) {
        if (_currentState != currentState) {
            [self willChangeValueForKey:@"currentState"];
            _currentState = currentState;
            switch (currentState) {
                case FWNetworkActivityManagerStateNotActive:
                    [self cancelActivationDelayTimer];
                    [self cancelCompletionDelayTimer];
                    [self setNetworkActivityIndicatorVisible:NO];
                    break;
                case FWNetworkActivityManagerStateDelayingStart:
                    [self startActivationDelayTimer];
                    break;
                case FWNetworkActivityManagerStateActive:
                    [self cancelCompletionDelayTimer];
                    [self setNetworkActivityIndicatorVisible:YES];
                    break;
                case FWNetworkActivityManagerStateDelayingEnd:
                    [self startCompletionDelayTimer];
                    break;
            }
            [self didChangeValueForKey:@"currentState"];
        }
        
    }
}

- (void)updateCurrentStateForNetworkActivityChange {
    if (self.enabled) {
        switch (self.currentState) {
            case FWNetworkActivityManagerStateNotActive:
                if (self.isNetworkActivityOccurring) {
                    [self setCurrentState:FWNetworkActivityManagerStateDelayingStart];
                }
                break;
            case FWNetworkActivityManagerStateDelayingStart:
                //No op. Let the delay timer finish out.
                break;
            case FWNetworkActivityManagerStateActive:
                if (!self.isNetworkActivityOccurring) {
                    [self setCurrentState:FWNetworkActivityManagerStateDelayingEnd];
                }
                break;
            case FWNetworkActivityManagerStateDelayingEnd:
                if (self.isNetworkActivityOccurring) {
                    [self setCurrentState:FWNetworkActivityManagerStateActive];
                }
                break;
        }
    }
}

- (void)startActivationDelayTimer {
    self.activationDelayTimer = [NSTimer
                                 timerWithTimeInterval:self.activationDelay target:self selector:@selector(activationDelayTimerFired) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.activationDelayTimer forMode:NSRunLoopCommonModes];
}

- (void)activationDelayTimerFired {
    if (self.networkActivityOccurring) {
        [self setCurrentState:FWNetworkActivityManagerStateActive];
    } else {
        [self setCurrentState:FWNetworkActivityManagerStateNotActive];
    }
}

- (void)startCompletionDelayTimer {
    [self.completionDelayTimer invalidate];
    self.completionDelayTimer = [NSTimer timerWithTimeInterval:self.completionDelay target:self selector:@selector(completionDelayTimerFired) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.completionDelayTimer forMode:NSRunLoopCommonModes];
}

- (void)completionDelayTimerFired {
    [self setCurrentState:FWNetworkActivityManagerStateNotActive];
}

- (void)cancelActivationDelayTimer {
    [self.activationDelayTimer invalidate];
}

- (void)cancelCompletionDelayTimer {
    [self.completionDelayTimer invalidate];
}

@end

#endif
