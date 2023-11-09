//
//  ZoomImageView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import PhotosUI
import AVFoundation

/// ZoomImageView事件代理
@objc(__FWZoomImageViewDelegate)
public protocol ZoomImageViewDelegate {

    /// 单击事件代理方法
    @objc optional func singleTouch(in zoomImageView: ZoomImageView, location: CGPoint)
    
    /// 双击事件代理方法
    @objc optional func doubleTouch(in zoomImageView: ZoomImageView, location: CGPoint)
    
    /// 长按事件代理方法
    @objc optional func longPress(in zoomImageView: ZoomImageView)
    
    /// 在视频预览界面里，由于用户点击了空白区域或播放视频等导致了底部的视频工具栏被显示或隐藏
    @objc optional func zoomImageView(_ zoomImageView: ZoomImageView, didHideVideoToolbar didHide: Bool)
    
    /// 自定义内容视图代理方法，contentView根据显示内容不同而不同
    @objc optional func zoomImageView(_ zoomImageView: ZoomImageView, customContentView contentView: UIView)
    
    /// 是否支持缩放，默认为 YES
    @objc optional func enabledZoomView(in zoomImageView: ZoomImageView) -> Bool
    
}

/// 支持缩放查看静态图片、live photo、视频的控件
///
/// 默认显示完整图片或视频，可双击查看放大后的大小，再次双击恢复到初始大小。
/// 支持通过修改 contentMode 来控制静态图片和 live photo 默认的显示模式，目前仅支持 UIViewContentModeCenter、UIViewContentModeScaleAspectFill、UIViewContentModeScaleAspectFit、UIViewContentModeScaleToFill(仅宽度拉伸)，默认为 UIViewContentModeScaleAspectFit。注意这里的显示模式是基于 viewportRect 而言的而非整个 zoomImageView。
/// ZoomImageView 提供最基础的图片预览和缩放功能，其他功能请通过继承来实现。
///
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
@objcMembers
@objc(__FWZoomImageView)
open class ZoomImageView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    /// 代理
    open weak var delegate: ZoomImageViewDelegate?

    /// 比如常见的上传头像预览界面中间有一个用于裁剪的方框，则 viewportRect 必须被设置为这个方框在 zoomImageView 坐标系内的 frame，否则拖拽图片或视频时无法正确限制它们的显示范围
    ///
    /// 图片或视频的初始位置会位于 viewportRect 正中间，
    /// 如果想要图片覆盖整个 viewportRect，将 contentMode 设置为 UIViewContentModeScaleAspectFill 即可。
    /// 如果设置为 CGRectZero 则表示使用默认值，默认值为和整个 zoomImageView 一样大
    open var viewportRect: CGRect = .zero

    /// 最大缩放比率，默认0根据contentMode自动计算
    open var maximumZoomScale: CGFloat {
        get {
            if _maximumZoomScale > 0 {
                return _maximumZoomScale
            }
            
            if image == nil && livePhoto == nil && videoPlayerItem == nil {
                return 1
            }
            
            let viewport = finalViewportRect()
            var mediaSize = CGSize.zero
            if let image = self.image {
                mediaSize = image.size
            } else if let livePhoto = self.livePhoto {
                mediaSize = livePhoto.size
            } else if self.videoPlayerItem != nil {
                mediaSize = videoSize
            }
            let scaleX = viewport.width / mediaSize.width
            let scaleY = viewport.height / mediaSize.height
            
            if let scaleBlock = maximumZoomScaleBlock {
                return scaleBlock(scaleX, scaleY)
            }
            
            let minScale = minimumZoomScale
            return max(minScale * 2, 2)
        }
        set {
            _maximumZoomScale = newValue
            scrollView.maximumZoomScale = newValue
        }
    }
    private var _maximumZoomScale: CGFloat = 0

    /// 最小缩率比率，默认0根据contentMode自动计算
    open var minimumZoomScale: CGFloat {
        get {
            if _minimumZoomScale > 0 {
                return _minimumZoomScale
            }
            
            if image == nil && livePhoto == nil && videoPlayerItem == nil {
                return 1
            }
            
            let viewport = finalViewportRect()
            var mediaSize = CGSize.zero
            if let image = self.image {
                mediaSize = image.size
            } else if let livePhoto = self.livePhoto {
                mediaSize = livePhoto.size
            } else if self.videoPlayerItem != nil {
                mediaSize = videoSize
            }
            let scaleX = viewport.width / mediaSize.width
            let scaleY = viewport.height / mediaSize.height
            
            if let scaleBlock = minimumZoomScaleBlock {
                return scaleBlock(scaleX, scaleY)
            }
            
            var minScale: CGFloat = 1
            switch contentMode {
            case .scaleAspectFit:
                minScale = min(scaleX, scaleY)
            case .scaleAspectFill:
                minScale = max(scaleX, scaleY)
            case .center:
                if scaleX >= 1 && scaleY >= 1 {
                    minScale = 1
                } else {
                    minScale = min(scaleX, scaleY)
                }
            case .scaleToFill:
                minScale = scaleX
            default:
                break
            }
            return minScale
        }
        set {
            _minimumZoomScale = newValue
            scrollView.minimumZoomScale = newValue
        }
    }
    private var _minimumZoomScale: CGFloat = 0

    /// 自定义最大缩放比率句柄，默认nil时根据contentMode自动计算
    open var maximumZoomScaleBlock: ((_ scaleX: CGFloat, _ scaleY: CGFloat) -> CGFloat)?

    /// 最定义最小缩放比率句柄，默认nil时根据contentMode自动计算
    open var minimumZoomScaleBlock: ((_ scaleX: CGFloat,  _ scaleY: CGFloat) -> CGFloat)?

    /// 自定义双击放大比率句柄，默认nil时直接放大到最大比率
    open var zoomInScaleBlock: ((UIScrollView) -> CGFloat)?

    /// 重用标识符
    open var reusedIdentifier: String?

    /// 设置当前要显示的图片，会把 livePhoto/video 相关内容清空，因此注意不要直接通过 imageView.image 来设置图片。
    open weak var image: UIImage? {
        didSet {
            if image != nil && image == oldValue { return }
            
            if image != nil {
                livePhoto = nil
                videoPlayerItem = nil
            }
            
            if image == nil {
                _imageView?.image = nil
                _imageView?.removeFromSuperview()
                _imageView = nil
                return
            }
            
            imageView.image = image
            // 更新 imageView 的大小时，imageView 可能已经被缩放过，所以要应用当前的缩放
            imageView.fw_frameApplyTransform = CGRect(x: 0, y: 0, width: image?.size.width ?? 0, height: image?.size.height ?? 0)
            hideViews()
            imageView.isHidden = false
            
            revertZooming()
            delegate?.zoomImageView?(self, customContentView: imageView)
        }
    }

    /// 设置当前要显示的 Live Photo，会把 image/video 相关内容清空，因此注意不要直接通过 livePhotoView.livePhoto 来设置
    open weak var livePhoto: PHLivePhoto? {
        didSet {
            if livePhoto != nil {
                image = nil
                videoPlayerItem = nil
            }
            
            if livePhoto == nil {
                _livePhotoView?.livePhoto = nil
                _livePhotoView?.removeFromSuperview()
                _livePhotoView = nil
                return
            }
            
            livePhotoView.livePhoto = livePhoto
            livePhotoView.isHidden = false
            // 更新 livePhotoView 的大小时，livePhotoView 可能已经被缩放过，所以要应用当前的缩放
            livePhotoView.fw_frameApplyTransform = CGRect(x: 0, y: 0, width: livePhoto?.size.width ?? 0, height: livePhoto?.size.height ?? 0)
            
            revertZooming()
            delegate?.zoomImageView?(self, customContentView: livePhotoView)
        }
    }

    /// 设置当前要显示的 video ，会把 image/livePhoto 相关内容清空，因此注意不要直接通过 videoPlayerLayer 来设置
    open weak var videoPlayerItem: AVPlayerItem? {
        didSet {
            if videoPlayerItem != nil {
                livePhoto = nil
                image = nil
                hideViews()
            }
            
            // 移除旧的 videoPlayer 时，同时移除相应的 timeObserver
            if videoPlayer != nil {
                removePlayerTimeObserver()
            }
            
            if videoPlayerItem == nil {
                destroyVideoRelatedObjectsIfNeeded()
                return
            }
            
            // 获取视频尺寸
            let tracksArray = videoPlayerItem?.asset.tracks ?? []
            self.videoSize = .zero
            for track in tracksArray {
                if track.mediaType == .video {
                    let size = track.naturalSize.applying(track.preferredTransform)
                    self.videoSize = CGSize(width: abs(size.width), height: abs(size.height))
                    break
                }
            }
            
            self.videoPlayer = AVPlayer(playerItem: videoPlayerItem)
            initVideoRelatedViewsIfNeeded()
            _videoPlayerLayer?.player = self.videoPlayer
            // 更新 videoPlayerView 的大小时，videoView 可能已经被缩放过，所以要应用当前的缩放
            videoPlayerView?.fw_frameApplyTransform = CGRect(x: 0, y: 0, width: self.videoSize.width, height: self.videoSize.height)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleVideoPlayToEndEvent), name: AVPlayerItem.didPlayToEndTimeNotification, object: videoPlayerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            
            configVideoProgressSlider()
            
            videoPlayerLayer.isHidden = false
            videoPlayButton.isHidden = false
            videoToolbar.playButton.isHidden = false
            if !showsVideoToolbar && showsVideoCloseButton {
                videoCloseButton.isHidden = false
            }
            
            revertZooming()
            delegate?.zoomImageView?(self, customContentView: videoPlayerView!)
        }
    }

    /// 获取当前正在显示的图片/视频的容器
    open weak var contentView: UIView? {
        if _imageView != nil {
            return _imageView
        }
        if _livePhotoView != nil {
            return _livePhotoView
        }
        if videoPlayerView != nil {
            return videoPlayerView
        }
        return nil
    }
    
    /// 获取当前正在显示的图片/视频在整个 ZoomImageView 坐标系里的 rect（会按照当前的缩放状态来计算）
    open var contentViewRect: CGRect {
        guard let contentView = contentView else {
            return .zero
        }
        
        return convert(contentView.frame, from: contentView.superview)
    }

    /// 是否播放video时显示底部的工具栏，默认NO
    open var showsVideoToolbar = false

    /// 视频底部控制条的 margins，会在此基础上自动叠加安全区域，默认值为 {0, 16, 16, 8}
    open var videoToolbarMargins = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 8) {
        didSet {
            setNeedsLayout()
        }
    }

    /// 可通过此属性修改 video 播放时屏幕中央的播放按钮图片
    open var videoPlayButtonImage: UIImage? {
        didSet {
            videoPlayButton.setImage(videoPlayButtonImage, for: .normal)
            setNeedsLayout()
        }
    }

    /// 是否显示播放 video 时屏幕左上角的关闭按钮，默认NO，仅播放视频时生效
    open var showsVideoCloseButton = false

    /// 可通过此属性修改 video 播放时屏幕左上角的关闭按钮图片
    open var videoCloseButtonImage: UIImage? {
        didSet {
            videoCloseButton.setImage(videoCloseButtonImage, for: .normal)
            setNeedsLayout()
        }
    }

    /// 播放 video 时屏幕左上角的关闭按钮中心句柄，默认同导航栏关闭按钮
    open var videoCloseButtonCenter: (() -> CGPoint)? {
        didSet {
            setNeedsLayout()
        }
    }

    /// 是否隐藏进度视图，默认NO
    open var hidesProgressView = false

    /// 设置当前进度，自动显示或隐藏进度视图
    open var progress: CGFloat {
        get {
            return progressView.progress
        }
        set {
            progressView.progress = newValue
            if hidesProgressView || (newValue >= 1 || newValue <= 0) {
                if !progressView.isHidden {
                    progressView.isHidden = true
                }
            } else {
                if progressView.isHidden {
                    progressView.isHidden = false
                }
            }
        }
    }

    /// 是否正在播放视频
    open var isPlayingVideo: Bool {
        guard let player = self.videoPlayer else { return false }
        return player.rate != 0
    }

    /// 是否忽略本地图片缓存，默认NO
    open var ignoreImageCache = false
    
    /// 滚动视图
    open lazy var scrollView: UIScrollView = {
        let result = UIScrollView(frame: bounds)
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.delegate = self
        result.contentInsetAdjustmentBehavior = .never
        return result
    }()
    
    /// 用于显示图片的 UIImageView，注意不要通过 imageView.image 来设置图片，请使用 image 属性。
    open var imageView: UIImageView {
        if let result = _imageView {
            return result
        }
        
        let result = UIImageView.fw_animatedImageView()
        _imageView = result
        scrollView.addSubview(result)
        return result
    }
    private var _imageView: UIImageView?

    /// 用于显示 Live Photo 的 view，仅在 iOS 9.1 及以后才有效
    open var livePhotoView: PHLivePhotoView {
        initLivePhotoViewIfNeeded()
        return _livePhotoView!
    }
    private var _livePhotoView: PHLivePhotoView?

    /// 用于显示 video 的 layer
    open var videoPlayerLayer: AVPlayerLayer {
        initVideoPlayerLayerIfNeeded()
        return _videoPlayerLayer!
    }
    private var _videoPlayerLayer: AVPlayerLayer?
    
    /// 播放 video 时底部的工具栏，你可通过此属性来拿到并修改上面的播放/暂停按钮、进度条、Label 等的样式，默认paddings为{10, 10, 10, 10}
    open var videoToolbar: ZoomImageVideoToolbar {
        initVideoToolbarIfNeeded()
        return _videoToolbar!
    }
    private var _videoToolbar: ZoomImageVideoToolbar?

    /// 播放 video 时屏幕中央的播放按钮
    open var videoPlayButton: UIButton {
        initVideoPlayButtonIfNeeded()
        return _videoPlayButton!
    }
    private var _videoPlayButton: UIButton?

    /// 播放 video 时屏幕左上角的关闭按钮，默认自动关闭所在present控制器
    open var videoCloseButton: UIButton {
        initVideoCloseButtonIfNeeded()
        return _videoCloseButton!
    }
    private var _videoCloseButton: UIButton?

    /// 进度视图，居中显示
    open lazy var progressView: UIView & ProgressViewPlugin = {
        let result = UIView.fw_progressView(style: .imagePreview)
        result.isHidden = true
        addSubview(result)
        result.fw_alignCenter()
        return result
    }() {
        didSet {
            oldValue.removeFromSuperview()
            progressView.isHidden = true
            addSubview(progressView)
            progressView.fw_alignCenter()
        }
    }
    
    open override var frame: CGRect {
        didSet {
            if !frame.size.equalTo(oldValue.size) {
                revertZooming()
            }
        }
    }
    
    open override var contentMode: UIView.ContentMode {
        didSet {
            if contentMode != oldValue {
                revertZooming()
            }
        }
    }
    
    private var videoPlayerView: ZoomImageVideoPlayerView?
    private var videoPlayer: AVPlayer?
    private var videoTimeObserver: Any?
    private var isSeekingVideo = false
    private var videoSize: CGSize = .zero
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        didInitialize()
    }
    
    private func didInitialize() {
        videoPlayButtonImage = AppBundle.videoPlayImage
        videoCloseButtonImage = AppBundle.navCloseImage
        fw_hidesImageIndicator = true
        
        addSubview(scrollView)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTapGesture(_:)))
        singleTapGesture.delegate = self
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        addGestureRecognizer(singleTapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        addGestureRecognizer(longPressGesture)
        
        // 双击失败后才出发单击
        singleTapGesture.require(toFail: doubleTapGesture)
        
        contentMode = .scaleAspectFit
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // 当 self.window 为 nil 时说明此 view 被移出了可视区域（比如所在的 controller 被 pop 了），此时应该停止视频播放
        if window == nil {
            endPlayingVideo()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard !CGRectIsEmpty(bounds) else { return }
        
        scrollView.frame = bounds
        
        let viewportRect = finalViewportRect()
        
        if let _videoPlayButton = _videoPlayButton {
            _videoPlayButton.sizeToFit()
            _videoPlayButton.center = CGPoint(x: viewportRect.midX, y: viewportRect.midY)
        }
        
        if let _videoCloseButton = _videoCloseButton {
            _videoCloseButton.sizeToFit()
            let videoCloseButtonCenter = videoCloseButtonCenter?() ?? CGPoint(x: UIScreen.fw_safeAreaInsets.left + 24, y: UIScreen.fw_statusBarHeight + UIScreen.fw_navigationBarHeight / 2)
            _videoCloseButton.center = videoCloseButtonCenter
        }
        
        if let _videoToolbar = _videoToolbar {
            _videoToolbar.frame = {
                let margins = UIEdgeInsets(top: videoToolbarMargins.top + safeAreaInsets.top, left: videoToolbarMargins.left + safeAreaInsets.left, bottom: videoToolbarMargins.bottom + safeAreaInsets.bottom, right: videoToolbarMargins.right + safeAreaInsets.right)
                let width = bounds.width - (margins.left + margins.right)
                let height = _videoToolbar.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
                return CGRect(x: margins.left, y: bounds.height - margins.bottom - height, width: width, height: height)
            }()
        }
    }

    /// 开始视频播放
    open func playVideo() {
        if videoPlayer == nil { return }
        handlePlayButton(nil)
    }

    /// 暂停视频播放
    open func pauseVideo() {
        if videoPlayer == nil { return }
        handlePauseButton()
        removePlayerTimeObserver()
    }

    /// 停止视频播放，将播放状态重置到初始状态
    open func endPlayingVideo() {
        guard let videoPlayer = videoPlayer else { return }
        videoPlayer.seek(to: CMTimeMake(value: 0, timescale: 1))
        pauseVideo()
        syncVideoProgressSlider()
        videoToolbar.isHidden = true
        videoCloseButton.isHidden = true
        videoPlayButton.isHidden = false
    }

    /// 重置图片或视频的大小，使用的场景例如：相册控件里放大当前图片、划到下一张、再回来，当前的图片或视频应该恢复到原来大小。注意子类重写需要调一下super
    open func revertZooming() {
        guard !CGRectIsEmpty(bounds) else { return }
        
        let enabledZoomImageView = enabledZoomImageView()
        let minimumZoomScale = self.minimumZoomScale
        let maximumZoomScale = enabledZoomImageView ? self.maximumZoomScale : minimumZoomScale
        
        let zoomScale = minimumZoomScale
        let shouldFireDidZoomingManual = zoomScale == scrollView.zoomScale
        scrollView.panGestureRecognizer.isEnabled = enabledZoomImageView
        scrollView.pinchGestureRecognizer?.isEnabled = enabledZoomImageView
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        contentView?.frame = CGRect(x: 0, y: 0, width: contentView?.frame.size.width ?? 0, height: contentView?.frame.size.height ?? 0)
        setZoomScale(zoomScale, animated: false)
        
        // 只有前后的 zoomScale 不相等，才会触发 UIScrollViewDelegate scrollViewDidZoom:，因此对于相等的情况要自己手动触发
        if shouldFireDidZoomingManual {
            handleDidEndZooming()
        }
        
        // 当内容比 viewport 的区域更大时，要把内容放在 viewport 正中间
        scrollView.contentOffset = {
            var x = scrollView.contentOffset.x
            var y = scrollView.contentOffset.y
            let viewport = finalViewportRect()
            if !CGRectIsEmpty(viewport), let contentView = self.contentView {
                if viewport.width < contentView.frame.width {
                    x = (contentView.frame.width / 2 - viewport.width / 2) - viewport.minX
                }
                if viewport.height < contentView.frame.height {
                    y = (contentView.frame.height / 2 - viewport.height / 2) - viewport.minY
                }
            }
            return CGPoint(x: x, y: y)
        }()
    }

    /// 快速设置图片URL，支持占位图和完成回调，参数支持UIImage|PHLivePhoto|AVPlayerItem|NSURL|NSString类型
    open func setImageURL(_ aImageURL: Any?, placeholderImage aPlaceholderImage: UIImage? = nil, completion: ((UIImage?) -> Void)? = nil) {
        var imageURL = aImageURL
        if let urlString = imageURL as? String {
            if (urlString as NSString).isAbsolutePath {
                imageURL = URL(fileURLWithPath: urlString)
            } else {
                imageURL = URL.fw_url(string: urlString)
            }
        }
        if let url = imageURL as? URL {
            // 默认只判断几种视频格式，不使用缓存，如果不满足需求，自行生成AVPlayerItem即可
            let pathExtension = url.pathExtension
            let videoExtensions = ["mp4", "mov", "m4v", "3gp", "avi"]
            let isVideo = videoExtensions.contains(pathExtension)
            if isVideo {
                imageURL = AVPlayerItem(url: url)
            }
        }
        
        fw_cancelImageRequest()
        if let url = imageURL as? URL {
            progress = 0.01
            // 默认缓存图片存在时使用缓存图片为placeholder，解决偶现快速切换image时转场动画异常问题
            var placeholderImage = aPlaceholderImage
            if !ignoreImageCache {
                if let cachedImage = fw_loadImageCache(url: url) {
                    placeholderImage = cachedImage
                }
            }
            fw_setImage(url: url, placeholderImage: placeholderImage, options: .avoidSetImage, context: nil) { [weak self] image in
                self?.image = image
            } completion: { [weak self] image, error in
                self?.progress = 1
                if image != nil { self?.image = image }
                completion?(image)
            } progress: { [weak self] progress in
                self?.progress = progress
            }
        } else if let livePhoto = imageURL as? PHLivePhoto {
            progress = 1
            self.livePhoto = livePhoto
            completion?(nil)
        } else if let playerItem = imageURL as? AVPlayerItem {
            progress = 1
            self.videoPlayerItem = playerItem
            completion?(nil)
        } else if let image = imageURL as? UIImage {
            progress = 1
            self.image = image
            completion?(self.image)
        } else {
            progress = 1
            self.image = aPlaceholderImage
            completion?(nil)
        }
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UISlider {
            return false
        }
        return true
    }
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        handleDidEndZooming()
    }
    
    private func setZoomScale(_ zoomScale: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .init(rawValue: 7<<16)) {
                self.scrollView.zoomScale = zoomScale
            }
        } else {
            scrollView.zoomScale = zoomScale
        }
    }
    
    private func zoomToRect(_ rect: CGRect, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .init(rawValue: 7<<16)) {
                self.scrollView.zoom(to: rect, animated: false)
            }
        } else {
            scrollView.zoom(to: rect, animated: false)
        }
    }
    
    private func syncVideoProgressSlider() {
        guard let videoPlayer = videoPlayer else { return }
        let currentSeconds = CMTimeGetSeconds(videoPlayer.currentTime())
        videoToolbar.slider.value = Float(currentSeconds)
        updateVideoSliderLeftLabel()
    }
    
    private func configVideoProgressSlider() {
        guard let videoPlayerItem = videoPlayerItem else { return }
        videoToolbar.sliderLeftLabel.text = timeString(from: 0)
        let duration = CMTimeGetSeconds(videoPlayerItem.asset.duration)
        videoToolbar.sliderRightLabel.text = timeString(from: duration)
        
        videoToolbar.slider.minimumValue = 0.0
        videoToolbar.slider.maximumValue = Float(duration)
        videoToolbar.slider.value = 0
        videoToolbar.slider.addTarget(self, action: #selector(handleStartDragVideoSlider(_:)), for: .touchDown)
        videoToolbar.slider.addTarget(self, action: #selector(handleDraggingVideoSlider(_:)), for: .valueChanged)
        videoToolbar.slider.addTarget(self, action: #selector(handleFinishDragVideoSlider(_:)), for: .touchUpInside)
        
        addPlayerTimeObserver()
    }
    
    private func addPlayerTimeObserver() {
        guard videoTimeObserver == nil else { return }
        videoTimeObserver = videoPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { [weak self] time in
            self?.syncVideoProgressSlider()
        })
    }
    
    private func removePlayerTimeObserver() {
        guard let observer = videoTimeObserver else { return }
        videoPlayer?.removeTimeObserver(observer)
        videoTimeObserver = nil
    }
    
    private func updateVideoSliderLeftLabel() {
        guard let videoPlayer = videoPlayer else { return }
        let currentSeconds = CMTimeGetSeconds(videoPlayer.currentTime())
        videoToolbar.sliderLeftLabel.text = timeString(from: currentSeconds)
    }
    
    private func timeString(from seconds: Double) -> String {
        let min: UInt = UInt(floor(seconds / 60.0))
        let sec: UInt = UInt(floor(seconds - Double(min * 60)))
        return String(format: "%02ld:%02ld", min, sec)
    }
    
    private func initLivePhotoViewIfNeeded() {
        if _livePhotoView != nil { return }
        let result = PHLivePhotoView()
        _livePhotoView = result
        scrollView.addSubview(result)
    }
    
    private func initVideoPlayerLayerIfNeeded() {
        guard videoPlayerView == nil else { return }
        
        let videoPlayerView = ZoomImageVideoPlayerView()
        self.videoPlayerView = videoPlayerView
        _videoPlayerLayer = videoPlayerView.layer as? AVPlayerLayer
        videoPlayerView.isHidden = true
        scrollView.addSubview(videoPlayerView)
    }
    
    private func initVideoToolbarIfNeeded() {
        guard _videoToolbar == nil else { return }
            
        _videoToolbar = {
            let videoToolbar = ZoomImageVideoToolbar()
            videoToolbar.paddings = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            videoToolbar.playButton.addTarget(self, action: #selector(handlePlayButton(_:)), for: .touchUpInside)
            videoToolbar.pauseButton.addTarget(self, action: #selector(handlePauseButton), for: .touchUpInside)
            videoToolbar.isHidden = true
            addSubview(videoToolbar)
            return videoToolbar
        }()
    }
    
    private func initVideoPlayButtonIfNeeded() {
        guard _videoPlayButton == nil else { return }
        
        _videoPlayButton = {
            let playButton = UIButton()
            playButton.fw_touchInsets = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)
            playButton.tag = 1
            playButton.setImage(videoPlayButtonImage, for: .normal)
            playButton.addTarget(self, action: #selector(handlePlayButton(_:)), for: .touchUpInside)
            playButton.isHidden = true
            addSubview(playButton)
            return playButton
        }()
    }
    
    private func initVideoCloseButtonIfNeeded() {
        guard _videoCloseButton == nil else { return }
        
        _videoCloseButton = {
            let closeButton = UIButton()
            closeButton.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            closeButton.setImage(videoCloseButtonImage, for: .normal)
            closeButton.addTarget(self, action: #selector(handleCloseButton(_:)), for: .touchUpInside)
            closeButton.isHidden = true
            addSubview(closeButton)
            return closeButton
        }()
    }
    
    private func initVideoRelatedViewsIfNeeded() {
        initVideoPlayerLayerIfNeeded()
        initVideoToolbarIfNeeded()
        initVideoPlayButtonIfNeeded()
        initVideoCloseButtonIfNeeded()
        setNeedsLayout()
    }
    
    private func destroyVideoRelatedObjectsIfNeeded() {
        NotificationCenter.default.removeObserver(self, name: AVPlayerItem.didPlayToEndTimeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        removePlayerTimeObserver()
        
        videoPlayerView?.removeFromSuperview()
        videoPlayerView = nil
        
        videoToolbar.removeFromSuperview()
        _videoToolbar = nil
        
        videoPlayButton.removeFromSuperview()
        _videoPlayButton = nil
        
        videoCloseButton.removeFromSuperview()
        _videoCloseButton = nil
        
        videoPlayer = nil
        _videoPlayerLayer?.player = nil
    }
    
    private func enabledZoomImageView() -> Bool {
        var enabledZoom = true
        if let isEnabled = delegate?.enabledZoomView?(in: self) {
            enabledZoom = isEnabled
        } else if image == nil && livePhoto == nil && videoPlayerItem == nil {
            enabledZoom = false
        }
        return enabledZoom
    }
    
    private func finalViewportRect() -> CGRect {
        var rect = viewportRect
        if CGRectIsEmpty(rect) && !CGRectIsEmpty(bounds) {
            // 有可能此时还没有走到过 layoutSubviews 因此拿不到正确的 scrollView 的 size，因此这里要强制 layout 一下
            if !scrollView.bounds.size.equalTo(bounds.size) {
                setNeedsLayout()
                layoutIfNeeded()
            }
            rect = CGRect(x: 0, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
        }
        return rect
    }
    
    private func hideViews() {
        _livePhotoView?.isHidden = true
        _imageView?.isHidden = true
        _videoPlayButton?.isHidden = true
        _videoPlayerLayer?.isHidden = true
        _videoToolbar?.isHidden = true
        _videoCloseButton?.isHidden = true
        _videoToolbar?.pauseButton.isHidden = true
        _videoToolbar?.playButton.isHidden = true
    }
    
    private func handleDidEndZooming() {
        let viewport = finalViewportRect()
        
        let contentView = self.contentView
        // 强制 layout 以确保下面的一堆计算依赖的都是最新的 frame 的值
        layoutIfNeeded()
        let contentViewFrame = contentView != nil ? convert(contentView!.frame, from: contentView?.superview) : CGRect.zero
        var contentInset = UIEdgeInsets.zero
        contentInset.top = viewport.minY
        contentInset.left = viewport.minX
        contentInset.right = bounds.width - viewport.maxX
        contentInset.bottom = bounds.height - viewport.maxY
        
        // 图片 height 比选图框(viewport)的 height 小，这时应该把图片纵向摆放在选图框中间，且不允许上下移动
        if viewport.height > contentViewFrame.height {
            // 用 floor 而不是 flat，是因为 flat 本质上是向上取整，会导致 top + bottom 比实际的大，然后 scrollView 就认为可滚动了
            contentInset.top = floor(viewport.midY - contentViewFrame.height / 2.0)
            contentInset.bottom = floor(bounds.height - viewport.midY - contentViewFrame.height / 2.0)
        }
        
        // 图片 width 比选图框的 width 小，这时应该把图片横向摆放在选图框中间，且不允许左右移动
        if viewport.width > contentViewFrame.width {
            contentInset.left = floor(viewport.midX - contentViewFrame.width / 2.0)
            contentInset.right = floor(bounds.width - viewport.midX - contentViewFrame.width / 2.0)
        }
        
        scrollView.contentInset = contentInset
        scrollView.contentSize = contentView?.frame.size ?? .zero
    }
    
    @objc private func handleCloseButton(_ button: UIButton) {
        if let viewController = fw_viewController, viewController.fw_isPresented {
            viewController.dismiss(animated: true)
        }
    }
    
    @objc private func handlePlayButton(_ button: UIButton?) {
        addPlayerTimeObserver()
        videoPlayer?.play()
        videoPlayButton.isHidden = true
        videoToolbar.playButton.isHidden = true
        videoToolbar.pauseButton.isHidden = false
        if button?.tag == 1 {
            if showsVideoCloseButton {
                videoCloseButton.isHidden = true
            }
            if showsVideoToolbar {
                videoToolbar.isHidden = true
                delegate?.zoomImageView?(self, didHideVideoToolbar: true)
            }
        }
    }
    
    @objc private func handlePauseButton() {
        videoPlayer?.pause()
        videoToolbar.playButton.isHidden = false
        videoToolbar.pauseButton.isHidden = true
        if !showsVideoToolbar {
            videoPlayButton.isHidden = false
        }
    }
    
    @objc private func handleVideoPlayToEndEvent() {
        videoPlayer?.seek(to: CMTimeMake(value: 0, timescale: 1))
        videoPlayButton.isHidden = false
        videoToolbar.playButton.isHidden = false
        videoToolbar.pauseButton.isHidden = true
    }
    
    @objc private func handleStartDragVideoSlider(_ slider: UISlider) {
        videoPlayer?.pause()
        removePlayerTimeObserver()
    }
    
    @objc private func handleDraggingVideoSlider(_ slider: UISlider) {
        guard !isSeekingVideo else { return }
        isSeekingVideo = true
        updateVideoSliderLeftLabel()
        
        let currentValue: Float64 = Float64(slider.value)
        videoPlayer?.seek(to: CMTimeMakeWithSeconds(currentValue, preferredTimescale: Int32(NSEC_PER_SEC)), completionHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.isSeekingVideo = false
            }
        })
    }
    
    @objc private func handleFinishDragVideoSlider(_ slider: UISlider) {
        videoPlayer?.play()
        videoPlayButton.isHidden = true
        videoToolbar.playButton.isHidden = true
        videoToolbar.pauseButton.isHidden = false
        
        addPlayerTimeObserver()
    }
    
    @objc private func handleSingleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        if videoPlayerItem != nil {
            if showsVideoCloseButton {
                videoCloseButton.isHidden = !videoCloseButton.isHidden
            }
            if showsVideoToolbar {
                videoToolbar.isHidden = !videoToolbar.isHidden
                delegate?.zoomImageView?(self, didHideVideoToolbar: videoToolbar.isHidden)
            }
        }
        
        let gesturePoint = gestureRecognizer.location(in: gestureRecognizer.view)
        delegate?.singleTouch?(in: self, location: gesturePoint)
    }
    
    @objc private func handleDoubleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        let gesturePoint = gestureRecognizer.location(in: gestureRecognizer.view)
        delegate?.doubleTouch?(in: self, location: gesturePoint)
        
        if enabledZoomImageView() {
            // 默认第一次双击放大，再次双击还原，可通过zoomInScaleBlock自定义缩放效果
            if scrollView.zoomScale >= scrollView.maximumZoomScale {
                setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                var newZoomScale = scrollView.maximumZoomScale
                if let scaleBlock = zoomInScaleBlock {
                    newZoomScale = scaleBlock(scrollView)
                }
                
                var zoomRect: CGRect = .zero
                let tapPoint: CGPoint = contentView?.convert(gesturePoint, from: gestureRecognizer.view) ?? .zero
                zoomRect.size.width = self.bounds.width / newZoomScale
                zoomRect.size.height = self.bounds.height / newZoomScale
                zoomRect.origin.x = tapPoint.x - zoomRect.width / 2
                zoomRect.origin.y = tapPoint.y - zoomRect.height / 2
                zoomToRect(zoomRect, animated: true)
            }
        }
    }
    
    @objc private func handleLongPressGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if enabledZoomImageView() && gestureRecognizer.state == .began {
            delegate?.longPress?(in: self)
        }
    }
    
    @objc private func applicationDidEnterBackground() {
        pauseVideo()
    }
    
}

/// ZoomImageView视频工具栏
open class ZoomImageVideoToolbar: UIView {
    
    /// 自定义toolbar 内部的间距，默认为 {0, 0, 0, 0}
    open var paddings: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 自定义video 播放时屏幕底部工具栏的播放图标
    open var playButtonImage: UIImage? {
        didSet {
            playButton.setImage(playButtonImage, for: .normal)
            setNeedsLayout()
        }
    }
    
    /// 自定义video 播放时屏幕底部工具栏的暂停图标
    open var pauseButtonImage: UIImage? {
        didSet {
            pauseButton.setImage(pauseButtonImage, for: .normal)
            setNeedsLayout()
        }
    }
    
    open lazy var playButton: UIButton = {
        let result = UIButton()
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.setImage(playButtonImage, for: .normal)
        return result
    }()
    
    open lazy var pauseButton: UIButton = {
        let result = UIButton()
        result.isHidden = true
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.setImage(pauseButtonImage, for: .normal)
        return result
    }()
    
    open lazy var slider: UISlider = {
        let result = UISlider()
        result.minimumTrackTintColor = UIColor(red: 195.0 / 255.0, green: 195.0 / 255.0, blue: 195.0 / 255.0, alpha: 1.0)
        result.maximumTrackTintColor = UIColor(red: 95.0 / 255.0, green: 95.0 / 255.0, blue: 95.0 / 255.0, alpha: 1.0)
        result.fw_thumbSize = CGSize(width: 12, height: 12)
        result.fw_thumbColor = UIColor.white
        return result
    }()
    
    open lazy var sliderLeftLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 12)
        result.textColor = UIColor.white
        result.textAlignment = .center
        return result
    }()
    
    open lazy var sliderRightLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 12)
        result.textColor = UIColor.white
        result.textAlignment = .center
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
        playButtonImage = AppBundle.videoStartImage
        pauseButtonImage = AppBundle.videoPauseImage
        
        addSubview(playButton)
        addSubview(pauseButton)
        addSubview(slider)
        addSubview(sliderLeftLabel)
        addSubview(sliderRightLabel)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 10
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let contentHeight = bounds.height - (paddings.top + paddings.bottom)
        let timeLabelWidth: CGFloat = 55
        
        playButton.frame = {
            let size = playButton.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            return CGRect(x: paddings.left, y: (contentHeight - size.height) / 2.0 + paddings.top, width: size.width, height: size.height)
        }()
        
        pauseButton.frame = {
            let size = pauseButton.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            return CGRect(x: playButton.frame.midX - size.width / 2, y: playButton.frame.midY - size.height / 2, width: size.width, height: size.height)
        }()
        
        sliderLeftLabel.frame = {
            let marginLeft: CGFloat = 19
            return CGRect(x: playButton.frame.maxX + marginLeft, y: paddings.top, width: timeLabelWidth, height: contentHeight)
        }()
        
        sliderRightLabel.frame = {
            return CGRect(x: bounds.width - paddings.right - timeLabelWidth, y: paddings.top, width: timeLabelWidth, height: contentHeight)
        }()
        
        slider.frame = {
            let marginToLabel: CGFloat = 4
            let x = sliderLeftLabel.frame.maxX + marginToLabel
            return CGRect(x: x, y: paddings.top, width: sliderRightLabel.frame.minX - marginToLabel - x, height: contentHeight)
        }()
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let contentHeight = maxHeightAmongViews([playButton, pauseButton, sliderLeftLabel, sliderRightLabel, slider])
        var fittingSize = size
        fittingSize.height = contentHeight + (paddings.top + paddings.bottom)
        return fittingSize
    }
    
    private func maxHeightAmongViews(_ views: [UIView]) -> CGFloat {
        var maxValue: CGFloat = 0
        views.forEach { view in
            let height = view.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height
            maxValue = max(height, maxValue)
        }
        return maxValue
    }
    
}

/// ZoomImageView视频播放器视图
open class ZoomImageVideoPlayerView: UIView {
    
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
}
