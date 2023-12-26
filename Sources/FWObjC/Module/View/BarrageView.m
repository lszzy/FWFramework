//
//  BarrageView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "BarrageView.h"

#pragma mark - __FWBarrageRenderView

#define kNextAvailableTimeKey(identifier, index) [NSString stringWithFormat:@"%@_%d", identifier, index]

@implementation __FWBarrageRenderView

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

@end
