//
//  TestBarrageController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/10/17.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestBarrageController: UIViewController, ViewControllerProtocol {
    lazy var textLayer: CATextLayer = {
        let result = CATextLayer()
        return result
    }()

    let barrageManager: BarrageManager = {
        let result = BarrageManager()
        return result
    }()

    private var times: Int = 0
    private var stopY: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        view.app.height = APP.screenHeight - APP.topBarHeight
        view.addSubview(barrageManager.renderView)
        barrageManager.renderView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        barrageManager.renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.backgroundColor = AppTheme.backgroundColor

        let originY = CGRectGetHeight(view.frame) - 50
        let button = UIButton(type: .custom)
        button.setTitle("开始", for: .normal)
        button.setTitleColor(AppTheme.textColor, for: .normal)
        button.addTarget(self, action: #selector(startBarrage), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: originY, width: 50, height: 50)
        button.backgroundColor = .red.withAlphaComponent(0.2)
        view.addSubview(button)

        let button2 = UIButton(type: .custom)
        button2.setTitle("暂停", for: .normal)
        button2.setTitleColor(AppTheme.textColor, for: .normal)
        button2.addTarget(self, action: #selector(pauseBarrage), for: .touchUpInside)
        button2.frame = CGRect(x: 55, y: originY, width: 50, height: 50)
        button2.backgroundColor = .red.withAlphaComponent(0.2)
        view.addSubview(button2)

        let button3 = UIButton(type: .custom)
        button3.setTitle("继续", for: .normal)
        button3.setTitleColor(AppTheme.textColor, for: .normal)
        button3.addTarget(self, action: #selector(resumeBarrage), for: .touchUpInside)
        button3.frame = CGRect(x: 110, y: originY, width: 50, height: 50)
        button3.backgroundColor = .red.withAlphaComponent(0.2)
        view.addSubview(button3)

        let button4 = UIButton(type: .custom)
        button4.setTitle("停止", for: .normal)
        button4.setTitleColor(AppTheme.textColor, for: .normal)
        button4.addTarget(self, action: #selector(stopBarrage), for: .touchUpInside)
        button4.frame = CGRect(x: 165, y: originY, width: 50, height: 50)
        button4.backgroundColor = .red.withAlphaComponent(0.2)
        view.addSubview(button4)

        barrageManager.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addNormalBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addFixedSpeedAnimationCell), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addWalkBannerBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addGifBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addStopoverBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addVerticalAnimationCell), object: nil)
    }

    func addBarrage() {
        perform(#selector(addNormalBarrage), with: nil, afterDelay: 0.5)
        perform(#selector(addFixedSpeedAnimationCell), with: nil, afterDelay: 0.5)
        perform(#selector(addWalkBannerBarrage), with: nil, afterDelay: 0.5)
        perform(#selector(addStopoverBarrage), with: nil, afterDelay: 0.5)
        perform(#selector(addGifBarrage), with: nil, afterDelay: 0.5)
        perform(#selector(addVerticalAnimationCell), with: nil, afterDelay: 0.5)
    }

    func removeBarrage() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addNormalBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addFixedSpeedAnimationCell), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addWalkBannerBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addStopoverBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addGifBarrage), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(addVerticalAnimationCell), object: nil)
    }

    @objc func addNormalBarrage() {
        updateTitle()

        let descriptor = BarrageTextDescriptor()
        descriptor.text = "~弹幕~"
        descriptor.textColor = AppTheme.textColor
        descriptor.positionPriority = .low
        descriptor.textFont = UIFont.systemFont(ofSize: 17)
        descriptor.strokeColor = AppTheme.textColor.withAlphaComponent(0.3)
        descriptor.strokeWidth = -1
        descriptor.animationDuration = CGFloat(arc4random() % 5 + 5)
        descriptor.barrageCellClass = BarrageTextCell.self

        barrageManager.renderBarrageDescriptor(descriptor)

        perform(#selector(addNormalBarrage), with: nil, afterDelay: 0.25)
    }

    @objc func addFixedSpeedAnimationCell() {
        let descriptor = BarrageGradientBackgroundColorDescriptor()
        descriptor.text = "~等速弹幕~"
        descriptor.textColor = AppTheme.textColor
        descriptor.positionPriority = .low
        descriptor.textFont = UIFont.systemFont(ofSize: 17)
        descriptor.strokeColor = AppTheme.textColor.withAlphaComponent(0.3)
        descriptor.strokeWidth = -1
        descriptor.fixedSpeed = 50
        descriptor.barrageCellClass = BarrageGradientBackgroundColorCell.self
        descriptor.gradientColor = UIColor.app.randomColor

        barrageManager.renderBarrageDescriptor(descriptor)

        perform(#selector(addFixedSpeedAnimationCell), with: nil, afterDelay: 0.5)
    }

    @objc func addWalkBannerBarrage() {
        let descriptor = BarrageWalkBannerDescriptor()
        descriptor.cellTouchedAction = { [weak self] _, cell in
            self?.app.showAlert(title: "弹幕", message: "为你服务")

            if let cell = cell as? BarrageWalkBannerCell {
                cell.textLabel.backgroundColor = .red
            }
        }

        descriptor.text = "~欢迎大驾光临~"
        descriptor.textColor = AppTheme.textColor
        descriptor.positionPriority = .middle
        descriptor.textFont = UIFont.systemFont(ofSize: 17)
        descriptor.strokeColor = AppTheme.textColor.withAlphaComponent(0.3)
        descriptor.strokeWidth = -1
        descriptor.animationDuration = CGFloat(arc4random() % 5 + 5)
        descriptor.barrageCellClass = BarrageWalkBannerCell.self

        barrageManager.renderBarrageDescriptor(descriptor)

        perform(#selector(addWalkBannerBarrage), with: nil, afterDelay: 1.0)
    }

    @objc func addStopoverBarrage() {
        let descriptor = BarrageBecomeNobleDescriptor()
        let attrString = NSMutableAttributedString(string: "~样式弹幕~")
        attrString.addAttribute(.foregroundColor, value: AppTheme.textColor, range: NSMakeRange(0, attrString.length))
        attrString.addAttribute(.foregroundColor, value: UIColor.green, range: NSMakeRange(1, 2))
        attrString.addAttribute(.foregroundColor, value: UIColor.cyan, range: NSMakeRange(3, 2))
        attrString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: NSMakeRange(0, attrString.length))
        descriptor.attributedText = attrString
        let bannerHeight: CGFloat = 185.0 / 2.0
        let minOriginY: CGFloat = CGRectGetMidY(view.frame) - bannerHeight
        let maxOriginY: CGFloat = CGRectGetMidY(view.frame) + bannerHeight
        descriptor.renderRange = NSMakeRange(Int(minOriginY), Int(maxOriginY))
        descriptor.positionPriority = .veryHigh
        descriptor.animationDuration = 4
        descriptor.barrageCellClass = BarrageBecomeNobleCell.self
        descriptor.backgroundImage = UIImage.app.appIconImage()

        barrageManager.renderBarrageDescriptor(descriptor)

        perform(#selector(addStopoverBarrage), with: nil, afterDelay: 4.0)

        if stopY == 0 {
            stopY = Int(bannerHeight)
        } else {
            stopY = 0
        }
    }

    @objc func addVerticalAnimationCell() {
        let descriptor = BarrageVerticalTextDescriptor()
        descriptor.text = "~从上往下的动画~"
        descriptor.textColor = AppTheme.textColor
        descriptor.positionPriority = .low
        descriptor.textFont = UIFont.systemFont(ofSize: 17)
        descriptor.strokeColor = AppTheme.textColor.withAlphaComponent(0.3)
        descriptor.strokeWidth = -1
        descriptor.animationDuration = 5
        descriptor.barrageCellClass = BarrageVerticalAnimationCell.self

        barrageManager.renderBarrageDescriptor(descriptor)

        perform(#selector(addVerticalAnimationCell), with: nil, afterDelay: 0.5)
    }

    @objc func addGifBarrage() {
        let descriptor = BarrageGifDescriptor()
        descriptor.image = ModuleBundle.imageNamed("Loading.gif")
        descriptor.positionPriority = .high
        descriptor.animationDuration = CGFloat(arc4random() % 5 + 5)
        descriptor.barrageCellClass = BarrageGifCell.self

        barrageManager.renderBarrageDescriptor(descriptor)

        perform(#selector(addGifBarrage), with: nil, afterDelay: 3.0)
    }

    @objc func startBarrage() {
        barrageManager.start()
        addBarrage()
    }

    @objc func pauseBarrage() {
        barrageManager.pause()
    }

    @objc func resumeBarrage() {
        barrageManager.resume()
    }

    @objc func stopBarrage() {
        barrageManager.stop()
        removeBarrage()
        updateTitle()
    }

    private func updateTitle() {
        let barrageCount = barrageManager.renderView.animatingCells.count
        navigationItem.title = "现在有 \(barrageCount) 条弹幕"
    }
}

class BarrageGradientBackgroundColorDescriptor: BarrageTextDescriptor {
    var gradientColor: UIColor?
}

class BarrageGradientBackgroundColorCell: BarrageTextCell {
    var gradientLayer: CAGradientLayer?
    var gradientDescriptor: BarrageGradientBackgroundColorDescriptor?

    override var barrageDescriptor: BarrageDescriptor? {
        didSet {
            gradientDescriptor = barrageDescriptor as? BarrageGradientBackgroundColorDescriptor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel.attributedText = nil
        addSubview(textLabel)
    }

    override func layoutContentSubviews() {
        super.layoutContentSubviews()
        addGradientLayer()
    }

    override func convertContentToImage() {
        let contentImage = layer.app.snapshotImage(size: gradientLayer?.frame.size ?? .zero)
        layer.contents = contentImage?.cgImage
    }

    override func removeSubviewsAndSublayers() {
        super.removeSubviewsAndSublayers()

        gradientLayer = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        textLabel.center = gradientLayer?.position ?? .zero
    }

    private func addGradientLayer() {
        guard let color = gradientDescriptor?.gradientColor else { return }

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [color.withAlphaComponent(0.8).cgColor, color.withAlphaComponent(0).cgColor]
        gradientLayer.locations = [0.2, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: textLabel.frame.width + 20, height: textLabel.frame.height)

        let maskPath = UIBezierPath(roundedRect: gradientLayer.bounds, byRoundingCorners: [.bottomLeft, .topLeft], cornerRadii: gradientLayer.bounds.size)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = gradientLayer.bounds
        maskLayer.path = maskPath.cgPath
        gradientLayer.mask = maskLayer
        self.gradientLayer = gradientLayer
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

class BarrageWalkBannerDescriptor: BarrageTextDescriptor {
    var bannerLeftImageSrc: String?
    var bannerMiddleColor: UIColor?
    var bannerRightImageSrc: String?
}

class BarrageWalkBannerCell: BarrageTextCell {
    let imageWidth: CGFloat = 89
    let imageHeight: CGFloat = 57

    var walkBannerDescriptor: BarrageWalkBannerDescriptor?

    override var barrageDescriptor: BarrageDescriptor? {
        didSet {
            walkBannerDescriptor = barrageDescriptor as? BarrageWalkBannerDescriptor
        }
    }

    lazy var leftImageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFit
        return result
    }()

    lazy var middleImageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFit
        return result
    }()

    lazy var rightImageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFit
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel.backgroundColor = .clear
    }

    private func setupSubviews() {
        addSubview(leftImageView)
        addSubview(middleImageView)
        addSubview(rightImageView)
    }

    override func updateSubviewsData() {
        super.updateSubviewsData()

        leftImageView.image = UIImage.app.appIconImage()
        middleImageView.backgroundColor = UIColor(red: 1, green: 0.83, blue: 0.26, alpha: 1)
        rightImageView.image = UIImage.app.appIconImage()
    }

    override func layoutContentSubviews() {
        super.layoutContentSubviews()

        let leftImageViewX: CGFloat = 0
        let leftImageViewY: CGFloat = 0
        let leftImageViewW = imageWidth
        let leftImageViewH = imageHeight
        leftImageView.frame = CGRect(x: leftImageViewX, y: leftImageViewY, width: leftImageViewW, height: leftImageViewH)

        let middleImageViewW = CGRectGetWidth(textLabel.bounds)
        let middleImageViewH: CGFloat = 19
        let middleImageViewX = CGRectGetMaxX(leftImageView.bounds) - 1
        let middleImageViewY = (leftImageViewH - middleImageViewH) / 2.0
        middleImageView.frame = CGRect(x: middleImageViewX, y: middleImageViewY, width: middleImageViewW, height: middleImageViewH)
        textLabel.center = middleImageView.center

        let rightImageViewX = CGRectGetMaxX(textLabel.frame) - 1
        let rightImageViewY = leftImageViewY
        let rightImageViewW = CGRectGetWidth(rightImageView.frame) > 2 ? CGRectGetWidth(rightImageView.frame) : 22
        let rightImageViewH = imageHeight
        rightImageView.frame = CGRectMake(rightImageViewX, rightImageViewY, rightImageViewW, rightImageViewH)
    }

    override func convertContentToImage() {
        let contentImage = layer.app.snapshotImage(size: CGSize(width: CGRectGetMaxX(rightImageView.frame), height: CGRectGetMaxY(rightImageView.frame)))
        layer.contents = contentImage?.cgImage
    }

    override func removeSubviewsAndSublayers() {
        // 如果不要删除leftImageView, middleImageView, rightImageView, textLabel, 只需重写这个方法并留空就可以了.
        // 比如: 你想在这个cell被点击的时候, 修改文本颜色
    }
}

class BarrageBecomeNobleDescriptor: BarrageTextDescriptor {
    var backgroundImage: UIImage?
}

class BarrageBecomeNobleCell: BarrageTextCell {
    var nobleDescriptor: BarrageBecomeNobleDescriptor?

    override var barrageDescriptor: BarrageDescriptor? {
        didSet {
            nobleDescriptor = barrageDescriptor as? BarrageBecomeNobleDescriptor
        }
    }

    lazy var backgroundImageLayer: CALayer = {
        let result = CALayer()
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSublayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSublayers() {
        layer.insertSublayer(backgroundImageLayer, at: 0)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        addSublayers()
    }

    override func updateSubviewsData() {
        super.updateSubviewsData()

        backgroundImageLayer.contents = nobleDescriptor?.backgroundImage?.cgImage
    }

    override func layoutContentSubviews() {
        super.layoutContentSubviews()

        backgroundImageLayer.frame = CGRect(x: 0, y: 0, width: nobleDescriptor?.backgroundImage?.size.width ?? 0, height: nobleDescriptor?.backgroundImage?.size.height ?? 0)
        var center = backgroundImageLayer.position
        center.y += 17
        textLabel.center = center
    }

    override func convertContentToImage() {
        let image = layer.app.snapshotImage(size: CGSize(width: nobleDescriptor?.backgroundImage?.size.width ?? 0, height: nobleDescriptor?.backgroundImage?.size.height ?? 0))
        layer.contents = image?.cgImage
    }

    override func addBarrageAnimation(delegate: CAAnimationDelegate?) {
        guard let superview else { return }

        let startCenter = CGPoint(x: CGRectGetMaxX(superview.bounds) + CGRectGetWidth(bounds) / 2.0, y: center.y)
        let stopCenter = CGPoint(x: CGRectGetMidX(superview.bounds), y: center.y)
        let endCenter = CGPoint(x: -(CGRectGetWidth(bounds) / 2.0), y: center.y)

        let walkAnimation = CAKeyframeAnimation(keyPath: "position")
        walkAnimation.values = [NSValue(cgPoint: startCenter), NSValue(cgPoint: stopCenter), NSValue(cgPoint: stopCenter), NSValue(cgPoint: endCenter)]
        walkAnimation.keyTimes = [0, 0.25, 0.75, 1.0]
        walkAnimation.duration = Double(barrageDescriptor?.animationDuration ?? 0)
        walkAnimation.repeatCount = 1
        walkAnimation.delegate = delegate
        walkAnimation.isRemovedOnCompletion = false
        walkAnimation.fillMode = .forwards

        layer.add(walkAnimation, forKey: Self.barrageAnimationKey)
    }
}

class BarrageMixedImageAndTextCell: BarrageTextCell {
    lazy var mixedImageAndTextLabel: AttributedLabel = {
        let result = AttributedLabel()
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(mixedImageAndTextLabel)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mixedImageAndTextLabel.attributedText = nil
    }

    override func updateSubviewsData() {
        mixedImageAndTextLabel.attributedText = textDescriptor?.attributedText
    }

    override func layoutContentSubviews() {
        let cellSize = mixedImageAndTextLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        mixedImageAndTextLabel.frame = CGRect(x: 0, y: 0, width: cellSize.width, height: cellSize.height)
    }

    override func removeSubviewsAndSublayers() {}
}

class BarrageGifDescriptor: BarrageDescriptor {
    var image: UIImage?
}

class BarrageGifCell: BarrageCell {
    var gifDescriptor: BarrageGifDescriptor?

    override var barrageDescriptor: BarrageDescriptor? {
        didSet {
            gifDescriptor = barrageDescriptor as? BarrageGifDescriptor
        }
    }

    lazy var imageView: UIImageView = {
        let result = UIImageView()
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(imageView)
    }

    override func updateSubviewsData() {
        imageView.image = gifDescriptor?.image
    }

    override func layoutContentSubviews() {
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    }

    override func addBarrageAnimation(delegate: CAAnimationDelegate?) {
        guard let superview else { return }

        let startCenter = CGPoint(x: CGRectGetMaxX(superview.bounds) + CGRectGetWidth(bounds) / 2.0, y: center.y)
        let endCenter = CGPoint(x: -(CGRectGetWidth(bounds) / 2.0), y: center.y)

        let walkAnimation = CAKeyframeAnimation(keyPath: "position")
        walkAnimation.values = [NSValue(cgPoint: startCenter), NSValue(cgPoint: endCenter)]
        walkAnimation.keyTimes = [0, 1.0]
        walkAnimation.duration = Double(barrageDescriptor?.animationDuration ?? 0)
        walkAnimation.repeatCount = 1
        walkAnimation.delegate = delegate
        walkAnimation.isRemovedOnCompletion = false
        walkAnimation.fillMode = .forwards

        layer.add(walkAnimation, forKey: Self.barrageAnimationKey)
    }

    override func removeSubviewsAndSublayers() {}
}

class BarrageVerticalTextDescriptor: BarrageTextDescriptor {}

class BarrageVerticalAnimationCell: BarrageTextCell {
    var verticalTextDescriptor: BarrageVerticalTextDescriptor?

    override var barrageDescriptor: BarrageDescriptor? {
        didSet {
            verticalTextDescriptor = barrageDescriptor as? BarrageVerticalTextDescriptor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func addBarrageAnimation(delegate: CAAnimationDelegate?) {
        guard let superview else { return }

        let startCenter = CGPoint(x: CGRectGetMidX(superview.bounds), y: -(CGRectGetHeight(bounds) / 2.0))
        let endCenter = CGPoint(x: CGRectGetMidX(superview.bounds), y: CGRectGetHeight(superview.bounds) + CGRectGetHeight(bounds) / 2)

        let walkAnimation = CAKeyframeAnimation(keyPath: "position")
        walkAnimation.values = [NSValue(cgPoint: startCenter), NSValue(cgPoint: endCenter)]
        walkAnimation.keyTimes = [0, 1.0]
        walkAnimation.duration = Double(barrageDescriptor?.animationDuration ?? 0)
        walkAnimation.repeatCount = 1
        walkAnimation.delegate = delegate
        walkAnimation.isRemovedOnCompletion = false
        walkAnimation.fillMode = .forwards

        layer.add(walkAnimation, forKey: Self.barrageAnimationKey)
    }
}
