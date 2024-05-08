//
//  StatisticalExtension.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - BannerView+Statistical
extension BannerView {
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        return true
    }
    
    open override func statisticalViewChildViews() -> [UIView]? {
        return mainView.subviews
    }
    
    open override func statisticalViewIndexPath() -> IndexPath? {
        let itemIndex = flowLayout.currentPage ?? 0
        let indexPath = IndexPath(row: pageControlIndex(cellIndex: itemIndex), section: 0)
        return indexPath
    }
}

extension BannerViewCell {
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        return true
    }
    
    open override func statisticalViewWillBindExposure(_ containerView: UIView?) -> Bool {
        let bannerView: UIView? = (containerView is BannerView) ? containerView : statisticalViewContainerView()
        return bannerView?.fw_statisticalBindExposure(containerView) ?? false
    }
    
    open override func statisticalViewContainerView() -> UIView? {
        var superview = self.superview
        while superview != nil {
            if let bannerView = superview as? BannerView {
                return bannerView
            }
            superview = superview?.superview
        }
        return nil
    }
    
    open override func statisticalViewIndexPath() -> IndexPath? {
        guard let bannerView = statisticalViewContainerView() as? BannerView,
              let cellIndexPath = bannerView.mainView.indexPath(for: self) else {
            return nil
        }
        
        let indexPath = IndexPath(row: bannerView.pageControlIndex(cellIndex: cellIndexPath.row), section: 0)
        return indexPath
    }
}

// MARK: - SegmentedControl+Statistical
extension SegmentedControl {
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        return true
    }
    
    open override func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        let visibleMin = scrollView.contentOffset.x
        let visibleMax = visibleMin + scrollView.frame.size.width
        var sectionCount = 0
        var dynamicWidth = false
        if self.type == .text && segmentWidthStyle == .fixed {
            sectionCount = sectionTitles.count
        } else if segmentWidthStyle == .dynamic {
            sectionCount = segmentWidthsArray.count
            dynamicWidth = true
        } else {
            sectionCount = sectionImages.count
        }
        
        var indexPaths = [IndexPath]()
        var currentMin = contentEdgeInset.left
        for i in 0..<sectionCount {
            let currentMax = currentMin + (dynamicWidth ? segmentWidthsArray[i] : segmentWidth)
            if currentMin > visibleMax { break }
            
            if currentMin >= visibleMin && currentMax <= visibleMax {
                indexPaths.append(IndexPath(row: i, section: 0))
            }
            currentMin = currentMax
        }
        return indexPaths
    }
}

// MARK: - SegmentedControl+Statistical
extension TagCollectionView {
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        return true
    }
    
    open override func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        var indexPaths: [IndexPath] = []
        let subviewsCount = containerView.subviews.count
        for idx in 0..<subviewsCount {
            indexPaths.append(IndexPath(row: idx, section: 0))
        }
        return indexPaths
    }
}

extension TextTagCollectionView {
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        return true
    }
    
    open override func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        return tagCollectionView.statisticalViewVisibleIndexPaths()
    }
}

// MARK: - Autoloader+Module
@objc extension Autoloader {
    static func loadPlugin_Module() {
        BannerView.trackClickBlock = { view, indexPath in
            return view.fw_statisticalTrackClick(indexPath: indexPath)
        }
        
        BannerView.trackExposureBlock = { view in
            view.fw_statisticalCheckExposure()
        }
    }
}
