//
//  TestVideoController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestVideoController: UIViewController, ViewControllerProtocol {
    
    // MARK: - Accessor
    fileprivate var player = VideoPlayer()
    lazy var resourceLoader = PlayerCacheLoaderManager()
    
    @StoredValue("TestVideoCacheEnabled")
    private var cacheEnabled: Bool = false
    
    @StoredValue("TestVideoUrl")
    private var videoUrl: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.player.playerDelegate = self
        self.player.playbackDelegate = self
        
        self.player.playerView.playerBackgroundColor = AppTheme.backgroundColor
        
        self.addChild(self.player)
        self.view.addSubview(self.player.view)
        self.player.view.app.pinEdges()
        self.player.didMove(toParent: self)
        
        self.playVideo()
        self.player.playbackLoops = true
        
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
        
        app.showLoading()
    }
    
    deinit {
        self.player.willMove(toParent: nil)
        self.player.view.removeFromSuperview()
        self.player.removeFromParent()
    }
    
    // MARK: - Private
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            guard let self = self else { return }
            
            self.app.showSheet(title: nil, message: nil, actions: [
                self.cacheEnabled ? "禁用缓存" : "启用缓存",
                "自定义视频URL",
            ], actionBlock: { [weak self] index in
                guard let self = self else { return }
                
                if index == 0 {
                    self.cacheEnabled = !self.cacheEnabled
                    self.playVideo()
                } else {
                    self.app.showPrompt(title: "请输入视频URL", message: nil) { [weak self] textField in
                        textField.text = self?.videoUrl ?? ""
                    } confirmBlock: { [weak self] text in
                        self?.videoUrl = text
                        self?.playVideo()
                    }
                }
            })
        }
    }
    
    private func playVideo() {
        var url: URL?
        if !videoUrl.isEmpty {
            url = URL.app.url(string: videoUrl)
        } else {
            url = Bundle.main.url(forResource: "Video", withExtension: "mp4")
        }
        guard let url = url else { return }
        
        if cacheEnabled {
            self.player.asset = resourceLoader.urlAsset(url: url)
        } else {
            self.player.url = url
        }
    }
    
    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        switch self.player.playbackState {
        case .stopped:
            self.player.playFromBeginning()
            break
        case .paused:
            self.player.playFromCurrentTime()
            break
        case .playing:
            self.player.pause()
            break
        case .failed:
            self.player.pause()
            break
        }
    }
    
}

extension TestVideoController: VideoPlayerDelegate, VideoPlayerPlaybackDelegate {
    
    func playerReady(_ player: VideoPlayer) {
        print("\(#function) ready")
        
        app.hideLoading()
    }
    
    func playerPlaybackStateDidChange(_ player: VideoPlayer) {
        print("\(#function) \(player.playbackState.rawValue)")
    }
    
    func player(_ player: VideoPlayer, didFailWithError error: Error?) {
        print("\(#function) error.description")
        
        app.hideLoading()
    }
    
}

class TestPlayerView: VideoPlayerView, VideoPlayerDelegate {
    static func videoPlayer() -> VideoPlayer {
        let result = VideoPlayer()
        result.modalPresentationStyle = .fullScreen
        let playerView = TestPlayerView(frame: .zero)
        playerView.videoPlayer = result
        result.playerView = playerView
        return result
    }
    
    weak var videoPlayer: VideoPlayer? {
        didSet {
            videoPlayer?.playerDelegate = self
        }
    }
    
    private lazy var closeButton: ToolbarButton = {
        let result = ToolbarButton(image: Icon.closeImage)
        result.tintColor = AppTheme.textColor
        result.app.addTouch { sender in
            Navigator.close(animated: true)
        }
        return result
    }()
    
    private lazy var playButton: ToolbarButton = {
        let result = ToolbarButton(image: APP.iconImage("zdmi-var-play", 24))
        result.tintColor = AppTheme.textColor
        result.app.addTouch { [weak self] sender in
            guard let player = self?.videoPlayer else { return }
            
            if player.playbackState == .playing {
                player.pause()
            } else if player.playbackState == .paused {
                player.playFromCurrentTime()
            } else {
                player.playFromBeginning()
            }
        }
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.backgroundColor
        
        addSubview(closeButton)
        addSubview(playButton)
        closeButton.app.layoutChain.left(toSafeArea: 8).top(toSafeArea: 8)
        playButton.app.layoutChain.right(toSafeArea: 8).top(toSafeArea: 8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playerPlaybackStateDidChange(_ player: VideoPlayer) {
        if player.playbackState == .playing {
            playButton.setImage(APP.iconImage("zdmi-var-pause", 24), for: .normal)
        } else {
            playButton.setImage(APP.iconImage("zdmi-var-play", 24), for: .normal)
        }
    }
}
