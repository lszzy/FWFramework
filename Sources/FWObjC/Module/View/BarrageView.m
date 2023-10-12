//
//  BarrageView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "BarrageView.h"

NSString *const __FWBarrageAnimation = @"FWBarrageAnimation";

#pragma mark - __FWBarrageManager

@implementation __FWBarrageManager

- (void)dealloc {
    [_renderView stop];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _renderView = [[__FWBarrageRenderView alloc] init];
    }
    return self;
}

- (void)start {
    [self.renderView start];
}

- (void)pause {
    [self.renderView pause];
}

- (void)resume {
    [self.renderView resume];
}

- (void)stop {
    [self.renderView stop];
}

- (void)renderBarrageDescriptor:(__FWBarrageDescriptor *)barrageDescriptor {
    if (!barrageDescriptor) {
        return;
    }
    if (![barrageDescriptor isKindOfClass:[__FWBarrageDescriptor class]]) {
        return;
    }
    
    __FWBarrageCell *barrageCell = [self.renderView dequeueReusableCellWithClass:barrageDescriptor.barrageCellClass];
    if (!barrageCell) {
        return;
    }
    barrageCell.barrageDescriptor = barrageDescriptor;
    [self.renderView fireBarrageCell:barrageCell];
}

#pragma mark ------ getter
- (__FWBarrageRenderView *)renderView {
    return _renderView;
}

@end

#pragma mark - __FWBarrageRenderView

#define kNextAvailableTimeKey(identifier, index) [NSString stringWithFormat:@"%@_%d", identifier, index]

@implementation __FWBarrageRenderView

- (instancetype)init {
    self = [super init];
    if (self) {
        _animatingCellsLock = dispatch_semaphore_create(1);
        _idleCellsLock = dispatch_semaphore_create(1);
        _trackInfoLock = dispatch_semaphore_create(1);
        _lowPositionView = [[UIView alloc] init];
        [self addSubview:_lowPositionView];
        _middlePositionView = [[UIView alloc] init];
        [self addSubview:_middlePositionView];
        _highPositionView = [[UIView alloc] init];
        [self addSubview:_highPositionView];
        _veryHighPositionView = [[UIView alloc] init];
        [self addSubview:_veryHighPositionView];
        self.layer.masksToBounds = YES;
        _trackNextAvailableTime = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (nullable __FWBarrageCell *)dequeueReusableCellWithClass:(Class)barrageCellClass {
    __FWBarrageCell *barrageCell = nil;
    
    dispatch_semaphore_wait(_idleCellsLock, DISPATCH_TIME_FOREVER);
    for (__FWBarrageCell *cell in self.idleCells) {
        if ([NSStringFromClass([cell class]) isEqualToString:NSStringFromClass(barrageCellClass)]) {
            barrageCell = cell;
            break;
        }
    }
    if (barrageCell) {
        [self.idleCells removeObject:barrageCell];
        barrageCell.idleTime = 0.0;
    } else {
        barrageCell = [self newCellWithClass:barrageCellClass];
    }
    dispatch_semaphore_signal(_idleCellsLock);
    if (![barrageCell isKindOfClass:[__FWBarrageCell class]]) {
        return nil;
    }
    
    return barrageCell;
}

- (__FWBarrageCell *)newCellWithClass:(Class)barrageCellClass {
    __FWBarrageCell *barrageCell = [[barrageCellClass alloc] init];
    if (![barrageCell isKindOfClass:[__FWBarrageCell class]]) {
        return nil;
    }
    
    return barrageCell;
}

- (void)start {
    switch (self.renderStatus) {
        case __FWBarrageRenderStarted: {
            return;
        }
            break;
        case __FWBarrageRenderPaused: {
            [self resume];
            return;
        }
            break;
        default: {
            _renderStatus = __FWBarrageRenderStarted;
        }
            break;
    }
}

- (void)pause {
    switch (self.renderStatus) {
        case __FWBarrageRenderStarted: {
            _renderStatus = __FWBarrageRenderPaused;
        }
            break;
        case __FWBarrageRenderPaused: {
            return;
        }
            break;
        default: {
            return;
        }
            break;
    }
    
    dispatch_semaphore_wait(_animatingCellsLock, DISPATCH_TIME_FOREVER);
    NSEnumerator *enumerator = [self.animatingCells reverseObjectEnumerator];
    __FWBarrageCell *cell = nil;
    while (cell = [enumerator nextObject]){
        CFTimeInterval pausedTime = [cell.layer convertTime:CACurrentMediaTime() fromLayer:nil];
        cell.layer.speed = 0.0;
        cell.layer.timeOffset = pausedTime;
    }
    dispatch_semaphore_signal(_animatingCellsLock);
}

- (void)resume {
    switch (self.renderStatus) {
        case __FWBarrageRenderStarted: {
            return;
        }
            break;
        case __FWBarrageRenderPaused: {
            _renderStatus = __FWBarrageRenderStarted;
        }
            break;
        default: {
            return;
        }
            break;
    }
    
    dispatch_semaphore_wait(_animatingCellsLock, DISPATCH_TIME_FOREVER);
    NSEnumerator *enumerator = [self.animatingCells reverseObjectEnumerator];
    __FWBarrageCell *cell = nil;
    while (cell = [enumerator nextObject]){
        CFTimeInterval pausedTime = cell.layer.timeOffset;
        cell.layer.speed = 1.0;
        cell.layer.timeOffset = 0.0;
        cell.layer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [cell.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        cell.layer.beginTime = timeSincePause;
    }
    dispatch_semaphore_signal(_animatingCellsLock);
}

- (void)stop {
    switch (self.renderStatus) {
        case __FWBarrageRenderStarted: {
            _renderStatus = __FWBarrageRenderStoped;
        }
            break;
        case __FWBarrageRenderPaused: {
            _renderStatus = __FWBarrageRenderStoped;
        }
            break;
        default: {
            return;
        }
            break;
    }
    
    if (_autoClear) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearIdleCells) object:nil];
    }
    
    dispatch_semaphore_wait(_animatingCellsLock, DISPATCH_TIME_FOREVER);
    NSEnumerator *animatingEnumerator = [self.animatingCells reverseObjectEnumerator];
    __FWBarrageCell *animatingCell = nil;
    while (animatingCell = [animatingEnumerator nextObject]){
        CFTimeInterval pausedTime = [animatingCell.layer convertTime:CACurrentMediaTime() fromLayer:nil];
        animatingCell.layer.speed = 0.0;
        animatingCell.layer.timeOffset = pausedTime;
        [animatingCell.layer removeAllAnimations];
        [animatingCell removeFromSuperview];
    }
    [self.animatingCells removeAllObjects];
    dispatch_semaphore_signal(_animatingCellsLock);
    
    dispatch_semaphore_wait(_idleCellsLock, DISPATCH_TIME_FOREVER);
    [self.idleCells removeAllObjects];
    dispatch_semaphore_signal(_idleCellsLock);
    
    dispatch_semaphore_wait(_trackInfoLock, DISPATCH_TIME_FOREVER);
    [_trackNextAvailableTime removeAllObjects];
    dispatch_semaphore_signal(_trackInfoLock);
}

- (void)fireBarrageCell:(__FWBarrageCell *)barrageCell {
    switch (self.renderStatus) {
        case __FWBarrageRenderStarted: {
            
        }
            break;
        case __FWBarrageRenderPaused: {
            
            return;
        }
            break;
        default:
            return;
            break;
    }
    if (!barrageCell) {
        return;
    }
    if (![barrageCell isKindOfClass:[__FWBarrageCell class]]) {
        return;
    }
    [barrageCell clearContents];
    [barrageCell updateSubviewsData];
    [barrageCell layoutContentSubviews];
    [barrageCell convertContentToImage];
    [barrageCell sizeToFit];
    [barrageCell removeSubViewsAndSublayers];
    [barrageCell addBorderAttributes];
    
    dispatch_semaphore_wait(_animatingCellsLock, DISPATCH_TIME_FOREVER);
    _lastestCell = [self.animatingCells lastObject];
    [self.animatingCells addObject:barrageCell];
    barrageCell.idle = NO;
    dispatch_semaphore_signal(_animatingCellsLock);
    
    [self addBarrageCell:barrageCell WithPositionPriority:barrageCell.barrageDescriptor.positionPriority];
    CGRect cellFrame = [self calculationBarrageCellFrame:barrageCell];
    barrageCell.frame = cellFrame;
    [barrageCell addBarrageAnimationWithDelegate:self];
    [self recordTrackInfoWithBarrageCell:barrageCell];
    
    _lastestCell = barrageCell;
}

- (void)addBarrageCell:(__FWBarrageCell *)barrageCell WithPositionPriority:(__FWBarragePositionPriority)positionPriority {
    switch (positionPriority) {
        case __FWBarragePositionMiddle: {
            [self insertSubview:barrageCell aboveSubview:_middlePositionView];
        }
            break;
        case __FWBarragePositionHigh: {
            [self insertSubview:barrageCell belowSubview:_highPositionView];
        }
            break;
        case __FWBarragePositionVeryHigh: {
            [self insertSubview:barrageCell belowSubview:_veryHighPositionView];
        }
            break;
        default: {
            [self insertSubview:barrageCell belowSubview:_lowPositionView];
        }
            break;
    }
}

- (CGRect)calculationBarrageCellFrame:(__FWBarrageCell *)barrageCell {
    CGRect cellFrame = barrageCell.bounds;
    cellFrame.origin.x = CGRectGetMaxX(self.frame);
    
    if (![[NSValue valueWithRange:barrageCell.barrageDescriptor.renderRange] isEqualToValue:[NSValue valueWithRange:NSMakeRange(0, 0)]]) {
        CGFloat cellHeight = CGRectGetHeight(barrageCell.bounds);
        CGFloat minOriginY = barrageCell.barrageDescriptor.renderRange.location;
        CGFloat maxOriginY = barrageCell.barrageDescriptor.renderRange.length;
        if (maxOriginY > CGRectGetHeight(self.bounds)) {
            maxOriginY = CGRectGetHeight(self.bounds);
        }
        if (minOriginY < 0) {
            minOriginY = 0;
        }
        CGFloat renderHeight = maxOriginY - minOriginY;
        if (renderHeight < 0) {
            renderHeight = cellHeight;
        }
        
        int trackCount = floorf(renderHeight/cellHeight);
        int trackIndex = arc4random_uniform(trackCount);//用户改变行高(比如弹幕文字大小不会引起显示bug, 因为虽然是同一个类, 但是trackCount变小了, 所以不会出现trackIndex*cellHeight超出屏幕边界的情况)
        
        dispatch_semaphore_wait(_trackInfoLock, DISPATCH_TIME_FOREVER);
        __FWBarrageTrackInfo *trackInfo = [_trackNextAvailableTime objectForKey:kNextAvailableTimeKey(NSStringFromClass([barrageCell class]), trackIndex)];
        if (trackInfo && trackInfo.nextAvailableTime > CACurrentMediaTime()) {//当前行暂不可用
            
            NSMutableArray *availableTrackInfos = [NSMutableArray array];
            for (__FWBarrageTrackInfo *info in _trackNextAvailableTime.allValues) {
                if (CACurrentMediaTime() > info.nextAvailableTime && [info.trackIdentifier containsString:NSStringFromClass([barrageCell class])]) {//只在同类弹幕中判断是否有可用的轨道
                    [availableTrackInfos addObject:info];
                }
            }
            if (availableTrackInfos.count > 0) {
                __FWBarrageTrackInfo *randomInfo = [availableTrackInfos objectAtIndex:arc4random_uniform((int)availableTrackInfos.count)];
                trackIndex = randomInfo.trackIndex;
            } else {
                if (_trackNextAvailableTime.count < trackCount) {//刚开始不是每一条轨道都跑过弹幕, 还有空轨道
                    NSMutableArray *numberArray = [NSMutableArray array];
                    for (int index = 0; index < trackCount; index++) {
                        __FWBarrageTrackInfo *emptyTrackInfo = [_trackNextAvailableTime objectForKey:kNextAvailableTimeKey(NSStringFromClass([barrageCell class]), index)];
                        if (!emptyTrackInfo) {
                            [numberArray addObject:[NSNumber numberWithInt:index]];
                        }
                    }
                    if (numberArray.count > 0) {
                        trackIndex = [[numberArray objectAtIndex:arc4random_uniform((int)numberArray.count)] intValue];
                    }
                }
                //真的是没有可用的轨道了
            }
        }
        dispatch_semaphore_signal(_trackInfoLock);
        
        barrageCell.trackIndex = trackIndex;
        cellFrame.origin.y = trackIndex*cellHeight+minOriginY;
    } else {
        switch (self.renderPositionStyle) {
            case __FWBarrageRenderPositionRandom: {
                CGFloat maxY = CGRectGetHeight(self.bounds) - CGRectGetHeight(cellFrame);
                int originY = floorl(maxY);
                cellFrame.origin.y = arc4random_uniform(originY);
            }
                break;
            case __FWBarrageRenderPositionIncrease: {
                if (_lastestCell) {
                    CGRect lastestFrame = _lastestCell.frame;
                    cellFrame.origin.y = CGRectGetMaxY(lastestFrame);
                } else {
                    cellFrame.origin.y = 0.0;
                }
            }
                break;
            default: {
                CGFloat renderViewHeight = CGRectGetHeight(self.bounds);
                CGFloat cellHeight = CGRectGetHeight(barrageCell.bounds);
                int trackCount = floorf(renderViewHeight/cellHeight);
                int trackIndex = arc4random_uniform(trackCount);//用户改变行高(比如弹幕文字大小不会引起显示bug, 因为虽然是同一个类, 但是trackCount变小了, 所以不会出现trackIndex*cellHeight超出屏幕边界的情况)
                
                dispatch_semaphore_wait(_trackInfoLock, DISPATCH_TIME_FOREVER);
                __FWBarrageTrackInfo *trackInfo = [_trackNextAvailableTime objectForKey:kNextAvailableTimeKey(NSStringFromClass([barrageCell class]), trackIndex)];
                if (trackInfo && trackInfo.nextAvailableTime > CACurrentMediaTime()) {//当前行暂不可用
                    NSMutableArray *availableTrackInfos = [NSMutableArray array];
                    for (__FWBarrageTrackInfo *info in _trackNextAvailableTime.allValues) {
                        if (CACurrentMediaTime() > info.nextAvailableTime && [info.trackIdentifier containsString:NSStringFromClass([barrageCell class])]) {//只在同类弹幕中判断是否有可用的轨道
                            [availableTrackInfos addObject:info];
                        }
                    }
                    if (availableTrackInfos.count > 0) {
                        __FWBarrageTrackInfo *randomInfo = [availableTrackInfos objectAtIndex:arc4random_uniform((int)availableTrackInfos.count)];
                        trackIndex = randomInfo.trackIndex;
                    } else {
                        if (_trackNextAvailableTime.count < trackCount) {//刚开始不是每一条轨道都跑过弹幕, 还有空轨道
                            NSMutableArray *numberArray = [NSMutableArray array];
                            for (int index = 0; index < trackCount; index++) {
                                __FWBarrageTrackInfo *emptyTrackInfo = [_trackNextAvailableTime objectForKey:kNextAvailableTimeKey(NSStringFromClass([barrageCell class]), index)];
                                if (!emptyTrackInfo) {
                                    [numberArray addObject:[NSNumber numberWithInt:index]];
                                }
                            }
                            if (numberArray.count > 0) {
                                trackIndex = [[numberArray objectAtIndex:arc4random_uniform((int)numberArray.count)] intValue];
                            }
                        }
                        //真的是没有可用的轨道了
                    }
                }
                dispatch_semaphore_signal(_trackInfoLock);
                
                barrageCell.trackIndex = trackIndex;
                cellFrame.origin.y = trackIndex*cellHeight;
            }
                break;
        }
    }
    
    if (CGRectGetMaxY(cellFrame) > CGRectGetHeight(self.bounds)) {
        cellFrame.origin.y = 0.0; //超过底部, 回到顶部
    } else if (cellFrame.origin.y  < 0) {
        cellFrame.origin.y = 0.0;
    }
    
    return cellFrame;
}

- (void)clearIdleCells {
    dispatch_semaphore_wait(_idleCellsLock, DISPATCH_TIME_FOREVER);
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSEnumerator *enumerator = [self.idleCells reverseObjectEnumerator];
    __FWBarrageCell *cell;
    while (cell = [enumerator nextObject]){
        CGFloat time = timeInterval - cell.idleTime;
        if (time > 5.0 && cell.idleTime > 0) {
            [self.idleCells removeObject:cell];
        }
    }
    
    if (self.idleCells.count == 0) {
        _autoClear = NO;
    } else {
        [self performSelector:@selector(clearIdleCells) withObject:nil afterDelay:5.0];
    }
    dispatch_semaphore_signal(_idleCellsLock);
}

- (void)recordTrackInfoWithBarrageCell:(__FWBarrageCell *)barrageCell {
    NSString *nextAvalibleTimeKey = kNextAvailableTimeKey(NSStringFromClass([barrageCell class]), barrageCell.trackIndex);
    CFTimeInterval duration = barrageCell.barrageAnimation.duration;
    NSValue *fromValue = nil;
    NSValue *toValue = nil;
    if ([barrageCell.barrageAnimation isKindOfClass:[CABasicAnimation class]]) {
        fromValue = [(CABasicAnimation *)barrageCell.barrageAnimation fromValue];
        toValue = [(CABasicAnimation *)barrageCell.barrageAnimation toValue];
    } else if ([barrageCell.barrageAnimation isKindOfClass:[CAKeyframeAnimation class]]) {
        fromValue = [[(CAKeyframeAnimation *)barrageCell.barrageAnimation values] firstObject];
        toValue = [[(CAKeyframeAnimation *)barrageCell.barrageAnimation values] lastObject];
    }
    const char *fromeValueType = [fromValue objCType];
    const char *toValueType = [toValue objCType];
    if (!fromeValueType || !toValueType) {
        return;
    }
    NSString *fromeValueTypeString = [NSString stringWithCString:fromeValueType encoding:NSUTF8StringEncoding];
    NSString *toValueTypeString = [NSString stringWithCString:toValueType encoding:NSUTF8StringEncoding];
    if (![fromeValueTypeString isEqualToString:toValueTypeString]) {
        return;
    }
    if ([fromeValueTypeString containsString:@"CGPoint"]) {
        CGPoint fromPoint = [fromValue CGPointValue];
        CGPoint toPoint = [toValue CGPointValue];
        
        dispatch_semaphore_wait(_trackInfoLock, DISPATCH_TIME_FOREVER);
        __FWBarrageTrackInfo *trackInfo = [_trackNextAvailableTime objectForKey:nextAvalibleTimeKey];
        if (!trackInfo) {
            trackInfo = [[__FWBarrageTrackInfo alloc] init];
            trackInfo.trackIdentifier = nextAvalibleTimeKey;
            trackInfo.trackIndex = barrageCell.trackIndex;
        }
        trackInfo.barrageCount++;
        
        trackInfo.nextAvailableTime = CGRectGetWidth(barrageCell.bounds);
        CGFloat distanceX = fabs(toPoint.x - fromPoint.x);
        CGFloat distanceY = fabs(toPoint.y - fromPoint.y);
        CGFloat distance = MAX(distanceX, distanceY);
        CGFloat speed = distance/duration;
        if (distanceX == distance) {
            CFTimeInterval time = CGRectGetWidth(barrageCell.bounds)/speed;
            trackInfo.nextAvailableTime = CACurrentMediaTime() + time + 0.1;//多加一点时间
            [_trackNextAvailableTime setValue:trackInfo forKey:nextAvalibleTimeKey];
        } else if (distanceY == distance) {
            //            CFTimeInterval time = CGRectGetHeight(barrageCell.bounds)/speed;
            
        } else {
            
        }
        dispatch_semaphore_signal(_trackInfoLock);
        return;
    } else if ([fromeValueTypeString containsString:@"CGVector"]) {
        
        return;
    } else if ([fromeValueTypeString containsString:@"CGSize"]) {
        
        return;
    } else if ([fromeValueTypeString containsString:@"CGRect"]) {
        
        return;
    } else if ([fromeValueTypeString containsString:@"CGAffineTransform"]) {
        
        return;
    } else if ([fromeValueTypeString containsString:@"UIEdgeInsets"]) {
        
        return;
    } else if ([fromeValueTypeString containsString:@"UIOffset"]) {
        
        return;
    }
}


#pragma mark ----- CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (!flag) {
        return;
    }
    
    if (self.renderStatus == __FWBarrageRenderStoped) {
        return;
    }
    __FWBarrageCell *animationedCell = nil;
    dispatch_semaphore_wait(_animatingCellsLock, DISPATCH_TIME_FOREVER);
    for (__FWBarrageCell *cell in self.animatingCells) {
        CAAnimation *barrageAnimation = [cell barrageAnimation];
        if (barrageAnimation == anim) {
            animationedCell = cell;
            [self.animatingCells removeObject:cell];
            break;
        }
    }
    dispatch_semaphore_signal(_animatingCellsLock);
    
    if (!animationedCell) {
        return;
    }
    
    dispatch_semaphore_wait(_trackInfoLock, DISPATCH_TIME_FOREVER);
    __FWBarrageTrackInfo *trackInfo = [_trackNextAvailableTime objectForKey:kNextAvailableTimeKey(NSStringFromClass([animationedCell class]), animationedCell.trackIndex)];
    if (trackInfo) {
        trackInfo.barrageCount--;
    }
    dispatch_semaphore_signal(_trackInfoLock);
    
    [animationedCell removeFromSuperview];
    [animationedCell prepareForReuse];
    
    dispatch_semaphore_wait(_idleCellsLock, DISPATCH_TIME_FOREVER);
    animationedCell.idleTime = [[NSDate date] timeIntervalSince1970];
    [self.idleCells addObject:animationedCell];
    dispatch_semaphore_signal(_idleCellsLock);
    
    if (!_autoClear) {
        [self performSelector:@selector(clearIdleCells) withObject:nil afterDelay:5.0];
        _autoClear = YES;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches) {
        UITouch *touch = [touches.allObjects firstObject];
        CGPoint touchPoint = [touch locationInView:self];
        [self trigerActionWithPoint:touchPoint];
    }
}

- (BOOL)trigerActionWithPoint:(CGPoint)touchPoint
{
    dispatch_semaphore_wait(_animatingCellsLock, DISPATCH_TIME_FOREVER);
    
    BOOL anyTriger = NO;
    NSEnumerator *enumerator = [self.animatingCells reverseObjectEnumerator];
    __FWBarrageCell *cell = nil;
    while (cell = [enumerator nextObject]){
        if ([cell.layer.presentationLayer hitTest:touchPoint]) {
            if (cell.barrageDescriptor.cellTouchedAction) {
                cell.barrageDescriptor.cellTouchedAction(cell.barrageDescriptor, cell);
                anyTriger = YES;
            }
            break;
        }
    }
    
    dispatch_semaphore_signal(_animatingCellsLock);
    
    return anyTriger;
}

#pragma mark ----- getter
- (NSMutableArray<__FWBarrageCell *> *)animatingCells {
    if (!_animatingCells) {
        _animatingCells = [[NSMutableArray alloc] init];
    }
    
    return _animatingCells;
}

- (NSMutableArray<__FWBarrageCell *> *)idleCells {
    if (!_idleCells) {
        _idleCells = [[NSMutableArray alloc] init];
    }
    
    return _idleCells;
}

- (__FWBarrageRenderStatus)renderStatus {
    return _renderStatus;
}

@end

#pragma mark - __FWBarrageDescriptor

@implementation __FWBarrageDescriptor

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

@end

#pragma mark - __FWBarrageCell

@implementation __FWBarrageCell

- (instancetype)init {
    self = [super init];
    if (self) {
        _trackIndex = -1;
    }
    
    return self;
}

- (void)prepareForReuse {
    [self.layer removeAnimationForKey:__FWBarrageAnimation];
    _barrageDescriptor = nil;
    if (!_idle) {
        _idle = YES;
    }
    _trackIndex = -1;
}

- (void)setBarrageDescriptor:(__FWBarrageDescriptor *)barrageDescriptor {
    _barrageDescriptor = barrageDescriptor;
}

- (void)clearContents {
    self.layer.contents = nil;
}

- (void)convertContentToImage {
    
}

- (void)sizeToFit {
    CGFloat height = 0.0;
    CGFloat width = 0.0;
    for (CALayer *sublayer in self.layer.sublayers) {
        CGFloat maxY = CGRectGetMaxY(sublayer.frame);
        if (maxY > height) {
            height = maxY;
        }
        CGFloat maxX = CGRectGetMaxX(sublayer.frame);
        if (maxX > width) {
            width = maxX;
        }
    }
    
    if (width == 0 || height == 0) {
        CGImageRef content = (__bridge CGImageRef)self.layer.contents;
        if (content) {
            UIImage *image = [UIImage imageWithCGImage:content];
            width = image.size.width/[UIScreen mainScreen].scale;
            height = image.size.height/[UIScreen mainScreen].scale;
        }
    }
    
    self.bounds = CGRectMake(0.0, 0.0, width, height);
}


- (void)removeSubViewsAndSublayers {
    NSEnumerator *viewEnumerator = [self.subviews reverseObjectEnumerator];
    UIView *subView = nil;
    while (subView = [viewEnumerator nextObject]){
        [subView removeFromSuperview];
    }
    
    NSEnumerator *layerEnumerator = [self.layer.sublayers reverseObjectEnumerator];
    CALayer *sublayer = nil;
    while (sublayer = [layerEnumerator nextObject]){
        [sublayer removeFromSuperlayer];
    }
}

- (void)addBorderAttributes {
    if (self.barrageDescriptor.borderColor) {
        self.layer.borderColor = self.barrageDescriptor.borderColor.CGColor;
    }
    if (self.barrageDescriptor.borderWidth > 0) {
        self.layer.borderWidth = self.barrageDescriptor.borderWidth;
    }
    if (self.barrageDescriptor.cornerRadius > 0) {
        self.layer.cornerRadius = self.barrageDescriptor.cornerRadius;
    }
}

- (void)addBarrageAnimationWithDelegate:(id<CAAnimationDelegate>)animationDelegate {
    
}

- (void)updateSubviewsData {
   
}

- (void)layoutContentSubviews {

}

- (CAAnimation *)barrageAnimation {
    return [self.layer animationForKey:__FWBarrageAnimation];
}

@end

#pragma mark - __FWBarrageTextDescriptor

@implementation __FWBarrageTextDescriptor

@synthesize textFont = _textFont, textColor = _textColor, shadowColor = _shadowColor, attributedText = _attributedText;

- (instancetype)init {
    self = [super init];
    if (self) {
        _textAttribute = [NSMutableDictionary dictionary];
        _shadowColor = [UIColor blackColor];
        _shadowOffset = CGSizeZero;
        _shadowRadius = 2.0;
        _shadowOpacity = 0.5;
    }
    
    return self;
}

#pragma mark ----- setter
- (void)setTextShadowOpened:(BOOL)textShadowOpened {
    _textShadowOpened = textShadowOpened;
    
    if (textShadowOpened) {
        [_textAttribute removeObjectForKey:NSStrokeColorAttributeName];
        [_textAttribute removeObjectForKey:NSStrokeWidthAttributeName];
    }
}

- (void)setTextFont:(UIFont *)textFont {
    _textFont = textFont;
    
    [_textAttribute setValue:textFont forKey:NSFontAttributeName];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor =  textColor;
    
    [_textAttribute setValue:textColor forKey:NSForegroundColorAttributeName];
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor =  strokeColor;
    
    if (_textShadowOpened) {
        return;
    }
    
    [_textAttribute setValue:strokeColor forKey:NSStrokeColorAttributeName];
}

- (void)setStrokeWidth:(int)strokeWidth {
    _strokeWidth = strokeWidth;
    
    if (_textShadowOpened) {
        return;
    }
    
    [_textAttribute setValue:[NSNumber numberWithInt:strokeWidth] forKey:NSStrokeWidthAttributeName];
}

#pragma mark ----- getter
- (NSString *)text {
    if (!_text) {
        _text = _attributedText.string;
    }
    
    return _text;
}

- (UIFont *)textFont {
    if (!_textFont) {
        _textFont = [UIFont systemFontOfSize:17.0];
    }
    
    return _textFont;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [UIColor whiteColor];
    }
    
    return _textColor;
}

- (UIColor *)shadowColor {
    if (!_shadowColor) {
        _shadowColor = [UIColor blackColor];
    }
    
    return _shadowColor;
}

- (NSAttributedString *)attributedText {
    if (!_attributedText) {
        if (!_text) {
            return nil;
        }
        _attributedText = [[NSAttributedString alloc] initWithString:_text attributes:_textAttribute];
    }
    
    //修复阿拉伯文字显示的bug.
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    NSMutableAttributedString *tempText = [[NSMutableAttributedString alloc] initWithAttributedString:_attributedText];
    [tempText addAttributes:@{NSParagraphStyleAttributeName:paragraphStyle} range:NSMakeRange(0, tempText.string.length)];
    
    return [tempText copy];
}

@end

#pragma mark - __FWBarrageTextCell

@implementation __FWBarrageTextCell

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
}

- (void)updateSubviewsData {
    if (!_textLabel) {
        [self addSubview:self.textLabel];
    }
    if (self.textDescriptor.textShadowOpened) {
        self.textLabel.layer.shadowColor = self.textDescriptor.shadowColor.CGColor;
        self.textLabel.layer.shadowOffset = self.textDescriptor.shadowOffset;
        self.textLabel.layer.shadowRadius = self.textDescriptor.shadowRadius;
        self.textLabel.layer.shadowOpacity = self.textDescriptor.shadowOpacity;
    }
    
    [self.textLabel setAttributedText:self.textDescriptor.attributedText];
}

- (void)layoutContentSubviews {
    CGRect textFrame = [self.textDescriptor.attributedText.string boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:[self.textDescriptor.attributedText attributesAtIndex:0 effectiveRange:NULL] context:nil];
    self.textLabel.frame = textFrame;
}

- (void)convertContentToImage {
    CGSize contentSize = _textLabel.frame.size;
    UIGraphicsBeginImageContextWithOptions(contentSize, 0.0, [UIScreen mainScreen].scale);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *contentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.layer setContents:(__bridge id)contentImage.CGImage];
}

- (void)removeSubViewsAndSublayers {
    [super removeSubViewsAndSublayers];
    
    _textLabel = nil;
}

- (void)addBarrageAnimationWithDelegate:(id<CAAnimationDelegate>)animationDelegate {
    if (!self.superview) {
        return;
    }
    
    CGPoint startCenter = CGPointMake(CGRectGetMaxX(self.superview.bounds) + CGRectGetWidth(self.bounds)/2, self.center.y);
    CGPoint endCenter = CGPointMake(-(CGRectGetWidth(self.bounds)/2), self.center.y);
    
    CGFloat animationDuration = self.barrageDescriptor.animationDuration;
    if (self.barrageDescriptor.fixedSpeed > 0.0) {//如果是固定速度那就用固定速度
        if (self.barrageDescriptor.fixedSpeed > 100.0) {
            self.barrageDescriptor.fixedSpeed = 100.0;
        }
        animationDuration = (startCenter.x - endCenter.x)/([UIScreen mainScreen].scale*2)/self.barrageDescriptor.fixedSpeed;
    }
    
    CAKeyframeAnimation *walkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    walkAnimation.values = @[[NSValue valueWithCGPoint:startCenter], [NSValue valueWithCGPoint:endCenter]];
    walkAnimation.keyTimes = @[@(0.0), @(1.0)];
    walkAnimation.duration = animationDuration;
    walkAnimation.repeatCount = 1;
    walkAnimation.delegate =  animationDelegate;
    walkAnimation.removedOnCompletion = NO;
    walkAnimation.fillMode = kCAFillModeForwards;
    
    [self.layer addAnimation:walkAnimation forKey:__FWBarrageAnimation];
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _textLabel;
}

- (void)setBarrageDescriptor:(__FWBarrageDescriptor *)barrageDescriptor {
    [super setBarrageDescriptor:barrageDescriptor];
    self.textDescriptor = (__FWBarrageTextDescriptor *)barrageDescriptor;
}

@end

#pragma mark - __FWBarrageTrackInfo

@implementation __FWBarrageTrackInfo

@end
