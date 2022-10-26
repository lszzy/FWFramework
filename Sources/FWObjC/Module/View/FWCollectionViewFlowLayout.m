//
//  FWCollectionViewFlowLayout.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWCollectionViewFlowLayout.h"
#import "tgmath.h"
#import <objc/runtime.h>

#pragma mark - FWCollectionViewSectionConfig

static NSString *const FWCollectionViewElementKind = @"FWCollectionViewElementKind";

@implementation FWCollectionViewSectionConfig

@end

@interface FWCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, strong) FWCollectionViewSectionConfig *sectionConfig;

@end

@implementation FWCollectionViewLayoutAttributes

@end

@interface FWCollectionViewReusableView : UICollectionReusableView

@end

@implementation FWCollectionViewReusableView

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    if (![layoutAttributes isKindOfClass:[FWCollectionViewLayoutAttributes class]]) return;
    FWCollectionViewSectionConfig *sectionConfig = ((FWCollectionViewLayoutAttributes *)layoutAttributes).sectionConfig;
    if (!sectionConfig) return;
    
    self.backgroundColor = sectionConfig.backgroundColor;
    if (sectionConfig.customBlock) {
        sectionConfig.customBlock(self);
    }
}

@end

@implementation UICollectionViewFlowLayout (FWCollectionViewSectionConfig)

- (NSMutableArray *)fw_sectionConfigAttributes {
    NSMutableArray *attributes = objc_getAssociatedObject(self, _cmd);
    if (!attributes) {
        attributes = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, attributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return attributes;
}

- (void)fw_sectionConfigPrepareLayout {
    if (![self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:configForSectionAtIndex:)]) return;
    [self registerClass:[FWCollectionViewReusableView class] forDecorationViewOfKind:FWCollectionViewElementKind];
    [self.fw_sectionConfigAttributes removeAllObjects];
    id<FWCollectionViewDelegateFlowLayout> delegate = (id<FWCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
    NSUInteger sectionCount = [self.collectionView numberOfSections];
    for (NSUInteger section = 0; section < sectionCount; section++) {
        NSUInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        if (itemCount < 1) continue;

        UICollectionViewLayoutAttributes *firstAttr = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
        UICollectionViewLayoutAttributes *lastAttr = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:itemCount - 1 inSection:section]];
        if (!firstAttr || !lastAttr) continue;
        
        UIEdgeInsets sectionInset = self.sectionInset;
        if ([delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
            UIEdgeInsets inset = [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
            if (!UIEdgeInsetsEqualToEdgeInsets(inset, sectionInset)) {
                sectionInset = inset;
            }
        }
        
        CGRect sectionFrame = CGRectUnion(firstAttr.frame, lastAttr.frame);
        sectionFrame.origin.x -= sectionInset.left;
        sectionFrame.origin.y -= sectionInset.top;
        if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            sectionFrame.size.width += sectionInset.left + sectionInset.right;
            sectionFrame.size.height = self.collectionView.frame.size.height;
        } else {
            sectionFrame.size.width = self.collectionView.frame.size.width;
            sectionFrame.size.height += sectionInset.top + sectionInset.bottom;
        }
        
        FWCollectionViewLayoutAttributes *attributes = [FWCollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:FWCollectionViewElementKind withIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        attributes.frame = sectionFrame;
        attributes.zIndex = -1;
        attributes.sectionConfig = [delegate collectionView:self.collectionView layout:self configForSectionAtIndex:section];
        [self.fw_sectionConfigAttributes addObject:attributes];
    }
}

- (NSArray<UICollectionViewLayoutAttributes *> *)fw_sectionConfigLayoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attrs = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attr in self.fw_sectionConfigAttributes) {
        if (CGRectIntersectsRect(rect, attr.frame)) {
            [attrs addObject:attr];
        }
    }
    return [attrs copy];
}

@end

#pragma mark - FWCollectionViewFlowLayout

@interface FWCollectionViewFlowLayout ()

@property (nonatomic, strong) NSMutableArray *allAttributes;

@end

@implementation FWCollectionViewFlowLayout

#pragma mark - Methods to Override

- (void)prepareLayout {
    [super prepareLayout];
    [self fw_sectionConfigPrepareLayout];
    
    if (self.itemRenderVertical && self.columnCount > 0 && self.rowCount > 0) {
        self.allAttributes = [NSMutableArray array];
        NSUInteger sectionCount = [self.collectionView numberOfSections];
        for (NSUInteger section = 0; section < sectionCount; section++) {
            NSUInteger itemCount = [self.collectionView numberOfItemsInSection:section];
            for (NSUInteger item = 0; item < itemCount; item++) {
                UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
                [self.allAttributes addObject:attributes];
            }
        }
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.itemRenderVertical && self.columnCount > 0 && self.rowCount > 0) {
        NSUInteger page = indexPath.item / (self.columnCount * self.rowCount);
        NSUInteger x = indexPath.item % self.columnCount + page * self.columnCount;
        NSUInteger y = indexPath.item / self.columnCount - page * self.rowCount;
        NSInteger item = x * self.rowCount + y;
        UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:indexPath.section]];
        attributes.indexPath = indexPath;
        return attributes;
    }
    
    return [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *newAttributes = [NSMutableArray array];
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    if (self.itemRenderVertical && self.columnCount > 0 && self.rowCount > 0) {
        for (UICollectionViewLayoutAttributes *attribute in attributes) {
            if (attribute.representedElementCategory != UICollectionElementCategoryCell) {
                [newAttributes addObject:attribute];
                continue;
            }
            for (UICollectionViewLayoutAttributes *newAttribute in self.allAttributes) {
                if (attribute.indexPath.section == newAttribute.indexPath.section &&
                    attribute.indexPath.item == newAttribute.indexPath.item) {
                    [newAttributes addObject:newAttribute];
                    break;
                }
            }
        }
    } else {
        if (attributes) newAttributes = [attributes mutableCopy];
    }
    
    NSArray *sectionAttributes = [self fw_sectionConfigLayoutAttributesForElementsInRect:rect];
    [newAttributes addObjectsFromArray:sectionAttributes];
    return [newAttributes copy];
}

#pragma mark - Public Methods

- (NSInteger)itemRenderCount:(NSInteger)itemCount {
    if (self.columnCount < 1 || self.rowCount < 1) {
        return itemCount;
    }
    
    NSInteger pageCount = self.columnCount * self.rowCount;
    NSInteger page = ceil(itemCount / (double)pageCount);
    return page * pageCount;
}

- (NSIndexPath *)verticalIndexPath:(NSIndexPath *)indexPath {
    if (self.columnCount < 1 || self.rowCount < 1) {
        return indexPath;
    }
    
    NSInteger page = indexPath.item / (self.columnCount * self.rowCount);
    NSInteger x = (indexPath.item % (self.columnCount * self.rowCount)) / self.rowCount;
    NSInteger y = indexPath.item % self.rowCount + page * self.rowCount;
    NSInteger item = y * self.columnCount + x;
    return [NSIndexPath indexPathForItem:item inSection:indexPath.section];
}

@end

#pragma mark - FWCollectionViewWaterfallLayout

@interface FWCollectionViewWaterfallLayout ()
/// The delegate will point to collection view's delegate automatically.
@property (nonatomic, weak) id <FWCollectionViewDelegateWaterfallLayout> delegate;
/// Array to store height for each column
@property (nonatomic, strong) NSMutableArray *columnHeights;
/// Array of arrays. Each array stores item attributes for each section
@property (nonatomic, strong) NSMutableArray *sectionItemAttributes;
/// Array to store attributes for all items includes headers, cells, and footers
@property (nonatomic, strong) NSMutableArray *allItemAttributes;
/// Dictionary to store section headers' attribute
@property (nonatomic, strong) NSMutableDictionary *headersAttribute;
/// Dictionary to store section footers' attribute
@property (nonatomic, strong) NSMutableDictionary *footersAttribute;
/// Array to store union rectangles
@property (nonatomic, strong) NSMutableArray *unionRects;
@end

@implementation FWCollectionViewWaterfallLayout

/// How many items to be union into a single rectangle
static const NSInteger unionSize = 20;

static CGFloat FWFloorCGFloat(CGFloat value) {
  CGFloat scale = [UIScreen mainScreen].scale;
  return floor(value * scale) / scale;
}

#pragma mark - Public Accessors
- (void)setColumnCount:(NSInteger)columnCount {
  if (_columnCount != columnCount) {
    _columnCount = columnCount;
    [self invalidateLayout];
  }
}

- (void)setMinimumColumnSpacing:(CGFloat)minimumColumnSpacing {
  if (_minimumColumnSpacing != minimumColumnSpacing) {
    _minimumColumnSpacing = minimumColumnSpacing;
    [self invalidateLayout];
  }
}

- (void)setMinimumInteritemSpacing:(CGFloat)minimumInteritemSpacing {
  if (_minimumInteritemSpacing != minimumInteritemSpacing) {
    _minimumInteritemSpacing = minimumInteritemSpacing;
    [self invalidateLayout];
  }
}

- (void)setHeaderHeight:(CGFloat)headerHeight {
  if (_headerHeight != headerHeight) {
    _headerHeight = headerHeight;
    [self invalidateLayout];
  }
}

- (void)setFooterHeight:(CGFloat)footerHeight {
  if (_footerHeight != footerHeight) {
    _footerHeight = footerHeight;
    [self invalidateLayout];
  }
}

- (void)setHeaderInset:(UIEdgeInsets)headerInset {
  if (!UIEdgeInsetsEqualToEdgeInsets(_headerInset, headerInset)) {
    _headerInset = headerInset;
    [self invalidateLayout];
  }
}

- (void)setFooterInset:(UIEdgeInsets)footerInset {
  if (!UIEdgeInsetsEqualToEdgeInsets(_footerInset, footerInset)) {
    _footerInset = footerInset;
    [self invalidateLayout];
  }
}

- (void)setSectionInset:(UIEdgeInsets)sectionInset {
  if (!UIEdgeInsetsEqualToEdgeInsets(_sectionInset, sectionInset)) {
    _sectionInset = sectionInset;
    [self invalidateLayout];
  }
}

- (void)setItemRenderDirection:(FWCollectionViewWaterfallLayoutItemRenderDirection)itemRenderDirection {
  if (_itemRenderDirection != itemRenderDirection) {
    _itemRenderDirection = itemRenderDirection;
    [self invalidateLayout];
  }
}

- (void)setSectionHeadersPinToVisibleBounds:(BOOL)sectionHeadersPinToVisibleBounds {
  if (_sectionHeadersPinToVisibleBounds != sectionHeadersPinToVisibleBounds) {
    _sectionHeadersPinToVisibleBounds = sectionHeadersPinToVisibleBounds;
    [self invalidateLayout];
  }
}

- (NSInteger)columnCountForSection:(NSInteger)section {
  if ([self.delegate respondsToSelector:@selector(collectionView:layout:columnCountForSection:)]) {
    return [self.delegate collectionView:self.collectionView layout:self columnCountForSection:section];
  } else {
    return self.columnCount;
  }
}

- (CGFloat)itemWidthInSectionAtIndex:(NSInteger)section {
  UIEdgeInsets sectionInset;
  if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
    sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
  } else {
    sectionInset = self.sectionInset;
  }
  CGFloat width = self.collectionView.bounds.size.width - sectionInset.left - sectionInset.right;
  NSInteger columnCount = [self columnCountForSection:section];

  CGFloat columnSpacing = self.minimumColumnSpacing;
  if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumColumnSpacingForSectionAtIndex:)]) {
    columnSpacing = [self.delegate collectionView:self.collectionView layout:self minimumColumnSpacingForSectionAtIndex:section];
  }

  return FWFloorCGFloat((width - (columnCount - 1) * columnSpacing) / columnCount);
}

#pragma mark - Private Accessors
- (NSMutableDictionary *)headersAttribute {
  if (!_headersAttribute) {
    _headersAttribute = [NSMutableDictionary dictionary];
  }
  return _headersAttribute;
}

- (NSMutableDictionary *)footersAttribute {
  if (!_footersAttribute) {
    _footersAttribute = [NSMutableDictionary dictionary];
  }
  return _footersAttribute;
}

- (NSMutableArray *)unionRects {
  if (!_unionRects) {
    _unionRects = [NSMutableArray array];
  }
  return _unionRects;
}

- (NSMutableArray *)columnHeights {
  if (!_columnHeights) {
    _columnHeights = [NSMutableArray array];
  }
  return _columnHeights;
}

- (NSMutableArray *)allItemAttributes {
  if (!_allItemAttributes) {
    _allItemAttributes = [NSMutableArray array];
  }
  return _allItemAttributes;
}

- (NSMutableArray *)sectionItemAttributes {
  if (!_sectionItemAttributes) {
    _sectionItemAttributes = [NSMutableArray array];
  }
  return _sectionItemAttributes;
}

- (id <FWCollectionViewDelegateWaterfallLayout> )delegate {
  return (id <FWCollectionViewDelegateWaterfallLayout> )self.collectionView.delegate;
}

#pragma mark - Init
- (void)commonInit {
  _columnCount = 2;
  _minimumColumnSpacing = 10;
  _minimumInteritemSpacing = 10;
  _headerHeight = 0;
  _footerHeight = 0;
  _sectionInset = UIEdgeInsetsZero;
  _headerInset  = UIEdgeInsetsZero;
  _footerInset  = UIEdgeInsetsZero;
  _itemRenderDirection = FWCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst;
}

- (id)init {
  if (self = [super init]) {
    [self commonInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self commonInit];
  }
  return self;
}

#pragma mark - Methods to Override
- (void)prepareLayout {
  [super prepareLayout];

  [self.headersAttribute removeAllObjects];
  [self.footersAttribute removeAllObjects];
  [self.unionRects removeAllObjects];
  [self.columnHeights removeAllObjects];
  [self.allItemAttributes removeAllObjects];
  [self.sectionItemAttributes removeAllObjects];

  NSInteger numberOfSections = [self.collectionView numberOfSections];
  if (numberOfSections == 0) {
    return;
  }

  NSAssert([self.delegate conformsToProtocol:@protocol(FWCollectionViewDelegateWaterfallLayout)], @"UICollectionView's delegate should conform to FWCollectionViewDelegateWaterfallLayout protocol");
  NSAssert(self.columnCount > 0 || [self.delegate respondsToSelector:@selector(collectionView:layout:columnCountForSection:)], @"FWCollectionViewWaterfallLayout's columnCount should be greater than 0, or delegate must implement columnCountForSection:");

  // Initialize variables
  NSInteger idx = 0;

  for (NSInteger section = 0; section < numberOfSections; section++) {
    NSInteger columnCount = [self columnCountForSection:section];
    NSMutableArray *sectionColumnHeights = [NSMutableArray arrayWithCapacity:columnCount];
    for (idx = 0; idx < columnCount; idx++) {
      [sectionColumnHeights addObject:@(0)];
    }
    [self.columnHeights addObject:sectionColumnHeights];
  }
  // Create attributes
  CGFloat top = 0;
  UICollectionViewLayoutAttributes *attributes;

  for (NSInteger section = 0; section < numberOfSections; ++section) {
    /*
     * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
     */
    CGFloat minimumInteritemSpacing;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
      minimumInteritemSpacing = [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
    } else {
      minimumInteritemSpacing = self.minimumInteritemSpacing;
    }

    CGFloat columnSpacing = self.minimumColumnSpacing;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumColumnSpacingForSectionAtIndex:)]) {
      columnSpacing = [self.delegate collectionView:self.collectionView layout:self minimumColumnSpacingForSectionAtIndex:section];
    }

    UIEdgeInsets sectionInset;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
      sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    } else {
      sectionInset = self.sectionInset;
    }

    CGFloat width = self.collectionView.bounds.size.width - sectionInset.left - sectionInset.right;
    NSInteger columnCount = [self columnCountForSection:section];
    CGFloat itemWidth = FWFloorCGFloat((width - (columnCount - 1) * columnSpacing) / columnCount);

    /*
     * 2. Section header
     */
    CGFloat headerHeight;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)]) {
      headerHeight = [self.delegate collectionView:self.collectionView layout:self heightForHeaderInSection:section];
    } else {
      headerHeight = self.headerHeight;
    }

    UIEdgeInsets headerInset;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForHeaderInSection:)]) {
      headerInset = [self.delegate collectionView:self.collectionView layout:self insetForHeaderInSection:section];
    } else {
      headerInset = self.headerInset;
    }

    top += headerInset.top;

    if (headerHeight > 0) {
      attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
      attributes.frame = CGRectMake(headerInset.left,
                                    top,
                                    self.collectionView.bounds.size.width - (headerInset.left + headerInset.right),
                                    headerHeight);

      self.headersAttribute[@(section)] = attributes;
      [self.allItemAttributes addObject:attributes];

      top = CGRectGetMaxY(attributes.frame) + headerInset.bottom;
    }

    top += sectionInset.top;
    for (idx = 0; idx < columnCount; idx++) {
      self.columnHeights[section][idx] = @(top);
    }

    /*
     * 3. Section items
     */
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
    NSMutableArray *itemAttributes = [NSMutableArray arrayWithCapacity:itemCount];

    // Item will be put into shortest column.
    for (idx = 0; idx < itemCount; idx++) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:section];
      NSUInteger columnIndex = [self nextColumnIndexForItem:idx inSection:section];
      CGFloat xOffset = sectionInset.left + (itemWidth + columnSpacing) * columnIndex;
      CGFloat yOffset = [self.columnHeights[section][columnIndex] floatValue];
      CGSize itemSize = [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
      CGFloat itemHeight = 0;
      if (itemSize.height > 0 && itemSize.width > 0) {
        itemHeight = FWFloorCGFloat(itemSize.height * itemWidth / itemSize.width);
      }

      attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
      attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
      [itemAttributes addObject:attributes];
      [self.allItemAttributes addObject:attributes];
      self.columnHeights[section][columnIndex] = @(CGRectGetMaxY(attributes.frame) + minimumInteritemSpacing);
    }

    [self.sectionItemAttributes addObject:itemAttributes];

    /*
     * 4. Section footer
     */
    CGFloat footerHeight;
    NSUInteger columnIndex = [self longestColumnIndexInSection:section];
    if (((NSArray *)self.columnHeights[section]).count > 0) {
      top = [self.columnHeights[section][columnIndex] floatValue] - minimumInteritemSpacing + sectionInset.bottom;
    } else {
          top = 0;
      }
      
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForFooterInSection:)]) {
      footerHeight = [self.delegate collectionView:self.collectionView layout:self heightForFooterInSection:section];
    } else {
      footerHeight = self.footerHeight;
    }

    UIEdgeInsets footerInset;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForFooterInSection:)]) {
      footerInset = [self.delegate collectionView:self.collectionView layout:self insetForFooterInSection:section];
    } else {
      footerInset = self.footerInset;
    }

    top += footerInset.top;

    if (footerHeight > 0) {
      attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
      attributes.frame = CGRectMake(footerInset.left,
                                    top,
                                    self.collectionView.bounds.size.width - (footerInset.left + footerInset.right),
                                    footerHeight);

      self.footersAttribute[@(section)] = attributes;
      [self.allItemAttributes addObject:attributes];

      top = CGRectGetMaxY(attributes.frame) + footerInset.bottom;
    }

    for (idx = 0; idx < columnCount; idx++) {
      self.columnHeights[section][idx] = @(top);
    }
  } // end of for (NSInteger section = 0; section < numberOfSections; ++section)

  // Build union rects
  idx = 0;
  NSInteger itemCounts = [self.allItemAttributes count];
  while (idx < itemCounts) {
    CGRect unionRect = ((UICollectionViewLayoutAttributes *)self.allItemAttributes[idx]).frame;
    NSInteger rectEndIndex = MIN(idx + unionSize, itemCounts);

    for (NSInteger i = idx + 1; i < rectEndIndex; i++) {
      unionRect = CGRectUnion(unionRect, ((UICollectionViewLayoutAttributes *)self.allItemAttributes[i]).frame);
    }

    idx = rectEndIndex;

    [self.unionRects addObject:[NSValue valueWithCGRect:unionRect]];
  }
}

- (CGSize)collectionViewContentSize {
  NSInteger numberOfSections = [self.collectionView numberOfSections];
  if (numberOfSections == 0) {
    return CGSizeZero;
  }

  CGSize contentSize = self.collectionView.bounds.size;
  contentSize.height = [[[self.columnHeights lastObject] firstObject] floatValue];

  if (contentSize.height < self.minimumContentHeight) {
    contentSize.height = self.minimumContentHeight;
  }

  return contentSize;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path {
  if (path.section >= [self.sectionItemAttributes count]) {
    return nil;
  }
  if (path.item >= [self.sectionItemAttributes[path.section] count]) {
    return nil;
  }
  return (self.sectionItemAttributes[path.section])[path.item];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewLayoutAttributes *attribute = nil;
  if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
    attribute = self.headersAttribute[@(indexPath.section)];
  } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
    attribute = self.footersAttribute[@(indexPath.section)];
  }
  return attribute;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
  NSInteger i;
  NSInteger begin = 0, end = self.unionRects.count;
  NSMutableDictionary *cellAttrDict = [NSMutableDictionary dictionary];
  NSMutableDictionary *supplHeaderAttrDict = [NSMutableDictionary dictionary];
  NSMutableDictionary *supplFooterAttrDict = [NSMutableDictionary dictionary];
  NSMutableDictionary *decorAttrDict = [NSMutableDictionary dictionary];

  for (i = 0; i < self.unionRects.count; i++) {
    if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
      begin = i * unionSize;
      break;
    }
  }
  for (i = self.unionRects.count - 1; i >= 0; i--) {
    if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
      end = MIN((i + 1) * unionSize, self.allItemAttributes.count);
      break;
    }
  }
  for (i = begin; i < end; i++) {
    UICollectionViewLayoutAttributes *attr = self.allItemAttributes[i];
    if (CGRectIntersectsRect(rect, attr.frame)) {
      switch (attr.representedElementCategory) {
        case UICollectionElementCategorySupplementaryView:
          if ([attr.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            supplHeaderAttrDict[attr.indexPath] = attr;
          } else if ([attr.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
            supplFooterAttrDict[attr.indexPath] = attr;
          }
          break;
        case UICollectionElementCategoryDecorationView:
          decorAttrDict[attr.indexPath] = attr;
          break;
        case UICollectionElementCategoryCell:
          cellAttrDict[attr.indexPath] = attr;
          break;
      }
    }
  }
  
  if (self.sectionHeadersPinToVisibleBounds) {
    for (int i = 0; i < self.allItemAttributes.count; i++) {
      UICollectionViewLayoutAttributes *attr = self.allItemAttributes[i];
      if (![attr.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) continue;
      NSInteger section = attr.indexPath.section;
      CGFloat pinOffset = 0;
      if ([self.delegate respondsToSelector:@selector(collectionView:layout:pinOffsetForHeaderInSection:)]) {
        pinOffset = [self.delegate collectionView:self.collectionView layout:self pinOffsetForHeaderInSection:section];
      }
      if (pinOffset < 0) continue;
      
      NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
      UICollectionViewLayoutAttributes *itemAttr = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
      if (!itemAttr) continue;
      CGRect attrFrame = attr.frame;
      attrFrame.origin.y = MAX(self.collectionView.contentOffset.y + pinOffset, CGRectGetMinY(itemAttr.frame) - CGRectGetHeight(attrFrame));
      attr.frame = attrFrame;
      attr.zIndex = 1024;
      supplHeaderAttrDict[attr.indexPath] = attr;
    }
  }

  NSArray *result = [cellAttrDict.allValues arrayByAddingObjectsFromArray:supplHeaderAttrDict.allValues];
  result = [result arrayByAddingObjectsFromArray:supplFooterAttrDict.allValues];
  result = [result arrayByAddingObjectsFromArray:decorAttrDict.allValues];
  return result;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
  if (self.sectionHeadersPinToVisibleBounds) {
    return YES;
  }
  CGRect oldBounds = self.collectionView.bounds;
  if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
    return YES;
  }
  return NO;
}

#pragma mark - Private Methods

/**
 *  Find the shortest column.
 *
 *  @return index for the shortest column
 */
- (NSUInteger)shortestColumnIndexInSection:(NSInteger)section {
  __block NSUInteger index = 0;
  __block CGFloat shortestHeight = MAXFLOAT;

  [self.columnHeights[section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CGFloat height = [obj floatValue];
    if (height < shortestHeight) {
      shortestHeight = height;
      index = idx;
    }
  }];

  return index;
}

/**
 *  Find the longest column.
 *
 *  @return index for the longest column
 */
- (NSUInteger)longestColumnIndexInSection:(NSInteger)section {
  __block NSUInteger index = 0;
  __block CGFloat longestHeight = 0;

  [self.columnHeights[section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CGFloat height = [obj floatValue];
    if (height > longestHeight) {
      longestHeight = height;
      index = idx;
    }
  }];

  return index;
}

/**
 *  Find the index for the next column.
 *
 *  @return index for the next column
 */
- (NSUInteger)nextColumnIndexForItem:(NSInteger)item inSection:(NSInteger)section {
  NSUInteger index = 0;
  NSInteger columnCount = [self columnCountForSection:section];
  switch (self.itemRenderDirection) {
    case FWCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst:
      index = [self shortestColumnIndexInSection:section];
      break;

    case FWCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight:
      index = (item % columnCount);
      break;

    case FWCollectionViewWaterfallLayoutItemRenderDirectionRightToLeft:
      index = (columnCount - 1) - (item % columnCount);
      break;

    default:
      index = [self shortestColumnIndexInSection:section];
      break;
  }
  return index;
}

@end

#pragma mark - FWCollectionViewAlignLayout

@interface FWCollectionViewAlignLayout ()

@property (nonatomic, strong) NSMutableDictionary *cachedFrame;

@end

@implementation FWCollectionViewAlignLayout

- (CGFloat)innerMinimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (self.collectionView.delegate && [self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        id<FWCollectionViewDelegateAlignLayout> delegate = (id<FWCollectionViewDelegateAlignLayout>) self.collectionView.delegate;
        return [delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
    } else {
        return self.minimumInteritemSpacing;
    }
}

- (UIEdgeInsets)innerInsetForSectionAtIndex:(NSInteger)section {
    if (self.collectionView.delegate && [self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        id<FWCollectionViewDelegateAlignLayout> delegate = (id<FWCollectionViewDelegateAlignLayout>) self.collectionView.delegate;
        return [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    } else {
        return self.sectionInset;
    }
}

- (FWCollectionViewItemsHorizontalAlignment)innerItemsHorizontalAlignmentForSectionAtIndex:(NSInteger)section {
    if (self.collectionView.delegate && [self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:itemsHorizontalAlignmentInSection:)]) {
        id<FWCollectionViewDelegateAlignLayout> delegate = (id<FWCollectionViewDelegateAlignLayout>) self.collectionView.delegate;
        return [delegate collectionView:self.collectionView layout:self itemsHorizontalAlignmentInSection:section];
    } else {
        return self.itemsHorizontalAlignment;
    }
}

- (FWCollectionViewItemsVerticalAlignment)innerItemsVerticalAlignmentForSectionAtIndex:(NSInteger)section {
    if (self.collectionView.delegate && [self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:itemsVerticalAlignmentInSection:)]) {
        id<FWCollectionViewDelegateAlignLayout> delegate = (id<FWCollectionViewDelegateAlignLayout>) self.collectionView.delegate;
        return [delegate collectionView:self.collectionView layout:self itemsVerticalAlignmentInSection:section];
    } else {
        return self.itemsVerticalAlignment;
    }
}

- (FWCollectionViewItemsDirection)innerItemsDirectionForSectionAtIndex:(NSInteger)section {
    if (self.collectionView.delegate && [self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:itemsDirectionInSection:)]) {
        id<FWCollectionViewDelegateAlignLayout> delegate = (id<FWCollectionViewDelegateAlignLayout>) self.collectionView.delegate;
        return [delegate collectionView:self.collectionView layout:self itemsDirectionInSection:section];
    } else {
        return self.itemsDirection;
    }
}

- (BOOL)innerIsLineStartAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        return YES;
    }
    NSIndexPath *currentIndexPath = indexPath;
    NSIndexPath *previousIndexPath = indexPath.item == 0 ? nil : [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];

    UICollectionViewLayoutAttributes *currentAttributes = [super layoutAttributesForItemAtIndexPath:currentIndexPath];
    UICollectionViewLayoutAttributes *previousAttributes = previousIndexPath ? [super layoutAttributesForItemAtIndexPath:previousIndexPath] : nil;
    CGRect currentFrame = currentAttributes.frame;
    CGRect previousFrame = previousAttributes ? previousAttributes.frame : CGRectZero;

    UIEdgeInsets insets = [self innerInsetForSectionAtIndex:currentIndexPath.section];
    CGRect currentLineFrame = CGRectMake(insets.left, currentFrame.origin.y, CGRectGetWidth(self.collectionView.frame), currentFrame.size.height);
    CGRect previousLineFrame = CGRectMake(insets.left, previousFrame.origin.y, CGRectGetWidth(self.collectionView.frame), previousFrame.size.height);

    return !CGRectIntersectsRect(currentLineFrame, previousLineFrame);
}

- (NSArray *)innerLineAttributesArrayWithStartAttributes:(UICollectionViewLayoutAttributes *)startAttributes {
    NSMutableArray *lineAttributesArray = [[NSMutableArray alloc] init];
    [lineAttributesArray addObject:startAttributes];
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:startAttributes.indexPath.section];
    UIEdgeInsets insets = [self innerInsetForSectionAtIndex:startAttributes.indexPath.section];
    NSInteger index = startAttributes.indexPath.item;
    BOOL isLineEnd = index == itemCount - 1;
    while (!isLineEnd) {
        index++;
        if (index == itemCount)
            break;
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:index inSection:startAttributes.indexPath.section];
        UICollectionViewLayoutAttributes *nextAttributes = [super layoutAttributesForItemAtIndexPath:nextIndexPath];
        CGRect nextLineFrame = CGRectMake(insets.left, nextAttributes.frame.origin.y, CGRectGetWidth(self.collectionView.frame), nextAttributes.frame.size.height);
        isLineEnd = !CGRectIntersectsRect(startAttributes.frame, nextLineFrame);
        if (isLineEnd)
            break;
        [lineAttributesArray addObject:nextAttributes];
    }
    return lineAttributesArray;
}

- (void)innerCacheTheItemFrame:(CGRect)frame forIndexPath:(NSIndexPath *)indexPath {
    self.cachedFrame[indexPath] = @(frame);
}

- (NSValue *)innerCachedItemFrameAtIndexPath:(NSIndexPath *)indexPath {
    return self.cachedFrame[indexPath];
}

- (void)innerCalculateAndCacheFrameForItemAttributesArray:(NSArray<UICollectionViewLayoutAttributes *> *)array {
    NSInteger section = [array firstObject].indexPath.section;

    //******************** 相关布局属性 ********************//
    FWCollectionViewItemsHorizontalAlignment horizontalAlignment = [self innerItemsHorizontalAlignmentForSectionAtIndex:section];
    FWCollectionViewItemsVerticalAlignment verticalAlignment = [self innerItemsVerticalAlignmentForSectionAtIndex:section];
    FWCollectionViewItemsDirection direction = [self innerItemsDirectionForSectionAtIndex:section];
    BOOL isR2L = direction == FWCollectionViewItemsDirectionRTL;
    UIEdgeInsets sectionInsets = [self innerInsetForSectionAtIndex:section];
    CGFloat minimumInteritemSpacing = [self innerMinimumInteritemSpacingForSectionAtIndex:section];
    UIEdgeInsets contentInsets = self.collectionView.contentInset;
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.frame);
    NSMutableArray *widthArray = [[NSMutableArray alloc] init];
    for (UICollectionViewLayoutAttributes *attr in array) {
        [widthArray addObject:@(CGRectGetWidth(attr.frame))];
    }
    CGFloat totalWidth = [[widthArray valueForKeyPath:@"@sum.self"] floatValue];
    NSInteger totalCount = array.count;
    CGFloat extra = collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.left - sectionInsets.right - minimumInteritemSpacing * (totalCount - 1);

    //******************** 竖直方向位置(origin.y)，用于竖直方向对齐方式计算 ********************//
    CGFloat tempOriginY = 0.f;
    NSArray *frameValues = [array valueForKeyPath:@"frame"];
    if (verticalAlignment == FWCollectionViewItemsVerticalAlignmentTop) {
        tempOriginY = CGFLOAT_MAX;
        for (NSValue *frameValue in frameValues) {
            tempOriginY = MIN(tempOriginY, CGRectGetMinY([frameValue CGRectValue]));
        }
    } else if (verticalAlignment == FWCollectionViewItemsVerticalAlignmentBottom) {
        tempOriginY = CGFLOAT_MIN;
        for (NSValue *frameValue in frameValues) {
            tempOriginY = MAX(tempOriginY, CGRectGetMaxY([frameValue CGRectValue]));
        }
    }

    //******************** 计算起点及间距 ********************//
    CGFloat start = 0.f, space = 0.f;
    switch (horizontalAlignment) {
        case FWCollectionViewItemsHorizontalAlignmentLeft: {
            start = isR2L ? (collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.left - minimumInteritemSpacing * (totalCount - 1)) : sectionInsets.left;
            space = minimumInteritemSpacing;
        } break;

        case FWCollectionViewItemsHorizontalAlignmentCenter: {
            CGFloat rest = extra / 2.f;
            start = isR2L ? sectionInsets.right + rest : sectionInsets.left + rest;
            space = minimumInteritemSpacing;
        } break;

        case FWCollectionViewItemsHorizontalAlignmentRight: {
            start = isR2L ? sectionInsets.right : (collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.right - minimumInteritemSpacing * (totalCount - 1));
            space = minimumInteritemSpacing;
        } break;

        case FWCollectionViewItemsHorizontalAlignmentFlow: {
            BOOL isEnd = array.lastObject.indexPath.item == [self.collectionView numberOfItemsInSection:section] - 1;
            start = isR2L ? sectionInsets.right : sectionInsets.left;
            space = isEnd ? minimumInteritemSpacing : (collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.left - sectionInsets.right) / (totalCount - 1);
        } break;

        case FWCollectionViewItemsHorizontalAlignmentFlowFilled: {
            start = isR2L ? sectionInsets.right : sectionInsets.left;
            space = minimumInteritemSpacing;
        } break;

        default:
            break;
    }

    //******************** 计算并缓存 frame ********************//
    CGFloat lastMaxX = 0.f;
    for (int i = 0; i < widthArray.count; i++) {
        CGRect frame = array[i].frame;
        CGFloat width = [widthArray[i] floatValue];
        if (horizontalAlignment == FWCollectionViewItemsHorizontalAlignmentFlowFilled) {
            width += extra / (totalWidth / width);
        }
        CGFloat originX = 0.f;
        if (isR2L) {
            originX = i == 0 ? collectionViewWidth - start - contentInsets.right - contentInsets.left - width : lastMaxX - space - width;
            lastMaxX = originX;
        } else {
            originX = i == 0 ? start : lastMaxX + space;
            lastMaxX = originX + width;
        }
        CGFloat originY;
        if (verticalAlignment == FWCollectionViewItemsVerticalAlignmentBottom) {
            originY = tempOriginY - CGRectGetHeight(frame);
        } else if (verticalAlignment == FWCollectionViewItemsVerticalAlignmentCenter) {
            originY = frame.origin.y;
        } else {
            originY = tempOriginY;
        }
        frame.origin.x = originX;
        frame.origin.y = originY;
        frame.size.width = width;
        [self innerCacheTheItemFrame:frame forIndexPath:array[i].indexPath];
    }
}

#pragma mark - Public

- (void)prepareLayout {
    [super prepareLayout];
    [self fw_sectionConfigPrepareLayout];
    self.cachedFrame = @{}.mutableCopy;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *originalAttributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *updatedAttributes = originalAttributes ? originalAttributes.mutableCopy : [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attributes in originalAttributes) {
        if (!attributes.representedElementKind || attributes.representedElementCategory == UICollectionElementCategoryCell) {
            NSUInteger index = [updatedAttributes indexOfObject:attributes];
            updatedAttributes[index] = [self layoutAttributesForItemAtIndexPath:attributes.indexPath];
        }
    }
    NSArray *sectionAttributes = [self fw_sectionConfigLayoutAttributesForElementsInRect:rect];
    [updatedAttributes addObjectsFromArray:sectionAttributes];
    return updatedAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    // This is likely occurring because the flow layout subclass FWCollectionViewAlignLayout is modifying attributes returned by UICollectionViewFlowLayout without copying them
    UICollectionViewLayoutAttributes *currentAttributes = [[super layoutAttributesForItemAtIndexPath:indexPath] copy];

    // 获取缓存的当前 indexPath 的 item frame value
    NSValue *frameValue = [self innerCachedItemFrameAtIndexPath:indexPath];
    // 如果没有缓存的 item frame value，则计算并缓存然后获取
    if (!frameValue) {
        // 判断是否为一行中的首个
        BOOL isLineStart = [self innerIsLineStartAtIndexPath:indexPath];
        // 如果是一行中的首个
        if (isLineStart) {
            // 获取当前行的所有 UICollectionViewLayoutAttributes
            NSArray *line = [self innerLineAttributesArrayWithStartAttributes:currentAttributes];
            if (line.count) {
                // 计算并缓存当前行的所有 UICollectionViewLayoutAttributes frame
                [self innerCalculateAndCacheFrameForItemAttributesArray:line];
            }
        }
        // 获取位于当前 indexPath 的 item frame
        frameValue = [self innerCachedItemFrameAtIndexPath:indexPath];
    }
    if (frameValue) {
        // 设置缓存的当前 indexPath 的 item frame
        CGRect frame = [frameValue CGRectValue];
        // 获取当前 indexPath 的 item frame 后修改当前 layoutAttributes.frame
        currentAttributes.frame = frame;
    }
    
    return currentAttributes;
}

@end
