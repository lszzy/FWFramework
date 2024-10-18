//
//  GuideView.swift
//  FWFramework
//
//  Created by wuyong on 2024/10/18.
//

import UIKit

/// 引导控制器
///
/// [KSGuideController](https://github.com/skx926/KSGuideController)
open class GuideViewController: UIViewController {
    private enum Region {
        case upperLeft
        case upperRight
        case lowerLeft
        case lowerRight
    }

    /// 样式属性定制
    open var bgAlpha: CGFloat = 0.7
    open var bgColor: UIColor?
    open var spacing: CGFloat = 20
    open var padding: CGFloat = 50
    open var maskCornerRadius: CGFloat = 5
    open var maskInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
    open var maskFillColor = UIColor.black
    open var font = UIFont.systemFont(ofSize: 14)
    open var textColor = UIColor.white
    open var arrowColor: UIColor? = UIColor.white
    open var arrowImage: UIImage?
    open var animationDuration = 0.3
    open var animatedMask = true
    open var animatedArrow = true
    open var animatedContent = true
    open var statusBarHidden = false

    /// 设置或获取当前索引
    open var currentIndex: Int = -1 {
        didSet {
            indexWillChangeBlock?(currentIndex, currentItem)
            configViews()
            indexDidChangeBlock?(currentIndex, currentItem)
        }
    }

    /// 索引将要改变句柄
    open var indexWillChangeBlock: ((_ index: Int, _ item: GuideViewItem) -> Void)?
    /// 索引已经改变句柄
    open var indexDidChangeBlock: ((_ index: Int, _ item: GuideViewItem) -> Void)?

    private var items = [GuideViewItem]()
    private let arrowImageView = UIImageView()
    private let textLabel = UILabel()
    private let imageView = UIImageView()
    private let maskLayer = CAShapeLayer()
    private var completion: (() -> Void)?
    private var guideKey: String?

    private var currentItem: GuideViewItem {
        items[currentIndex]
    }

    private var maskCenter: CGPoint {
        CGPoint(x: hollowFrame.midX, y: hollowFrame.midY)
    }

    private var region: Region {
        let center = maskCenter
        let bounds = view.bounds
        if center.x <= bounds.midX && center.y <= bounds.midY {
            return .upperLeft
        } else if center.x > bounds.midX && center.y <= bounds.midY {
            return .upperRight
        } else if center.x <= bounds.midX && center.y > bounds.midY {
            return .lowerLeft
        } else {
            return .lowerRight
        }
    }

    private var hollowFrame: CGRect {
        var rect: CGRect = .zero
        if let sourceView = currentItem.sourceView {
            rect = view.convert(sourceView.frame, from: sourceView.superview)
        } else {
            rect = currentItem.rect
        }
        rect.origin.x += maskInsets.left
        rect.origin.y += maskInsets.top
        rect.size.width -= maskInsets.right + maskInsets.left
        rect.size.height -= maskInsets.bottom + maskInsets.top
        return rect
    }

    /// 指定单个引导项初始化，key为nil时忽略缓存
    public convenience init(item: GuideViewItem, key: String? = nil) {
        self.init(items: [item], key: key)
    }

    /// 指定引导项并初始化，key为nil时忽略缓存
    public init(items: [GuideViewItem], key: String? = nil) {
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        self.items.append(contentsOf: items)
        self.guideKey = key
    }

    /// 显示引导，如果指定了key且已展示过，则不再显示
    open func show(from vc: UIViewController, completion: (() -> Void)? = nil) {
        self.completion = completion
        var shouldShow = true
        if let key = guideKey {
            shouldShow = GuideViewManager.shouldShowGuide(for: key)
        }
        if shouldShow {
            vc.present(self, animated: true, completion: nil)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        currentIndex = 0
    }

    override open var prefersStatusBarHidden: Bool {
        statusBarHidden
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.configMask()
            self.configViewFrames()
        }, completion: nil)
    }

    open func configViews() {
        let image = currentItem.arrowImage ?? arrowImage
        if let arrowColor {
            arrowImageView.image = image?.withRenderingMode(.alwaysTemplate)
            arrowImageView.tintColor = arrowColor
        } else {
            arrowImageView.image = image
        }
        view.backgroundColor = bgColor ?? UIColor(white: 0, alpha: bgAlpha)
        view.addSubview(arrowImageView)

        textLabel.textColor = textColor
        textLabel.font = font
        textLabel.textAlignment = .left
        textLabel.text = currentItem.text
        textLabel.numberOfLines = 0
        view.addSubview(textLabel)
        
        imageView.image = currentItem.image
        view.addSubview(imageView)

        configMask()
        configViewFrames()
    }

    open func configMask() {
        let fromPath = maskLayer.path

        maskLayer.fillColor = maskFillColor.cgColor
        let frame = hollowFrame
        let radius = min(maskCornerRadius, min(frame.width / 2.0, frame.height / 2.0))
        let highlightedPath = UIBezierPath(roundedRect: hollowFrame, cornerRadius: radius)
        let toPath = UIBezierPath(rect: view.bounds)
        toPath.append(highlightedPath)
        maskLayer.path = toPath.cgPath
        maskLayer.fillRule = .evenOdd
        view.layer.mask = maskLayer

        if animatedMask {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = animationDuration
            animation.fromValue = fromPath
            animation.toValue = toPath
            maskLayer.add(animation, forKey: nil)
        }
    }

    open func configViewFrames() {
        maskLayer.frame = view.bounds

        var textRect: CGRect = .zero
        var imageRect: CGRect = .zero
        var arrowRect: CGRect = .zero
        var transform: CGAffineTransform = .identity
        let arrowSize = arrowImageView.image?.size ?? .zero
        let maxWidth = view.frame.size.width - padding * 2
        let textSize = currentItem.text.fw.size(font: font, drawSize: CGSize(width: maxWidth, height: .infinity))
        let imageSize = currentItem.image?.size ?? .zero
        let maxX = padding + maxWidth - textSize.width

        switch region {
        case .upperLeft:
            transform = CGAffineTransform(scaleX: -1, y: 1)
            arrowRect = CGRect(x: hollowFrame.midX - arrowSize.width / 2,
                               y: hollowFrame.maxY + spacing,
                               width: arrowSize.width,
                               height: arrowSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.maxX - textSize.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.maxY + spacing,
                              width: textSize.width,
                              height: textSize.height)
            let imageX: CGFloat = max(padding, min(maxX, arrowRect.maxX - imageSize.width / 2))
            imageRect = CGRect(x: imageX,
                              y: arrowRect.maxY + spacing,
                              width: imageSize.width,
                              height: imageSize.height)

        case .upperRight:
            arrowRect = CGRect(x: hollowFrame.midX - arrowSize.width / 2,
                               y: hollowFrame.maxY + spacing,
                               width: arrowSize.width,
                               height: arrowSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.minX - textSize.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.maxY + spacing,
                              width: textSize.width,
                              height: textSize.height)
            let imageX: CGFloat = max(padding, min(maxX, arrowRect.minX - imageSize.width / 2))
            imageRect = CGRect(x: imageX,
                              y: arrowRect.maxY + spacing,
                              width: imageSize.width,
                              height: imageSize.height)

        case .lowerLeft:
            transform = CGAffineTransform(scaleX: -1, y: -1)
            arrowRect = CGRect(x: hollowFrame.midX - arrowSize.width / 2,
                               y: hollowFrame.minY - spacing - arrowSize.height,
                               width: arrowSize.width,
                               height: arrowSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.maxX - textSize.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.minY - spacing - textSize.height,
                              width: textSize.width,
                              height: textSize.height)
            let imageX: CGFloat = max(padding, min(maxX, arrowRect.maxX - imageSize.width / 2))
            imageRect = CGRect(x: imageX,
                              y: arrowRect.minY - spacing - imageSize.height,
                              width: imageSize.width,
                              height: imageSize.height)

        case .lowerRight:
            transform = CGAffineTransform(scaleX: 1, y: -1)
            arrowRect = CGRect(x: hollowFrame.midX - arrowSize.width / 2,
                               y: hollowFrame.minY - spacing - arrowSize.height,
                               width: arrowSize.width,
                               height: arrowSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.minX - textSize.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.minY - spacing - textSize.height,
                              width: textSize.width,
                              height: textSize.height)
            let imageX: CGFloat = max(padding, min(maxX, arrowRect.minX - imageSize.width / 2))
            imageRect = CGRect(x: imageX,
                              y: arrowRect.minY - spacing - imageSize.height,
                              width: imageSize.width,
                              height: imageSize.height)
        }

        if animatedArrow && animatedContent {
            UIView.animate(withDuration: animationDuration, animations: {
                self.arrowImageView.transform = transform
                self.arrowImageView.frame = arrowRect
                self.textLabel.frame = textRect
                self.imageView.frame = imageRect
            }, completion: nil)
            return
        }

        if animatedArrow {
            UIView.animate(withDuration: animationDuration, animations: {
                self.arrowImageView.transform = transform
                self.arrowImageView.frame = arrowRect
            }, completion: nil)
            textLabel.frame = textRect
            imageView.frame = imageRect
            return
        }

        if animatedContent {
            UIView.animate(withDuration: animationDuration, animations: {
                self.textLabel.frame = textRect
                self.imageView.frame = imageRect
            }, completion: nil)
            arrowImageView.transform = transform
            arrowImageView.frame = arrowRect
            return
        }

        arrowImageView.transform = transform
        arrowImageView.frame = arrowRect
        textLabel.frame = textRect
        imageView.frame = imageRect
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentIndex < items.count - 1 {
            currentIndex += 1
        } else {
            dismiss(animated: true, completion: completion)
        }
    }
}

/// 引导管理器
public class GuideViewManager {
    private static let dataKey = "FWGuideViewData"

    /// 是否应该显示指定key引导
    public static func shouldShowGuide(for key: String) -> Bool {
        var data = UserDefaults.standard.object(forKey: dataKey) as? [String: Bool] ?? [:]
        guard data.index(forKey: key) == nil else { return false }

        data[key] = true
        UserDefaults.standard.set(data, forKey: dataKey)
        UserDefaults.standard.synchronize()
        return true
    }

    /// 重置指定key引导
    public static func reset(for key: String) {
        if var data = UserDefaults.standard.object(forKey: dataKey) as? [String: Bool] {
            data.removeValue(forKey: key)
            UserDefaults.standard.set(data, forKey: dataKey)
            UserDefaults.standard.synchronize()
        }
    }

    /// 重置所有引导
    public static func resetAll() {
        UserDefaults.standard.set(nil, forKey: dataKey)
        UserDefaults.standard.synchronize()
    }
}

/// 引导视图项
open class GuideViewItem {
    open var sourceView: UIView?
    open var rect: CGRect = .zero
    open var arrowImage: UIImage?
    open var image: UIImage?
    open var text: String = ""

    public init() {}

    public convenience init(sourceView: UIView?, arrowImage: UIImage? = nil, text: String = "", image: UIImage? = nil) {
        self.init()
        self.sourceView = sourceView
        self.arrowImage = arrowImage
        self.text = text
        self.image = image
    }

    public convenience init(rect: CGRect, arrowImage: UIImage? = nil, text: String = "", image: UIImage? = nil) {
        self.init()
        self.rect = rect
        self.arrowImage = arrowImage
        self.text = text
        self.image = image
    }
}
