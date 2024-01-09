//
//  GridView.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import UIKit

/// 网格视图
///
/// 用于做九宫格布局，会将内部所有的 subview 根据指定的列数和行高，把每个 item（也即 subview） 拉伸到相同的大小。
/// 支持在 item 和 item 之间显示分隔线，分隔线支持虚线。
/// 注意分隔线是占位的，把 item 隔开，而不是盖在某个 item 上。
///
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
open class GridView: UIView {

    /// 指定要显示的列数，默认为 0
    @IBInspectable open var columnCount: Int = 0
    
    /// 指定每一行的高度，默认为 0
    @IBInspectable open var rowHeight: CGFloat = 0
    
    /// 指定 item 之间的分隔线宽度，默认为 0
    @IBInspectable open var separatorWidth: CGFloat = 0 {
        didSet {
            separatorLayer.lineWidth = separatorWidth
            separatorLayer.isHidden = separatorWidth <= 0
        }
    }
    
    /// 指定 item 之间的分隔线颜色，默认为 UIColorSeparator
    @IBInspectable open var separatorColor: UIColor? {
        didSet {
            separatorLayer.strokeColor = separatorColor?.cgColor
        }
    }
    
    /// item 之间的分隔线是否要用虚线显示，默认为 NO
    @IBInspectable open var separatorDashed: Bool = false
    
    /// 候选的初始化方法，亦可通过 initWithFrame:、init 来初始化。
    public init(column: Int, rowHeight: CGFloat) {
        super.init(frame: .zero)
        didInitialize()
        self.columnCount = column
        self.rowHeight = rowHeight
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private var separatorLayer: CAShapeLayer = CAShapeLayer()
        
    private func didInitialize() {
        separatorLayer.isHidden = true
        layer.addSublayer(separatorLayer)
        separatorColor = UIColor(red: 222.0/255.0, green: 224.0/255.0, blue: 226.0/255.0, alpha: 1)
        separatorLayer.strokeColor = separatorColor?.cgColor
    }
    
    // 返回最接近平均列宽的值，保证其为整数，因此所有columnWidth加起来可能比总宽度要小
    private func stretchColumnWidth() -> CGFloat {
        return floor((bounds.width - separatorWidth * CGFloat(columnCount - 1)) / CGFloat(columnCount))
    }
    
    private func rowCount() -> Int {
        let subviewCount = subviews.count
        return subviewCount / columnCount + (subviewCount % columnCount > 0 ? 1 : 0)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let rowCount = self.rowCount()
        let totalHeight = CGFloat(rowCount) * rowHeight + CGFloat(rowCount - 1) * separatorWidth
        return CGSize(width: size.width, height: totalHeight)
    }
    
    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let subviewCount = subviews.count
        if subviewCount == 0 { return }
        
        let size = bounds.size
        if size.width <= 0 || size.height <= 0 { return }
        
        let columnWidth = stretchColumnWidth()
        let rowCount = self.rowCount()
        
        let shouldShowSeparator = separatorWidth > 0
        let lineOffset = shouldShowSeparator ? separatorWidth / 2.0 : 0
        let separatorPath = shouldShowSeparator ? UIBezierPath() : nil
        
        for row in 0 ..< rowCount {
            for column in 0 ..< columnCount {
                let index = row * columnCount + column
                if index < subviewCount {
                    let isLastColumn = column == columnCount - 1
                    let isLastRow = row == rowCount - 1
                    
                    let subview = subviews[index]
                    var subviewFrame = CGRect(x: columnWidth * CGFloat(column) + separatorWidth * CGFloat(column), y: rowHeight * CGFloat(row) + separatorWidth * CGFloat(row), width: columnWidth, height: rowHeight)
                    
                    if isLastColumn {
                        // 每行最后一个item要占满剩余空间，否则可能因为strecthColumnWidth不精确导致右边漏空白
                        subviewFrame.size.width = size.width - columnWidth * CGFloat(columnCount - 1) - separatorWidth * CGFloat(columnCount - 1)
                    }
                    if isLastRow {
                        // 最后一行的item要占满剩余空间，避免一些计算偏差
                        subviewFrame.size.height = size.height - rowHeight * CGFloat(rowCount - 1) - separatorWidth * CGFloat(rowCount - 1)
                    }
                    
                    subview.frame = subviewFrame
                    subview.setNeedsLayout()
                    
                    if shouldShowSeparator {
                        // 每个 item 都画右边和下边这两条分隔线
                        let rightTopPoint = CGPoint(x: subviewFrame.maxX + lineOffset, y: subviewFrame.minY)
                        let rightBottomPoint = CGPoint(x: rightTopPoint.x - (isLastColumn ? lineOffset : 0), y: subviewFrame.maxY + (!isLastRow ? lineOffset : 0))
                        let leftBottomPoint = CGPoint(x: subviewFrame.minX, y: rightBottomPoint.y)
                        
                        if !isLastColumn {
                            separatorPath?.move(to: rightTopPoint)
                            separatorPath?.addLine(to: rightBottomPoint)
                        }
                        if !isLastRow {
                            separatorPath?.move(to: rightBottomPoint)
                            separatorPath?.addLine(to: leftBottomPoint)
                        }
                    }
                }
            }
        }
        
        if shouldShowSeparator {
            separatorLayer.path = separatorPath?.cgPath
        }
    }

}
