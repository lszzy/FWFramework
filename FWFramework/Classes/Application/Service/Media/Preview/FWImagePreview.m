/*!
 @header     FWImagePreview.h
 @indexgroup FWFramework
 @brief      FWImagePreview
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import "FWImagePreview.h"
#import "FWToolkit.h"

#pragma mark - FWCollectionViewPagingLayout

@interface FWCollectionViewPagingLayout () {
    CGFloat _maximumScale;
    CGFloat _minimumScale;
    CGSize _finalItemSize;
    CGFloat _pagingThreshold;
}

@end

@implementation FWCollectionViewPagingLayout

- (instancetype)initWithStyle:(FWCollectionViewPagingLayoutStyle)style {
    if (self = [super init]) {
        _style = style;
        self.velocityForEnsurePageDown = 0.4;
        self.allowsMultipleItemScroll = YES;
        self.multipleItemScrollVelocityLimit = 2.5;
        self.pagingThreshold = 2.0 / 3.0;
        self.maximumScale = 1.0;
        self.minimumScale = 0.94;
        
        self.minimumInteritemSpacing = 0;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

- (instancetype)init {
    return [self initWithStyle:FWCollectionViewPagingLayoutStyleDefault];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self init];
}

- (void)prepareLayout {
    [super prepareLayout];
    CGSize itemSize = self.itemSize;
    id<UICollectionViewDelegateFlowLayout> layoutDelegate = (id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate;
    if ([layoutDelegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        itemSize = [layoutDelegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    _finalItemSize = itemSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    if (self.style == FWCollectionViewPagingLayoutStyleScale) {
        return YES;
    }
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (self.style == FWCollectionViewPagingLayoutStyleDefault) {
        return [super layoutAttributesForElementsInRect:rect];
    }
    
    NSArray<UICollectionViewLayoutAttributes *> *resultAttributes = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
    CGFloat offset = CGRectGetMidX(self.collectionView.bounds);// 当前滚动位置的可视区域的中心点
    CGSize itemSize = _finalItemSize;
    
    if (self.style == FWCollectionViewPagingLayoutStyleScale) {
        
        CGFloat distanceForMinimumScale = itemSize.width + self.minimumLineSpacing;
        CGFloat distanceForMaximumScale = 0.0;
        
        for (UICollectionViewLayoutAttributes *attributes in resultAttributes) {
            CGFloat scale = 0;
            CGFloat distance = ABS(offset - attributes.center.x);
            if (distance >= distanceForMinimumScale) {
                scale = self.minimumScale;
            } else if (distance == distanceForMaximumScale) {
                scale = self.maximumScale;
            } else {
                scale = self.minimumScale + (distanceForMinimumScale - distance) * (self.maximumScale - self.minimumScale) / (distanceForMinimumScale - distanceForMaximumScale);
            }
            attributes.transform3D = CATransform3DMakeScale(scale, scale, 1);
            attributes.zIndex = 1;
        }
        return resultAttributes;
    }
    
    return resultAttributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    
    CGFloat itemSpacing = (self.scrollDirection == UICollectionViewScrollDirectionHorizontal ? _finalItemSize.width : _finalItemSize.height) + self.minimumLineSpacing;
    
    CGSize contentSize = self.collectionViewContentSize;
    CGSize frameSize = self.collectionView.bounds.size;
    UIEdgeInsets contentInset = self.collectionView.fwContentInset;
    
    BOOL scrollingToRight = proposedContentOffset.x < self.collectionView.contentOffset.x;// 代表 collectionView 期望的实际滚动方向是向右，但不代表手指拖拽的方向是向右，因为有可能此时已经在左边的尽头，继续往右拖拽，松手的瞬间由于回弹，这里会判断为是想向左滚动，但其实你的手指是向右拖拽
    BOOL scrollingToBottom = proposedContentOffset.y < self.collectionView.contentOffset.y;
    BOOL forcePaging = NO;
    
    CGPoint translation = [self.collectionView.panGestureRecognizer translationInView:self.collectionView];
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        if (!self.allowsMultipleItemScroll || ABS(velocity.y) <= ABS(self.multipleItemScrollVelocityLimit)) {
            proposedContentOffset = self.collectionView.contentOffset;// 一次性滚多次的本质是系统根据速度算出来的 proposedContentOffset 可能比当前 contentOffset 大很多，所以这里既然限制了一次只能滚一页，那就直接取瞬时 contentOffset 即可。
            
            // 只支持滚动一页 或者 支持滚动多页但是速度不够滚动多页，时，允许强制滚动
            if (ABS(velocity.y) > self.velocityForEnsurePageDown) {
                forcePaging = YES;
            }
        }
        
        // 最顶/最底
        if (proposedContentOffset.y < -contentInset.top || proposedContentOffset.y >= contentSize.height + contentInset.bottom - frameSize.height) {
            // iOS 10 及以上的版本，直接返回当前的 contentOffset，系统会自动帮你调整到边界状态，而 iOS 9 及以下的版本需要自己计算
            return proposedContentOffset;
        }
        
        CGFloat progress = ((contentInset.top + proposedContentOffset.y) + _finalItemSize.height / 2/*因为第一个 item 初始状态中心点离 contentOffset.y 有半个 item 的距离*/) / itemSpacing;
        NSInteger currentIndex = (NSInteger)progress;
        NSInteger targetIndex = currentIndex;
        // 加上下面这两个额外的 if 判断是为了避免那种“从0滚到1的左边 1/3，松手后反而会滚回0”的 bug
        if (translation.y < 0 && (ABS(translation.y) > _finalItemSize.height / 2 + self.minimumLineSpacing)) {
        } else if (translation.y > 0 && ABS(translation.y > _finalItemSize.height / 2)) {
        } else {
            CGFloat remainder = progress - currentIndex;
            CGFloat offset = remainder * itemSpacing;
            BOOL shouldNext = (forcePaging || (offset / _finalItemSize.height >= self.pagingThreshold)) && !scrollingToBottom && velocity.y > 0;
            BOOL shouldPrev = (forcePaging || (offset / _finalItemSize.height <= 1 - self.pagingThreshold)) && scrollingToBottom && velocity.y < 0;
            targetIndex = currentIndex + (shouldNext ? 1 : (shouldPrev ? -1 : 0));
        }
        proposedContentOffset.y = -contentInset.top + targetIndex * itemSpacing;
    }
    else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        if (!self.allowsMultipleItemScroll || ABS(velocity.x) <= ABS(self.multipleItemScrollVelocityLimit)) {
            proposedContentOffset = self.collectionView.contentOffset;// 一次性滚多次的本质是系统根据速度算出来的 proposedContentOffset 可能比当前 contentOffset 大很多，所以这里既然限制了一次只能滚一页，那就直接取瞬时 contentOffset 即可。
            
            // 只支持滚动一页 或者 支持滚动多页但是速度不够滚动多页，时，允许强制滚动
            if (ABS(velocity.x) > self.velocityForEnsurePageDown) {
                forcePaging = YES;
            }
        }
        
        // 最左/最右
        if (proposedContentOffset.x < -contentInset.left || proposedContentOffset.x >= contentSize.width + contentInset.right - frameSize.width) {
            // iOS 10 及以上的版本，直接返回当前的 contentOffset，系统会自动帮你调整到边界状态，而 iOS 9 及以下的版本需要自己计算
            return proposedContentOffset;
        }
        
        CGFloat progress = ((contentInset.left + proposedContentOffset.x) + _finalItemSize.width / 2/*因为第一个 item 初始状态中心点离 contentOffset.x 有半个 item 的距离*/) / itemSpacing;
        NSInteger currentIndex = (NSInteger)progress;
        NSInteger targetIndex = currentIndex;
        // 加上下面这两个额外的 if 判断是为了避免那种“从0滚到1的左边 1/3，松手后反而会滚回0”的 bug
        if (translation.x < 0 && (ABS(translation.x) > _finalItemSize.width / 2 + self.minimumLineSpacing)) {
        } else if (translation.x > 0 && ABS(translation.x > _finalItemSize.width / 2)) {
        } else {
            CGFloat remainder = progress - currentIndex;
            CGFloat offset = remainder * itemSpacing;
            // collectionView 关闭了 bounces 后，如果在第一页向左边快速滑动一段距离，并不会触发上一个「最左/最右」的判断（因为 proposedContentOffset 不够），此时的 velocity 为负数，所以要加上 velocity.x > 0 的判断，否则这种情况会命中 forcePaging && !scrollingToRight 这两个条件，当做下一页处理。
            BOOL shouldNext = (forcePaging || (offset / _finalItemSize.width >= self.pagingThreshold)) && !scrollingToRight && velocity.x > 0;
            BOOL shouldPrev = (forcePaging || (offset / _finalItemSize.width <= 1 - self.pagingThreshold)) && scrollingToRight && velocity.x < 0;
            targetIndex = currentIndex + (shouldNext ? 1 : (shouldPrev ? -1 : 0));
        }
        proposedContentOffset.x = -contentInset.left + targetIndex * itemSpacing;
    }
    
    return proposedContentOffset;
}

- (CGFloat)pagingThreshold {
    return _pagingThreshold;
}

- (void)setPagingThreshold:(CGFloat)pagingThreshold {
    _pagingThreshold = pagingThreshold;
}

- (CGFloat)maximumScale {
    return _maximumScale;
}

- (void)setMaximumScale:(CGFloat)maximumScale {
    _maximumScale = maximumScale;
}

- (CGFloat)minimumScale {
    return _minimumScale;
}

- (void)setMinimumScale:(CGFloat)minimumScale {
    _minimumScale = minimumScale;
}

@end
