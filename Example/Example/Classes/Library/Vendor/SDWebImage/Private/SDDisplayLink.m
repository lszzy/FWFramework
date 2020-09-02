/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDDisplayLink.h"
#import <FWFramework/FWFramework.h>
#import <QuartzCore/QuartzCore.h>

#define kSDDisplayLinkInterval 1.0 / 60

@interface SDDisplayLink ()

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation SDDisplayLink

- (void)dealloc {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (instancetype)initWithTarget:(id)target selector:(SEL)sel {
    self = [super init];
    if (self) {
        _target = target;
        _selector = sel;
        FWWeakProxy *weakProxy = [FWWeakProxy proxyWithTarget:self];
        _displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(displayLinkDidRefresh:)];
    }
    return self;
}

+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)sel {
    SDDisplayLink *displayLink = [[SDDisplayLink alloc] initWithTarget:target selector:sel];
    return displayLink;
}

- (CFTimeInterval)duration {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSTimeInterval duration = self.displayLink.duration * self.displayLink.frameInterval;
#pragma clang diagnostic pop
    if (duration == 0) {
        duration = kSDDisplayLinkInterval;
    }
    return duration;
}

- (BOOL)isRunning {
    return !self.displayLink.isPaused;
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode {
    if  (!runloop || !mode) {
        return;
    }
    [self.displayLink addToRunLoop:runloop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode {
    if  (!runloop || !mode) {
        return;
    }
    [self.displayLink removeFromRunLoop:runloop forMode:mode];
}

- (void)start {
    self.displayLink.paused = NO;
}

- (void)stop {
    self.displayLink.paused = YES;
}

- (void)displayLinkDidRefresh:(id)displayLink {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
}

@end
