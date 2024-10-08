//
//  TestPreviewController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/16.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPreviewController: UIViewController {
    var usePlugin = false
    var mockProgress = false
    var previewFade = false
    var showsToolbar = false
    var showsClose = false
    var autoplayVideo = false
    var dismissTappedImage = true
    var dismissTappedVideo = true
    var imagePreviewController: ImagePreviewController?
    var images: [Any] = []
    var exitAtIndex: Int?

    lazy var floatView: FloatingView = {
        let result = FloatingView()
        result.itemMargins = UIEdgeInsets(top: UIScreen.app.pixelOne, left: UIScreen.app.pixelOne, bottom: 0, right: 0)
        return result
    }()

    lazy var tipsLabel: UILabel = {
        let result = UILabel()
        result.font = APP.font(12)
        result.textColor = .darkText
        result.textAlignment = .center
        result.numberOfLines = 0
        result.text = "点击图片后可左右滑动，期间也可尝试横竖屏"
        return result
    }()
}

extension TestPreviewController: ViewControllerProtocol {
    func didInitialize() {
        images = [
            UIImage.app.appIconImage() as Any,
            ModuleBundle.imageNamed("Animation.png") as Any,
            "http://via.placeholder.com/100x2000.jpg",
            "http://via.placeholder.com/2000x100.jpg",
            "http://via.placeholder.com/2000x2000.jpg",
            "http://via.placeholder.com/100x100.jpg",
            FileManager.app.pathResource.app.appendingPath("Video.mp4")
        ]

        app.observeLifecycleState { vc, state in
            guard state == .didDeinit else { return }

            if let exitAtIndex = vc.exitAtIndex {
                UIWindow.app.showMessage(text: "浏览到第\(exitAtIndex + 1)张就deinit了")
            } else {
                UIWindow.app.showMessage(text: "还没浏览就deinit了")
            }
        }
    }

    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            guard let self else { return }
            let pluginText = usePlugin ? "不使用插件" : "使用插件"
            let progressText = mockProgress ? "关闭进度" : "开启进度"
            let fadeText = previewFade ? "关闭渐变效果" : "开启渐变效果"
            let toolbarText = showsToolbar ? "隐藏视频工具栏" : "开启视频工具栏"
            let autoText = autoplayVideo ? "关闭自动播放" : "开启自动播放"
            let dismissImageText = dismissTappedImage ? "单击图片时不关闭" : "单击图片时自动关闭"
            let dismissVideoText = dismissTappedVideo ? "单击视频时不关闭" : "单击视频时自动关闭"
            let closeText = showsClose ? "隐藏视频关闭按钮" : "开启视频关闭按钮"
            app.showSheet(title: nil, message: nil, cancel: "取消", actions: [pluginText, progressText, fadeText, toolbarText, autoText, dismissImageText, dismissVideoText, closeText], currentIndex: -1) { [weak self] index in
                guard let self else { return }
                if index == 0 {
                    usePlugin = !usePlugin
                } else if index == 1 {
                    mockProgress = !mockProgress
                } else if index == 2 {
                    previewFade = !previewFade
                } else if index == 3 {
                    showsToolbar = !showsToolbar
                } else if index == 4 {
                    autoplayVideo = !autoplayVideo
                } else if index == 5 {
                    dismissTappedImage = !dismissTappedImage
                } else if index == 6 {
                    dismissTappedVideo = !dismissTappedVideo
                } else if index == 7 {
                    showsClose = !showsClose
                }
            }
        }
    }

    func setupSubviews() {
        for image in images {
            let button = UIButton()
            button.imageView?.contentMode = .scaleAspectFill
            if let image = image as? UIImage {
                button.setImage(image, for: .normal)
            } else if let imageUrl = image as? String {
                if imageUrl.hasSuffix(".mp4") {
                    button.setImage(UIImage.app.appIconImage(), for: .normal)
                } else {
                    UIImage.app.downloadImage(imageUrl, options: .queryMemoryData) { image, _, _ in
                        button.setImage(image ?? UIImage.app.appIconImage(), for: .normal)
                    }
                }
            }
            button.addTarget(self, action: #selector(handleImageButtonEvent(_:)), for: .touchUpInside)
            floatView.addSubview(button)
        }
        view.addSubview(floatView)

        view.addSubview(tipsLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let margins = UIEdgeInsets(top: 24 + app.topBarHeight, left: 24 + view.safeAreaInsets.left, bottom: 24, right: 24 + view.safeAreaInsets.right)
        let contentWidth = view.app.width - (margins.left + margins.right)
        let column = APP.isIpad || APP.isInterfaceLandscape ? images.count : 3
        let imageWidth = contentWidth / CGFloat(column) - CGFloat(column - 1) * (floatView.itemMargins.left + floatView.itemMargins.right)
        floatView.minimumItemSize = CGSize(width: imageWidth, height: imageWidth)
        floatView.maximumItemSize = floatView.minimumItemSize
        floatView.frame = CGRect(x: margins.left, y: margins.top, width: contentWidth, height: floatView.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude)).height)

        tipsLabel.frame = CGRect(x: margins.left, y: CGRectGetMaxY(floatView.frame) + 16, width: contentWidth, height: tipsLabel.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude)).height)
    }

    @objc func handleImageButtonEvent(_ button: UIButton) {
        if usePlugin {
            let buttonIndex = floatView.subviews.firstIndex(of: button)
            app.showImagePreview(imageURLs: images, imageInfos: nil, currentIndex: buttonIndex ?? 0) { [weak self] index in
                return self?.floatView.subviews[index]
            }
            return
        }

        if self.imagePreviewController == nil {
            let imagePreviewController = ImagePreviewController()
            self.imagePreviewController = imagePreviewController
            imagePreviewController.showsPageLabel = true
            imagePreviewController.imagePreviewView.delegate = self
            imagePreviewController.sourceImageView = { [weak self] index in
                return self?.floatView.subviews[index]
            }
            imagePreviewController.imagePreviewView.customZoomContentView = { zoomImageView, contentView in
                guard let imageView = contentView as? UIImageView else { return }
                guard imageView.viewWithTag(102) == nil else { return }

                let tipLabel = UILabel()
                tipLabel.tag = 102
                tipLabel.app.contentInset = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
                tipLabel.app.setCornerRadius(APP.font(12).lineHeight / 2 + 2)
                tipLabel.backgroundColor = .red.withAlphaComponent(0.5)
                tipLabel.text = "图片仅供参考"
                tipLabel.font = APP.font(12)
                tipLabel.textColor = .white
                imageView.addSubview(tipLabel)

                // 图片仅供参考缩放后始终在图片右下角显示，显示不下就隐藏
                tipLabel.sizeToFit()
                let labelScale = 1.0 / zoomImageView.scrollView.zoomScale
                tipLabel.transform = CGAffineTransformMakeScale(labelScale, labelScale)
                let imageSize = zoomImageView.image?.size ?? .zero
                let labelSize = tipLabel.frame.size
                tipLabel.app.origin = CGPoint(x: imageSize.width - 16.0 * labelScale - labelSize.width, y: imageSize.height - 16.0 * labelScale - labelSize.height)
                tipLabel.isHidden = tipLabel.app.y < 0
            }
            imagePreviewController.app.observeLifecycleState { [weak self] previewController, state in
                if state == .willDisappear {
                    let exitAtIndex = previewController.imagePreviewView.currentImageIndex
                    self?.exitAtIndex = exitAtIndex
                    self?.tipsLabel.text = "浏览到第\(exitAtIndex + 1)张就退出了"
                }
            }
        }

        guard let imagePreviewController else { return }
        imagePreviewController.dismissingWhenTappedImage = dismissTappedImage
        imagePreviewController.dismissingWhenTappedVideo = dismissTappedVideo
        imagePreviewController.imagePreviewView.autoplayVideo = autoplayVideo
        imagePreviewController.presentingStyle = previewFade ? .fade : .zoom
        let buttonIndex = floatView.subviews.firstIndex(of: button)
        imagePreviewController.imagePreviewView.currentImageIndex = buttonIndex ?? 0
        present(imagePreviewController, animated: true)
    }
}

extension TestPreviewController: ImagePreviewViewDelegate {
    func numberOfImages(in imagePreviewView: ImagePreviewView) -> Int {
        images.count
    }

    func imagePreviewView(_ imagePreviewView: ImagePreviewView, assetTypeAt index: Int) -> ImagePreviewMediaType {
        .image
    }

    func imagePreviewView(_ imagePreviewView: ImagePreviewView, renderZoomImageView zoomImageView: ZoomImageView, at index: Int) {
        // 强制宽度缩放模式
        zoomImageView.contentMode = .scaleToFill
        zoomImageView.reusedIdentifier = "\(index)"
        zoomImageView.showsVideoToolbar = showsToolbar
        zoomImageView.showsVideoCloseButton = showsClose

        if mockProgress {
            TestController.mockProgress { [weak self] progress, finished in
                guard let identifier = zoomImageView.reusedIdentifier else { return }
                if identifier.app.safeInt != index { return }

                zoomImageView.progress = progress
                if finished {
                    zoomImageView.setImageURL(self?.images[index])
                }
            }
        } else {
            zoomImageView.setImageURL(images[index])
        }
    }
}
