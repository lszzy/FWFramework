//
//  BarrageView.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/25.
//

import UIKit

// MARK: - BarrageManager
/// 弹幕管理器
///
/// [OCBarrage](https://github.com/w1531724247/OCBarrage)
@MainActor open class BarrageManager: NSObject {
    open private(set) lazy var renderView: BarrageRenderView = {
        let result = BarrageRenderView()
        return result
    }()

    open var renderStatus: BarrageRenderStatus {
        renderView.renderStatus
    }

    open func start() {
        renderView.start()
    }

    open func pause() {
        renderView.pause()
    }

    open func resume() {
        renderView.resume()
    }

    open func stop() {
        renderView.stop()
    }

    open func renderBarrageDescriptor(_ barrageDescriptor: BarrageDescriptor) {
        guard let cellClass = barrageDescriptor.barrageCellClass,
              let barrageCell = renderView.dequeueReusableCell(withClass: cellClass) else {
            return
        }

        barrageCell.barrageDescriptor = barrageDescriptor
        renderView.fireBarrageCell(barrageCell)
    }
}

// MARK: - BarrageRenderView
public enum BarragePositionPriority: Int, Sendable {
    case low = 0
    case middle
    case high
    case veryHigh
}

public enum BarrageRenderPositionStyle: Int, Sendable {
    /// 将BarrageRenderView分成几条轨道, 随机选一条展示
    case randomTracks = 0
    /// y坐标随机
    case random
    /// y坐标递增, 循环
    case increase
}

public enum BarrageRenderStatus: Int, Sendable {
    case stopped = 0
    case started
    case paused
}

open class BarrageRenderView: UIView {
    private class MutableState: @unchecked Sendable {
        var animatingCells: [BarrageCell] = []
        var idleCells: [BarrageCell] = []
        var renderStatus: BarrageRenderStatus = .stopped
        var trackNextAvailableTime: [String: BarrageTrackInfo] = [:]
        var autoClear = false
    }

    open var renderPositionStyle: BarrageRenderPositionStyle = .randomTracks
    open var animatingCells: [BarrageCell] { mutableState.animatingCells }
    open var idleCells: [BarrageCell] { mutableState.idleCells }
    open var renderStatus: BarrageRenderStatus { mutableState.renderStatus }

    private let mutableState = MutableState()
    private let animatingCellsLock = DispatchSemaphore(value: 1)
    private let idleCellsLock = DispatchSemaphore(value: 1)
    private let trackInfoLock = DispatchSemaphore(value: 1)
    private var lastestCell: BarrageCell?

    private lazy var lowPositionView: UIView = {
        let result = UIView()
        return result
    }()

    private lazy var middlePositionView: UIView = {
        let result = UIView()
        return result
    }()

    private lazy var highPositionView: UIView = {
        let result = UIView()
        return result
    }()

    private lazy var veryHighPositionView: UIView = {
        let result = UIView()
        return result
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }

    private func didInitialize() {
        addSubview(lowPositionView)
        addSubview(middlePositionView)
        addSubview(highPositionView)
        addSubview(veryHighPositionView)
        layer.masksToBounds = true
    }

    deinit {
        guard mutableState.renderStatus != .stopped else { return }
        mutableState.renderStatus = .stopped

        if mutableState.autoClear {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(clearIdleCells), object: nil)
        }

        mutableState.animatingCells.removeAll()
        mutableState.idleCells.removeAll()
        mutableState.trackNextAvailableTime.removeAll()
    }

    open func dequeueReusableCell(withClass barrageCellClass: BarrageCell.Type) -> BarrageCell? {
        var barrageCell: BarrageCell?

        idleCellsLock.wait()
        for cell in mutableState.idleCells {
            if type(of: cell) == barrageCellClass {
                barrageCell = cell
                break
            }
        }
        if let barrageCell {
            mutableState.idleCells.removeAll { $0 == barrageCell }
            barrageCell.idleTime = 0
        } else {
            barrageCell = barrageCellClass.init()
        }
        idleCellsLock.signal()

        return barrageCell
    }

    open func fireBarrageCell(_ barrageCell: BarrageCell) {
        switch mutableState.renderStatus {
        case .started:
            break
        case .paused:
            return
        default:
            return
        }

        barrageCell.clearContents()
        barrageCell.updateSubviewsData()
        barrageCell.layoutContentSubviews()
        barrageCell.convertContentToImage()
        barrageCell.sizeToFit()
        barrageCell.removeSubviewsAndSublayers()
        barrageCell.addBorderAttributes()

        animatingCellsLock.wait()
        lastestCell = mutableState.animatingCells.last
        mutableState.animatingCells.append(barrageCell)
        barrageCell.isIdle = false
        animatingCellsLock.signal()

        addBarrageCell(barrageCell, positionPriority: barrageCell.barrageDescriptor?.positionPriority ?? .low)
        let cellFrame = calculateBarrageCellFrame(barrageCell)
        barrageCell.frame = cellFrame
        barrageCell.addBarrageAnimation(delegate: self)
        recordTrackInfo(barrageCell)

        lastestCell = barrageCell
    }

    @discardableResult
    open func triggerAction(point touchPoint: CGPoint) -> Bool {
        animatingCellsLock.wait()

        var anyTrigger = false
        let cells = mutableState.animatingCells.reversed()
        for cell in cells {
            if cell.layer.presentation()?.hitTest(touchPoint) != nil {
                if let barrageDescriptor = cell.barrageDescriptor,
                   let cellTouchedAction = barrageDescriptor.cellTouchedAction {
                    cellTouchedAction(barrageDescriptor, cell)
                    anyTrigger = true
                }
                break
            }
        }

        animatingCellsLock.signal()

        return anyTrigger
    }

    open func start() {
        switch mutableState.renderStatus {
        case .started:
            return
        case .paused:
            resume()
        default:
            mutableState.renderStatus = .started
        }
    }

    open func pause() {
        switch mutableState.renderStatus {
        case .started:
            mutableState.renderStatus = .paused
        case .paused:
            return
        default:
            return
        }

        animatingCellsLock.wait()
        let cells = mutableState.animatingCells.reversed()
        for cell in cells {
            let pausedTime = cell.layer.convertTime(CACurrentMediaTime(), from: nil)
            cell.layer.speed = 0
            cell.layer.timeOffset = pausedTime
        }
        animatingCellsLock.signal()
    }

    open func resume() {
        switch mutableState.renderStatus {
        case .started:
            return
        case .paused:
            mutableState.renderStatus = .started
        default:
            return
        }

        animatingCellsLock.wait()
        let cells = mutableState.animatingCells.reversed()
        for cell in cells {
            let pausedTime = cell.layer.timeOffset
            cell.layer.speed = 1.0
            cell.layer.timeOffset = 0
            cell.layer.beginTime = 0
            let timeSincePause = cell.layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            cell.layer.beginTime = timeSincePause
        }
        animatingCellsLock.signal()
    }

    open func stop() {
        switch mutableState.renderStatus {
        case .started:
            mutableState.renderStatus = .stopped
        case .paused:
            mutableState.renderStatus = .stopped
        default:
            return
        }

        if mutableState.autoClear {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(clearIdleCells), object: nil)
        }

        animatingCellsLock.wait()
        let cells = mutableState.animatingCells.reversed()
        for cell in cells {
            let pausedTime = cell.layer.convertTime(CACurrentMediaTime(), from: nil)
            cell.layer.speed = 0
            cell.layer.timeOffset = pausedTime
            cell.layer.removeAllAnimations()
            cell.removeFromSuperview()
        }
        mutableState.animatingCells.removeAll()
        animatingCellsLock.signal()

        idleCellsLock.wait()
        mutableState.idleCells.removeAll()
        idleCellsLock.signal()

        trackInfoLock.wait()
        mutableState.trackNextAvailableTime.removeAll()
        trackInfoLock.signal()
    }

    open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if !flag { return }
        if mutableState.renderStatus == .stopped { return }

        var animatedCell: BarrageCell?
        animatingCellsLock.wait()
        for cell in mutableState.animatingCells {
            if cell.barrageAnimation == anim {
                animatedCell = cell
                mutableState.animatingCells.removeAll { $0 == cell }
                break
            }
        }
        animatingCellsLock.signal()

        guard let animatedCell else { return }

        trackInfoLock.wait()
        let trackInfo = mutableState.trackNextAvailableTime[nextAvailableTimeKey(animatedCell, index: animatedCell.trackIndex)]
        if let trackInfo {
            trackInfo.barrageCount -= 1
        }
        trackInfoLock.signal()

        animatedCell.removeFromSuperview()
        animatedCell.prepareForReuse()

        idleCellsLock.wait()
        animatedCell.idleTime = Date().timeIntervalSince1970
        mutableState.idleCells.append(animatedCell)
        idleCellsLock.signal()

        if !mutableState.autoClear {
            perform(#selector(clearIdleCells), with: nil, afterDelay: 5.0)
            mutableState.autoClear = true
        }
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if event?.type == .touches, let touch = touches.first {
            let touchPoint = touch.location(in: self)
            triggerAction(point: touchPoint)
        }
    }

    private func addBarrageCell(_ barrageCell: BarrageCell, positionPriority: BarragePositionPriority) {
        switch positionPriority {
        case .middle:
            insertSubview(barrageCell, aboveSubview: middlePositionView)
        case .high:
            insertSubview(barrageCell, belowSubview: highPositionView)
        case .veryHigh:
            insertSubview(barrageCell, belowSubview: veryHighPositionView)
        default:
            insertSubview(barrageCell, belowSubview: lowPositionView)
        }
    }

    private func calculateBarrageCellFrame(_ barrageCell: BarrageCell) -> CGRect {
        var cellFrame = barrageCell.bounds
        cellFrame.origin.x = frame.maxX

        if let renderRange = barrageCell.barrageDescriptor?.renderRange {
            let cellHeight = barrageCell.bounds.height
            let minOriginY = max(0, CGFloat(renderRange.location))
            let maxOriginY = min(CGFloat(renderRange.length), bounds.height)
            var renderHeight = maxOriginY - minOriginY
            if renderHeight < 0 {
                renderHeight = cellHeight
            }

            // 用户改变行高(比如弹幕文字大小不会引起显示bug, 因为虽然是同一个类, 但是trackCount变小了, 所以不会出现trackIndex * cellHeight超出屏幕边界的情况)
            let trackCount = Int(floor(renderHeight / cellHeight))
            var trackIndex = Int(arc4random_uniform(UInt32(trackCount)))

            trackInfoLock.wait()
            let trackInfo = mutableState.trackNextAvailableTime[nextAvailableTimeKey(barrageCell, index: trackIndex)]
            // 当前行暂不可用
            if let trackInfo, trackInfo.nextAvailableTime > CACurrentMediaTime() {
                var availableTrackInfos = [BarrageTrackInfo]()
                for info in mutableState.trackNextAvailableTime.values {
                    // 只在同类弹幕中判断是否有可用的轨道
                    if CACurrentMediaTime() > info.nextAvailableTime && info.trackIdentifier.contains(NSStringFromClass(type(of: barrageCell))) {
                        availableTrackInfos.append(info)
                    }
                }
                if availableTrackInfos.count > 0 {
                    let randomInfo = availableTrackInfos.randomElement()
                    trackIndex = randomInfo?.trackIndex ?? 0
                } else {
                    // 刚开始不是每一条轨道都跑过弹幕, 还有空轨道
                    if mutableState.trackNextAvailableTime.count < trackCount {
                        var numberArray = [Int]()
                        for index in 0..<trackCount {
                            let emptyTrackInfo = mutableState.trackNextAvailableTime[nextAvailableTimeKey(barrageCell, index: index)]
                            if emptyTrackInfo == nil {
                                numberArray.append(index)
                            }
                        }
                        if numberArray.count > 0 {
                            trackIndex = numberArray.randomElement() ?? 0
                        }
                    }
                    // 真的是没有可用的轨道了
                }
            }
            trackInfoLock.signal()

            barrageCell.trackIndex = trackIndex
            cellFrame.origin.y = CGFloat(trackIndex) * cellHeight + minOriginY
        } else {
            switch renderPositionStyle {
            case .random:
                let maxY = bounds.height - cellFrame.height
                let originY = Int(floor(maxY))
                cellFrame.origin.y = CGFloat(arc4random_uniform(UInt32(originY)))
            case .increase:
                if let latestFrame = lastestCell?.frame {
                    cellFrame.origin.y = latestFrame.maxY
                } else {
                    cellFrame.origin.y = 0.0
                }
            default:
                let renderViewHeight = bounds.height
                let cellHeight = barrageCell.bounds.height
                // 用户改变行高(比如弹幕文字大小不会引起显示bug, 因为虽然是同一个类, 但是trackCount变小了, 所以不会出现trackIndex*cellHeight超出屏幕边界的情况)
                let trackCount = Int(floor(renderViewHeight / cellHeight))
                var trackIndex = Int(arc4random_uniform(UInt32(trackCount)))

                trackInfoLock.wait()
                let trackInfo = mutableState.trackNextAvailableTime[nextAvailableTimeKey(barrageCell, index: trackIndex)]
                // 当前行暂不可用
                if let trackInfo, trackInfo.nextAvailableTime > CACurrentMediaTime() {
                    var availableTrackInfos = [BarrageTrackInfo]()
                    for info in mutableState.trackNextAvailableTime.values {
                        // 只在同类弹幕中判断是否有可用的轨道
                        if CACurrentMediaTime() > info.nextAvailableTime && info.trackIdentifier.contains(NSStringFromClass(type(of: barrageCell))) {
                            availableTrackInfos.append(info)
                        }
                    }
                    if availableTrackInfos.count > 0 {
                        let randomInfo = availableTrackInfos.randomElement()
                        trackIndex = randomInfo?.trackIndex ?? 0
                    } else {
                        // 刚开始不是每一条轨道都跑过弹幕, 还有空轨道
                        if mutableState.trackNextAvailableTime.count < trackCount {
                            var numberArray = [Int]()
                            for index in 0..<trackCount {
                                let emptyTrackInfo = mutableState.trackNextAvailableTime[nextAvailableTimeKey(barrageCell, index: index)]
                                if emptyTrackInfo == nil {
                                    numberArray.append(index)
                                }
                            }
                            if numberArray.count > 0 {
                                trackIndex = numberArray.randomElement() ?? 0
                            }
                        }
                        // 真的是没有可用的轨道了
                    }
                }
                trackInfoLock.signal()

                barrageCell.trackIndex = trackIndex
                cellFrame.origin.y = CGFloat(trackIndex) * cellHeight
            }
        }

        // 超过底部, 回到顶部
        if cellFrame.maxY > bounds.height {
            cellFrame.origin.y = 0
        } else if cellFrame.origin.y < 0 {
            cellFrame.origin.y = 0
        }
        return cellFrame
    }

    @objc private func clearIdleCells() {
        idleCellsLock.wait()
        let timeInterval = Date().timeIntervalSince1970
        let cells = mutableState.idleCells.reversed()
        for cell in cells {
            let time = timeInterval - cell.idleTime
            if time > 5.0 && cell.idleTime > 0 {
                mutableState.idleCells.removeAll { $0 == cell }
            }
        }

        if mutableState.idleCells.isEmpty {
            mutableState.autoClear = false
        } else {
            perform(#selector(clearIdleCells), with: nil, afterDelay: 5.0)
        }
        idleCellsLock.signal()
    }

    private func recordTrackInfo(_ barrageCell: BarrageCell) {
        let nextAvailableTimeKey = nextAvailableTimeKey(barrageCell, index: barrageCell.trackIndex)
        let duration = barrageCell.barrageAnimation?.duration ?? 0
        var fromValue: NSValue?
        var toValue: NSValue?

        if let basicAnimation = barrageCell.barrageAnimation as? CABasicAnimation {
            fromValue = basicAnimation.fromValue as? NSValue
            toValue = basicAnimation.toValue as? NSValue
        } else if let keyframeAnimation = barrageCell.barrageAnimation as? CAKeyframeAnimation {
            fromValue = keyframeAnimation.values?.first as? NSValue
            toValue = keyframeAnimation.values?.last as? NSValue
        }

        guard let fromValueType = fromValue?.objCType,
              let toValueType = toValue?.objCType,
              let fromValueString = String(cString: fromValueType, encoding: .utf8),
              let toValueString = String(cString: toValueType, encoding: .utf8),
              fromValueString == toValueString else {
            return
        }

        if fromValueString.contains("CGPoint") {
            let fromPoint = fromValue?.cgPointValue ?? .zero
            let toPoint = toValue?.cgPointValue ?? .zero

            trackInfoLock.wait()

            var trackInfo: BarrageTrackInfo
            if let nextInfo = mutableState.trackNextAvailableTime[nextAvailableTimeKey] {
                trackInfo = nextInfo
            } else {
                trackInfo = BarrageTrackInfo()
                trackInfo.trackIdentifier = nextAvailableTimeKey
                trackInfo.trackIndex = barrageCell.trackIndex
            }
            trackInfo.barrageCount += 1

            trackInfo.nextAvailableTime = barrageCell.bounds.width
            let distanceX = abs(toPoint.x - fromPoint.x)
            let distanceY = abs(toPoint.y - fromPoint.y)
            let distance = max(distanceX, distanceY)
            let speed = distance / duration

            if distanceX == distance {
                let time = barrageCell.bounds.width / speed
                trackInfo.nextAvailableTime = CACurrentMediaTime() + time + 0.1
                mutableState.trackNextAvailableTime[nextAvailableTimeKey] = trackInfo
            }

            trackInfoLock.signal()
        }
    }

    private func nextAvailableTimeKey(_ barrageCell: BarrageCell, index: Int) -> String {
        "\(NSStringFromClass(type(of: barrageCell)))_\(index)"
    }
}

#if swift(>=6.0)
extension BarrageRenderView: @preconcurrency CAAnimationDelegate {}
#else
extension BarrageRenderView: CAAnimationDelegate {}
#endif

// MARK: - BarrageDescriptor
open class BarrageDescriptor: NSObject {
    open var barrageCellClass: BarrageCell.Type?
    /// 显示位置normal型的渲染在low型的上面, height型的渲染在normal上面
    open var positionPriority: BarragePositionPriority = .low
    /// 动画时间, 时间越长速度越慢, 时间越短速度越快
    open var animationDuration: CGFloat = 0
    /// 固定速度, 可以防止弹幕在有空闲轨道的情况下重叠, 取值0.0~100.0, animationDuration与fixedSpeed只能选择一个, fixedSpeed设置之后可以不用设置animationDuration
    open var fixedSpeed: CGFloat = 0

    /// 新属性里回传了被点击的cell, 可以在代码块里更改被点击的cell的属性, 比如之前有用户需要在弹幕被点击的时候修改被点击的弹幕的文字颜色等等. 用来替代旧版本的touchAction
    open var cellTouchedAction: (@MainActor @Sendable (BarrageDescriptor, BarrageCell) -> Void)?
    /// 边框颜色
    open var borderColor: UIColor?
    /// 边框宽度
    open var borderWidth: CGFloat = 0
    /// 圆角
    open var cornerRadius: CGFloat = 0

    /// 渲染范围, 最终渲染出来的弹幕的Y坐标最小不小于renderRange.location, 最大不超过renderRange.length-barrageCell.height
    open var renderRange: NSRange?
}

// MARK: - BarrageCell
public protocol BarrageCellDelegate: CAAnimationDelegate {}

open class BarrageCell: UIView {
    public static let barrageAnimationKey = "BarrageAnimation"

    /// 是否是空闲状态
    open var isIdle: Bool = false
    /// 开始闲置的时间, 闲置超过5秒的, 自动回收内存
    open var idleTime: TimeInterval = 0
    open var barrageDescriptor: BarrageDescriptor?
    open var trackIndex: Int = -1
    open var barrageAnimation: CAAnimation? {
        layer.animation(forKey: Self.barrageAnimationKey)
    }

    open func addBarrageAnimation(delegate: CAAnimationDelegate?) {}

    open func prepareForReuse() {
        layer.removeAnimation(forKey: Self.barrageAnimationKey)
        barrageDescriptor = nil
        if !isIdle {
            isIdle = true
        }
        trackIndex = -1
    }

    open func clearContents() {
        layer.contents = nil
    }

    open func updateSubviewsData() {}

    open func layoutContentSubviews() {}

    open func convertContentToImage() {}

    /// 设置好数据之后调用一下自动计算bounds
    override open func sizeToFit() {
        var height: CGFloat = 0.0
        var width: CGFloat = 0.0
        layer.sublayers?.forEach { sublayer in
            let maxY = sublayer.frame.maxY
            if maxY > height {
                height = maxY
            }

            let maxX = sublayer.frame.maxX
            if maxX > width {
                width = maxX
            }
        }

        if width == 0 || height == 0 {
            if let content = layer.contents, let cgImage = content as! CGImage? {
                let image = UIImage(cgImage: cgImage)
                width = image.size.width / UIScreen.main.scale
                height = image.size.height / UIScreen.main.scale
            }
        }

        bounds = CGRect(x: 0, y: 0, width: width, height: height)
    }

    /// 默认删除所有的subview和sublayer; 如果需要选择性的删除可以重写这个方法
    open func removeSubviewsAndSublayers() {
        subviews.forEach { $0.removeFromSuperview() }
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    open func addBorderAttributes() {
        if let borderColor = barrageDescriptor?.borderColor {
            layer.borderColor = borderColor.cgColor
        }
        if let borderWidth = barrageDescriptor?.borderWidth, borderWidth > 0 {
            layer.borderWidth = borderWidth
        }
        if let cornerRadius = barrageDescriptor?.cornerRadius, cornerRadius > 0 {
            layer.cornerRadius = cornerRadius
        }
    }
}

// MARK: - BarrageTextDescriptor
open class BarrageTextDescriptor: BarrageDescriptor {
    open var textFont: UIFont = .systemFont(ofSize: 17) {
        didSet {
            textAttribute[.font] = textFont
        }
    }

    open var textColor: UIColor = .white {
        didSet {
            textAttribute[.foregroundColor] = textColor
        }
    }

    /// 关闭文字阴影可大幅提升性能, 推荐使用strokeColor, 与shadowColor相比strokeColor性能更强悍
    open var textShadowOpened = false {
        didSet {
            if textShadowOpened {
                textAttribute.removeValue(forKey: .strokeColor)
                textAttribute.removeValue(forKey: .strokeWidth)
            }
        }
    }

    /// 默认黑色
    open var shadowColor: UIColor? = .black
    /// 默认CGSizeZero
    open var shadowOffset: CGSize = .zero
    /// 默认2.0
    open var shadowRadius: CGFloat = 2.0
    /// 默认0.5
    open var shadowOpacity: Float = 0.5

    open var strokeColor: UIColor? {
        didSet {
            if textShadowOpened { return }
            textAttribute[.strokeColor] = strokeColor
        }
    }

    /// 笔画宽度(粗细)，取值为整数，负值填充效果，正值中空效果
    open var strokeWidth: Int = 0 {
        didSet {
            if textShadowOpened { return }
            textAttribute[.strokeWidth] = NSNumber(value: strokeWidth)
        }
    }

    open var text: String? {
        get {
            if _text == nil {
                _text = _attributedText?.string
            }
            return _text
        }
        set {
            _text = newValue
        }
    }

    private var _text: String?

    open var attributedText: NSAttributedString? {
        get {
            if _attributedText == nil {
                guard let _text else { return nil }
                _attributedText = NSAttributedString(string: _text, attributes: textAttribute)
            }
            guard let _attributedText else { return nil }

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.baseWritingDirection = .leftToRight
            let attrText = NSMutableAttributedString(attributedString: _attributedText)
            attrText.addAttributes([.paragraphStyle: paragraphStyle], range: NSMakeRange(0, (attrText.string as NSString).length))
            return attrText
        }
        set {
            _attributedText = newValue
        }
    }

    private var _attributedText: NSAttributedString?

    private var textAttribute: [NSAttributedString.Key: Any] = [:]
}

// MARK: - BarrageTextCell
open class BarrageTextCell: BarrageCell {
    open var textDescriptor: BarrageTextDescriptor?

    override open var barrageDescriptor: BarrageDescriptor? {
        didSet {
            textDescriptor = barrageDescriptor as? BarrageTextDescriptor
        }
    }

    open var textLabel: UILabel {
        get {
            if let result = _textLabel {
                return result
            }

            let result = UILabel()
            result.textAlignment = .center
            _textLabel = result
            return result
        }
        set {
            _textLabel = newValue
        }
    }

    private var _textLabel: UILabel?

    override open func prepareForReuse() {
        super.prepareForReuse()
    }

    override open func updateSubviewsData() {
        if _textLabel == nil {
            addSubview(textLabel)
        }
        if let textDescriptor, textDescriptor.textShadowOpened {
            textLabel.layer.shadowColor = textDescriptor.shadowColor?.cgColor
            textLabel.layer.shadowOffset = textDescriptor.shadowOffset
            textLabel.layer.shadowRadius = textDescriptor.shadowRadius
            textLabel.layer.shadowOpacity = textDescriptor.shadowOpacity
        }

        textLabel.attributedText = textDescriptor?.attributedText
    }

    override open func layoutContentSubviews() {
        let textFrame = textDescriptor?.attributedText?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil) ?? .zero
        textLabel.frame = textFrame
    }

    override open func convertContentToImage() {
        let contentSize = _textLabel?.frame.size ?? .zero
        UIGraphicsBeginImageContextWithOptions(contentSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
        }
        let contentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        layer.contents = contentImage?.cgImage
    }

    override open func removeSubviewsAndSublayers() {
        super.removeSubviewsAndSublayers()

        _textLabel = nil
    }

    override open func addBarrageAnimation(delegate: CAAnimationDelegate?) {
        guard let superview else { return }

        let startCenter = CGPoint(x: superview.bounds.maxX + bounds.width / 2, y: center.y)
        let endCenter = CGPoint(x: -(bounds.width / 2), y: center.y)

        var animationDuration = barrageDescriptor?.animationDuration ?? 0
        if let barrageDescriptor, barrageDescriptor.fixedSpeed > 0.0 {
            if barrageDescriptor.fixedSpeed > 100.0 {
                barrageDescriptor.fixedSpeed = 100.0
            }
            animationDuration = (startCenter.x - endCenter.x) / (UIScreen.main.scale * 2) / barrageDescriptor.fixedSpeed
        }

        let walkAnimation = CAKeyframeAnimation(keyPath: "position")
        walkAnimation.values = [NSValue(cgPoint: startCenter), NSValue(cgPoint: endCenter)]
        walkAnimation.keyTimes = [0.0, 1.0]
        walkAnimation.duration = animationDuration
        walkAnimation.repeatCount = 1
        walkAnimation.delegate = delegate
        walkAnimation.isRemovedOnCompletion = false
        walkAnimation.fillMode = .forwards

        layer.add(walkAnimation, forKey: Self.barrageAnimationKey)
    }
}

// MARK: - BarrageTrackInfo
open class BarrageTrackInfo: NSObject {
    open var trackIndex: Int = 0
    open var trackIdentifier: String = ""
    /// 下次可用的时间
    open var nextAvailableTime: CFTimeInterval = 0
    /// 当前行的弹幕数量
    open var barrageCount: Int = 0
    /// 轨道高度
    open var trackHeight: CGFloat = 0
}
