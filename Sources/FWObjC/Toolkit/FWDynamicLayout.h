//
//  FWDynamicLayout.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UITableViewCell+FWDynamicLayout

typedef void(^FWCellConfigurationBlock)(__kindof UITableViewCell *cell) NS_SWIFT_NAME(CellConfigurationBlock);
typedef void(^FWCellIndexPathBlock)(__kindof UITableViewCell *cell, NSIndexPath *indexPath) NS_SWIFT_NAME(CellIndexPathBlock);

#pragma mark - UITableViewHeaderFooterView+FWDynamicLayout

typedef NS_ENUM(NSInteger, FWHeaderFooterViewType) {
    FWHeaderFooterViewTypeHeader = 0,
    FWHeaderFooterViewTypeFooter = 1,
} NS_SWIFT_NAME(HeaderFooterViewType);

typedef void(^FWHeaderFooterViewConfigurationBlock)(__kindof UITableViewHeaderFooterView *headerFooterView) NS_SWIFT_NAME(HeaderFooterViewConfigurationBlock);
typedef void(^FWHeaderFooterViewSectionBlock)(__kindof UITableViewHeaderFooterView *headerFooterView, NSInteger section) NS_SWIFT_NAME(HeaderFooterViewSectionBlock);

#pragma mark - UICollectionViewCell+FWDynamicLayout

typedef void(^FWCollectionCellConfigurationBlock)(__kindof UICollectionViewCell *cell) NS_SWIFT_NAME(CollectionCellConfigurationBlock);
typedef void(^FWCollectionCellIndexPathBlock)(__kindof UICollectionViewCell *cell, NSIndexPath *indexPath) NS_SWIFT_NAME(CollectionCellIndexPathBlock);

#pragma mark - UICollectionReusableView+FWDynamicLayout

typedef void(^FWReusableViewConfigurationBlock)(__kindof UICollectionReusableView *reusableView) NS_SWIFT_NAME(ReusableViewConfigurationBlock);
typedef void(^FWReusableViewIndexPathBlock)(__kindof UICollectionReusableView *reusableView, NSIndexPath *indexPath) NS_SWIFT_NAME(ReusableViewIndexPathBlock);

NS_ASSUME_NONNULL_END
