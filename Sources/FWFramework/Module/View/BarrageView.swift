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
open class BarrageManager: NSObject {
    open private(set) lazy var renderView: BarrageRenderView = {
        let result = BarrageRenderView()
        return result
    }()
    
    open var renderStatus: BarrageRenderStatus {
        return renderView.renderStatus
    }
    
    deinit {
        renderView.stop()
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
public enum BarragePositionPriority: Int {
    case low = 0
    case middle
    case high
    case veryHigh
}

public enum BarrageRenderPositionStyle: Int {
    /// 将BarrageRenderView分成几条轨道, 随机选一条展示
    case randomTracks = 0
    /// y坐标随机
    case random
    /// y坐标递增, 循环
    case increase
}

public enum BarrageRenderStatus: Int {
    case stopped = 0
    case started
    case paused
}

open class BarrageRenderView: UIView, CAAnimationDelegate {
    open var renderPositionStyle: BarrageRenderPositionStyle = .randomTracks
    open private(set) var animatingCells: [BarrageCell] = []
    open private(set) var idleCells: [BarrageCell] = []
    open private(set) var renderStatus: BarrageRenderStatus = .stopped
    
    private let animatingCellsLock = DispatchSemaphore(value: 1)
    private let idleCellsLock = DispatchSemaphore(value: 1)
    private let trackInfoLock = DispatchSemaphore(value: 1)
    private var lastestCell: BarrageCell?
    private var autoClear = false
    private var trackNextAvailableTime: [String: BarrageTrackInfo] = [:]
    
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
    
    public override init(frame: CGRect) {
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
    
    open func dequeueReusableCell(withClass barrageCellClass: BarrageCell.Type) -> BarrageCell? {
        var barrageCell: BarrageCell?
        
        idleCellsLock.wait()
        for cell in idleCells {
            if type(of: cell) == barrageCellClass {
                barrageCell = cell
                break
            }
        }
        if let barrageCell = barrageCell {
            idleCells.removeAll { $0 == barrageCell }
            barrageCell.idleTime = 0
        } else {
            barrageCell = barrageCellClass.init()
        }
        idleCellsLock.signal()
        
        return barrageCell
    }
    
    open func fireBarrageCell(_ barrageCell: BarrageCell) {
        switch renderStatus {
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
        lastestCell = animatingCells.last
        animatingCells.append(barrageCell)
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
        let cells = animatingCells.reversed()
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
        switch renderStatus {
        case .started:
            return
        case .paused:
            resume()
        default:
            renderStatus = .started
        }
    }
    
    open func pause() {
        switch renderStatus {
        case .started:
            renderStatus = .paused
        case .paused:
            return
        default:
            return
        }
        
        animatingCellsLock.wait()
        let cells = animatingCells.reversed()
        for cell in cells {
            let pausedTime = cell.layer.convertTime(CACurrentMediaTime(), from: nil)
            cell.layer.speed = 0
            cell.layer.timeOffset = pausedTime
        }
        animatingCellsLock.signal()
    }
    
    open func resume() {
        switch renderStatus {
        case .started:
            return
        case .paused:
            renderStatus = .started
        default:
            return
        }
        
        animatingCellsLock.wait()
        let cells = animatingCells.reversed()
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
        switch renderStatus {
        case .started:
            renderStatus = .stopped
        case .paused:
            renderStatus = .stopped
        default:
            return
        }
        
        if autoClear {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(clearIdleCells), object: nil)
        }
        
        animatingCellsLock.wait()
        let cells = animatingCells.reversed()
        for cell in cells {
            let pausedTime = cell.layer.convertTime(CACurrentMediaTime(), from: nil)
            cell.layer.speed = 0
            cell.layer.timeOffset = pausedTime
            cell.layer.removeAllAnimations()
            cell.removeFromSuperview()
        }
        animatingCells.removeAll()
        animatingCellsLock.signal()
        
        idleCellsLock.wait()
        idleCells.removeAll()
        idleCellsLock.signal()
        
        trackInfoLock.wait()
        trackNextAvailableTime.removeAll()
        trackInfoLock.signal()
    }
    
    open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if !flag { return }
        if renderStatus == .stopped { return }
        
        var animatedCell: BarrageCell?
        animatingCellsLock.wait()
        for cell in animatingCells {
            if cell.barrageAnimation == anim {
                animatedCell = cell
                animatingCells.removeAll { $0 == cell }
                break
            }
        }
        animatingCellsLock.signal()
        
        guard let animatedCell = animatedCell else { return }
        
        trackInfoLock.wait()
        let trackInfo = trackNextAvailableTime[nextAvailableTimeKey(animatedCell, index: animatedCell.trackIndex)]
        if let trackInfo = trackInfo {
            trackInfo.barrageCount -= 1
        }
        trackInfoLock.signal()
        
        animatedCell.removeFromSuperview()
        animatedCell.prepareForReuse()
        
        idleCellsLock.wait()
        animatedCell.idleTime = Date().timeIntervalSince1970
        idleCells.append(animatedCell)
        idleCellsLock.signal()
        
        if !autoClear {
            perform(#selector(clearIdleCells), with: nil, afterDelay: 5.0)
            autoClear = true
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
        
    }
    
    @objc private func clearIdleCells() {
        idleCellsLock.wait()
        let timeInterval = Date().timeIntervalSince1970
        let cells = idleCells.reversed()
        for cell in cells {
            let time = timeInterval - cell.idleTime
            if time > 5.0 && cell.idleTime > 0 {
                idleCells.removeAll { $0 == cell }
            }
        }
        
        if idleCells.isEmpty {
            autoClear = false
        } else {
            perform(#selector(clearIdleCells), with: nil, afterDelay: 5.0)
        }
        idleCellsLock.signal()
    }
    
    private func recordTrackInfo(_ barrageCell: BarrageCell) {
        
    }
    
    private func nextAvailableTimeKey(_ barrageCell: BarrageCell, index: Int) -> String {
        return "\(NSStringFromClass(barrageCell.classForCoder))_\(index)"
    }
}

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
    open var cellTouchedAction: ((BarrageDescriptor, BarrageCell) -> Void)?
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
    public static let BarrageAnimationKey = "BarrageAnimation"
    
    /// 是否是空闲状态
    open var isIdle: Bool = false
    /// 开始闲置的时间, 闲置超过5秒的, 自动回收内存
    open var idleTime: TimeInterval = 0
    open var barrageDescriptor: BarrageDescriptor?
    open var trackIndex: Int = -1
    open var barrageAnimation: CAAnimation? {
        return layer.animation(forKey: Self.BarrageAnimationKey)
    }

    open func addBarrageAnimation(delegate: CAAnimationDelegate?) {}

    open func prepareForReuse() {
        self.layer.removeAnimation(forKey: Self.BarrageAnimationKey)
        barrageDescriptor = nil
        if !isIdle {
            isIdle = true
        }
        trackIndex = -1
    }

    open func clearContents() {
        self.layer.contents = nil
    }

    open func updateSubviewsData() {}

    open func layoutContentSubviews() {}

    open func convertContentToImage() {}

    /// 设置好数据之后调用一下自动计算bounds
    open override func sizeToFit() {
        var height: CGFloat = 0.0
        var width: CGFloat = 0.0
        self.layer.sublayers?.forEach({ sublayer in
            let maxY = sublayer.frame.maxY
            if maxY > height {
                height = maxY
            }
            
            let maxX = sublayer.frame.maxX
            if maxX > width {
                width = maxX
            }
        })
        
        if width == 0 || height == 0 {
            if let content = self.layer.contents, let cgImage = content as! CGImage? {
                let image = UIImage(cgImage: cgImage)
                width = image.size.width / UIScreen.main.scale
                height = image.size.height / UIScreen.main.scale
            }
        }
        
        self.bounds = CGRect(x: 0, y: 0, width: width, height: height)
    }

    /// 默认删除所有的subview和sublayer; 如果需要选择性的删除可以重写这个方法
    open func removeSubviewsAndSublayers() {
        self.subviews.forEach { $0.removeFromSuperview() }
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    open func addBorderAttributes() {
        if let borderColor = barrageDescriptor?.borderColor {
            self.layer.borderColor = borderColor.cgColor
        }
        if let borderWidth = barrageDescriptor?.borderWidth, borderWidth > 0 {
            self.layer.borderWidth = borderWidth
        }
        if let cornerRadius = barrageDescriptor?.cornerRadius, cornerRadius > 0 {
            self.layer.cornerRadius = cornerRadius
        }
    }
}

// MARK: - BarrageTextDescriptor
open class BarrageTextDescriptor: BarrageDescriptor {
    open var textFont: UIFont = UIFont.systemFont(ofSize: 17) {
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
                guard let _text = _text else { return nil }
                _attributedText = NSAttributedString(string: _text, attributes: textAttribute)
            }
            guard let _attributedText = _attributedText else { return nil }
            
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
    
    open override var barrageDescriptor: BarrageDescriptor? {
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
    
    open override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    open override func updateSubviewsData() {
        if _textLabel == nil {
            addSubview(textLabel)
        }
        if let textDescriptor = textDescriptor, textDescriptor.textShadowOpened {
            textLabel.layer.shadowColor = textDescriptor.shadowColor?.cgColor
            textLabel.layer.shadowOffset = textDescriptor.shadowOffset
            textLabel.layer.shadowRadius = textDescriptor.shadowRadius
            textLabel.layer.shadowOpacity = textDescriptor.shadowOpacity
        }
        
        textLabel.attributedText = textDescriptor?.attributedText
    }
    
    open override func layoutContentSubviews() {
        let textFrame = textDescriptor?.attributedText?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil) ?? .zero
        textLabel.frame = textFrame
    }
    
    open override func convertContentToImage() {
        let contentSize = _textLabel?.frame.size ?? .zero
        UIGraphicsBeginImageContextWithOptions(contentSize, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
        }
        let contentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.layer.contents = contentImage?.cgImage
    }
    
    open override func removeSubviewsAndSublayers() {
        super.removeSubviewsAndSublayers()
        
        _textLabel = nil
    }
    
    open override func addBarrageAnimation(delegate: CAAnimationDelegate?) {
        guard let superview = self.superview else { return }
        
        let startCenter = CGPoint(x: superview.bounds.maxX + bounds.width/2, y: center.y)
        let endCenter = CGPoint(x: -(bounds.width/2), y: center.y)
        
        var animationDuration = barrageDescriptor?.animationDuration ?? 0
        if let barrageDescriptor = barrageDescriptor, barrageDescriptor.fixedSpeed > 0.0 {
            if barrageDescriptor.fixedSpeed > 100.0 {
                barrageDescriptor.fixedSpeed = 100.0
            }
            animationDuration = (startCenter.x - endCenter.x)/(UIScreen.main.scale*2)/barrageDescriptor.fixedSpeed
        }
        
        let walkAnimation = CAKeyframeAnimation(keyPath: "position")
        walkAnimation.values = [NSValue(cgPoint: startCenter), NSValue(cgPoint: endCenter)]
        walkAnimation.keyTimes = [0.0, 1.0]
        walkAnimation.duration = animationDuration
        walkAnimation.repeatCount = 1
        walkAnimation.delegate = delegate
        walkAnimation.isRemovedOnCompletion = false
        walkAnimation.fillMode = .forwards
        
        self.layer.add(walkAnimation, forKey: Self.BarrageAnimationKey)
    }
}

// MARK: - BarrageTrackInfo
open class BarrageTrackInfo: NSObject {
    open var trackIndex: Int = 0
    open var trackIdentifier: String?
    /// 下次可用的时间
    open var nextAvailableTime: CFTimeInterval = 0
    /// 当前行的弹幕数量
    open var barrageCount: Int = 0
    /// 轨道高度
    open var trackHeight: CGFloat = 0
}
