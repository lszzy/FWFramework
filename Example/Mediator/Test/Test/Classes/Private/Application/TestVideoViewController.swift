//
//  TestVideoViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

class TestPlayerView: FWVideoPlayerView, FWVideoPlayerDelegate {
    static func videoPlayer() -> FWVideoPlayer {
        let result = FWVideoPlayer()
        result.modalPresentationStyle = .fullScreen
        let playerView = TestPlayerView(frame: .zero)
        playerView.videoPlayer = result
        result.playerView = playerView
        return result
    }
    
    weak var videoPlayer: FWVideoPlayer? {
        didSet {
            videoPlayer?.playerDelegate = self
        }
    }
    
    private lazy var closeButton: FWNavigationButton = {
        let result = FWNavigationButton(image: FWIcon.closeImage)
        result.tintColor = Theme.textColor
        result.fwAddTouch { sender in
            FWRouter.closeViewController(animated: true)
        }
        return result
    }()
    
    private lazy var playButton: FWNavigationButton = {
        let result = FWNavigationButton(image: FWIconImage("octicon-playback-play", 24))
        result.tintColor = Theme.textColor
        result.fwAddTouch { [weak self] sender in
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
        backgroundColor = Theme.backgroundColor
        
        addSubview(closeButton)
        addSubview(playButton)
        closeButton.fwLayoutChain.leftToSafeArea(8).topToSafeArea(8)
        playButton.fwLayoutChain.rightToSafeArea(8).topToSafeArea(8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playerPlaybackStateDidChange(_ player: FWVideoPlayer) {
        if player.playbackState == .playing {
            playButton.setImage(FWIconImage("octicon-playback-pause", 24), for: .normal)
        } else {
            playButton.setImage(FWIconImage("octicon-playback-play", 24), for: .normal)
        }
    }
}

@objcMembers class TestVideoViewController: TestViewController, FWVideoPlayerDelegate, FWVideoPlayerPlaybackDelegate {
    fileprivate var player = FWVideoPlayer()
    lazy var resourceLoader = FWPlayerCacheLoaderManager()
    
    @FWUserDefaultAnnotation("TestVideoCacheEnabled", defaultValue: false)
    private var cacheEnabled: Bool
    
    // MARK: object lifecycle
    deinit {
        self.player.willMove(toParent: nil)
        self.player.view.removeFromSuperview()
        self.player.removeFromParent()
    }

    // MARK: view lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player.playerDelegate = self
        self.player.playbackDelegate = self
        
        self.player.playerView.playerBackgroundColor = Theme.backgroundColor
        
        self.addChild(self.player)
        self.fwView.addSubview(self.player.view)
        self.player.view.fwPinEdgesToSuperview()
        self.player.didMove(toParent: self)
        
        self.playVideo()
        self.player.playbackLoops = true
        
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
        
        fwShowLoading()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !fwIsDataLoaded {
            fwIsDataLoaded = true
            self.player.playFromBeginning()
        }
    }
    
    override func renderModel() {
        fwSetRightBarItem(cacheEnabled ? "禁用缓存" : "启用缓存") { [weak self] sender in
            guard let strongSelf = self else { return }
            strongSelf.cacheEnabled = !strongSelf.cacheEnabled
            strongSelf.playVideo()
            strongSelf.renderModel()
        }
    }
    
    private func playVideo() {
        let videoUrl = URL(string: "http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4")!
        if cacheEnabled {
            self.player.asset = resourceLoader.urlAsset(with: videoUrl)
        } else {
            self.player.url = videoUrl
        }
    }
    
    // MARK: -
    
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
    
    func playerReady(_ player: FWVideoPlayer) {
        print("\(#function) ready")
        
        fwHideLoading()
    }
    
    func playerPlaybackStateDidChange(_ player: FWVideoPlayer) {
        print("\(#function) \(player.playbackState.rawValue)")
    }
    
    func player(_ player: FWVideoPlayer, didFailWithError error: Error?) {
        print("\(#function) error.description")
        
        fwHideLoading()
    }
}
