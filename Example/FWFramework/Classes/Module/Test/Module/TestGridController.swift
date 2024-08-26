//
//  TestGridController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestGridController: UIViewController, ViewControllerProtocol {
    private lazy var gridView: GridView = {
        let result = GridView()
        result.columnCount = 3
        result.rowHeight = 60
        result.separatorWidth = 0.5
        result.separatorColor = AppTheme.borderColor
        result.separatorDashed = false
        return result
    }()

    private lazy var tipsLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.attributedText = NSAttributedString(string: "适用于那种要将若干个 UIView 以九宫格的布局摆放的情况，支持显示 item 之间的分隔线。\n注意当宽度发生较大变化时（例如横屏旋转），并不会自动增加列数，这种场景要么自己重新设置 columnCount，要么改为用 UICollectionView 实现。", attributes: [
            .font: APP.font(12),
            .foregroundColor: AppTheme.textColor
        ])
        return result
    }()

    func setupSubviews() {
        view.addSubview(gridView)
        gridView.app.layoutChain
            .edges(toSafeArea: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24), excludingEdge: .bottom)

        let themeColors = [UIColor.app.randomColor, UIColor.app.randomColor, UIColor.app.randomColor, UIColor.app.randomColor, UIColor.app.randomColor, UIColor.app.randomColor, UIColor.app.randomColor, UIColor.app.randomColor]
        for themeColor in themeColors {
            let view = UIView()
            view.backgroundColor = themeColor.withAlphaComponent(0.7)
            gridView.addSubview(view)
        }

        view.addSubview(tipsLabel)
        tipsLabel.app.layoutChain
            .left(24)
            .right(24)
            .top(toViewBottom: gridView, offset: 16)
    }
}
