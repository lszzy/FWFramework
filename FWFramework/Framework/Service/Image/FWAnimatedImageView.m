/*!
 @header     FWAnimatedImageView.m
 @indexgroup FWFramework
 @brief      FWAnimatedImageView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/27
 */

#import "FWAnimatedImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "FWProxy.h"
#import <mach/mach.h>

#ifndef SD_LOCK
#define SD_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef SD_UNLOCK
#define SD_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

@interface FWAnimatedImageView () <CALayerDelegate> {
    BOOL _initFinished; // Extra flag to mark the `commonInit` is called
    NSRunLoopMode _runLoopMode;
    NSUInteger _maxBufferSize;
    double _playbackRate;
}

@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;
@property (nonatomic, assign, readwrite) NSUInteger currentLoopCount;
@property (nonatomic, assign) BOOL shouldAnimate;
@property (nonatomic, assign) BOOL isProgressive;
@property (nonatomic,strong) FWAnimatedImagePlayer *player; // The animation player.
@property (nonatomic) CALayer *imageViewLayer; // The actual rendering layer.

@end

@implementation FWAnimatedImageView

@dynamic animationRepeatCount; // we re-use this property from `UIImageView` super class on iOS.

#pragma mark - Initializers

// -initWithImage: isn't documented as a designated initializer of UIImageView, but it actually seems to be.
// Using -initWithImage: doesn't call any of the other designated initializers.
- (instancetype)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        [self commonInit];
    }
    return self;
}

// -initWithImage:highlightedImage: also isn't documented as a designated initializer of UIImageView, but it doesn't call any other designated initializers.
- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    // Pay attention that UIKit's `initWithImage:` will trigger a `setImage:` during initialization before this `commonInit`.
    // So the properties which rely on this order, should using lazy-evaluation or do extra check in `setImage:`.
    self.shouldCustomLoopCount = NO;
    self.shouldIncrementalLoad = YES;
    self.playbackRate = 1.0;
    // Mark commonInit finished
    _initFinished = YES;
}

#pragma mark - Accessors
#pragma mark Public

- (void)setImage:(UIImage *)image
{
    if (self.image == image) {
        return;
    }
    
    // Check Progressive rendering
    [self updateIsProgressiveWithImage:image];
    
    if (!self.isProgressive) {
        // Stop animating
        self.player = nil;
        self.currentFrame = nil;
        self.currentFrameIndex = 0;
        self.currentLoopCount = 0;
    }
    
    // We need call super method to keep function. This will impliedly call `setNeedsDisplay`. But we have no way to avoid this when using animated image. So we call `setNeedsDisplay` again at the end.
    super.image = image;
    if ([image.class conformsToProtocol:@protocol(FWAnimatedImage)]) {
        if (!self.player) {
            id<FWAnimatedImageProvider> provider;
            // Check progressive loading
            if (self.isProgressive) {
                provider = [self progressiveAnimatedCoderForImage:image];
            } else {
                provider = (id<FWAnimatedImage>)image;
            }
            // Create animted player
            self.player = [FWAnimatedImagePlayer playerWithProvider:provider];
        } else {
            // Update Frame Count
            self.player.totalFrameCount = [(id<FWAnimatedImage>)image animatedImageFrameCount];
        }
        
        if (!self.player) {
            // animated player nil means the image format is not supported, or frame count <= 1
            return;
        }
        
        // Custom Loop Count
        if (self.shouldCustomLoopCount) {
            self.player.totalLoopCount = self.animationRepeatCount;
        }
        
        // RunLoop Mode
        self.player.runLoopMode = self.runLoopMode;
        
        // Max Buffer Size
        self.player.maxBufferSize = self.maxBufferSize;
        
        // Play Rate
        self.player.playbackRate = self.playbackRate;
        
        // Setup handler
        __weak __typeof__(self) self_weak_ = self;
        self.player.animationFrameHandler = ^(NSUInteger index, UIImage * frame) {
            __typeof__(self) self = self_weak_;
            self.currentFrameIndex = index;
            self.currentFrame = frame;
            [self.imageViewLayer setNeedsDisplay];
        };
        self.player.animationLoopHandler = ^(NSUInteger loopCount) {
            __typeof__(self) self = self_weak_;
            // Progressive image reach the current last frame index. Keep the state and pause animating. Wait for later restart
            if (self.isProgressive) {
                NSUInteger lastFrameIndex = self.player.totalFrameCount - 1;
                [self.player seekToFrameAtIndex:lastFrameIndex loopCount:0];
                [self.player pausePlaying];
            } else {
                self.currentLoopCount = loopCount;
            }
        };
        
        // Ensure disabled highlighting; it's not supported (see `-setHighlighted:`).
        super.highlighted = NO;
        
        // Start animating
        [self startAnimating];

        [self.imageViewLayer setNeedsDisplay];
    }
}

#pragma mark - Configuration

- (void)setRunLoopMode:(NSRunLoopMode)runLoopMode
{
    _runLoopMode = [runLoopMode copy];
    self.player.runLoopMode = runLoopMode;
}

- (NSRunLoopMode)runLoopMode
{
    if (!_runLoopMode) {
        _runLoopMode = [[self class] defaultRunLoopMode];
    }
    return _runLoopMode;
}

+ (NSString *)defaultRunLoopMode {
    // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}

- (void)setMaxBufferSize:(NSUInteger)maxBufferSize
{
    _maxBufferSize = maxBufferSize;
    self.player.maxBufferSize = maxBufferSize;
}

- (NSUInteger)maxBufferSize {
    return _maxBufferSize; // Defaults to 0
}

- (void)setPlaybackRate:(double)playbackRate
{
    _playbackRate = playbackRate;
    self.player.playbackRate = playbackRate;
}

- (double)playbackRate
{
    if (!_initFinished) {
        return 1.0; // Defaults to 1.0
    }
    return _playbackRate;
}

- (BOOL)shouldIncrementalLoad
{
    if (!_initFinished) {
        return YES; // Defaults to YES
    }
    return _initFinished;
}

#pragma mark - UIView Method Overrides
#pragma mark Observing View-Related Changes

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

#pragma mark - UIImageView Method Overrides
#pragma mark Image Data

- (void)setAnimationRepeatCount:(NSInteger)animationRepeatCount
{
    [super setAnimationRepeatCount:animationRepeatCount];
    
    if (self.shouldCustomLoopCount) {
        self.player.totalLoopCount = animationRepeatCount;
    }
}

- (void)startAnimating
{
    if (self.player) {
        [self updateShouldAnimate];
        if (self.shouldAnimate) {
            [self.player startPlaying];
        }
    } else {
        [super startAnimating];
    }
}

- (void)stopAnimating
{
    if (self.player) {
        if (self.resetFrameIndexWhenStopped) {
            [self.player stopPlaying];
        } else {
            [self.player pausePlaying];
        }
        if (self.clearBufferWhenStopped) {
            [self.player clearFrameBuffer];
        }
    } else {
        [super stopAnimating];
    }
}

- (BOOL)isAnimating
{
    if (self.player) {
        return self.player.isPlaying;
    } else {
        return [super isAnimating];
    }
}

#pragma mark Highlighted Image Unsupport

- (void)setHighlighted:(BOOL)highlighted
{
    // Highlighted image is unsupported for animated images, but implementing it breaks the image view when embedded in a UICollectionViewCell.
    if (!self.player) {
        [super setHighlighted:highlighted];
    }
}


#pragma mark - Private Methods
#pragma mark Animation

// Don't repeatedly check our window & superview in `-displayDidRefresh:` for performance reasons.
// Just update our cached value whenever the animated image or visibility (window, superview, hidden, alpha) is changed.
- (void)updateShouldAnimate
{
    BOOL isVisible = self.window && self.superview && ![self isHidden] && self.alpha > 0.0;
    self.shouldAnimate = self.player && isVisible;
}

// Update progressive status only after `setImage:` call.
- (void)updateIsProgressiveWithImage:(UIImage *)image
{
    self.isProgressive = NO;
    if (!self.shouldIncrementalLoad) {
        // Early return
        return;
    }
    // We must use `image.class conformsToProtocol:` instead of `image conformsToProtocol:` here
    // Because UIKit on macOS, using internal hard-coded override method, which returns NO
    id<FWAnimatedImageCoder> currentAnimatedCoder = [self progressiveAnimatedCoderForImage:image];
    if (currentAnimatedCoder) {
        UIImage *previousImage = self.image;
        if (!previousImage) {
            // If current animated coder supports progressive, and no previous image to check, start progressive loading
            self.isProgressive = YES;
        } else {
            id<FWAnimatedImageCoder> previousAnimatedCoder = [self progressiveAnimatedCoderForImage:previousImage];
            if (previousAnimatedCoder == currentAnimatedCoder) {
                // If current animated coder is the same as previous, start progressive loading
                self.isProgressive = YES;
            }
        }
    }
}

// Check if image can represent a `Progressive Animated Image` during loading
- (id<FWAnimatedImageCoder, FWProgressiveImageCoder>)progressiveAnimatedCoderForImage:(UIImage *)image
{
    if ([image.class conformsToProtocol:@protocol(FWAnimatedImage)] && image.fw_isIncremental && [image respondsToSelector:@selector(animatedCoder)]) {
        id<FWAnimatedImageCoder> animatedCoder = [(id<FWAnimatedImage>)image animatedCoder];
        if ([animatedCoder conformsToProtocol:@protocol(FWProgressiveImageCoder)]) {
            return (id<FWAnimatedImageCoder, FWProgressiveImageCoder>)animatedCoder;
        }
    }
    return nil;
}


#pragma mark Providing the Layer's Content
#pragma mark - CALayerDelegate

- (void)displayLayer:(CALayer *)layer
{
    UIImage *currentFrame = self.currentFrame;
    if (currentFrame) {
        layer.contentsScale = currentFrame.scale;
        layer.contents = (__bridge id)currentFrame.CGImage;
    }
}

// on iOS, it's the imageView itself's layer
- (CALayer *)imageViewLayer {
    return self.layer;
}

@end

@interface SDDisplayLink : NSObject

@property (readonly, nonatomic, weak, nullable) id target;
@property (readonly, nonatomic, assign, nonnull) SEL selector;
@property (readonly, nonatomic) CFTimeInterval duration;
@property (readonly, nonatomic) BOOL isRunning;

+ (nonnull instancetype)displayLinkWithTarget:(nonnull id)target selector:(nonnull SEL)sel;

- (void)addToRunLoop:(nonnull NSRunLoop *)runloop forMode:(nonnull NSRunLoopMode)mode;
- (void)removeFromRunLoop:(nonnull NSRunLoop *)runloop forMode:(nonnull NSRunLoopMode)mode;

- (void)start;
- (void)stop;

@end

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

@interface SDDeviceHelper : NSObject

+ (NSUInteger)totalMemory;
+ (NSUInteger)freeMemory;

@end

@implementation SDDeviceHelper

+ (NSUInteger)totalMemory {
    return (NSUInteger)[[NSProcessInfo processInfo] physicalMemory];
}

+ (NSUInteger)freeMemory {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return 0;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return 0;
    return vm_stat.free_count * page_size;
}

@end

@interface FWAnimatedImagePlayer () {
    NSRunLoopMode _runLoopMode;
}

@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;
@property (nonatomic, assign, readwrite) NSUInteger currentLoopCount;
@property (nonatomic, strong) id<FWAnimatedImageProvider> animatedProvider;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *frameBuffer;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) BOOL bufferMiss;
@property (nonatomic, assign) BOOL needsDisplayWhenImageBecomesAvailable;
@property (nonatomic, assign) NSUInteger maxBufferCount;
@property (nonatomic, strong) NSOperationQueue *fetchQueue;
@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, strong) SDDisplayLink *displayLink;

@end

@implementation FWAnimatedImagePlayer

- (instancetype)initWithProvider:(id<FWAnimatedImageProvider>)provider {
    self = [super init];
    if (self) {
        NSUInteger animatedImageFrameCount = provider.animatedImageFrameCount;
        // Check the frame count
        if (animatedImageFrameCount <= 1) {
            return nil;
        }
        self.totalFrameCount = animatedImageFrameCount;
        // Get the current frame and loop count.
        self.totalLoopCount = provider.animatedImageLoopCount;
        self.animatedProvider = provider;
        self.playbackRate = 1.0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

+ (instancetype)playerWithProvider:(id<FWAnimatedImageProvider>)provider {
    FWAnimatedImagePlayer *player = [[FWAnimatedImagePlayer alloc] initWithProvider:provider];
    return player;
}

#pragma mark - Life Cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [_fetchQueue cancelAllOperations];
    [_fetchQueue addOperationWithBlock:^{
        NSNumber *currentFrameIndex = @(self.currentFrameIndex);
        SD_LOCK(self.lock);
        NSArray *keys = self.frameBuffer.allKeys;
        // only keep the next frame for later rendering
        for (NSNumber * key in keys) {
            if (![key isEqualToNumber:currentFrameIndex]) {
                [self.frameBuffer removeObjectForKey:key];
            }
        }
        SD_UNLOCK(self.lock);
    }];
}

#pragma mark - Private
- (NSOperationQueue *)fetchQueue {
    if (!_fetchQueue) {
        _fetchQueue = [[NSOperationQueue alloc] init];
        _fetchQueue.maxConcurrentOperationCount = 1;
    }
    return _fetchQueue;
}

- (NSMutableDictionary<NSNumber *,UIImage *> *)frameBuffer {
    if (!_frameBuffer) {
        _frameBuffer = [NSMutableDictionary dictionary];
    }
    return _frameBuffer;
}

- (dispatch_semaphore_t)lock {
    if (!_lock) {
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

- (SDDisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [SDDisplayLink displayLinkWithTarget:self selector:@selector(displayDidRefresh:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
        [_displayLink stop];
    }
    return _displayLink;
}

- (void)setRunLoopMode:(NSRunLoopMode)runLoopMode {
    if ([_runLoopMode isEqual:runLoopMode]) {
        return;
    }
    if (_displayLink) {
        if (_runLoopMode) {
            [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_runLoopMode];
        }
        if (runLoopMode.length > 0) {
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:runLoopMode];
        }
    }
    _runLoopMode = [runLoopMode copy];
}

- (NSRunLoopMode)runLoopMode {
    if (!_runLoopMode) {
        _runLoopMode = [[self class] defaultRunLoopMode];
    }
    return _runLoopMode;
}

#pragma mark - State Control

- (void)setupCurrentFrame {
    if (self.currentFrameIndex != 0) {
        return;
    }
    if ([self.animatedProvider isKindOfClass:[UIImage class]]) {
        UIImage *image = (UIImage *)self.animatedProvider;
        // Use the poster image if available
        #if SD_MAC
        UIImage *posterFrame = [[NSImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:kCGImagePropertyOrientationUp];
        #else
        UIImage *posterFrame = [[UIImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:image.imageOrientation];
        #endif
        if (posterFrame) {
            self.currentFrame = posterFrame;
            SD_LOCK(self.lock);
            self.frameBuffer[@(self.currentFrameIndex)] = self.currentFrame;
            SD_UNLOCK(self.lock);
            [self handleFrameChange];
        }
    }
}

- (void)resetCurrentFrameIndex {
    self.currentFrame = nil;
    self.currentFrameIndex = 0;
    self.currentLoopCount = 0;
    self.currentTime = 0;
    self.bufferMiss = NO;
    self.needsDisplayWhenImageBecomesAvailable = NO;
    [self handleFrameChange];
}

- (void)clearFrameBuffer {
    SD_LOCK(self.lock);
    [_frameBuffer removeAllObjects];
    SD_UNLOCK(self.lock);
}

#pragma mark - Animation Control
- (void)startPlaying {
    [self.displayLink start];
    // Calculate max buffer size
    [self calculateMaxBufferCount];
    // Setup frame
    if (self.currentFrameIndex == 0 && !self.currentFrame) {
        [self setupCurrentFrame];
    }
}

- (void)stopPlaying {
    [_fetchQueue cancelAllOperations];
    // Using `_displayLink` here because when UIImageView dealloc, it may trigger `[self stopAnimating]`, we already release the display link in FWAnimatedImageView's dealloc method.
    [_displayLink stop];
    [self resetCurrentFrameIndex];
}

- (void)pausePlaying {
    [_fetchQueue cancelAllOperations];
    [_displayLink stop];
}

- (BOOL)isPlaying {
    return _displayLink.isRunning;
}

- (void)seekToFrameAtIndex:(NSUInteger)index loopCount:(NSUInteger)loopCount {
    if (index >= self.totalFrameCount) {
        return;
    }
    self.currentFrameIndex = index;
    self.currentLoopCount = loopCount;
    [self handleFrameChange];
}

#pragma mark - Core Render
- (void)displayDidRefresh:(SDDisplayLink *)displayLink {
    // If for some reason a wild call makes it through when we shouldn't be animating, bail.
    // Early return!
    if (!self.isPlaying) {
        return;
    }
    
    NSUInteger totalFrameCount = self.totalFrameCount;
    if (totalFrameCount <= 1) {
        // Total frame count less than 1, wrong configuration and stop animating
        [self stopPlaying];
        return;
    }
    
    NSTimeInterval playbackRate = self.playbackRate;
    if (playbackRate <= 0) {
        // Does not support <= 0 play rate
        [self stopPlaying];
        return;
    }
    
    // Calculate refresh duration
    NSTimeInterval duration = self.displayLink.duration;
    
    NSUInteger currentFrameIndex = self.currentFrameIndex;
    NSUInteger nextFrameIndex = (currentFrameIndex + 1) % totalFrameCount;
    
    // Check if we need to display new frame firstly
    BOOL bufferFull = NO;
    if (self.needsDisplayWhenImageBecomesAvailable) {
        UIImage *currentFrame;
        SD_LOCK(self.lock);
        currentFrame = self.frameBuffer[@(currentFrameIndex)];
        SD_UNLOCK(self.lock);
        
        // Update the current frame
        if (currentFrame) {
            SD_LOCK(self.lock);
            // Remove the frame buffer if need
            if (self.frameBuffer.count > self.maxBufferCount) {
                self.frameBuffer[@(currentFrameIndex)] = nil;
            }
            // Check whether we can stop fetch
            if (self.frameBuffer.count == totalFrameCount) {
                bufferFull = YES;
            }
            SD_UNLOCK(self.lock);
            
            // Update the current frame immediately
            self.currentFrame = currentFrame;
            [self handleFrameChange];
            
            self.bufferMiss = NO;
            self.needsDisplayWhenImageBecomesAvailable = NO;
        }
        else {
            self.bufferMiss = YES;
        }
    }
    
    // Check if we have the frame buffer
    if (!self.bufferMiss) {
        // Then check if timestamp is reached
        self.currentTime += duration;
        NSTimeInterval currentDuration = [self.animatedProvider animatedImageDurationAtIndex:currentFrameIndex];
        currentDuration = currentDuration / playbackRate;
        if (self.currentTime < currentDuration) {
            // Current frame timestamp not reached, return
            return;
        }
        
        // Otherwise, we shoudle be ready to display next frame
        self.needsDisplayWhenImageBecomesAvailable = YES;
        self.currentFrameIndex = nextFrameIndex;
        self.currentTime -= currentDuration;
        NSTimeInterval nextDuration = [self.animatedProvider animatedImageDurationAtIndex:nextFrameIndex];
        nextDuration = nextDuration / playbackRate;
        if (self.currentTime > nextDuration) {
            // Do not skip frame
            self.currentTime = nextDuration;
        }
        
        // Update the loop count when last frame rendered
        if (nextFrameIndex == 0) {
            // Update the loop count
            self.currentLoopCount++;
            [self handleLoopChnage];
            
            // if reached the max loop count, stop animating, 0 means loop indefinitely
            NSUInteger maxLoopCount = self.totalLoopCount;
            if (maxLoopCount != 0 && (self.currentLoopCount >= maxLoopCount)) {
                [self stopPlaying];
                return;
            }
        }
    }
    
    // Since we support handler, check animating state again
    if (!self.isPlaying) {
        return;
    }
    
    // Check if we should prefetch next frame or current frame
    // When buffer miss, means the decode speed is slower than render speed, we fetch current miss frame
    // Or, most cases, the decode speed is faster than render speed, we fetch next frame
    NSUInteger fetchFrameIndex = self.bufferMiss? currentFrameIndex : nextFrameIndex;
    UIImage *fetchFrame;
    SD_LOCK(self.lock);
    fetchFrame = self.bufferMiss? nil : self.frameBuffer[@(nextFrameIndex)];
    SD_UNLOCK(self.lock);
    
    if (!fetchFrame && !bufferFull && self.fetchQueue.operationCount == 0) {
        // Prefetch next frame in background queue
        id<FWAnimatedImageProvider> animatedProvider = self.animatedProvider;
        __weak __typeof__(self) self_weak_ = self;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            __typeof__(self) self = self_weak_;
            if (!self) {
                return;
            }
            UIImage *frame = [animatedProvider animatedImageFrameAtIndex:fetchFrameIndex];

            BOOL isAnimating = self.displayLink.isRunning;
            if (isAnimating) {
                SD_LOCK(self.lock);
                self.frameBuffer[@(fetchFrameIndex)] = frame;
                SD_UNLOCK(self.lock);
            }
        }];
        [self.fetchQueue addOperation:operation];
    }
}

- (void)handleFrameChange {
    if (self.animationFrameHandler) {
        self.animationFrameHandler(self.currentFrameIndex, self.currentFrame);
    }
}

- (void)handleLoopChnage {
    if (self.animationLoopHandler) {
        self.animationLoopHandler(self.currentLoopCount);
    }
}

#pragma mark - Util
- (void)calculateMaxBufferCount {
    NSUInteger bytes = CGImageGetBytesPerRow(self.currentFrame.CGImage) * CGImageGetHeight(self.currentFrame.CGImage);
    if (bytes == 0) bytes = 1024;
    
    NSUInteger max = 0;
    if (self.maxBufferSize > 0) {
        max = self.maxBufferSize;
    } else {
        // Calculate based on current memory, these factors are by experience
        NSUInteger total = [SDDeviceHelper totalMemory];
        NSUInteger free = [SDDeviceHelper freeMemory];
        max = MIN(total * 0.2, free * 0.6);
    }
    
    NSUInteger maxBufferCount = (double)max / (double)bytes;
    if (!maxBufferCount) {
        // At least 1 frame
        maxBufferCount = 1;
    }
    
    self.maxBufferCount = maxBufferCount;
}

+ (NSString *)defaultRunLoopMode {
    // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}

@end
