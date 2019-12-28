//
//  TestTableLayoutViewController.swift
//  Example
//
//  Created by wuyong on 2019/12/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

extension TestTableLayoutViewController {
    @objc func setupAnimatedSwift() {
        self.tableView.fwTabAnimated = FWTabTableAnimated(cellClass: TestTableLayoutCell.self, cellHeight: 140)
        self.tableView.fwTabAnimated?.animatedBackgroundColor = UIColor.appColorBg()
        self.tableView.fwTabAnimated?.adjustBlock = { (manager) in
            var color: UIColor = UIColor.appColorWhite()
            if #available(iOS 13.0, *) {
                color = UIColor(dynamicProvider: { (traitCollection) -> UIColor in
                    if traitCollection.userInterfaceStyle == .dark {
                        return UIColor.appColorMain()
                    } else {
                        return UIColor.appColorWhite()
                    }
                })
            }
            
            manager.animation(3)?.z(-1).height(120).color(color)
            manager.animation(3)?.layer.fwSetShadowColor(UIColor.gray, offset: CGSize(width: 0, height: 0), radius: 5)
            manager.animations(indexs: 0,1)?.line(1)
            manager.animations(1, 1)?.up(5)
            manager.animation(0)?.width(100).toLongAnimation()
            manager.animation(2)?.width(30).height(30).placeholder("AppIcon")
        }
    }
}
